import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import '../../investments/models/holding_model.dart';
import 'quant_forecast_service.dart';

class AiAdvisorService {
  final _storage = const FlutterSecureStorage();

  // Helper: Sanitize financial profile to ensure 100% privacy
  String generateSanitizedProfile({
    required List<Transaction> transactions,
    required List<CreditCard> cards,
    required List<Loan> loans,
    required List<Holding> holdings,
    required double netWorth,
    required double cashAndBank,
    required QuantForecastResult forecast,
  }) {
    final buffer = StringBuffer();

    buffer.writeln("=== USER FINANCIAL PROFILE (SANITIZED) ===");
    buffer.writeln("Net Worth: ₹${netWorth.toStringAsFixed(0)}");
    buffer.writeln("Cash & Bank Balance: ₹${cashAndBank.toStringAsFixed(0)}");
    buffer.writeln("Monthly Daily Velocity Spends: ₹${(forecast.dailyVelocity * 30).toStringAsFixed(0)} (₹${forecast.dailyVelocity.toStringAsFixed(0)}/day)");
    buffer.writeln("Monthly Recurring EMIs: ₹${forecast.recurringEmis.toStringAsFixed(0)}");
    buffer.writeln("Monthly Rent: ₹${forecast.detectedRent.toStringAsFixed(0)}");
    buffer.writeln("Projected Spend Remaining This Month: ₹${forecast.projectedSpend.toStringAsFixed(0)}");
    buffer.writeln("Emergency Fund Coverage: ${forecast.emergencyFundMonths.toStringAsFixed(1)} months (Recommended is 6.0 months)");

    // Holdings summary (Aggregated - no individual tickers/names sent)
    buffer.writeln("Investment Portfolio Valuations:");
    buffer.writeln("- Stock Holdings: ₹${forecast.stocksVal.toStringAsFixed(0)} (${forecast.stocksPercentage.toStringAsFixed(1)}% of portfolio)");
    buffer.writeln("- Mutual Fund Holdings: ₹${forecast.mfVal.toStringAsFixed(0)} (${forecast.mfsPercentage.toStringAsFixed(1)}% of portfolio)");
    if (forecast.rebalanceAmount > 0) {
      buffer.writeln("- Rebalance recommendation: Shift ₹${forecast.rebalanceAmount.toStringAsFixed(0)} from Stocks to Mutual/Hybrid funds to maintain standard 70/30 asset allocation.");
    }

    // Credit cards (Anonymized)
    buffer.writeln("Credit Cards Outstanding:");
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      buffer.writeln("- Card ${String.fromCharCode(65 + i)}: Balance ₹${card.balance.toStringAsFixed(0)}, Limit ₹${card.creditLimit.toStringAsFixed(0)}");
    }

    // Loans (Anonymized)
    buffer.writeln("Active Debts & Receivables:");
    for (final loan in loans) {
      final type = loan.isLent ? "Receivable (Lent)" : "Debt (Borrowed)";
      String sanitizedName = "Personal Loan";
      final lowerName = loan.contactName.toLowerCase();
      if (lowerName.contains('home')) {
        sanitizedName = "Home Loan";
      } else if (lowerName.contains('car')) {
        sanitizedName = "Car Loan";
      } else if (loan.interestRate == 0) {
        sanitizedName = "Interest-free Loan";
      }
      buffer.writeln("- $sanitizedName ($type): Remaining Balance ₹${loan.remainingBalance.toStringAsFixed(0)}, Interest Rate ${loan.interestRate}%, Monthly EMI ₹${loan.emiAmount.toStringAsFixed(0)}");
    }

    // Transactions (Sanitized list - last 10 transactions)
    buffer.writeln("Recent Transactions (Last 10):");
    final recentTxs = transactions.take(10).toList();
    for (final tx in recentTxs) {
      // Replaces raw merchant description with generic category name for absolute privacy
      final genericInfo = tx.category;
      buffer.writeln("- ${tx.timestamp.toString().substring(0, 10)} | ${tx.transactionType.toUpperCase()} | ₹${tx.amount.toStringAsFixed(0)} | Category: ${tx.category} | Info: Spend on $genericInfo");
    }

