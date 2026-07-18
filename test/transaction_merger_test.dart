import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/core/utils/transaction_merger.dart';

void main() {
  group('TransactionMerger Tests', () {
    test('Should return empty list if input is empty', () {
      final result = TransactionMerger.mergeDuplicateTransactions([]);
      expect(result, isEmpty);
    });

    test('Should not merge transactions with different amounts or types', () {
      final now = DateTime.now();
      final items = [
        {
          'body': 'Spent Rs. 100 on Netflix',
          'date': now,
          'source': 'sms',
          'approvedByRegex': true,
          'isAlreadyRecorded': false,
          'isSkipped': false,
        },
        {
          'body': 'Spent Rs. 200 on Spotify',
          'date': now,
          'source': 'email',
          'approvedByRegex': true,
          'isAlreadyRecorded': false,
          'isSkipped': false,
        }
      ];

      final result = TransactionMerger.mergeDuplicateTransactions(items);
      expect(result.length, 2);
    });
  });
}
