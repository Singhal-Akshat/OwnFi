import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'sync_service.dart';
import '../features/expenses/models/transaction_model.dart';
import '../features/expenses/models/budget_model.dart';
import '../features/expenses/models/alert_model.dart';
import '../features/expenses/models/subscription_model.dart';
import '../features/cards_loans/models/card_loan_models.dart';
import '../features/investments/models/holding_model.dart';
import 'package:my_personal_tracker/features/parser/services/sms_sync_service.dart';
import 'package:my_personal_tracker/features/parser/services/email_sync_service.dart';
import '../features/investments/services/portfolio_parser_service.dart';
import '../features/investments/services/investment_sync_service.dart';
import 'sync/google_auth_manager.dart';
import 'sync/drive_backup_service.dart';
import 'sync/gmail_sync_service.dart';
import 'sync/backup_orchestrator.dart';

import '../features/cards_loans/utils/card_timeline_helper.dart';

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

    // Check budget limits for this transaction
    try {
      await _checkBudgets(transaction);
    } catch (e) {
      print('Error checking budgets: $e');
    }

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
    ref.invalidate(alertsProvider);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveTransaction(transaction);
    ref.invalidateSelf();
    await future;

    // Check budget limits for this transaction
    try {
      await _checkBudgets(transaction);
    } catch (e) {
      print('Error checking budgets: $e');
    }

    // Invalidate dependent providers to update Net Worth instantly
    ref.invalidate(creditCardsProvider);
    ref.invalidate(bankAccountsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(holdingsProvider);
  }

  Future<void> _checkBudgets(Transaction transaction) async {
    if (transaction.transactionType != 'expense' || transaction.isDeleted) return;

    final db = ref.read(databaseServiceProvider);
    final yearMonth = transaction.timestamp.year * 100 + transaction.timestamp.month;
    
    final budgets = await db.getMonthlyBudgets(yearMonth);
    if (budgets.isEmpty) return;

    final txs = state.valueOrNull ?? [];
    double categorySpent = 0.0;
    double globalSpent = 0.0;

    for (final tx in txs) {
      if (tx.timestamp.year == transaction.timestamp.year &&
          tx.timestamp.month == transaction.timestamp.month &&
          !tx.isDeleted &&
          tx.transactionType == 'expense') {
        globalSpent += tx.amount;
        if (tx.category == transaction.category) {
          categorySpent += tx.amount;
        }
      }
    }

    Budget? catBudget;
    Budget? globalBudget;
    for (final b in budgets) {
      if (b.category == transaction.category) {
        catBudget = b;
      } else if (b.category == 'All') {
        globalBudget = b;
      }
    }

    if (catBudget != null) {
      final limit = catBudget.amountLimit;
      if (categorySpent >= limit) {
        final alert = InAppAlert()
          ..title = 'Budget Limit Breached'
          ..message = 'You have spent ₹${categorySpent.toStringAsFixed(0)} of your ₹${limit.toStringAsFixed(0)} budget for ${transaction.category}.'
          ..timestamp = DateTime.now();
        await db.saveAlert(alert);
      } else if (categorySpent >= limit * 0.8) {
        final alert = InAppAlert()
          ..title = 'Budget Warning (80%+)'
          ..message = 'You have spent ₹${categorySpent.toStringAsFixed(0)} (80%+) of your ₹${limit.toStringAsFixed(0)} budget for ${transaction.category}.'
          ..timestamp = DateTime.now();
        await db.saveAlert(alert);
      }
    }

    if (globalBudget != null) {
      final limit = globalBudget.amountLimit;
      if (globalSpent >= limit) {
        final alert = InAppAlert()
          ..title = 'Global Limit Breached'
          ..message = 'Your total monthly spending of ₹${globalSpent.toStringAsFixed(0)} exceeds your global limit of ₹${limit.toStringAsFixed(0)}.'
          ..timestamp = DateTime.now();
        await db.saveAlert(alert);
      } else if (globalSpent >= limit * 0.8) {
        final alert = InAppAlert()
          ..title = 'Global Limit Warning (80%+)'
          ..message = 'Your total monthly spending has reached ₹${globalSpent.toStringAsFixed(0)} (80%+) of your ₹${limit.toStringAsFixed(0)} limit.'
          ..timestamp = DateTime.now();
        await db.saveAlert(alert);
      }
    }

    ref.invalidate(alertsProvider);
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

// --- BUDGETS NOTIFIER ---
@Riverpod(keepAlive: true)
class Budgets extends _$Budgets {
  @override
  FutureOr<List<Budget>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    final now = DateTime.now();
    final yearMonth = now.year * 100 + now.month;
    return dbService.getMonthlyBudgets(yearMonth);
  }

  Future<void> loadBudgetsForMonth(int yearMonth) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dbService = ref.read(databaseServiceProvider);
      return dbService.getMonthlyBudgets(yearMonth);
    });
  }

  Future<void> addOrUpdateBudget(Budget budget) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.saveBudget(budget);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeBudget(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteBudget(id);
    ref.invalidateSelf();
    await future;
  }
}

