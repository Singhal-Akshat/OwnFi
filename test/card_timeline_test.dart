import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/cards_loans/utils/card_timeline_helper.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';

void main() {
  group('Credit Card Billing Timeline Calculator Tests', () {
    late CreditCard card;

    setUp(() {
      card = CreditCard()
        ..id = 1
        ..cardName = 'Mock Scapia Card'
        ..statementDay = 15
        ..dueDay = 5
        ..statementAmount = 0.0;
    });

    test('Paid status when there are no transactions or payments exceed statement balance', () {
      final timeline = CardTimelineHelper.calculateTimeline(
        card,
        [],
        mockNow: DateTime(2026, 7, 20),
      );

      expect(timeline.status, CardTimelineStatus.paid);
      expect(timeline.statementBalance, 0.0);
      expect(timeline.remainingDue, 0.0);
    });

    test('Due status when there is an unpaid balance and due date is close', () {
      final txs = [
        Transaction()
          ..cardId = '1'
          ..transactionType = 'expense'
          ..amount = 5000.0
          ..timestamp = DateTime(2026, 6, 20), // falls in June 15 to July 15 cycle
      ];

      // Current date is Aug 3, due is Aug 5 (dueDay 5 < statementDay 15, so next month Aug 5)
      // Days remaining: 2 days (Aug 5 - Aug 3) -> due soon!
      final timeline = CardTimelineHelper.calculateTimeline(
        card,
        txs,
        mockNow: DateTime(2026, 8, 3), // statement date was July 15th
      );

      expect(timeline.statementDate, DateTime(2026, 7, 15));
      expect(timeline.dueDate, DateTime(2026, 8, 5));
      expect(timeline.statementBalance, 5000.0);
      expect(timeline.daysRemaining, 2);
      expect(timeline.status, CardTimelineStatus.dueSoon);
    });

    test('Overdue status when due date has passed without payment', () {
      final txs = [
        Transaction()
          ..cardId = '1'
          ..transactionType = 'expense'
          ..amount = 3000.0
          ..timestamp = DateTime(2026, 6, 20),
      ];

      // Current date is Aug 6, due is Aug 5.
      // Days remaining: -1 day -> overdue!
      final timeline = CardTimelineHelper.calculateTimeline(
        card,
        txs,
        mockNow: DateTime(2026, 8, 6),
      );

      expect(timeline.status, CardTimelineStatus.overdue);
      expect(timeline.daysRemaining, -1);
      expect(timeline.remainingDue, 3000.0);
    });

    test('Statement override balance is respected', () {
      card.statementAmount = 7500.0;
      final timeline = CardTimelineHelper.calculateTimeline(
        card,
        [],
        mockNow: DateTime(2026, 8, 1),
      );

      expect(timeline.statementBalance, 7500.0);
    });
  });
}
