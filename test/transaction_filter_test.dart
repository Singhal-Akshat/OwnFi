import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';

class MockTransactions extends Transactions {
  final List<Transaction> initialTransactions;
  MockTransactions(this.initialTransactions);

  @override
  FutureOr<List<Transaction>> build() {
    return initialTransactions;
  }
}

void main() {
  group('Transaction Filter & Sorting Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          transactionsProvider.overrideWith(() => MockTransactions([
            Transaction()
              ..id = 1
              ..description = 'Netflix Subscription'
              ..category = 'Entertainment'
              ..transactionType = 'expense'
              ..accountName = 'bank:Account1'
              ..amount = 649.0
              ..timestamp = DateTime(2026, 7, 10),
            Transaction()
              ..id = 2
              ..description = 'Spotify Premium'
              ..category = 'Entertainment'
              ..cardId = 'Card2'
              ..transactionType = 'expense'
              ..amount = 149.0
              ..timestamp = DateTime(2026, 7, 12),
            Transaction()
              ..id = 3
              ..description = 'Salary Cash Credit'
              ..category = 'Salary'
              ..accountName = 'bank:Account1'
              ..transactionType = 'income'
              ..amount = 50000.0
              ..timestamp = DateTime(2026, 7, 1),
          ])),
        ],
      );
      // Align month filter with the mock data timestamps
      container.read(transactionMonthFilterProvider.notifier).state = DateTime(2026, 7);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state returns all records sorted by date descending', () {
      final state = container.read(filteredTransactionsProvider);
      expect(state.hasValue, isTrue);
      
      final result = state.value!;
      expect(result.length, 3);
      expect(result[0].description, 'Spotify Premium'); // July 12
      expect(result[1].description, 'Netflix Subscription'); // July 10
      expect(result[2].description, 'Salary Cash Credit'); // July 1
    });

    test('Filter by transaction month', () {
      // Set filter to June 2026 (should return 0)
      container.read(transactionMonthFilterProvider.notifier).state = DateTime(2026, 6);
      var result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 0);

      // Set filter to July 2026 (should return 3)
      container.read(transactionMonthFilterProvider.notifier).state = DateTime(2026, 7);
      result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 3);

      // Set filter to null / All Time (should return all 3)
      container.read(transactionMonthFilterProvider.notifier).state = null;
      result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 3);
    });

    test('Filter by search query matching description', () {
      container.read(transactionSearchQueryProvider.notifier).state = 'spotify';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 1);
      expect(result[0].description, 'Spotify Premium');
    });

    test('Filter by search query matching category name', () {
      container.read(transactionSearchQueryProvider.notifier).state = 'entertainment';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 2);
      expect(result.any((t) => t.description == 'Spotify Premium'), isTrue);
      expect(result.any((t) => t.description == 'Netflix Subscription'), isTrue);
    });

    test('Filter by transaction type', () {
      container.read(transactionTypeFilterProvider.notifier).state = 'income';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 1);
      expect(result[0].description, 'Salary Cash Credit');
    });

    test('Filter by category', () {
      container.read(transactionCategoryFilterProvider.notifier).state = 'Salary';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 1);
      expect(result[0].description, 'Salary Cash Credit');
    });

    test('Filter by account / card id association', () {
      container.read(transactionAccountFilterProvider.notifier).state = 'Card2';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 1);
      expect(result[0].description, 'Spotify Premium');
    });

    test('Filter by bank account name key', () {
      container.read(transactionAccountFilterProvider.notifier).state = 'bank:Account1';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 2);
      expect(result.any((t) => t.description == 'Netflix Subscription'), isTrue);
      expect(result.any((t) => t.description == 'Salary Cash Credit'), isTrue);
    });

    test('Sorting by amount ascending order', () {
      container.read(transactionSortProvider.notifier).state = 'amount_asc';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 3);
      expect(result[0].description, 'Spotify Premium'); // 149
      expect(result[1].description, 'Netflix Subscription'); // 649
      expect(result[2].description, 'Salary Cash Credit'); // 50000
    });

    test('Sorting by amount descending order', () {
      container.read(transactionSortProvider.notifier).state = 'amount_desc';
      
      final result = container.read(filteredTransactionsProvider).value!;
      expect(result.length, 3);
      expect(result[0].description, 'Salary Cash Credit'); // 50000
      expect(result[1].description, 'Netflix Subscription'); // 649
      expect(result[2].description, 'Spotify Premium'); // 149
    });
  });
}
