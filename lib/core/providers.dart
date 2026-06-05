import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database_service.dart';
import 'sync_service.dart';
import '../features/expenses/models/transaction_model.dart';
import '../features/cards_loans/models/card_loan_models.dart';
import '../features/investments/models/holding_model.dart';
import 'package:my_personal_tracker/features/parser/services/sms_sync_service.dart';
import 'package:my_personal_tracker/features/parser/services/email_sync_service.dart';
import '../features/investments/services/portfolio_parser_service.dart';
import '../features/investments/services/investment_sync_service.dart';

part 'providers.g.dart';

// --- TRANSACTIONS NOTIFIER ---
@Riverpod(keepAlive: true)
class Transactions extends _$Transactions {
  @override
  FutureOr<List<Transaction>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getAllTransactionsSync();
  }

  Future<void> loadTransactions() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addTransaction(Transaction transaction) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveTransaction(transaction);
    ref.invalidateSelf();
    await future;
    // Invalidate dependent providers to update Net Worth instantly
    ref.invalidate(creditCardsProvider);
    ref.invalidate(bankAccountsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(holdingsProvider);
  }

  Future<void> removeTransaction(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteTransaction(id);
    ref.invalidateSelf();
    await future;
    // Invalidate dependent providers to update Net Worth instantly
    ref.invalidate(creditCardsProvider);
    ref.invalidate(bankAccountsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(holdingsProvider);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveTransaction(transaction);
    ref.invalidateSelf();
    await future;
    // Invalidate dependent providers to update Net Worth instantly
    ref.invalidate(creditCardsProvider);
    ref.invalidate(bankAccountsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(holdingsProvider);
  }
}

// --- CREDIT CARDS NOTIFIER ---
@Riverpod(keepAlive: true)
class CreditCards extends _$CreditCards {
  @override
  FutureOr<List<CreditCard>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getAllCreditCardsSync();
  }

  Future<void> loadCreditCards() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addCreditCard(CreditCard card) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveCreditCard(card);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeCreditCard(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteCreditCard(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateCreditCard(CreditCard card) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveCreditCard(card);
    ref.invalidateSelf();
    await future;
  }
}

// --- BANK ACCOUNTS NOTIFIER ---
@Riverpod(keepAlive: true)
class BankAccounts extends _$BankAccounts {
  @override
  FutureOr<List<BankAccount>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getAllBankAccountsSync();
  }

  Future<void> loadBankAccounts() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addBankAccount(BankAccount account) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveBankAccount(account);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeBankAccount(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteBankAccount(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateBankAccount(BankAccount account) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveBankAccount(account);
    ref.invalidateSelf();
    await future;
  }
}

// --- LOANS NOTIFIER ---
@Riverpod(keepAlive: true)
class Loans extends _$Loans {
  @override
  FutureOr<List<Loan>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getAllLoansSync();
  }

  Future<void> loadLoans() async {
    ref.invalidateSelf();
    await future;
  }

  Future<int> addLoan(Loan loan) async {
    final dbService = ref.read(databaseServiceProvider);
    final id = await dbService.saveLoan(loan);
    ref.invalidateSelf();
    await future;
    return id;
  }

  Future<void> removeLoan(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteLoan(id);
    ref.invalidateSelf();
    await future;
    ref.invalidate(transactionsProvider);
  }
}

// --- HOLDINGS NOTIFIER ---
@Riverpod(keepAlive: true)
class Holdings extends _$Holdings {
  @override
  FutureOr<List<Holding>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getAllHoldingsSync();
  }

  Future<void> loadHoldings() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addHolding(Holding holding) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveHolding(holding);
    ref.invalidateSelf();
    await future;
  }

  Future<void> clearAllHoldings() async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.clearHoldings();
    ref.invalidateSelf();
    await future;
  }
}

// --- NET WORTH CALCULATIONS ---
@riverpod
double totalHoldingsValue(TotalHoldingsValueRef ref) {
  final holdings = ref.watch(holdingsProvider).valueOrNull ?? [];
  double total = 0.0;
  for (final h in holdings) {
    total += h.currentPrice * h.quantity;
  }
  return total;
}

@riverpod
double totalCardOutstanding(TotalCardOutstandingRef ref) {
  final cards = ref.watch(creditCardsProvider).valueOrNull ?? [];
  double total = 0.0;
  for (final c in cards) {
    total += c.balance;
  }
  return total;
}

@riverpod
double totalDebts(TotalDebtsRef ref) {
  final loans = ref.watch(loansProvider).valueOrNull ?? [];
  double total = 0.0;
  for (final l in loans) {
    if (!l.isLent) {
      total += l.remainingBalance;
    }
  }
  return total;
}

@riverpod
double totalReceivables(TotalReceivablesRef ref) {
  final loans = ref.watch(loansProvider).valueOrNull ?? [];
  double total = 0.0;
  for (final l in loans) {
    if (l.isLent) {
      total += l.remainingBalance;
    }
  }
  return total;
}

@riverpod
double cashAndBank(CashAndBankRef ref) {
  double total = 0.0;
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  for (final tx in txs) {
    // Skip investment-income transactions: they are tracked in Holdings
    // (totalHoldingsValue), not in Cash/Bank. Counting them here causes
    // double-counting in Net Worth when the user categorises a credited SMS
    // as 'Investment' and a Holding is also created.
    if (tx.transactionType == 'income' && tx.category == 'Investment') {
      continue;
    }
    if (tx.cardId == null &&
        (tx.accountName == 'Cash' ||
            tx.accountName == null ||
            (!tx.accountName!.startsWith('bank:') &&
                tx.accountName != 'Credit Card'))) {
      if (tx.transactionType == 'income') {
        total += tx.amount;
      } else if (tx.transactionType == 'expense') {
        total -= tx.amount;
      }
    }
  }
  final bankAccounts = ref.watch(bankAccountsProvider).valueOrNull ?? [];
  for (final acc in bankAccounts) {
    total += acc.balance;
  }
  return total;
}

@riverpod
double netWorth(NetWorthRef ref) {
  final holdings = ref.watch(totalHoldingsValueProvider);
  final cashBank = ref.watch(cashAndBankProvider);
  final receivables = ref.watch(totalReceivablesProvider);
  final cards = ref.watch(totalCardOutstandingProvider);
  final debts = ref.watch(totalDebtsProvider);
  return holdings + cashBank + receivables - cards - debts;
}

// --- AUTOMATION SERVICES PROVIDERS ---
@Riverpod(keepAlive: true)
SmsSyncService smsSyncService(SmsSyncServiceRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return SmsSyncService(db);
}

@Riverpod(keepAlive: true)
EmailSyncService emailSyncService(EmailSyncServiceRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return EmailSyncService(db);
}

@Riverpod(keepAlive: true)
PortfolioParserService portfolioParserService(PortfolioParserServiceRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return PortfolioParserService(db);
}

@Riverpod(keepAlive: true)
InvestmentSyncService investmentSyncService(InvestmentSyncServiceRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return InvestmentSyncService(db);
}

@Riverpod(keepAlive: true)
SyncService syncService(SyncServiceRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return SyncService(db);
}
