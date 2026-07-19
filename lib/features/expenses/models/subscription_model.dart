import 'package:isar/isar.dart';

part 'subscription_model.g.dart';

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  String name = '';
  double amount = 0.0;
  DateTime startDate = DateTime.now();
  String billingCycle = 'monthly'; // 'weekly', 'monthly', 'yearly'
  String category = 'Subscriptions';
  bool isActive = true;
  DateTime? nextRenewalDate;

  // Calculates the next renewal date after or equal to today
  DateTime calculateNextRenewalDate() {
    final now = DateTime.now();
    DateTime checkDate = startDate;

    // Normalize dates to midnight for consistent comparisons
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final today = DateTime(now.year, now.month, now.day);

    if (checkDate.isAfter(today) || checkDate.isAtSameMomentAs(today)) {
      return checkDate;
    }

    while (checkDate.isBefore(today)) {
      if (billingCycle == 'weekly') {
        checkDate = checkDate.add(const Duration(days: 7));
      } else if (billingCycle == 'monthly') {
        int year = checkDate.year;
        int month = checkDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        // Safely clamp day if target month has fewer days (e.g. Jan 31 -> Feb 28)
        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        final targetDay = startDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : startDate.day;
        checkDate = DateTime(year, month, targetDay);
      } else if (billingCycle == 'yearly') {
        checkDate = DateTime(checkDate.year + 1, checkDate.month, checkDate.day);
      } else {
        checkDate = checkDate.add(const Duration(days: 30));
        break;
      }
    }
    return checkDate;
  }
}
