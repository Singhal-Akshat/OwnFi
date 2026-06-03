class ParsedSmsTransaction {
  final double amount;
  final String description;
  final String transactionType; // 'expense' or 'income'
  final String category;
  final String? cardLast4;
  final String? accountLast4;
  final String merchant;

  ParsedSmsTransaction({
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.category,
    this.cardLast4,
    this.accountLast4,
    required this.merchant,
  });

  @override
  String toString() {
    return 'ParsedSmsTransaction(amount: $amount, desc: $description, type: $transactionType, cat: $category, card: $cardLast4, acct: $accountLast4, merchant: $merchant)';
  }
}

class SmsParserService {
  // Common keywords to identify financial transactions
  static final RegExp _financialKeywords = RegExp(
    r'(debited|spent|charged|withdrawn|sent|paid|credited|received|deposited|added)',
    caseSensitive: false,
  );

  ParsedSmsTransaction? parse(String smsBody) {
    final body = smsBody.trim();
    if (!_financialKeywords.hasMatch(body)) {
      return null; // Not a financial transaction SMS
    }

    double? amount;
    String transactionType = 'expense';
    String? cardLast4;
    String? accountLast4;
    String merchant = 'Unknown Merchant';

    // 1. EXTRACT AMOUNT
    // Standard patterns: Rs. 100, Rs.100, Rs 100, INR 100, RS 100.00
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
      return null; // Could not extract valid amount
    }

    // 2. DETECT TRANSACTION TYPE (Income vs Expense)
    // Credit indicators
    final creditReg = RegExp(
      r'(credited|received|deposited|added|refunded)',
      caseSensitive: false,
    );
    if (creditReg.hasMatch(body)) {
      transactionType = 'income';
    }

    // 3. EXTRACT CREDIT CARD / ACCOUNT DETAILS
    // Patterns for cards: card ending 1234, card xx1234, card no. 1234
    final cardReg = RegExp(
      r'(?:card|cc)(?:\s+ending|\s+no\.?)?\s+(?:[a-z]*\s*)?([0-9]{4})',
      caseSensitive: false,
    );
    final cardMatch = cardReg.firstMatch(body);
    if (cardMatch != null) {
      cardLast4 = cardMatch.group(1);
    }

    // Patterns for accounts: a/c ending 1234, acct xx1234, ac xx9876
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