    return buffer.toString();
  }

  // Primary entrypoint to query the advisor (local or cloud or quant-fallback)
  Future<String> queryAdvisor({
    required String userQuery,
    required String sanitizedProfile,
    required QuantForecastResult forecast,
  }) async {
    // Read preferences
    final useLocalStr = await _storage.read(key: 'ai_use_local');
    final useLocal = useLocalStr == 'true';
    final ollamaHost = await _storage.read(key: 'ai_ollama_host') ?? 'http://localhost:11434';
    final geminiKey = await _storage.read(key: 'ai_gemini_key');

    final systemInstruction = 
        "You are a professional wealth advisor and financial analyst. "
        "Answer the user's financial questions based on their sanitized profile. "
        "Do not reference any specific real company names or stock tickers that were not provided in the profile. "
        "Keep advice local, logical, quantitative, and privacy-first.";

    final prompt = """
$systemInstruction

Here is the user's sanitized financial profile:
$sanitizedProfile

User's Question: "$userQuery"

Provide a concise, professional financial assessment in 2-3 paragraphs. Discuss budgeting, debt consolidation, investment rebalancing, or emergency savings where relevant.
""";

    // 1. Try Local Ollama if enabled
    if (useLocal) {
      try {
        final url = Uri.parse('$ollamaHost/api/generate');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'model': 'gemma2:2b', // default light model
            'prompt': prompt,
            'stream': false,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final text = data['response']?.toString();
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
      } catch (e) {
        print('Ollama connection failed, trying cloud fallback: $e');
      }
    }

    // 2. Try Gemini Cloud API if key is available
    if (geminiKey != null && geminiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: geminiKey,
          systemInstruction: Content.system(systemInstruction),
        );
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!.trim();
        }
      } catch (e) {
        print('Gemini API call failed: $e');
      }
    }

    // 3. Fallback: Rule-based quantitative advisor response (completely local & offline)
    return _generateRuleBasedResponse(userQuery, forecast);
  }

  // Generates a robust, intelligent quantitative response locally based on user data
  String _generateRuleBasedResponse(String query, QuantForecastResult forecast) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('rebalance') || lowerQuery.contains('holdings') || lowerQuery.contains('portfolio') || lowerQuery.contains('invest')) {
      if (forecast.rebalanceAmount > 0) {
        return "Based on your holdings of ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds, you have an equity allocation skew. "
            "To align with a standard balanced portfolio (70% direct stocks / 30% diversified mutual funds), we recommend shifting ₹${forecast.rebalanceAmount.toStringAsFixed(0)} from stocks into mutual/hybrid funds. "
            "This reduces single-stock exposure and ensures automated index diversification.";
      } else {
        return "Your portfolio allocation is well-balanced with ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds. "
            "No active rebalancing is required. Maintain your current SIP schedules to compound wealth steadily.";
      }
    }

    if (lowerQuery.contains('emergency') || lowerQuery.contains('save') || lowerQuery.contains('buffer') || lowerQuery.contains('cash')) {
      if (forecast.emergencyFundMonths < 6.0) {
        final shortAmt = forecast.recommendedEmergencyFund - forecast.cashAndBank;
        return "Your current emergency buffer (₹${forecast.cashAndBank.toStringAsFixed(0)}) covers only ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of cash outflows (including rent and EMIs). "
            "We strongly recommend building this up to ₹${forecast.recommendedEmergencyFund.toStringAsFixed(0)} (6 months of coverage). "
            "Consider allocating ₹${shortAmt.toStringAsFixed(0)} from future savings before making further high-risk equity investments.";
      } else {
        return "Your emergency savings of ₹${forecast.cashAndBank.toStringAsFixed(0)} are excellent, covering ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of total cash outflows. "
            "This provides a solid safety net. You can confidently deploy surplus monthly cash flow into long-term equity SIPs or debt pre-payments.";
      }
    }

    if (lowerQuery.contains('emi') || lowerQuery.contains('debt') || lowerQuery.contains('loan') || lowerQuery.contains('prepay')) {
      return "Your active monthly EMI burden is ₹${forecast.recurringEmis.toStringAsFixed(0)}. "
          "If you have low-interest debts like a home loan (~8.5%), standard long-term returns from index mutual funds (~12%) will outperform the interest savings from pre-payment. "
          "However, prepaying high-interest liabilities or credit card outstandings is guaranteed risk-free savings. Always pay card balances in full before month-end.";
    }

    // Default response
    return "Analyzing your local portfolio: Net Worth is ₹${(forecast.cashAndBank + forecast.stocksVal + forecast.mfVal).toStringAsFixed(0)} (Cash: ₹${forecast.cashAndBank.toStringAsFixed(0)}, Portfolio: ₹${(forecast.stocksVal + forecast.mfVal).toStringAsFixed(0)}). "
        "Your projected spending for this month is ₹${forecast.projectedSpend.toStringAsFixed(0)} with a daily spending velocity of ₹${forecast.dailyVelocity.toStringAsFixed(0)}/day. "
        "To get tailored advice, please ask about 'rebalancing portfolio', 'emergency fund status', or 'debt pre-payment guidance'.";
  }
}
