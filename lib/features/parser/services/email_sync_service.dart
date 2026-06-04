import 'dart:typed_data';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/database_service.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import 'sms_parser_service.dart';

class EmailSyncService {
  final DatabaseService _dbService;
  final SmsParserService _parser = SmsParserService(); // We reuse regex logic for email bodies
  final _storage = const FlutterSecureStorage();

  EmailSyncService(this._dbService);

  // Check if email credentials are set in secure storage
  Future<bool> hasCredentials() async {
    final email = await _storage.read(key: 'imap_email');
    final password = await _storage.read(key: 'imap_password');
    return email != null && password != null;
  }

  // Save email credentials
  Future<void> saveCredentials(String email, String password, String host, int port) async {
    await _storage.write(key: 'imap_email', value: email);
    await _storage.write(key: 'imap_password', value: password);
    await _storage.write(key: 'imap_host', value: host);
    await _storage.write(key: 'imap_port', value: port.toString());
  }

  // Main sync method
  Future<int> syncEmails() async {
    final email = await _storage.read(key: 'imap_email');
    final password = await _storage.read(key: 'imap_password');
    final host = await _storage.read(key: 'imap_host') ?? 'imap.gmail.com';
    final portStr = await _storage.read(key: 'imap_port') ?? '993';
    final port = int.tryParse(portStr) ?? 993;

    if (email == null || password == null) {
      throw Exception('IMAP credentials not configured. Please configure them in Settings.');
    }

    final client = ImapClient();
    try {
      await client.connectToServer(host, port, isSecure: true);
      await client.login(email, password);
      await client.selectInbox();
    } catch (e) {
      throw Exception('Failed to connect or log in to IMAP server: $e');
    }

    // Determine search date (last sync time or 14 days ago by default)
    final lastSyncStr = await _storage.read(key: 'last_email_sync_time');
    DateTime lastSyncTime = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.now().subtract(const Duration(days: 14));

    // Construct IMAP Search
    // Search since lastSyncTime and matching keywords: "debited", "spent", "credited", "statement"
    final query = SearchQueryBuilder.from(
      '',
      SearchQueryType.subject,
      sentSince: lastSyncTime,
    );
    final searchResult = await client.searchMessagesWithQuery(query);

    if (searchResult.matchingSequence == null || searchResult.matchingSequence!.isEmpty) {
      await client.logout();
      return 0;
    }

    // Fetch messages details
    final fetchResult = await client.fetchMessages(
      searchResult.matchingSequence!,
      'BODY.PEEK[]', // Fetch full email body and attachments
    );

    // Pre-validate Gemini key for bulk
    final apiKey = await _storage.read(key: 'ai_gemini_key');
    if (apiKey == null || apiKey.isEmpty) {
      await client.logout();
      throw Exception('Gemini API Key missing! Please configure it in AI Advisor settings before performing an email sync.');
    }

    int count = 0;
    final isar = _dbService.isar;
    final cards = await _dbService.getAllCreditCards();

    for (final message in fetchResult.messages) {
      final subject = message.decodeSubject() ?? '';
      final bodyText = message.decodeTextPlainPart() ?? message.decodeTextHtmlPart() ?? '';
      final date = message.decodeDate() ?? DateTime.now();

      // Case 1: Detect transaction alert emails
      if (_isTransactionSubject(subject) || _isTransactionBody(bodyText)) {
        final parsed = await _parser.parseAsync(bodyText, isBulk: true);
        if (parsed != null) {
          await isar.writeTxn(() async {
            // Deduplicate
            final existing = await isar.transactions
                .filter()
                .amountEqualTo(parsed.amount)
                .descriptionEqualTo(parsed.description)
                .timestampEqualTo(date)
                .findFirst();

            if (existing == null) {
              String? cardId;
              String? accountName = parsed.cardLast4 != null ? 'Credit Card' : (parsed.accountLast4 != null ? 'Bank' : 'Cash');

              if (parsed.cardLast4 != null) {
                final card = cards.firstWhere((c) => c.last4 == parsed.cardLast4, orElse: () => CreditCard());
                if (card.id != Isar.autoIncrement) {
                  cardId = card.id.toString();
                  accountName = '${card.cardName} (..${card.last4})';
                  if (parsed.transactionType == 'expense') {
                    card.balance += parsed.amount;
                  } else {
                    card.balance -= parsed.amount;
                  }
                  await isar.creditCards.put(card);
                }
              }

              final tx = Transaction()
                ..amount = parsed.amount
                ..description = parsed.description
                ..category = parsed.category
                ..timestamp = date
                ..transactionType = parsed.transactionType
                ..source = 'email'
                ..cardId = cardId
                ..accountName = accountName
                ..parserSource = parsed.parserSource
                ..aiComparisonNotes = parsed.aiComparisonNotes
                ..rawMessage = bodyText;

              await isar.transactions.put(tx);
              count++;
            }
          });
        }
      }

      // Case 2: Detect credit card statement attachments
      if (_isStatementSubject(subject)) {
        // Look for PDF attachments
        final parts = message.parts;
        if (parts != null) {
          for (final part in parts) {
            final fileName = part.decodeFileName() ?? '';
            if (fileName.toLowerCase().endsWith('.pdf')) {
              final pdfBytes = part.decodeContentBinary();
              if (pdfBytes != null) {
                await _processStatementPdf(pdfBytes, fileName, cards);
              }
            }
          }
        }
      }
    }

    await client.logout();
    await _storage.write(key: 'last_email_sync_time', value: DateTime.now().toIso8601String());
    return count;
  }