// --- ALERTS NOTIFIER ---
@Riverpod(keepAlive: true)
class Alerts extends _$Alerts {
  @override
  FutureOr<List<InAppAlert>> build() async {
    final db = ref.watch(databaseServiceProvider);
    
    // Check and generate Credit Card alerts dynamically
    final txsAsync = ref.watch(transactionsProvider);
    final cardsAsync = ref.watch(creditCardsProvider);

    if (txsAsync.value != null && cardsAsync.value != null) {
      final txs = txsAsync.value!;
      final cards = cardsAsync.value!;
      final existingAlerts = await db.getUnreadAlerts();
      
      for (final card in cards) {
        final timeline = CardTimelineHelper.calculateTimeline(card, txs);
        if (timeline.status == CardTimelineStatus.dueSoon || timeline.status == CardTimelineStatus.overdue) {
          final alertKey = '${card.id}_${timeline.statementDate.toIso8601String()}';
          final hasAlert = existingAlerts.any((a) => a.message.contains(alertKey));
          
          if (!hasAlert) {
            final alert = InAppAlert()
              ..title = timeline.status == CardTimelineStatus.overdue
                  ? 'Credit Bill Overdue!'
                  : 'Credit Bill Due Soon'
              ..message = timeline.status == CardTimelineStatus.overdue
                  ? 'Your bill of \u{20B9}${timeline.remainingDue.toStringAsFixed(0)} for ${card.cardName} is OVERDUE (ref: $alertKey)'
                  : 'Your bill of \u{20B9}${timeline.remainingDue.toStringAsFixed(0)} for ${card.cardName} is due in ${timeline.daysRemaining} days (ref: $alertKey)'
              ..timestamp = DateTime.now();
            await db.saveAlert(alert);
          }
        }
      }
    }

    return db.getUnreadAlerts();
  }

