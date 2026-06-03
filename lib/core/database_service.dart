import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/expenses/models/transaction_model.dart';
import '../features/cards_loans/models/card_loan_models.dart';
import '../features/investments/models/holding_model.dart';

// Riverpod provider for the database service
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

class DatabaseService {
  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      throw StateError(
        'DatabaseService has not been initialized. Call init() first.',
      );
    }
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null) return;
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open(
      [TransactionSchema, CreditCardSchema, LoanSchema, HoldingSchema],
      directory: dir.path,
      inspector: true, // Enable local Isar DB inspector in debug mode
    );
    await seedDemoData();
  }

  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }

  Future<void> seedDemoData() async {
    const storage = FlutterSecureStorage();
    final hasCleared = await storage.read(key: 'settings_has_cleared_data');
    if (hasCleared == 'true') return; // do not re-seed if the user cleared data

    final cardCount = await isar.creditCards.count();
    if (cardCount > 0) return; // already seeded

    await isar.writeTxn(() async {
      // 1. Credit Cards
      final card1 = CreditCard()
        ..cardName = 'HDFC Regalia'
        ..last4 = '1234'
        ..creditLimit = 500000.0
        ..statementDay = 15
        ..dueDay = 5
        ..balance = 145000.0
        ..activeEmis = [
          CreditCardEmi()
            ..description = 'MacBook Pro 16'
            ..totalAmount = 240000.0
            ..monthlyInstallment = 20000.0
            ..totalMonths = 12
            ..remainingMonths = 8
            ..startDate = DateTime.now().subtract(const Duration(days: 120)),
        ];

      final card2 = CreditCard()
        ..cardName = 'ICICI Amazon Pay'
        ..last4 = '5678'
        ..creditLimit = 300000.0
        ..statementDay = 20
        ..dueDay = 10
        ..balance = 24500.0;

      await isar.creditCards.putAll([card1, card2]);

      // 2. Loans
      final loan1 = Loan()
        ..contactName = 'SBI Home Loan'
        ..isLent = false
        ..amount = 4500000.0
        ..interestRate = 8.5
        ..compoundInterval = 'monthly'
        ..startDate = DateTime.now().subtract(const Duration(days: 365))
        ..emiAmount = 38200.0
        ..remainingBalance = 4320000.0;

      final loan2 = Loan()
        ..contactName = 'Joy (Split settlement)'
        ..isLent = true
        ..amount = 3500.0
        ..interestRate = 0.0
        ..compoundInterval = 'none'
        ..startDate = DateTime.now().subtract(const Duration(days: 5))
        ..emiAmount = 0.0
        ..remainingBalance = 3500.0;

      await isar.loans.putAll([loan1, loan2]);

      // 3. Holdings
      final holding1 = Holding()
        ..symbol = 'TCS'
        ..name = 'Tata Consultancy Services'
        ..quantity = 25.0
        ..buyAvgPrice = 3820.0
        ..currentPrice = 4150.0
        ..assetType = 'stock'
        ..broker = 'zerodha';

      final holding2 = Holding()
        ..symbol = 'RELIANCE'
        ..name = 'Reliance Industries Ltd.'
        ..quantity = 50.0
        ..buyAvgPrice = 2450.0
        ..currentPrice = 2920.0
        ..assetType = 'stock'
        ..broker = 'zerodha';

      final holding3 = Holding()
        ..symbol = 'Parag Parikh Flexi Cap'
        ..name = 'Direct Growth Mutual Fund'
        ..quantity = 1240.0
        ..buyAvgPrice = 62.4
        ..currentPrice = 78.9
        ..assetType = 'mutual_fund'
        ..broker = 'coin';

      await isar.holdings.putAll([holding1, holding2, holding3]);

      // 4. Transactions
      final tx1 = Transaction()
        ..amount = 649.0
        ..description = 'Netflix Subscription'
        ..timestamp = DateTime.now().subtract(const Duration(days: 1))
        ..transactionType = 'expense'
        ..category = 'Entertainment'
        ..source = 'manual'
        ..accountName = 'Cash';

      final tx2 = Transaction()
        ..amount = 1200.0
        ..description = 'Zerodha Dividend'
        ..timestamp = DateTime.now().subtract(const Duration(days: 2))
        ..transactionType = 'income'
        ..category = 'Investment'
        ..source = 'manual'
        ..accountName = 'Bank';

      final tx3 = Transaction()
        ..amount = 15000.0
        ..description = 'Amazon Purchase'
        ..timestamp = DateTime.now().subtract(const Duration(days: 3))
        ..transactionType = 'expense'
        ..category = 'Electronics'
        ..source = 'manual'
        ..accountName = 'Cash';

      await isar.transactions.putAll([tx1, tx2, tx3]);
    });
  }

  // ----------------- TRANSACTIONS CRUD -----------------
  Future<List<Transaction>> getAllTransactions() async {
    return isar.transactions.where().sortByTimestampDesc().findAll();
  }

  Future<void> saveTransaction(Transaction transaction) async {
    await isar.writeTxn(() async {
      // If editing an existing transaction, revert its old effect on card balance first
      if (transaction.id != Isar.autoIncrement) {
        final oldTx = await isar.transactions.get(transaction.id);
        if (oldTx != null && oldTx.cardId != null) {
          final cardIdInt = int.tryParse(oldTx.cardId!);
          if (cardIdInt != null) {
            final card = await isar.creditCards.get(cardIdInt);
            if (card != null) {
              if (oldTx.transactionType == 'expense') {
                card.balance -= oldTx.amount;
              } else if (oldTx.transactionType == 'transfer') {
                card.balance += oldTx.amount;
              }
              await isar.creditCards.put(card);
            }
          }
        }
      }

      await isar.transactions.put(transaction);

      // If it's linked to a credit card, update card balance!
      if (transaction.cardId != null &&
          transaction.transactionType == 'expense') {
        final cardIdInt = int.tryParse(transaction.cardId!);
        if (cardIdInt != null) {
          final card = await isar.creditCards.get(cardIdInt);
          if (card != null) {
            card.balance += transaction.amount;
            await isar.creditCards.put(card);
          }
        }
      } else if (transaction.cardId != null &&
          transaction.transactionType == 'transfer') {
        // Paying credit card bill
        final cardIdInt = int.tryParse(transaction.cardId!);
        if (cardIdInt != null) {
          final card = await isar.creditCards.get(cardIdInt);
          if (card != null) {
            card.balance -= transaction.amount;
            await isar.creditCards.put(card);
          }
        }
      }
    });
  }

  Future<void> deleteTransaction(int id) async {
    await isar.writeTxn(() async {
      final transaction = await isar.transactions.get(id);
      if (transaction != null && transaction.cardId != null) {
        // Revert card balance adjustment
        final cardIdInt = int.tryParse(transaction.cardId!);
        if (cardIdInt != null) {
          final card = await isar.creditCards.get(cardIdInt);
          if (card != null) {
            if (transaction.transactionType == 'expense') {
              card.balance -= transaction.amount;
            } else if (transaction.transactionType == 'transfer') {
              card.balance += transaction.amount;
            }
            await isar.creditCards.put(card);
          }
        }
      }
      await isar.transactions.delete(id);
    });
  }

  // ----------------- CREDIT CARDS CRUD -----------------
  Future<List<CreditCard>> getAllCreditCards() async {
    return isar.creditCards.where().findAll();
  }

  Future<void> saveCreditCard(CreditCard card) async {
    await isar.writeTxn(() async {
      await isar.creditCards.put(card);
    });
  }

  // ----------------- LOANS CRUD -----------------
  Future<List<Loan>> getAllLoans() async {
    return isar.loans.where().findAll();
  }

  Future<void> saveLoan(Loan loan) async {
    await isar.writeTxn(() async {
      await isar.loans.put(loan);
    });
  }

  Future<void> deleteLoan(int id) async {
    await isar.writeTxn(() async {
      await isar.loans.delete(id);
    });
  }

  // ----------------- HOLDINGS CRUD -----------------
  Future<List<Holding>> getAllHoldings() async {
    return isar.holdings.where().findAll();
  }

  Future<void> saveHolding(Holding holding) async {
    await isar.writeTxn(() async {
      await isar.holdings.put(holding);
    });
  }

  Future<void> clearHoldings() async {
    await isar.writeTxn(() async {
      await isar.holdings.clear();
    });
  }

  Future<void> clearAllData() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'settings_has_cleared_data', value: 'true');

    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.creditCards.clear();
      await isar.loans.clear();
      await isar.holdings.clear();
    });
  }
}
