import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/model_repository.dart';
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
  });

  @override
  String toString() {
    return 'ParsedSmsTransaction(amount: $amount, desc: $description, type: $transactionType, cat: $category, card: $cardLast4, acct: $accountLast4, merchant: $merchant, src: $parserSource)';
  }
}

class SmsParserService {
  final _storage = const FlutterSecureStorage();

  // Common keywords to identify financial transactions
  static final RegExp _financialKeywords = RegExp(
    r'(debited|spent|charged|withdrawn|sent|paid|credited|received|deposited|added)',
    caseSensitive: false,
  );

  Future<ParsedSmsTransaction?> parseAsync(String smsBody, {bool isBulk = false}) async {
    final body = smsBody.trim();
    if (!_financialKeywords.hasMatch(body)) {
      return null; // Not a financial transaction SMS
    }

    final regexResult = _parseRegex(body);

    if (isBulk) {
      final key = await _storage.read(key: 'ai_gemini_key');
      if (key == null || key.isEmpty) {
        throw Exception("Gemini API Key missing for Bulk Sync.");
      }
      final aiResultStr = await _parseWithGeminiRaw(body, key);
      final aiResult = _decodeAiJson(aiResultStr);
      if (aiResult != null) {
        return ParsedSmsTransaction(
          amount: aiResult.amount,
          description: aiResult.description,
          transactionType: aiResult.transactionType,
          category: aiResult.category,
          cardLast4: aiResult.cardLast4 ?? regexResult?.cardLast4,
          accountLast4: aiResult.accountLast4 ?? regexResult?.accountLast4,
          merchant: aiResult.merchant,
          parserSource: 'gemini',
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
      );
    }
  }

  ParsedSmsTransaction? _decodeAiJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      final cleanJson = jsonStr.substring(jsonStart, jsonEnd + 1);
      final map = jsonDecode(cleanJson);
      
      final double amt = (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount'].toString()) ?? 0.0;
      if (amt <= 0) return null;

      final type = map['transactionType']?.toString().toLowerCase() == 'income' ? 'income' : 'expense';
      final merchant = map['merchant']?.toString() ?? 'Unknown Merchant';

      return ParsedSmsTransaction(
        amount: amt,
        description: type == 'income' ? 'Received from $merchant' : 'Spent at $merchant',
        transactionType: type,
        category: map['category']?.toString() ?? 'Other',
        cardLast4: map['cardLast4']?.toString(),
        accountLast4: map['accountLast4']?.toString(),
        merchant: merchant,
      );
    } catch (e) {
      print("JSON Decode Error: $e");
      return null;
    }
  }

  Future<String?> _parseWithGeminiRaw(String sms, String apiKey) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: apiKey,
      );
      final prompt = _buildParserPrompt(sms);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print("Gemini API Error: $e");
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
      final prompt = _buildParserPrompt(sms);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final response = await session.getResponse();
      await session.close();
      return response;
    } catch (e) {
      print("Gemma Error: $e");
      return null;
    }
  }

  String _buildParserPrompt(String sms) {
    return '''
You are a financial SMS parser. Extract the details of the transaction and output ONLY valid JSON format.
Do NOT include markdown formatting or backticks. Only output the raw JSON object.

Fields required:
- "amount": numeric value of the transaction
- "transactionType": "expense" or "income"
- "merchant": the name of the store or person
- "category": choose from (Food, Shopping, Travel, Entertainment, Utilities, Investment, Salary, Other)
- "cardLast4": last 4 digits of credit card if present, else null
- "accountLast4": last 4 digits of bank account if present, else null

SMS: "$sms"
''';
  }

  ParsedSmsTransaction? _parseRegex(String smsBody) {
    final body = smsBody.trim();

    double? amount;
    String transactionType = 'expense';
    String? cardLast4;
    String? accountLast4;
    String merchant = 'Unknown Merchant';

    // 1. EXTRACT AMOUNT
    final amountReg = RegExp(
      r'(?:rs\.?|inr|rs)\s*([0-9,]+(?:\.[0-9]{2})?)',
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

    // 2. DETECT TRANSACTION TYPE (Income vs Expense)
    final creditReg = RegExp(
      r'(credited|received|deposited|added|refunded)',
      caseSensitive: false,
    );
    if (creditReg.hasMatch(body)) {
      transactionType = 'income';
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
    merchant = _extractMerchant(body);
    final category = _detectCategory(merchant, body);

    final description = transactionType == 'income'
        ? 'Received from $merchant'
        : 'Spent at $merchant';

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
    var match = RegExp(r'(?:at|to|vpa)\s+([A-Za-z0-9\- \.\@]+?)(?:\s+on|\s+ref|\s+bal|\s+limit|\s+via|\.|$)', caseSensitive: false).firstMatch(body);
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
