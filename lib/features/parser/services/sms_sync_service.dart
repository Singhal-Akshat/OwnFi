import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import '../../../core/database_service.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import 'sms_parser_service.dart';

class SmsSyncService {
  final DatabaseService _dbService;
  final SmsParserService _parser = SmsParserService();
  final SmsQuery _query = SmsQuery();
  final _storage = const FlutterSecureStorage();

  SmsSyncService(this._dbService);

  Future<int> syncSmsInbox() async {
    // 1. Request SMS Permissions
    var permission = await Permission.sms.status;
    if (permission.isDenied) {
      permission = await Permission.sms.request();
      if (permission.isDenied) {
        throw Exception('SMS read permission was denied by the user.');
      }
    }

    // 2. Fetch last sync timestamp (default to 7 days ago if first time)
    final lastSyncStr = await _storage.read(key: 'last_sms_sync_time');
    DateTime lastSyncTime = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.now().subtract(const Duration(days: 7));

    // 3. Query all inbox messages
    List<SmsMessage> messages = [];
    try {
      messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );
    } catch (e) {
      // On Windows/non-Android, querying SMS will fail/throw
      throw Exception('SMS reading is only supported on Android: $e');
    }

    // 4. Filter messages that are newer than lastSyncTime
    final newMessages = messages.where((msg) {
      if (msg.date == null || msg.body == null) return false;
      return msg.date!.isAfter(lastSyncTime);
    }).toList();

    if (newMessages.isEmpty) {
      return 0;
    }

    int importedCount = 0;
    final isar = _dbService.isar;

    // Load credit cards to match last4 digits
    final cards = await _dbService.getAllCreditCards();

    // 5. Process and insert transactions
    await isar.writeTxn(() async {
      for (final msg in newMessages) {
        final parsed = _parser.parse(msg.body!);
        if (parsed == null) continue;

        final txDate = msg.date ?? DateTime.now();

        // Idempotency check: verify this transaction doesn't already exist
        final existing = await isar.transactions
            .filter()
            .amountEqualTo(parsed.amount)
            .descriptionEqualTo(parsed.description)
            .timestampEqualTo(txDate)
            .findFirst();

        if (existing != null) continue; // Duplicate

        // Match card last4 if present
        String? matchedCardId;
        String? accountName = parsed.cardLast4 != null ? 'Credit Card' : (parsed.accountLast4 != null ? 'Bank' : 'Cash');

        if (parsed.cardLast4 != null) {
          final matchedCard = cards.firstWhere(
            (c) => c.last4 == parsed.cardLast4,
            orElse: () => CreditCard(),
          );
          if (matchedCard.id != Isar.autoIncrement) {
            matchedCardId = matchedCard.id.toString();
            accountName = '${matchedCard.cardName} (..${matchedCard.last4})';
            
            // Adjust card balance in database!
            if (parsed.transactionType == 'expense') {
              matchedCard.balance += parsed.amount;
            } else if (parsed.transactionType == 'income') {
              // Cash back or refunds
              matchedCard.balance -= parsed.amount;
            }
            await isar.creditCards.put(matchedCard);
          }
        }

        final tx = Transaction()
          ..amount = parsed.amount
          ..description = parsed.description
          ..category = parsed.category
          ..timestamp = txDate
          ..transactionType = parsed.transactionType
          ..source = 'sms'
          ..cardId = matchedCardId
          ..accountName = accountName;

        await isar.transactions.put(tx);
        importedCount++;
      }
    });

    // 6. Update last sync time
    await _storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());

    return importedCount;
  }
}
