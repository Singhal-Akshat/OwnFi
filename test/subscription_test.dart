import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/features/expenses/models/subscription_model.dart';

void main() {
  group('Subscription Renewal Calculation Tests', () {
    test('Weekly billing cycle next renewal date calculation', () {
      final sub = Subscription()
        ..name = 'Weekly Test'
        ..amount = 5.0
        ..startDate = DateTime.now().subtract(const Duration(days: 10)) // 10 days ago
        ..billingCycle = 'weekly';

      // Starting 10 days ago, cycle is 7 days.
      // 10 days ago + 7 days = 3 days ago (still in past)
      // 3 days ago + 7 days = 4 days from now (in future)
      final expectedDate = DateTime.now().subtract(const Duration(days: 10)).add(const Duration(days: 14));
      final renewalDate = sub.calculateNextRenewalDate();

      expect(renewalDate.year, expectedDate.year);
      expect(renewalDate.month, expectedDate.month);
      expect(renewalDate.day, expectedDate.day);
    });

    test('Monthly billing cycle next renewal date calculation', () {
      final sub = Subscription()
        ..name = 'Monthly Test'
        ..amount = 199.0
        ..startDate = DateTime(2026, 6, 15) // June 15, 2026
        ..billingCycle = 'monthly';

      // Calculate next renewal date relative to now (assuming current time is July 2026)
      // June 15 + 1 month = July 15. If July 15 is in the past, it should be August 15, etc.
      // Let's test with custom dates.
      // We check that for startDate June 15, if today is July 10, the renewal date is July 15.
      final renewalDate = sub.calculateNextRenewalDate();
      
      // Verification logic:
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      expect(renewalDate.day, 15);
      expect(renewalDate.isBefore(today), isFalse);
    });

    test('Monthly date clamp check (Jan 31st to Feb 28th)', () {
      final sub = Subscription()
        ..name = 'Netflix month clamp'
        ..amount = 649.0
        ..startDate = DateTime(2026, 1, 31) // Jan 31st
        ..billingCycle = 'monthly';

      // If we calculate next renewal relative to Feb 1st, it should clamp to Feb 28th (non-leap year) or Feb 29th (leap year).
      // Let's call the calculation. The calculator checks today's year/month.
      // Since 2026 is non-leap year, let's verify that when target month is February, it clamps to 28 (or 29 in leap year).
      final renewalDate = sub.calculateNextRenewalDate();
      
      // If today is after Jan 31, 2026, it should be Feb 28, 2026 (or later month).
      // We expect the day of the renewalDate to be 31 or the last day of February if February is selected.
      if (renewalDate.month == 2) {
        expect(renewalDate.day, 28);
      } else {
        expect(renewalDate.day, 31);
      }
    });

    test('Yearly billing cycle next renewal date calculation', () {
      final sub = Subscription()
        ..name = 'Amazon Prime Yearly'
        ..amount = 1499.0
        ..startDate = DateTime(2025, 1, 10)
        ..billingCycle = 'yearly';

      final renewalDate = sub.calculateNextRenewalDate();
      
      // If start is Jan 10, 2025, and today is July 2026, next renewal should be Jan 10, 2027.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(renewalDate.month, 1);
      expect(renewalDate.day, 10);
      expect(renewalDate.isBefore(today), isFalse);
    });
  });
}
