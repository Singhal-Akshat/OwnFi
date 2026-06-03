import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import '../../investments/models/holding_model.dart';

class QuantForecastResult {
  final double dailyVelocity;
  final int remainingDays;
  final double projectedSpend;
  final double recurringEmis;
  final double detectedRent;
  final double cashAndBank;
  final double stocksVal;
  final double mfVal;
  final double stocksPercentage;
  final double mfsPercentage;
  final double emergencyFundMonths;
  final double recommendedEmergencyFund;
  final double rebalanceAmount;

  QuantForecastResult({
    required this.dailyVelocity,
    required this.remainingDays,
    required this.projectedSpend,
    required this.recurringEmis,
    required this.detectedRent,
    required this.cashAndBank,
    required this.stocksVal,
    required this.mfVal,
    required this.stocksPercentage,
    required this.mfsPercentage,
    required this.emergencyFundMonths,
    required this.recommendedEmergencyFund,
    required this.rebalanceAmount,
  });
}

class QuantForecastService {
  QuantForecastResult calculateForecast({
    required List<Transaction> transactions,
    required List<CreditCard> cards,
    required List<Loan> loans,
    required List<Holding> holdings,
    required List<BankAccount> bankAccounts,
  }) {
    final now = DateTime.now();

    final isEmptyDb = transactions.isEmpty && cards.isEmpty && loans.isEmpty && holdings.isEmpty;
    if (isEmptyDb) {
      return QuantForecastResult(
        dailyVelocity: 0.0,
        remainingDays: DateTime(now.year, now.month + 1, 0).day - now.day,
        projectedSpend: 0.0,
        recurringEmis: 0.0,
        detectedRent: 0.0,
        cashAndBank: 0.0,
        stocksVal: 0.0,
        mfVal: 0.0,
        stocksPercentage: 0.0,
        mfsPercentage: 0.0,
        emergencyFundMonths: 0.0,
        recommendedEmergencyFund: 0.0,
        rebalanceAmount: 0.0,
      );
    }

    // 1. Calculate Daily Spending Velocity of the last 30 days
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentExpenses = transactions.where((tx) =>
        tx.transactionType == 'expense' &&
        tx.timestamp.isAfter(thirtyDaysAgo) &&
        tx.category.toLowerCase() != 'rent' && // Exclude rent to prevent double counting
        tx.category.toLowerCase() != 'investment');

    double totalExpense = 0.0;
    for (final tx in recentExpenses) {
      totalExpense += tx.amount;
    }
    // If no transactions, fallback to a daily velocity of 0.0
    final dailyVelocity = recentExpenses.isEmpty ? 0.0 : totalExpense / 30.0;

    // 2. Calculate remaining days in month
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = lastDay - now.day;

    // 3. Sum monthly recurring EMIs
    double recurringEmis = 0.0;
    for (final card in cards) {
      for (final emi in card.activeEmis) {
        recurringEmis += emi.monthlyInstallment;
      }
    }
    for (final loan in loans) {
      if (!loan.isLent && loan.emiAmount > 0) {
        recurringEmis += loan.emiAmount;
      }
    }

    // 4. Detect Rent
    double detectedRent = 0.0; // Default rent fallback
    bool rentDetected = false;
    for (final tx in transactions) {
      final isRent = tx.category.toLowerCase() == 'rent' ||
          tx.description.toLowerCase().contains('rent');
      if (isRent && tx.amount > 0) {
        detectedRent = tx.amount;
        rentDetected = true;
        break;
      }
    }

    // 5. Projected Spend for current month
    // (Velocity * remaining days) + EMIs + Rent (if rent was not paid yet this month)
    // Check if rent has already been paid this month
    final firstOfMonth = DateTime(now.year, now.month, 1);
    bool rentPaidThisMonth = transactions.any((tx) =>
        (tx.category.toLowerCase() == 'rent' || tx.description.toLowerCase().contains('rent')) &&
        tx.timestamp.isAfter(firstOfMonth) &&
        tx.transactionType == 'expense');

    double projectedSpend = (dailyVelocity * remainingDays) + recurringEmis;
    if (!rentPaidThisMonth) {
      projectedSpend += detectedRent;
    }

    // 6. Calculate Cash and Bank Balance
    double cashAndBank = 0.0;
    for (final acc in bankAccounts) {
      cashAndBank += acc.balance;
    }
    for (final tx in transactions) {
      if (tx.cardId == null) {
        if (tx.transactionType == 'income') {
          cashAndBank += tx.amount;
        } else if (tx.transactionType == 'expense') {
          cashAndBank -= tx.amount;
        }
      }
    }

    // 7. Calculate Asset Allocation (Stocks vs Mutual Funds)
    double stocksVal = 0.0;
    double mfVal = 0.0;
    for (final h in holdings) {
      final val = h.currentPrice * h.quantity;
      if (h.assetType == 'stock') {
        stocksVal += val;
      } else if (h.assetType == 'mutual_fund') {
        mfVal += val;
      }
    }
    final totalPortfolioVal = stocksVal + mfVal;
    
    double stocksPercentage = 0.0;
    double mfsPercentage = 0.0;
    if (totalPortfolioVal > 0) {
      stocksPercentage = (stocksVal / totalPortfolioVal) * 100;
      mfsPercentage = (mfVal / totalPortfolioVal) * 100;
    }

    // Standard aggressive model: 70% Equity / 30% Mutual/Hybrid/Debt Funds
    double rebalanceAmount = 0.0;
    if (stocksPercentage > 70.0 && totalPortfolioVal > 0) {
      final targetStocksVal = totalPortfolioVal * 0.70;
      rebalanceAmount = stocksVal - targetStocksVal;
    }

    // 8. Emergency Fund Analysis (Months coverage of outflow)
    final monthlyCashOutflow = (dailyVelocity * 30) + recurringEmis + detectedRent;
    final emergencyFundMonths = monthlyCashOutflow > 0 ? cashAndBank / monthlyCashOutflow : 0.0;
    final recommendedEmergencyFund = monthlyCashOutflow * 6.0;

    return QuantForecastResult(
      dailyVelocity: dailyVelocity,
      remainingDays: remainingDays,
      projectedSpend: projectedSpend,
      recurringEmis: recurringEmis,
      detectedRent: detectedRent,
      cashAndBank: cashAndBank,
      stocksVal: stocksVal,
      mfVal: mfVal,
      stocksPercentage: stocksPercentage,
      mfsPercentage: mfsPercentage,
      emergencyFundMonths: emergencyFundMonths,
      recommendedEmergencyFund: recommendedEmergencyFund,
      rebalanceAmount: rebalanceAmount,
    );
  }
}