  bool _isTransactionSubject(String subject) {
    final s = subject.toLowerCase();
    return s.contains('transaction alert') ||
        s.contains('alert:') ||
        s.contains('spent') ||
        s.contains('debited') ||
        s.contains('credited') ||
        s.contains('payment successful');
  }

  bool _isTransactionBody(String body) {
    final b = body.toLowerCase();
    return b.contains('spent rs') || b.contains('debited from') || b.contains('credited to');
  }

  bool _isStatementSubject(String subject) {
    final s = subject.toLowerCase();
    return s.contains('credit card statement') || s.contains('e-statement') || s.contains('statement ending');
  }

  // PDF statement parsing and decryption
  Future<void> _processStatementPdf(Uint8List pdfBytes, String fileName, List<CreditCard> cards) async {
    // 1. Identify which credit card this statement belongs to (from filename or content snippet)
    CreditCard? matchedCard;
    for (final card in cards) {
      if (fileName.toLowerCase().contains(card.cardName.toLowerCase().replaceAll(' ', '')) ||
          fileName.toLowerCase().contains(card.last4)) {
        matchedCard = card;
        break;
      }
    }

    if (matchedCard == null) return;

    // 2. Fetch the password from Secure Storage
    final passwordKey = 'card_password_${matchedCard.id}';
    final cardPassword = await _storage.read(key: passwordKey);

    if (cardPassword == null || cardPassword.isEmpty) {
      // Cannot decrypt statement without user password
      return;
    }

    try {
      // 3. Load and decrypt PDF locally using Syncfusion PDF library
      final PdfDocument document = PdfDocument(
        inputBytes: pdfBytes,
        password: cardPassword,
      );

      // 4. Extract text content
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();

      // 5. Parse EMIs and Transactions from statement text
      await _parseStatementText(text, matchedCard);
    } catch (e) {
      // Decryption failed or parsing error
      print('Failed to decrypt statement PDF: $e');
    }
  }

  Future<void> _parseStatementText(String text, CreditCard card) async {
    final isar = _dbService.isar;
    final lines = text.split('\n');

    // Simple regex to find EMI schedules (e.g. "EMI 3 of 12", "MacBook Emi Rs. 10000")
    final emiReg = RegExp(
      r'(?:emi|installment)\s*(\d+)\s*(?:of|/)\s*(\d+).*?([0-9,]+(?:\.[0-9]{2})?)',
      caseSensitive: false,
    );

    List<CreditCardEmi> parsedEmis = [];

    for (final line in lines) {
      final match = emiReg.firstMatch(line);
      if (match != null) {
        final currentMonth = int.tryParse(match.group(1)!) ?? 1;
        final totalMonths = int.tryParse(match.group(2)!) ?? 12;
        final installmentAmt = double.tryParse(match.group(3)!.replaceAll(',', '')) ?? 0.0;

        // Try to find a description before the match
        var desc = line.substring(0, match.start).trim();
        if (desc.isEmpty) desc = 'Active Credit Card EMI';

        parsedEmis.add(
          CreditCardEmi()
            ..description = desc
            ..totalAmount = installmentAmt * totalMonths
            ..monthlyInstallment = installmentAmt
            ..totalMonths = totalMonths
            ..remainingMonths = totalMonths - currentMonth
            ..startDate = DateTime.now().subtract(Duration(days: 30 * currentMonth)),
        );
      }
    }

    // Save active EMIs list to card
    if (parsedEmis.isNotEmpty) {
      await isar.writeTxn(() async {
        card.activeEmis = parsedEmis;
        await isar.creditCards.put(card);
      });
    }
  }
}
