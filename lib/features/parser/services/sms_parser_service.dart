import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/model_repository.dart';
import '../../cards_loans/models/card_loan_models.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ParsedSmsTransaction {
  final double amount;
  final String description;
  final String transactionType; // 'expense' or 'income'
  final String category;
  final String? cardLast4;
  final String? accountLast4;
  final String merchant;
  final String? parserSource;
  final String? aiComparisonNotes;
  final String? matchedAccountId;
  final bool isTransaction;

  ParsedSmsTransaction({
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.category,
    this.cardLast4,
    this.accountLast4,
    required this.merchant,
    this.parserSource,
    this.aiComparisonNotes,
    this.matchedAccountId,
    this.isTransaction = true,
  });

  @override
  String toString() {
    return 'ParsedSmsTransaction(amount: $amount, desc: $description, type: $transactionType, cat: $category, card: $cardLast4, acct: $accountLast4, merchant: $merchant, src: $parserSource, matchedAcc: $matchedAccountId, isTx: $isTransaction)';
  }
}

class SmsParserService {
  final _storage = const FlutterSecureStorage();

  Future<void> logDebug(String message) async {
    print('[SMS_PARSER_DEBUG] $message');
    try {
      final dir = await getApplicationSupportDirectory();
      final logFile = File('${dir.path}/sms_parser_debug.log');
      final timestamp = DateTime.now().toIso8601String();
      await logFile.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  // Common keywords to identify financial transactions
  static final RegExp _financialKeywords = RegExp(
    r'\b(debited|spent|charged|withdrawn|sent|paid|payment|credited|received|deposited|added)\b|(?:txn\s+of)',
    caseSensitive: false,
  );

  // Keywords to identify OTPs, authorization codes, and bank promotions to exclude them
  static final RegExp _otpOrPromotionalKeywords = RegExp(
    r'(otp|one-time password|one time password|verification code|verify|security code|auth code|passcode|pre-approved|pre approved|apply now|win|offer|eligible|rate of interest|subscrib|bonus|upgrade|recharge)',
    caseSensitive: false,
  );

  static bool isOtpOrPromo(String text) {
    return _otpOrPromotionalKeywords.hasMatch(text);
  }

  Future<ParsedSmsTransaction?> parseAsync(
    String smsBody, {
    bool isBulk = false,
    List<CreditCard>? cards,
    List<BankAccount>? bankAccounts,
  }) async {
    final body = smsBody.trim();
    await logDebug('Parsing SMS Body: "$body"');

    final prefs = await SharedPreferences.getInstance();
    final customRedList = prefs.getStringList('custom_red_flags') ?? [];
    final customGreenList = prefs.getStringList('custom_green_flags') ?? [];

    RegExp financialKeywords = _financialKeywords;
    if (customGreenList.isNotEmpty) {
      final escaped = customGreenList.map((e) => RegExp.escape(e)).join('|');
      financialKeywords = RegExp(
        '(${_financialKeywords.pattern}|$escaped)',
        caseSensitive: false,
      );
    }

    RegExp otpOrPromotionalKeywords = _otpOrPromotionalKeywords;
    if (customRedList.isNotEmpty) {
      final escaped = customRedList.map((e) => RegExp.escape(e)).join('|');
      otpOrPromotionalKeywords = RegExp(
        '(${_otpOrPromotionalKeywords.pattern}|$escaped)',
        caseSensitive: false,
      );
    }

    if (!financialKeywords.hasMatch(body) || otpOrPromotionalKeywords.hasMatch(body)) {
      return null; // Not a financial transaction SMS or is an OTP/Promo
    }

    final regexResult = _parseRegex(body);

    if (isBulk) {
      final key = await _storage.read(key: 'ai_gemini_key');
      if (key == null || key.isEmpty) {
        throw Exception("Gemini API Key missing for Bulk Sync.");
      }
      final aiResultStr = await _parseWithGeminiRaw(
        body,
        key,
        cards: cards,
        bankAccounts: bankAccounts,
      );
      final aiResult = _decodeAiJson(aiResultStr);
      if (aiResult != null) {
        if (!aiResult.isTransaction) return null;
        return ParsedSmsTransaction(
          amount: aiResult.amount,
          description: aiResult.description,
          transactionType: aiResult.transactionType,
          category: aiResult.category,
          cardLast4: aiResult.cardLast4 ?? regexResult?.cardLast4,
          accountLast4: aiResult.accountLast4 ?? regexResult?.accountLast4,
          merchant: aiResult.merchant,
          matchedAccountId: aiResult.matchedAccountId,
          parserSource: 'gemini',
          isTransaction: true,
        );
      }
      if (regexResult != null) {
        return ParsedSmsTransaction(
          amount: regexResult.amount,
          description: regexResult.description,
          transactionType: regexResult.transactionType,
          category: regexResult.category,
          cardLast4: regexResult.cardLast4,
          accountLast4: regexResult.accountLast4,
          merchant: regexResult.merchant,
          parserSource: 'regex_fallback',
          isTransaction: true,
        );
      }
      return null;
    } else {
      final key = await _storage.read(key: 'ai_gemini_key');
      String? geminiJson;
      String? gemmaJson;

      if (key != null && key.isNotEmpty) {
        final results = await Future.wait([
          _parseWithGeminiRaw(body, key),
          _parseWithGemmaRaw(body),
        ]);
        geminiJson = results[0];
        gemmaJson = results[1];
      } else {
        gemmaJson = await _parseWithGemmaRaw(body);
      }

      final geminiParsed = _decodeAiJson(geminiJson);
      final gemmaParsed = _decodeAiJson(gemmaJson);

      if (geminiParsed != null && !geminiParsed.isTransaction) return null;
      if (gemmaParsed != null && !gemmaParsed.isTransaction) return null;

      String notes = "";
      if (geminiJson != null) notes += "Gemini: $geminiJson\n";
      if (gemmaJson != null) notes += "Gemma: $gemmaJson\n";

      final finalBase = geminiParsed ?? gemmaParsed ?? regexResult;
      if (finalBase == null) return null;

      return ParsedSmsTransaction(
        amount: finalBase.amount,
        description: finalBase.description,
        transactionType: finalBase.transactionType,
        category: finalBase.category,
        cardLast4: finalBase.cardLast4 ?? regexResult?.cardLast4,
        accountLast4: finalBase.accountLast4 ?? regexResult?.accountLast4,
        merchant: finalBase.merchant,
        parserSource: geminiParsed != null ? 'gemini' : (gemmaParsed != null ? 'gemma' : 'regex'),
        aiComparisonNotes: notes.trim(),
        isTransaction: finalBase.isTransaction,
      );
    }
  }

  Future<Map<String, dynamic>> previewParse(String smsBody) async {
    final body = smsBody.trim();
    if (_otpOrPromotionalKeywords.hasMatch(body)) {
      return {
        'regex': null,
        'gemini': null,
        'geminiRaw': null,
      };
    }
    final regexResult = _parseRegex(body);
    final key = await _storage.read(key: 'ai_gemini_key');
    ParsedSmsTransaction? geminiResult;
    String? geminiRaw;
    if (key != null && key.isNotEmpty) {
      geminiRaw = await _parseWithGeminiRaw(body, key);
      geminiResult = _decodeAiJson(geminiRaw);
    }
    return {
      'regex': regexResult,
      'gemini': geminiResult,
      'geminiRaw': geminiRaw,
    };
  }

  ParsedSmsTransaction? parseRegexOnly(String smsBody) {
    return _parseRegex(smsBody);
  }

  Future<ParsedSmsTransaction?> parseGeminiOnly(
    String smsBody, {
    List<CreditCard>? cards,
    List<BankAccount>? bankAccounts,
  }) async {
    final body = smsBody.trim();
    await logDebug('parseGeminiOnly SMS Body: "$body"');
    final prefs = await SharedPreferences.getInstance();
    final customRedList = prefs.getStringList('custom_red_flags') ?? [];
    RegExp otpOrPromotionalKeywords = _otpOrPromotionalKeywords;
    if (customRedList.isNotEmpty) {
      final escaped = customRedList.map((e) => RegExp.escape(e)).join('|');
      otpOrPromotionalKeywords = RegExp(
        '(${_otpOrPromotionalKeywords.pattern}|$escaped)',
        caseSensitive: false,
      );
    }
    if (otpOrPromotionalKeywords.hasMatch(body)) {
      return null;
    }
    final key = await _storage.read(key: 'ai_gemini_key');
    if (key == null || key.isEmpty) return null;
    final geminiRaw = await _parseWithGeminiRaw(body, key, cards: cards, bankAccounts: bankAccounts);
    return _decodeAiJson(geminiRaw);
  }

  Future<bool> isTransactionalSms(String smsBody) async {
    final body = smsBody.trim();
    final prefs = await SharedPreferences.getInstance();
    final customRedList = prefs.getStringList('custom_red_flags') ?? [];
    final customGreenList = prefs.getStringList('custom_green_flags') ?? [];

    RegExp financialKeywords = _financialKeywords;
    if (customGreenList.isNotEmpty) {
      final escaped = customGreenList.map((e) => RegExp.escape(e)).join('|');
      financialKeywords = RegExp(
        '(${_financialKeywords.pattern}|$escaped)',
        caseSensitive: false,
      );
    }

    RegExp otpOrPromotionalKeywords = _otpOrPromotionalKeywords;
    if (customRedList.isNotEmpty) {
      final escaped = customRedList.map((e) => RegExp.escape(e)).join('|');
      otpOrPromotionalKeywords = RegExp(
        '(${_otpOrPromotionalKeywords.pattern}|$escaped)',
        caseSensitive: false,
      );
    }

    if (!financialKeywords.hasMatch(body) || otpOrPromotionalKeywords.hasMatch(body)) {
      return false;
    }

    return _parseRegex(body) != null;
  }

  ParsedSmsTransaction? _decodeAiJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      final cleanJson = jsonStr.substring(jsonStart, jsonEnd + 1);
      final map = jsonDecode(cleanJson);
      
      final bool isTx = map['isTransaction'] == null ? true : (map['isTransaction'] as bool);
      final double amt = (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount'].toString()) ?? 0.0;
      final bool isRealTx = isTx && amt > 0;

      final rawType = map['transactionType']?.toString().toLowerCase();
      final type = (rawType == 'income') ? 'income' : (rawType == 'transfer' ? 'transfer' : 'expense');
      final merchant = map['merchant']?.toString() ?? 'Unknown Merchant';
      
      final description = type == 'income'
          ? 'Received from $merchant'
          : (type == 'transfer' ? 'Transfer to $merchant' : 'Spent at $merchant');

      return ParsedSmsTransaction(
        amount: amt,
        description: description,
        transactionType: type,
        category: map['category']?.toString() ?? 'Other',
        cardLast4: map['cardLast4']?.toString(),
        accountLast4: map['accountLast4']?.toString(),
        merchant: merchant,
        matchedAccountId: map['matchedAccountId']?.toString(),
        isTransaction: isRealTx,
      );
    } catch (e) {
      print("JSON Decode Error: $e");
      return null;
    }
  }

  Future<String?> _parseWithGeminiRaw(
    String sms,
    String apiKey, {
    List<CreditCard>? cards,
    List<BankAccount>? bankAccounts,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: apiKey,
      );
      final prompt = await _buildParserPrompt(sms, cards: cards, bankAccounts: bankAccounts);
      await logDebug('Gemini Prompt:\n$prompt');
      final response = await model.generateContent([Content.text(prompt)]);
      await logDebug('Gemini Response:\n${response.text}');
      return response.text;
    } catch (e) {
      await logDebug("Gemini API Error: $e");
      return null;
    }
  }