  Future<void> markAsRead(int id) async {
    final db = ref.read(databaseServiceProvider);
    await db.markAlertAsRead(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadAlerts() async {
    ref.invalidateSelf();
    await future;
  }
}

// --- SUBSCRIPTIONS NOTIFIER ---
@Riverpod(keepAlive: true)
class Subscriptions extends _$Subscriptions {
  @override
  FutureOr<List<Subscription>> build() {
    final dbService = ref.watch(databaseServiceProvider);
    return dbService.getSubscriptions();
  }

  Future<void> addOrUpdateSubscription(Subscription sub) async {
    final dbService = ref.read(databaseServiceProvider);
    sub.nextRenewalDate = sub.calculateNextRenewalDate();
    await dbService.saveSubscription(sub);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeSubscription(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteSubscription(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleSubscriptionActive(int id) async {
    final dbService = ref.read(databaseServiceProvider);
    final subs = state.valueOrNull ?? [];
    for (final s in subs) {
      if (s.id == id) {
        s.isActive = !s.isActive;
        if (s.isActive) {
          s.nextRenewalDate = s.calculateNextRenewalDate();
        } else {
          s.nextRenewalDate = null;
        }
        await dbService.saveSubscription(s);
        break;
      }
    }
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

// --- MONTHLY ANALYTICS PROVIDERS ---
@riverpod
Map<String, double> monthlyCategoryDistribution(
  MonthlyCategoryDistributionRef ref, {
  required DateTime month,
  required String type,
}) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final distribution = <String, double>{};
  for (final tx in txs) {
    if (tx.transactionType == type &&
        tx.timestamp.year == month.year &&
        tx.timestamp.month == month.month) {
      final cat = tx.category.isEmpty ? 'Other' : tx.category;
      distribution[cat] = (distribution[cat] ?? 0.0) + tx.amount;
    }
  }
  return distribution;
}

@riverpod
Map<String, double> monthlyCashFlow(MonthlyCashFlowRef ref, DateTime month) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  double income = 0.0;
  double expense = 0.0;
  for (final tx in txs) {
    if (tx.timestamp.year == month.year && tx.timestamp.month == month.month) {
      if (tx.transactionType == 'income') {
        income += tx.amount;
      } else if (tx.transactionType == 'expense') {
        expense += tx.amount;
      }
    }
  }
  return {
    'income': income,
    'expense': expense,
  };
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

@Riverpod(keepAlive: true)
GoogleAuthManager googleAuthManager(GoogleAuthManagerRef ref) {
  return GoogleAuthManager();
}

@Riverpod(keepAlive: true)
DriveBackupService driveBackupService(DriveBackupServiceRef ref) {
  final auth = ref.watch(googleAuthManagerProvider);
  return DriveBackupService(auth);
}

@Riverpod(keepAlive: true)
GmailSyncService gmailSyncService(GmailSyncServiceRef ref) {
  final auth = ref.watch(googleAuthManagerProvider);
  return GmailSyncService(auth);
}

@Riverpod(keepAlive: true)
BackupOrchestrator backupOrchestrator(BackupOrchestratorRef ref) {
  return BackupOrchestrator();
}

final monthlyBudgetsProvider = FutureProvider.family<List<Budget>, int>((ref, yearMonth) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getMonthlyBudgets(yearMonth);
});

// --- TRANSACTION FILTERS ---
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final transactionTypeFilterProvider = StateProvider<String?>((ref) => null);
final transactionCategoryFilterProvider = StateProvider<String?>((ref) => null);
final transactionAccountFilterProvider = StateProvider<String?>((ref) => null);
final transactionSortProvider = StateProvider<String>((ref) => 'date_desc');
final transactionMonthFilterProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

@riverpod
AsyncValue<List<Transaction>> filteredTransactions(FilteredTransactionsRef ref) {
  final txsState = ref.watch(transactionsProvider);

  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();
  final type = ref.watch(transactionTypeFilterProvider);
  final category = ref.watch(transactionCategoryFilterProvider);
  final accountId = ref.watch(transactionAccountFilterProvider);
  final sort = ref.watch(transactionSortProvider);
  final monthFilter = ref.watch(transactionMonthFilterProvider);

  return txsState.whenData((txs) {
    List<Transaction> result = txs.where((tx) => !tx.isDeleted).toList();

    // Filter by month
    if (monthFilter != null) {
      result = result.where((tx) =>
          tx.timestamp.year == monthFilter.year &&
          tx.timestamp.month == monthFilter.month).toList();
    }

    // Filter by query
    if (query.isNotEmpty) {
      result = result.where((tx) {
        return tx.description.toLowerCase().contains(query) ||
               tx.category.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by type
    if (type != null) {
      result = result.where((tx) => tx.transactionType == type).toList();
    }

    // Filter by category
    if (category != null) {
      result = result.where((tx) => tx.category == category).toList();
    }

    // Filter by card/account
    if (accountId != null) {
      if (accountId.startsWith('bank:')) {
        result = result.where((tx) => tx.accountName == accountId).toList();
      } else {
        result = result.where((tx) => tx.cardId == accountId).toList();
      }
    }

    // Sort
    if (sort == 'date_asc') {
      result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (sort == 'date_desc') {
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (sort == 'amount_asc') {
      result.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (sort == 'amount_desc') {
      result.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return result;
  });
}
