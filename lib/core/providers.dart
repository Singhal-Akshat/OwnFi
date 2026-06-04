import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'sync_service.dart';
import '../features/expenses/models/transaction_model.dart';
import '../features/cards_loans/models/card_loan_models.dart';
import '../features/investments/models/holding_model.dart';
import 'package:my_personal_tracker/features/parser/services/sms_sync_service.dart';
import 'package:my_personal_tracker/features/parser/services/email_sync_service.dart';
import '../features/investments/services/portfolio_parser_service.dart';
import '../features/investments/services/investment_sync_service.dart';

// --- TRANSACTIONS NOTIFIER ---
class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final DatabaseService _dbService;
  final Ref _ref;

  TransactionsNotifier(this._dbService, this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final txs = await _dbService.getAllTransactions();
      state = AsyncValue.data(txs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _dbService.saveTransaction(transaction);
      await loadTransactions();
      // Reload dependent providers to update Net Worth instantly
      _ref.read(creditCardsProvider.notifier).loadCreditCards();
      _ref.read(bankAccountsProvider.notifier).loadBankAccounts();
      _ref.read(loansProvider.notifier).loadLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeTransaction(int id) async {
    try {
      await _dbService.deleteTransaction(id);
      await loadTransactions();
      // Reload dependent providers to update Net Worth instantly
      _ref.read(creditCardsProvider.notifier).loadCreditCards();
      _ref.read(bankAccountsProvider.notifier).loadBankAccounts();
      _ref.read(loansProvider.notifier).loadLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TransactionsNotifier(dbService, ref);
});

// --- CREDIT CARDS NOTIFIER ---
class CreditCardsNotifier extends StateNotifier<AsyncValue<List<CreditCard>>> {
  final DatabaseService _dbService;

  CreditCardsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadCreditCards();
  }

  Future<void> loadCreditCards() async {
    state = const AsyncValue.loading();
    try {
      final cards = await _dbService.getAllCreditCards();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCreditCard(CreditCard card) async {
    try {
      await _dbService.saveCreditCard(card);
      await loadCreditCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeCreditCard(int id) async {
    try {
      await _dbService.deleteCreditCard(id);
      await loadCreditCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCreditCard(CreditCard card) async {
    try {
      await _dbService.saveCreditCard(card);
      await loadCreditCards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final creditCardsProvider = StateNotifierProvider<CreditCardsNotifier, AsyncValue<List<CreditCard>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return CreditCardsNotifier(dbService);
});

// --- BANK ACCOUNTS NOTIFIER ---
class BankAccountsNotifier extends StateNotifier<AsyncValue<List<BankAccount>>> {
  final DatabaseService _dbService;

  BankAccountsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadBankAccounts();
  }

  Future<void> loadBankAccounts() async {
    try {
      state = const AsyncValue.loading();
      final accounts = await _dbService.getAllBankAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBankAccount(BankAccount account) async {
    try {
      await _dbService.saveBankAccount(account);
      await loadBankAccounts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeBankAccount(int id) async {
    try {
      await _dbService.deleteBankAccount(id);
      await loadBankAccounts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBankAccount(BankAccount account) async {
    try {
      await _dbService.saveBankAccount(account);
      await loadBankAccounts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bankAccountsProvider = StateNotifierProvider<BankAccountsNotifier, AsyncValue<List<BankAccount>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BankAccountsNotifier(dbService);
});

// --- LOANS NOTIFIER ---
class LoansNotifier extends StateNotifier<AsyncValue<List<Loan>>> {
  final DatabaseService _dbService;

  LoansNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    state = const AsyncValue.loading();
    try {
      final loans = await _dbService.getAllLoans();
      state = AsyncValue.data(loans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLoan(Loan loan) async {
    try {
      await _dbService.saveLoan(loan);
      await loadLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeLoan(int id) async {
    try {
      await _dbService.deleteLoan(id);
      await loadLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final loansProvider = StateNotifierProvider<LoansNotifier, AsyncValue<List<Loan>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return LoansNotifier(dbService);
});

// --- HOLDINGS NOTIFIER ---
class HoldingsNotifier extends StateNotifier<AsyncValue<List<Holding>>> {
  final DatabaseService _dbService;

  HoldingsNotifier(this._dbService) : super(const AsyncValue.loading()) {
    loadHoldings();
  }

  Future<void> loadHoldings() async {
    state = const AsyncValue.loading();
    try {
      final holdings = await _dbService.getAllHoldings();
      state = AsyncValue.data(holdings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHolding(Holding holding) async {
    try {
      await _dbService.saveHolding(holding);
      await loadHoldings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAllHoldings() async {
    try {
      await _dbService.clearHoldings();
      await loadHoldings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final holdingsProvider = StateNotifierProvider<HoldingsNotifier, AsyncValue<List<Holding>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return HoldingsNotifier(dbService);
});

// --- AUTOMATION SERVICES PROVIDERS ---
final smsSyncServiceProvider = Provider<SmsSyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SmsSyncService(db);
});

final emailSyncServiceProvider = Provider<EmailSyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return EmailSyncService(db);
});

final portfolioParserServiceProvider = Provider<PortfolioParserService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return PortfolioParserService(db);
});

final investmentSyncServiceProvider = Provider<InvestmentSyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return InvestmentSyncService(db);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SyncService(db);
});
