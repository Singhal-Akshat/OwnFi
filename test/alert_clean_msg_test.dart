import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Alert Banner Utility Tests', () {
    test('Should clean technical references from warning message strings correctly', () {
      String cleanMessage(String msg) {
        final idx = msg.indexOf('(ref:');
        if (idx != -1) {
          return msg.substring(0, idx).trim();
        }
        return msg;
      }

      const rawMsg1 = 'Your bill of ₹5745 for Scapia Rupay is due in 1 days (ref: 11_2026-07-01T00:00:00.000)';
      expect(cleanMessage(rawMsg1), 'Your bill of ₹5745 for Scapia Rupay is due in 1 days');

      const rawMsg2 = 'Your bill of ₹676 for IDFC Visa is OVERDUE (ref: 8_2026-06-20T00:00:00.000)';
      expect(cleanMessage(rawMsg2), 'Your bill of ₹676 for IDFC Visa is OVERDUE');

      const cleanMsg = 'You have spent 85% of your Category budget.';
      expect(cleanMessage(cleanMsg), 'You have spent 85% of your Category budget.');
    });
  });
}
