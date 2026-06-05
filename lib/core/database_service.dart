import 'package:flutter/foundation.dart';
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
  VoidCallback? onChanged;

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
      [TransactionSchema, CreditCardSchema, LoanSchema, HoldingSchema, BankAccountSchema],
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
        ..cardId = '1'
        ..accountName = 'Credit Card'
        ..source = 'demo';

      final tx2 = Transaction()
        ..amount = 1200.0
        ..description = 'Dinner at restaurant'
        ..timestamp = DateTime.now().subtract(const Duration(days: 2))
        ..transactionType = 'expense'
        ..category = 'Food'
        ..cardId = null
        ..accountName = 'Cash'
        ..source = 'demo';

      final tx3 = Transaction()
        ..amount = 75000.0
        ..description = 'Monthly Salary'
        ..timestamp = DateTime.now().subtract(const Duration(days: 5))
        ..transactionType = 'income'
        ..category = 'Salary'
        ..cardId = null
        ..accountName = 'bank:1'
        ..source = 'demo';

      await isar.transactions.putAll([tx1, tx2, tx3]);

      // 5. Bank Accounts
      final bank1 = BankAccount()
        ..bankName = 'HDFC Bank'
        ..accountHolderName = 'Akshat Singhal'
        ..last4 = '9876'
        ..fullAccountNumber = '50100234567890'
        ..ifscCode = 'HDFC0000123'
        ..balance = 125430.0
        ..logoAsset = 'HDB.svg'
        ..colorHex = '#003366';

      final bank2 = BankAccount()
        ..bankName = 'State Bank of India'
        ..accountHolderName = 'Akshat Singhal'
        ..last4 = '4321'
        ..fullAccountNumber = '30012345678'
        ..ifscCode = 'SBIN0000301'
        ..balance = 45320.0
        ..logoAsset = 'SBI.svg'
        ..colorHex = '#2196F3';

      await isar.bankAccounts.putAll([bank1, bank2]);
    });
  }

  // ----------------- TRANSACTIONS CRUD -----------------
  Future<List<Transaction>> getActiveTransactions() async {
    return isar.transactions.filter().isDeletedEqualTo(false).sortByTimestampDesc().findAll();
  }

  Future<List<Transaction>> getAllTransactions() async {
    return getActiveTransactions();
  }

  Future<List<Transaction>> getDeletedTransactions() async {
    return isar.transactions.filter().isDeletedEqualTo(true).sortByDeletedAtDesc().findAll();
  }

  Future<void> saveTransaction(Transaction transaction) async {
    await isar.writeTxn(() async {
      // Revert old transaction balances if we are updating an existing transaction
      if (transaction.id != null && transaction.id != Isar.autoIncrement) {
        final oldTx = await isar.transactions.get(transaction.id);
        if (oldTx != null && !oldTx.isDeleted) {
          if (oldTx.cardId != null) {
            if (oldTx.cardId!.startsWith('bank:')) {
              final toBankIdInt = int.tryParse(oldTx.cardId!.substring(5));
              if (toBankIdInt != null) {
                final toBank = await isar.bankAccounts.get(toBankIdInt);
                if (toBank != null) {
                  if (oldTx.transactionType == 'transfer') {
                    toBank.balance -= oldTx.amount;
                  }
                  await isar.bankAccounts.put(toBank);
                }
              }
            } else {
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

          if (oldTx.accountName != null && oldTx.accountName!.startsWith('bank:')) {
            final bankIdInt = int.tryParse(oldTx.accountName!.substring(5));
            if (bankIdInt != null) {
              final bank = await isar.bankAccounts.get(bankIdInt);
              if (bank != null) {
                if (oldTx.transactionType == 'expense' || oldTx.transactionType == 'transfer') {
                  bank.balance += oldTx.amount;
                } else if (oldTx.transactionType == 'income') {
                  bank.balance -= oldTx.amount;
                }
                await isar.bankAccounts.put(bank);
              }
            }
          }
        }
      }

      await isar.transactions.put(transaction);

      // Adjust credit card balance if transaction is linked to a card
      if (transaction.cardId != null && !transaction.isDeleted) {
        if (transaction.cardId!.startsWith('bank:')) {
          final toBankIdInt = int.tryParse(transaction.cardId!.substring(5));
          if (toBankIdInt != null) {
            final toBank = await isar.bankAccounts.get(toBankIdInt);
            if (toBank != null) {
              if (transaction.transactionType == 'transfer') {
                toBank.balance += transaction.amount;
              }
              await isar.bankAccounts.put(toBank);
            }
          }
        } else {
          final cardIdInt = int.tryParse(transaction.cardId!);
          if (cardIdInt != null) {
            final card = await isar.creditCards.get(cardIdInt);
            if (card != null) {
              if (transaction.transactionType == 'expense') {
                card.balance += transaction.amount;
              } else if (transaction.transactionType == 'transfer') {
                card.balance -= transaction.amount;
              }
              await isar.creditCards.put(card);
            }
          }
        }
      }

      // Adjust bank account balance if transaction is linked to a bank
      if (transaction.accountName != null && transaction.accountName!.startsWith('bank:') && !transaction.isDeleted) {
        final bankIdInt = int.tryParse(transaction.accountName!.substring(5));
        if (bankIdInt != null) {
          final bank = await isar.bankAccounts.get(bankIdInt);
          if (bank != null) {
            if (transaction.transactionType == 'expense' || transaction.transactionType == 'transfer') {
              bank.balance -= transaction.amount;
            } else if (transaction.transactionType == 'income') {
              bank.balance += transaction.amount;
            }
            await isar.bankAccounts.put(bank);
          }
        }
      }
    });
    onChanged?.call();
  }

  Future<void> softDeleteTransaction(int id) async {
    print('DEBUG: softDeleteTransaction called for id: $id');
    await isar.writeTxn(() async {
      final transaction = await isar.transactions.get(id);
      if (transaction != null) {
        transaction.isDeleted = true;
        transaction.deletedAt = DateTime.now();
        await isar.transactions.put(transaction);
        print('DEBUG: softDeleteTransaction - marked transaction ${transaction.id} as deleted. type: ${transaction.transactionType}, amount: ${transaction.amount}, accountName: ${transaction.accountName}, cardId: ${transaction.cardId}');

        if (transaction.cardId != null) {
          if (transaction.cardId!.startsWith('bank:')) {
            final toBankIdInt = int.tryParse(transaction.cardId!.substring(5));
            if (toBankIdInt != null) {
              final toBank = await isar.bankAccounts.get(toBankIdInt);
              if (toBank != null) {
                final oldBalance = toBank.balance;
                if (transaction.transactionType == 'transfer') {
                  toBank.balance -= transaction.amount;
                }
                await isar.bankAccounts.put(toBank);
                print('DEBUG: softDeleteTransaction - reverted cardId bank (toBank) balance from $oldBalance to ${toBank.balance}');
              }
            }
          } else {
            // Revert card balance adjustment
            final cardIdInt = int.tryParse(transaction.cardId!);
            if (cardIdInt != null) {
              final card = await isar.creditCards.get(cardIdInt);
              if (card != null) {
                final oldBalance = card.balance;
                if (transaction.transactionType == 'expense') {
                  card.balance -= transaction.amount;
                } else if (transaction.transactionType == 'transfer') {
                  card.balance += transaction.amount;
                }
                await isar.creditCards.put(card);
                print('DEBUG: softDeleteTransaction - reverted creditCard balance from $oldBalance to ${card.balance}');
              }
            }
          }
        }

        if (transaction.accountName != null && transaction.accountName!.startsWith('bank:')) {
          // Revert bank balance adjustment
          final bankIdInt = int.tryParse(transaction.accountName!.substring(5));
          if (bankIdInt != null) {
            final bank = await isar.bankAccounts.get(bankIdInt);
            if (bank != null) {
              final oldBalance = bank.balance;
              if (transaction.transactionType == 'expense' || transaction.transactionType == 'transfer') {
                bank.balance += transaction.amount;
              } else if (transaction.transactionType == 'income') {
                bank.balance -= transaction.amount;
              }
              await isar.bankAccounts.put(bank);
              print('DEBUG: softDeleteTransaction - reverted accountName bank balance from $oldBalance to ${bank.balance}');
            } else {
              print('DEBUG: softDeleteTransaction - bank account with id $bankIdInt not found in DB');
            }
          }
        }
      } else {
        print('DEBUG: softDeleteTransaction - transaction with id $id was null');
      }
    });
    onChanged?.call();
  }

  Future<void> deleteTransaction(int id) async {
    await softDeleteTransaction(id);
  }

  Future<void> restoreTransaction(int id) async {
    await isar.writeTxn(() async {
      final transaction = await isar.transactions.get(id);
      if (transaction != null) {
        transaction.isDeleted = false;
        transaction.deletedAt = null;
        await isar.transactions.put(transaction);

        if (transaction.cardId != null) {
          if (transaction.cardId!.startsWith('bank:')) {
            final toBankIdInt = int.tryParse(transaction.cardId!.substring(5));
            if (toBankIdInt != null) {
              final toBank = await isar.bankAccounts.get(toBankIdInt);
              if (toBank != null) {
                if (transaction.transactionType == 'transfer') {
                  toBank.balance += transaction.amount;
                }
                await isar.bankAccounts.put(toBank);
              }
            }
          } else {
            // Re-apply card balance adjustment
            final cardIdInt = int.tryParse(transaction.cardId!);
            if (cardIdInt != null) {
              final card = await isar.creditCards.get(cardIdInt);
              if (card != null) {
                if (transaction.transactionType == 'expense') {
                  card.balance += transaction.amount;
                } else if (transaction.transactionType == 'transfer') {
                  card.balance -= transaction.amount;
                }
                await isar.creditCards.put(card);
              }
            }
          }
        }

        if (transaction.accountName != null && transaction.accountName!.startsWith('bank:')) {
          // Re-apply bank balance adjustment
          final bankIdInt = int.tryParse(transaction.accountName!.substring(5));
          if (bankIdInt != null) {
            final bank = await isar.bankAccounts.get(bankIdInt);
            if (bank != null) {
              if (transaction.transactionType == 'expense' || transaction.transactionType == 'transfer') {
                bank.balance -= transaction.amount;
              } else if (transaction.transactionType == 'income') {
                bank.balance += transaction.amount;
              }
              await isar.bankAccounts.put(bank);
            }
          }
        }
      }
    });
    onChanged?.call();
  }

  Future<void> permanentlyDeleteTransaction(int id) async {
    await isar.writeTxn(() async {
      await isar.transactions.delete(id);
    });
    onChanged?.call();
  }

  Future<void> clearAllTransactions() async {
    await isar.writeTxn(() async {
      await isar.transactions.clear();
      
      // Reset card balances to 0.0 when clearing all transactions
      final cards = await isar.creditCards.where().findAll();
      for (var card in cards) {
        card.balance = 0.0;
        await isar.creditCards.put(card);
      }

      // Reset bank account balances to 0.0 when clearing all transactions
      final banks = await isar.bankAccounts.where().findAll();
      for (var bank in banks) {
        bank.balance = 0.0;
        await isar.bankAccounts.put(bank);
      }
    });
    onChanged?.call();
  }

  Future<void> clearAllLoans() async {
    await isar.writeTxn(() async {
      await isar.loans.clear();
    });
    onChanged?.call();
  }

  // ----------------- CREDIT CARDS CRUD -----------------
  Future<List<CreditCard>> getAllCreditCards() async {
    return isar.creditCards.where().findAll();
  }

  Future<void> saveCreditCard(CreditCard card) async {
    await isar.writeTxn(() async {
      await isar.creditCards.put(card);
    });
    onChanged?.call();
  }

  Future<void> deleteCreditCard(int id) async {
    await isar.writeTxn(() async {
      await isar.creditCards.delete(id);
    });
    onChanged?.call();
  }

  // ----------------- LOANS CRUD -----------------
  Future<List<Loan>> getAllLoans() async {
    return isar.loans.where().findAll();
  }

  Future<int> saveLoan(Loan loan) async {
    final id = await isar.writeTxn(() async {
      return await isar.loans.put(loan);
    });
    onChanged?.call();
    return id;
  }

  Future<void> deleteLoan(int id) async {
    await isar.writeTxn(() async {
      await isar.loans.delete(id);
    });
    onChanged?.call();
  }

  // ----------------- HOLDINGS CRUD -----------------
  Future<List<Holding>> getAllHoldings() async {
    return isar.holdings.where().findAll();
  }

  Future<void> saveHolding(Holding holding) async {
    await isar.writeTxn(() async {
      await isar.holdings.put(holding);
    });
    onChanged?.call();
  }

  Future<void> clearHoldings() async {
    await isar.writeTxn(() async {
      await isar.holdings.clear();
    });
    onChanged?.call();
  }

  // ----------------- BANK ACCOUNTS CRUD -----------------
  Future<List<BankAccount>> getAllBankAccounts() async {
    return isar.bankAccounts.where().findAll();
  }

  Future<void> saveBankAccount(BankAccount account) async {
    await isar.writeTxn(() async {
      await isar.bankAccounts.put(account);
    });
    onChanged?.call();
  }

  Future<void> deleteBankAccount(int id) async {
    await isar.writeTxn(() async {
      await isar.bankAccounts.delete(id);
    });
    onChanged?.call();
  }

  Future<void> clearAllData() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'settings_has_cleared_data', value: 'true');

    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.creditCards.clear();
      await isar.loans.clear();
      await isar.holdings.clear();
      await isar.bankAccounts.clear();
    });
    onChanged?.call();
  }
}
