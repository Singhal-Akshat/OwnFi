import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import '../../../core/database_service.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import 'sms_parser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Check if user set a custom calendar range
    final customStartStr = await _storage.read(key: 'settings_sync_start_date');
    final customEndStr = await _storage.read(key: 'settings_sync_end_date');
    DateTime? customStart;
    DateTime? customEnd;
    if (customStartStr != null && customEndStr != null) {
      customStart = DateTime.parse(customStartStr);
      customEnd = DateTime.parse(customEndStr);
    }

    DateTime? lastSyncTime;
    if (customStart == null || customEnd == null) {
      // 2. Fetch last sync timestamp
      final lastSyncStr = await _storage.read(key: 'last_sms_sync_time');
      if (lastSyncStr != null) {
        lastSyncTime = DateTime.parse(lastSyncStr);
      } else {
        // Calculate dynamic lookback time based on user settings
        String? lookbackValueStr = await _storage.read(key: 'settings_sms_lookback_value');
        String? lookbackUnit = await _storage.read(key: 'settings_sms_lookback_unit');

        if (lookbackValueStr == null) {
          // Fallback to legacy key settings_sms_lookback_days
          final legacyDays = await _storage.read(key: 'settings_sms_lookback_days');
          if (legacyDays != null) {
            lookbackValueStr = legacyDays;
            lookbackUnit = 'days';
          }
        }

        final lookbackValue = int.tryParse(lookbackValueStr ?? '180') ?? 180;
        final unit = lookbackUnit ?? 'days';

        if (unit == 'months') {
          final now = DateTime.now();
          int years = lookbackValue ~/ 12;
          int months = lookbackValue % 12;
          int targetYear = now.year - years;
          int targetMonth = now.month - months;
          if (targetMonth <= 0) {
            targetYear -= 1;
            targetMonth += 12;
          }
          int targetDay = now.day;
          final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          if (targetDay > daysInMonth) {
            targetDay = daysInMonth;
          }
          lastSyncTime = DateTime(targetYear, targetMonth, targetDay, now.hour, now.minute, now.second);
        } else {
          // days
          lastSyncTime = DateTime.now().subtract(Duration(days: lookbackValue));
        }
      }
    }

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

    // 4. Filter messages that are newer than lastSyncTime or within custom range
    final newMessages = messages.where((msg) {
      if (msg.date == null || msg.body == null) return false;
      if (customStart != null && customEnd != null) {
        return msg.date!.isAfter(customStart!) && msg.date!.isBefore(customEnd!.add(const Duration(days: 1)));
      }
      return msg.date!.isAfter(lastSyncTime!);
    }).toList();

    if (newMessages.isEmpty) {
      return 0;
    }

    int importedCount = 0;
    final isar = _dbService.isar;

    // Load credit cards to match last4 digits
    final cards = await _dbService.getAllCreditCards();

    // Pre-validate Gemini key for bulk
    final apiKey = await _storage.read(key: 'ai_gemini_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key missing! Please configure it in AI Advisor settings before performing a bulk sync.');
    }

    final prefs = await SharedPreferences.getInstance();
    final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];

    // 5. Pre-parse all messages via API before opening a DB transaction
    List<MapEntry<SmsMessage, ParsedSmsTransaction>> parsedMessages = [];
    for (final msg in newMessages) {
      if (msg.body == null) continue;
      if (skippedList.contains(msg.body)) continue;
      final parsed = await _parser.parseAsync(msg.body!, isBulk: true);
      if (parsed != null) {
        parsedMessages.add(MapEntry(msg, parsed));
      }
    }

    // 6. Process and insert transactions
    await isar.writeTxn(() async {
      for (final entry in parsedMessages) {
        final msg = entry.key;
        final txDate = msg.date ?? DateTime.now();
        final parsed = entry.value;

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
          ..accountName = accountName
          ..parserSource = parsed.parserSource
          ..aiComparisonNotes = parsed.aiComparisonNotes
          ..rawMessage = msg.body;

        await isar.transactions.put(tx);
        importedCount++;
      }
    });

    // 6. Update last sync time
    await _storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());

    return importedCount;
  }

  Future<List<Map<String, dynamic>>> fetchNewSmsForReview() async {
    var permission = await Permission.sms.status;
    if (permission.isDenied) {
      permission = await Permission.sms.request();
      if (permission.isDenied) {
        throw Exception('SMS read permission was denied by the user.');
      }
    }

    final customStartStr = await _storage.read(key: 'settings_sync_start_date');
    final customEndStr = await _storage.read(key: 'settings_sync_end_date');
    DateTime? customStart;
    DateTime? customEnd;
    if (customStartStr != null && customEndStr != null) {
      customStart = DateTime.parse(customStartStr);
      customEnd = DateTime.parse(customEndStr);
    }

    DateTime? lastSyncTime;
    if (customStart == null || customEnd == null) {
      final lastSyncStr = await _storage.read(key: 'last_sms_sync_time');
      if (lastSyncStr != null) {
        lastSyncTime = DateTime.parse(lastSyncStr);
      } else {
        final lookbackValueStr = await _storage.read(key: 'settings_sms_lookback_value');
        final lookbackValue = int.tryParse(lookbackValueStr ?? '180') ?? 180;
        lastSyncTime = DateTime.now().subtract(Duration(days: lookbackValue));
      }
    }

    List<SmsMessage> messages = [];
    try {
      messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
      await _parser.logDebug('Total SMS retrieved from Android Inbox: ${messages.length}');
    } catch (e) {
      await _parser.logDebug('Failed to query SMS Inbox: $e');
      throw Exception('SMS reading is only supported on Android: $e');
    }

    final newMessages = messages.where((msg) {
      if (msg.date == null || msg.body == null) return false;
      if (customStart != null && customEnd != null) {
        return msg.date!.isAfter(customStart!) && msg.date!.isBefore(customEnd!.add(const Duration(days: 1)));
      }
      return msg.date!.isAfter(lastSyncTime!);
    }).toList();

    // Sort descending by date (newest first)
    newMessages.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
    await _parser.logDebug('Filtered to ${newMessages.length} new messages after date check.');

    final allowDuplicatesStr = await _storage.read(key: 'settings_sms_sync_allow_duplicates') ?? 'false';
    final bool allowDuplicates = allowDuplicatesStr == 'true';

    List<Map<String, dynamic>> results = [];
    final isar = _dbService.isar;

    final prefs = await SharedPreferences.getInstance();
    final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];

    for (final msg in newMessages) {
      if (msg.body == null) continue;
      if (skippedList.contains(msg.body)) continue;

      if (!allowDuplicates) {
        final existing = await isar.transactions
            .filter()
            .rawMessageEqualTo(msg.body)
            .findFirst();
        if (existing != null) continue;
      }

      final isTx = await _parser.isTransactionalSms(msg.body!);

      results.add({
        'body': msg.body,
        'date': msg.date ?? DateTime.now(),
        'source': 'sms',
        'approvedByRegex': isTx,
      });
    }

    return results;
  }
}