  Future<String?> _parseWithGemmaRaw(String sms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modelId = prefs.getString('selectedModelId') ?? 'gemma2_turbo_2b';
      final meta = await ModelRepository.instance.getMeta(modelId);
      if (meta == null) return null;

      final modelPath = await ModelRepository.instance.localModelPath(meta.assetPath);
      final file = File(modelPath);
      if (!await file.exists()) return null;

      if (!FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromFile(modelPath).install();
      }

      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final session = await model.createSession();
      final prompt = await _buildParserPrompt(sms);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final response = await session.getResponse();
      await session.close();
      return response;
    } catch (e) {
      print("Gemma Error: $e");
      return null;
    }
  }

  Future<String> _buildParserPrompt(
    String sms, {
    List<CreditCard>? cards,
    List<BankAccount>? bankAccounts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expenseCats = prefs.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Other'];
    final incomeCats = prefs.getStringList('categories_income') ?? ['Salary', 'Investment', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other'];
    final transferCats = prefs.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Investment', 'Other'];

    String cardListText = '';
    if (cards != null && cards.isNotEmpty) {
      cardListText = '\nAvailable Credit Cards:\n' +
          cards.map((c) => '- "${c.cardName}" (Last 4: ${c.last4}, ID: "card:${c.id}")').join('\n') +
          '\n';
    }

    String bankListText = '';
    if (bankAccounts != null && bankAccounts.isNotEmpty) {
      bankListText = '\nAvailable Bank Accounts:\n' +
          bankAccounts.map((b) => '- "${b.bankName}" (Last 4: ${b.last4}, ID: "bank:${b.id}")').join('\n') +
          '\n';
    }

    return '''
You are a financial SMS parser. First, evaluate if the SMS describes an actual completed financial transaction (debit, credit, or transfer of money). If it is promotional, advertisement, OTP, login alert, limit increase offer, payment option offer, upgrade offer, or spam, it is NOT a transaction.

Output ONLY valid JSON format. Do NOT include markdown formatting or backticks. Only output the raw JSON object.

Available Accounts/Cards to match:
$cardListText$bankListText
Fields required in the JSON:
- "isTransaction": boolean. Set to true if the SMS is an actual completed financial transaction (debit, credit, or transfer), else false.
- "amount": numeric value of the transaction. Set to 0 if not a transaction.
- "transactionType": "expense", "income", or "transfer" (use "transfer" if the SMS indicates a transfer between own accounts/self-transfer, sending money to a contact/person, or a payment/deposit credited to a credit card to pay its bill).
- "merchant": the name of the store, person, or beneficiary. Note: The user of this app is "Akshat Singhal" (so any transfer sent to "Akshat Singhal" is a self-transfer to himself). For self-transfers (where transactionType is "transfer" and the beneficiary is "Akshat Singhal" or yourself), the merchant MUST be the destination bank account (e.g. if sent from HDFC Bank, the merchant should be "SBI Account" or "SBI Bank", and vice versa). Do NOT return "Akshat Singhal" as the merchant for self-transfers. For any merchant name that is a UPI VPA/ID or email-style address (containing @, e.g. "anshikajain0203@okaxis" or "merchant@upi"), you MUST clean it to be just the name before the @ symbol, and strip any numbers, punctuation, or spaces (e.g. "anshikajain0203@okaxis" should be cleaned to "Anshikajain" or "Anshika Jain").
- "category": choose from these based on transactionType:
  * For "expense": choose from (${expenseCats.join(', ')})
  * For "income": choose from (${incomeCats.join(', ')})
  * For "transfer": choose from (${transferCats.join(', ')})
- "cardLast4": last 4 digits of credit card if present, else null
- "accountLast4": last 4 digits of bank account if present, else null
- "matchedAccountId": Look at the SMS body and match it against the "Available Accounts/Cards" listed above. You must perform a fuzzy match on card/bank names, bank name keywords, and payment networks (Visa, RuPay, Mastercard). For example:
  1) If the SMS says "Scapia Federal RuPay credit card" and the list contains "Scapia Rupay" (ID: "card:11"), they both refer to Scapia and RuPay, so you MUST output "card:11".
  2) If the SMS mentions "HDFC Bank A/C *3558" and the list has "hdfc" (ID: "bank:2") with a different last 4, you MUST match it to "bank:2" because the bank name "HDFC" matches.
  Do NOT return null if a name, bank keyword, or network match is found in the SMS. Output the matched ID (e.g., "card:11" or "bank:2"). Only output null if there is absolutely no matching bank, account, or card brand/name in the list.

SMS: "$sms"
''';
  }

  ParsedSmsTransaction? _parseRegex(String smsBody) {
    final body = smsBody.trim();
    if (_otpOrPromotionalKeywords.hasMatch(body)) {
      return null;
    }

    double? amount;
    String transactionType = 'expense';
    String? cardLast4;
    String? accountLast4;
    String merchant = 'Unknown Merchant';

    // 1. EXTRACT AMOUNT
    final amountReg = RegExp(
      r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{2})?)',
      caseSensitive: false,
    );
    final amtMatch = amountReg.firstMatch(body);
    if (amtMatch != null) {
      final amtStr = amtMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(amtStr);
    }

    if (amount == null || amount <= 0) {
      return null; 
    }

    // 2. DETECT TRANSACTION TYPE (Income vs Expense vs Transfer)
    final bodyLower = body.toLowerCase();
    final bool isTransfer = bodyLower.contains('self transfer') ||
        bodyLower.contains('transfer to') ||
        (bodyLower.contains('payment') && (bodyLower.contains('credited to') || bodyLower.contains('received for') || bodyLower.contains('paid to') || bodyLower.contains('towards'))) ||
        (bodyLower.contains('sent') && (bodyLower.contains('to akshat') || bodyLower.contains('self')));

    if (isTransfer) {
      transactionType = 'transfer';
    } else {
      final creditReg = RegExp(
        r'(credited|received|deposited|added|refunded)',
        caseSensitive: false,
      );
      if (creditReg.hasMatch(body)) {
        transactionType = 'income';
      }
    }

    // 3. EXTRACT CREDIT CARD / ACCOUNT DETAILS
    final cardReg = RegExp(
      r'(?:card|cc)(?:\s+ending|\s+no\.?)?\s+(?:[a-z]*\s*)?([0-9]{4})',
      caseSensitive: false,
    );
    final cardMatch = cardReg.firstMatch(body);
    if (cardMatch != null) {
      cardLast4 = cardMatch.group(1);
    }

    final acctReg = RegExp(
      r'(?:a/c|acct|ac|account|acct\s+no\.?)\s+(?:[a-z\s]*\s*)?[x\*]*([0-9]{4})',
      caseSensitive: false,
    );
    final acctMatch = acctReg.firstMatch(body);
    if (acctMatch != null) {
      accountLast4 = acctMatch.group(1);
    }

    // 4. DETECT MERCHANT & CATEGORY
    if (transactionType == 'transfer') {
      final bodyLower = body.toLowerCase();
      if (bodyLower.contains('hdfc')) {
        merchant = 'SBI Account';
      } else if (bodyLower.contains('sbi')) {
        merchant = 'HDFC Account';
      } else {
        merchant = 'Self Transfer';
      }
    } else {
      merchant = _extractMerchant(body);
    }
    final category = _detectCategory(merchant, body);

    final description = transactionType == 'income'
        ? 'Received from $merchant'
        : (transactionType == 'transfer' ? 'Transfer to $merchant' : 'Spent at $merchant');

    return ParsedSmsTransaction(
      amount: amount,
      description: description,
      transactionType: transactionType,
      category: category,
      cardLast4: cardLast4,
      accountLast4: accountLast4,
      merchant: merchant,
    );
  }

  // Merchant extraction rules
  String _extractMerchant(String body) {
    // Look for merchant keywords: "at <merchant>", "to <merchant>", "info: <merchant>", "vpa <merchant>"
    // Case 1: HDFC/ICICI "at [Merchant] on" or "at [Merchant] Ref"
    var match = RegExp(r'(?:at|to|vpa|from\s+vpa|from)\s+([A-Za-z0-9\- \.\@]+?)(?:\s+on|\s+ref|\s+bal|\s+limit|\s+via|\.|$)', caseSensitive: false).firstMatch(body);
    if (match != null) {
      final m = match.group(1)!.trim();
      if (m.isNotEmpty && m.length < 30) {
        return _cleanMerchantName(m);
      }
    }

    // Case 2: SBI "to [Merchant] Ref"
    match = RegExp(r'debited\s+by\s+Rs\.[0-9\.]+\s+on\s+[0-9a-zA-Z\s]+\s+to\s+([A-Za-z0-9 \.\-]+?)(?:\s+Ref|$)', caseSensitive: false).firstMatch(body);
    if (match != null) {
      final m = match.group(1)!.trim();
      if (m.isNotEmpty) return _cleanMerchantName(m);
    }

    // Case 3: ICICI "Info: [Merchant]"
    match = RegExp(r'Info:\s*([A-Za-z0-9\-\/ \.]+?)(?:\s*\.|\s+Ref|$)', caseSensitive: false).firstMatch(body);
    if (match != null) {
      final m = match.group(1)!.trim();
      if (m.isNotEmpty) return _cleanMerchantName(m);
    }

    // Fallback: extract banking name if mentioned
    if (body.contains('HDFC')) return 'HDFC Bank';
    if (body.contains('ICICI')) return 'ICICI Bank';
    if (body.contains('SBI')) return 'SBI Bank';
    if (body.contains('AXIS')) return 'Axis Bank';

    return 'Merchant Alert';
  }

  String _cleanMerchantName(String name) {
    // If it's a UPI VPA like swiggy@apl, clean it to "Swiggy"
    if (name.contains('@')) {
      final parts = name.split('@');
      var prefix = parts[0].replaceAll(RegExp(r'[0-9\.\-_]+'), ' ').trim();
      if (prefix.isNotEmpty) return _titleCase(prefix);
    }
    
    // Replace standard UPI markers
    var clean = name.replaceAll(RegExp(r'(UPI|VPA|PG|REF|ON|VIA|INFO)', caseSensitive: false), '').trim();
    clean = clean.replaceAll(RegExp(r'\s+'), ' '); // clean multiple spaces
    
    if (clean.length > 20) {
      clean = clean.substring(0, 20).trim();
    }
    
    return clean.isEmpty ? 'Unknown Merchant' : _titleCase(clean);
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Automatic category classification based on merchant names & email/SMS content
  String _detectCategory(String merchant, String body) {
    final lowerMerchant = merchant.toLowerCase();
    final lowerBody = body.toLowerCase();

    // Food & Dining
    if (lowerMerchant.contains('swiggy') ||
        lowerMerchant.contains('zomato') ||
        lowerMerchant.contains('starbucks') ||
        lowerMerchant.contains('mcdonald') ||
        lowerMerchant.contains('dominos') ||
        lowerMerchant.contains('restaurant') ||
        lowerBody.contains('dining') ||
        lowerBody.contains('food')) {
      return 'Food';
    }

    // Shopping / Retail
    if (lowerMerchant.contains('amazon') ||
        lowerMerchant.contains('flipkart') ||
        lowerMerchant.contains('myntra') ||
        lowerMerchant.contains('croma') ||
        lowerMerchant.contains('reliance retail') ||
        lowerMerchant.contains('reliance digital') ||
        lowerMerchant.contains('dmart') ||
        lowerBody.contains('grocery') ||
        lowerBody.contains('supermarket')) {
      return 'Shopping';
    }

    // Travel & Commute
    if (lowerMerchant.contains('uber') ||
        lowerMerchant.contains('ola') ||
        lowerMerchant.contains('rapido') ||
        lowerMerchant.contains('irctc') ||
        lowerMerchant.contains('makemytrip') ||
        lowerMerchant.contains('indigo') ||
        lowerMerchant.contains('redbus') ||
        lowerMerchant.contains('fuel') ||
        lowerMerchant.contains('petrol') ||
        lowerBody.contains('metro') ||
        lowerBody.contains('cab')) {
      return 'Travel';
    }

    // Entertainment
    if (lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('spotify') ||
        lowerMerchant.contains('prime video') ||
        lowerMerchant.contains('bookmyshow') ||
        lowerMerchant.contains('hotstar') ||
        lowerBody.contains('cinema') ||
        lowerBody.contains('movie')) {
      return 'Entertainment';
    }

    // Utilities / Subscriptions
    if (lowerBody.contains('electricity') ||
        lowerBody.contains('bill pay') ||
        lowerBody.contains('recharge') ||
        lowerBody.contains('broadband') ||
        lowerBody.contains('water bill') ||
        lowerBody.contains('insurance')) {
      return 'Utilities';
    }

    // Investments / Savings
    if (lowerMerchant.contains('zerodha') ||
        lowerMerchant.contains('groww') ||
        lowerMerchant.contains('mutual fund') ||
        lowerMerchant.contains('coin') ||
        lowerMerchant.contains('kuvera') ||
        lowerMerchant.contains('upstox')) {
      return 'Investment';
    }

    // Default categories based on income vs expense
    if (lowerBody.contains('salary') || lowerBody.contains('dividend') || lowerBody.contains('interest credited')) {
      return 'Salary';
    }

    return 'Other';
  }
}
