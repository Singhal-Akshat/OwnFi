import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';

enum CardTimelineStatus {
  paid,
  dueSoon,
  overdue,
  normal,
}

class CardTimeline {
  final DateTime statementDate;
  final DateTime dueDate;
  final double statementBalance;
  final double totalPaid;
  final double remainingDue;
  final int daysRemaining;
  final CardTimelineStatus status;

  CardTimeline({
    required this.statementDate,
    required this.dueDate,
    required this.statementBalance,
    required this.totalPaid,
    required this.remainingDue,
    required this.daysRemaining,
    required this.status,
  });
}

class CardTimelineHelper {
  /// Calculate the billing timeline parameters for a credit card
  static CardTimeline calculateTimeline(
    CreditCard card,
    List<Transaction> transactions, {
    DateTime? mockNow,
  }) {
    final now = mockNow ?? DateTime.now();

    // 1. Calculate most recent statement generation date
    final DateTime statementDate;
    if (now.day >= card.statementDay) {
      statementDate = DateTime(now.year, now.month, card.statementDay);
    } else {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      statementDate = DateTime(prevYear, prevMonth, card.statementDay);
    }

    // 2. Calculate the previous statement date (start of statement cycle)
    final prevMonth = statementDate.month == 1 ? 12 : statementDate.month - 1;
    final prevYear = statementDate.month == 1 ? statementDate.year - 1 : statementDate.year;
    final DateTime previousStatementDate = DateTime(prevYear, prevMonth, card.statementDay);

    // 3. Calculate due date for the statement bill
    final DateTime dueDate;
    if (card.dueDay > card.statementDay) {
      dueDate = DateTime(statementDate.year, statementDate.month, card.dueDay);
    } else {
      final nextMonth = statementDate.month == 12 ? 1 : statementDate.month + 1;
      final nextYear = statementDate.month == 12 ? statementDate.year + 1 : statementDate.year;
      dueDate = DateTime(nextYear, nextMonth, card.dueDay);
    }

    // 4. Calculate statement balance (expenses from previousStatementDate to statementDate)
    final cardId = card.id.toString();
    final statementBalance = transactions
        .where((t) =>
            t.cardId == cardId &&
            t.transactionType == 'expense' &&
            (t.timestamp.isAtSameMomentAs(previousStatementDate) || t.timestamp.isAfter(previousStatementDate)) &&
            t.timestamp.isBefore(statementDate))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    // 5. Calculate payment transactions made since statement Date
    final totalPaid = transactions
        .where((t) =>
            t.cardId == cardId &&
            t.transactionType == 'transfer' &&
            (t.timestamp.isAtSameMomentAs(statementDate) || t.timestamp.isAfter(statementDate)))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    // 6. Remaining statement due
    final targetDue = card.statementAmount > 0.0 ? card.statementAmount : statementBalance;
    final remainingDue = (targetDue - totalPaid).clamp(0.0, double.infinity);

    // 7. Days remaining
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysRemaining = dueStart.difference(todayStart).inDays;

    // 8. Determine timeline status
    CardTimelineStatus status = CardTimelineStatus.normal;
    if (remainingDue <= 0.0) {
      status = CardTimelineStatus.paid;
    } else if (daysRemaining < 0) {
      status = CardTimelineStatus.overdue;
    } else if (daysRemaining <= 3) {
      status = CardTimelineStatus.dueSoon;
    }

    return CardTimeline(
      statementDate: statementDate,
      dueDate: dueDate,
      statementBalance: targetDue,
      totalPaid: totalPaid,
      remainingDue: remainingDue,
      daysRemaining: daysRemaining,
      status: status,
    );
  }
}
