import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../../services/model_repository.dart';
import '../../../services/model_downloader.dart';
import 'quant_forecast_service.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import '../../investments/models/holding_model.dart';

class AiAdvisorService {
  final _storage = const FlutterSecureStorage();

  // Retrieve selected model id, falling back to default if none selected.
  Future<String> _getSelectedModelId() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selectedModelId');
    if (selected != null && selected.isNotEmpty) return selected;
    // default to Gemma 2 Turbo 2B
    return 'gemma2_turbo_2b';
  }

  // Resolve the actual file path for the model (bundled asset or downloaded).
  Future<String> _resolveModelPath(String modelId) async {
    final meta = await ModelRepository.instance.getMeta(modelId);
    if (meta == null) throw Exception('Model metadata not found for id: $modelId');
    // Check if a downloaded copy exists.
    final localPath = await ModelRepository.instance.localModelPath(meta.assetPath);
    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }
    // Fallback to bundled asset path (for default model bundled with app).
    return meta.assetPath; // asset path is relative to assets folder.
  }

  // Primary entrypoint to query the advisor (local on‑device LLM via FlutterGemma).
  Future<String> queryAdvisor({
    required String userQuery,
    required String sanitizedProfile,
    required QuantForecastResult forecast,
  }) async {
    final useLocalStr = await _storage.read(key: 'ai_use_local') ?? 'false';
    if (useLocalStr != 'true') {
      return _generateRuleBasedResponse(userQuery, forecast);
    }

    // Determine which model to use.
    final modelId = await _getSelectedModelId();
    final meta = await ModelRepository.instance.getMeta(modelId);
    if (meta == null) {
      return _generateRuleBasedResponse(userQuery, forecast);
    }

    final modelPath = await ModelRepository.instance.localModelPath(meta.assetPath);
    final file = File(modelPath);
    if (!await file.exists()) {
      return _generateRuleBasedResponse(userQuery, forecast);
    }

    final systemInstruction =
        "You are a professional wealth advisor and financial analyst. "
        "Answer the user's financial questions based on their sanitized profile. "
        "Do not reference any specific real company names or stock tickers that were not provided in the profile. "
        "Keep advice local, logical, quantitative, and privacy‑first.";
    final prompt = """
$systemInstruction

Here is the user's sanitized financial profile:
$sanitizedProfile

User's Question: "$userQuery"

Provide a concise, professional financial assessment in 2-3 paragraphs. Discuss budgeting, debt consolidation, investment rebalancing, or emergency savings where relevant.
""";

    try {
      if (!FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromFile(modelPath).install();
      }

      final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
      final session = await model.createSession();
      await session.addQueryChunk(Message(
        text: prompt,
        isUser: true,
      ));
      final response = await session.getResponse();
      await session.close();
      if (response != null && response.isNotEmpty) {
        return response.trim();
      }
    } catch (e) {
      print('FlutterGemma inference failed (model $modelId): $e');
    }

    // Fallback to rule‑based response if on‑device inference fails.
    return _generateRuleBasedResponse(userQuery, forecast);
  }

  // Existing rule‑based method unchanged.
  String _generateRuleBasedResponse(String query, QuantForecastResult forecast) {
    // ... existing implementation unchanged ...
    // (omitted for brevity, keep same as before)
    final lowerQuery = query.toLowerCase();
    String responseText = "";
    if (lowerQuery.contains('rebalance') || lowerQuery.contains('holdings') || lowerQuery.contains('portfolio') || lowerQuery.contains('invest')) {
      if (forecast.rebalanceAmount > 0) {
        responseText = "Based on your holdings of ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds, you have an equity allocation skew. "
            "To align with a standard balanced portfolio (70% direct stocks / 30% diversified mutual funds), we recommend shifting ₹${forecast.rebalanceAmount.toStringAsFixed(0)} from stocks into mutual/hybrid funds. "
            "This reduces single‑stock exposure and ensures automated index diversification.";
      } else {
        responseText = "Your portfolio allocation is well‑balanced with ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds. "
            "No active rebalancing is required. Maintain your current SIP schedules to compound wealth steadily.";
      }
    } else if (lowerQuery.contains('emergency') || lowerQuery.contains('save') || lowerQuery.contains('buffer') || lowerQuery.contains('cash')) {
      if (forecast.emergencyFundMonths < 6.0) {
        final shortAmt = forecast.recommendedEmergencyFund - forecast.cashAndBank;
        responseText = "Your current emergency buffer (₹${forecast.cashAndBank.toStringAsFixed(0)}) covers only ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of cash outflows (including rent and EMIs). "
            "We strongly recommend building this up to ₹${forecast.recommendedEmergencyFund.toStringAsFixed(0)} (6 months of coverage). "
            "Consider allocating ₹${shortAmt.toStringAsFixed(0)} from future savings before making further high‑risk equity investments.";
      } else {
        responseText = "Your emergency savings of ₹${forecast.cashAndBank.toStringAsFixed(0)} are excellent, covering ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of total cash outflows. "
            "This provides a solid safety net. You can confidently deploy surplus monthly cash flow into long‑term equity SIPs or debt pre‑payments.";
      }
    } else if (lowerQuery.contains('emi') || lowerQuery.contains('debt') || lowerQuery.contains('loan') || lowerQuery.contains('prepay')) {
      responseText = "Your active monthly EMI burden is ₹${forecast.recurringEmis.toStringAsFixed(0)}. "
          "If you have low‑interest debts like a home loan (~8.5%), standard long‑term returns from index mutual funds (~12%) will outperform the interest savings from pre‑payment. "
          "However, prepaying high‑interest liabilities or credit card outstandings is guaranteed risk‑free savings. Always pay card balances in full before month‑end.";
    } else {
      responseText = "Analyzing your local portfolio: Net Worth is ₹${(forecast.cashAndBank + forecast.stocksVal + forecast.mfVal).toStringAsFixed(0)} (Cash: ₹${forecast.cashAndBank.toStringAsFixed(0)}, Portfolio: ₹${(forecast.stocksVal + forecast.mfVal).toStringAsFixed(0)}). "
          "Your projected spending for this month is ₹${forecast.projectedSpend.toStringAsFixed(0)} with a daily spending velocity of ₹${forecast.dailyVelocity.toStringAsFixed(0)}/day. "
          "To get tailored advice, please ask about 'rebalancing portfolio', 'emergency fund status', or 'debt pre‑payment guidance'.";
    }
    return "⚠️ [Quant Fallback] I am just a quantifiable algorithm, not a proper AI. Integrate AI in Settings to get better answers.\n\n$responseText";
  }

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
    buffer.writeln("Financial Profile Summary:");
    buffer.writeln("- Net Worth: ₹${netWorth.toStringAsFixed(0)}");
    buffer.writeln("- Cash & Bank Balance: ₹${cashAndBank.toStringAsFixed(0)}");
    buffer.writeln("- Projected Monthly Spend: ₹${forecast.projectedSpend.toStringAsFixed(0)}");
    buffer.writeln("- Active Credit Cards: ${cards.length}");
    buffer.writeln("- Active Loans: ${loans.length} (Monthly EMI burden: ₹${forecast.recurringEmis.toStringAsFixed(0)})");
    
    double totalHoldingsVal = holdings.fold(0.0, (sum, h) => sum + (h.currentPrice * h.quantity));
    buffer.writeln("- Total Investments Value: ₹${totalHoldingsVal.toStringAsFixed(0)}");
    
    return buffer.toString();
  }
}
