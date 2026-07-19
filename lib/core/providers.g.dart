// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$totalHoldingsValueHash() =>
    r'29aa24189142ee74d026ab11ff5a32fb5cd2cd41';

/// See also [totalHoldingsValue].
@ProviderFor(totalHoldingsValue)
final totalHoldingsValueProvider = AutoDisposeProvider<double>.internal(
  totalHoldingsValue,
  name: r'totalHoldingsValueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalHoldingsValueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalHoldingsValueRef = AutoDisposeProviderRef<double>;
String _$totalCardOutstandingHash() =>
    r'5219f7b4e56129a183d419fe976a457147cb83dc';

/// See also [totalCardOutstanding].
@ProviderFor(totalCardOutstanding)
final totalCardOutstandingProvider = AutoDisposeProvider<double>.internal(
  totalCardOutstanding,
  name: r'totalCardOutstandingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalCardOutstandingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalCardOutstandingRef = AutoDisposeProviderRef<double>;
String _$totalDebtsHash() => r'549aad0b113e1bc0d999d1ce55f56194c0b9427b';

/// See also [totalDebts].
@ProviderFor(totalDebts)
final totalDebtsProvider = AutoDisposeProvider<double>.internal(
  totalDebts,
  name: r'totalDebtsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$totalDebtsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalDebtsRef = AutoDisposeProviderRef<double>;
String _$totalReceivablesHash() => r'f4c4a6579c62e701331620ec1cbb4bc25a637640';

/// See also [totalReceivables].
@ProviderFor(totalReceivables)
final totalReceivablesProvider = AutoDisposeProvider<double>.internal(
  totalReceivables,
  name: r'totalReceivablesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalReceivablesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalReceivablesRef = AutoDisposeProviderRef<double>;
String _$cashAndBankHash() => r'2b68915e04ab890977fc5b928d45ba8d25c90410';

/// See also [cashAndBank].
@ProviderFor(cashAndBank)
final cashAndBankProvider = AutoDisposeProvider<double>.internal(
  cashAndBank,
  name: r'cashAndBankProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cashAndBankHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CashAndBankRef = AutoDisposeProviderRef<double>;
String _$netWorthHash() => r'5a43fb4a77a982db1a48a0ba62a85e3e2f34a9fd';

/// See also [netWorth].
@ProviderFor(netWorth)
final netWorthProvider = AutoDisposeProvider<double>.internal(
  netWorth,
  name: r'netWorthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$netWorthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetWorthRef = AutoDisposeProviderRef<double>;
String _$monthlyCategoryDistributionHash() =>
    r'a960e76e9820c7dbddaf69ec5c61a9d46522ca7d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [monthlyCategoryDistribution].
@ProviderFor(monthlyCategoryDistribution)
const monthlyCategoryDistributionProvider = MonthlyCategoryDistributionFamily();

/// See also [monthlyCategoryDistribution].
class MonthlyCategoryDistributionFamily extends Family<Map<String, double>> {
  /// See also [monthlyCategoryDistribution].
  const MonthlyCategoryDistributionFamily();

  /// See also [monthlyCategoryDistribution].
  MonthlyCategoryDistributionProvider call({
    required DateTime month,
    required String type,
  }) {
    return MonthlyCategoryDistributionProvider(
      month: month,
      type: type,
    );
  }

  @override
  MonthlyCategoryDistributionProvider getProviderOverride(
    covariant MonthlyCategoryDistributionProvider provider,
  ) {
    return call(
      month: provider.month,
      type: provider.type,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyCategoryDistributionProvider';
}

/// See also [monthlyCategoryDistribution].
class MonthlyCategoryDistributionProvider
    extends AutoDisposeProvider<Map<String, double>> {
  /// See also [monthlyCategoryDistribution].
  MonthlyCategoryDistributionProvider({
    required DateTime month,
    required String type,
  }) : this._internal(
          (ref) => monthlyCategoryDistribution(
            ref as MonthlyCategoryDistributionRef,
            month: month,
            type: type,
          ),
          from: monthlyCategoryDistributionProvider,
          name: r'monthlyCategoryDistributionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyCategoryDistributionHash,
          dependencies: MonthlyCategoryDistributionFamily._dependencies,
          allTransitiveDependencies:
              MonthlyCategoryDistributionFamily._allTransitiveDependencies,
          month: month,
          type: type,
        );

  MonthlyCategoryDistributionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
    required this.type,
  }) : super.internal();

  final DateTime month;
  final String type;

  @override
  Override overrideWith(
    Map<String, double> Function(MonthlyCategoryDistributionRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyCategoryDistributionProvider._internal(
        (ref) => create(ref as MonthlyCategoryDistributionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Map<String, double>> createElement() {
    return _MonthlyCategoryDistributionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyCategoryDistributionProvider &&
        other.month == month &&
        other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyCategoryDistributionRef
    on AutoDisposeProviderRef<Map<String, double>> {
  /// The parameter `month` of this provider.
  DateTime get month;

  /// The parameter `type` of this provider.
  String get type;
}

class _MonthlyCategoryDistributionProviderElement
    extends AutoDisposeProviderElement<Map<String, double>>
    with MonthlyCategoryDistributionRef {
  _MonthlyCategoryDistributionProviderElement(super.provider);

  @override
  DateTime get month => (origin as MonthlyCategoryDistributionProvider).month;
  @override
  String get type => (origin as MonthlyCategoryDistributionProvider).type;
}

String _$monthlyCashFlowHash() => r'101158449a0c458ef8dd12c4554234ee7b39a5b8';

/// See also [monthlyCashFlow].
@ProviderFor(monthlyCashFlow)
const monthlyCashFlowProvider = MonthlyCashFlowFamily();

/// See also [monthlyCashFlow].
class MonthlyCashFlowFamily extends Family<Map<String, double>> {
  /// See also [monthlyCashFlow].
  const MonthlyCashFlowFamily();

  /// See also [monthlyCashFlow].
  MonthlyCashFlowProvider call(
    DateTime month,
  ) {
    return MonthlyCashFlowProvider(
      month,
    );
  }

  @override
  MonthlyCashFlowProvider getProviderOverride(
    covariant MonthlyCashFlowProvider provider,
  ) {
    return call(
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyCashFlowProvider';
}

/// See also [monthlyCashFlow].
class MonthlyCashFlowProvider extends AutoDisposeProvider<Map<String, double>> {
  /// See also [monthlyCashFlow].
  MonthlyCashFlowProvider(
    DateTime month,
  ) : this._internal(
          (ref) => monthlyCashFlow(
            ref as MonthlyCashFlowRef,
            month,
          ),
          from: monthlyCashFlowProvider,
          name: r'monthlyCashFlowProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyCashFlowHash,
          dependencies: MonthlyCashFlowFamily._dependencies,
          allTransitiveDependencies:
              MonthlyCashFlowFamily._allTransitiveDependencies,
          month: month,
        );

  MonthlyCashFlowProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    Map<String, double> Function(MonthlyCashFlowRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyCashFlowProvider._internal(
        (ref) => create(ref as MonthlyCashFlowRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Map<String, double>> createElement() {
    return _MonthlyCashFlowProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyCashFlowProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyCashFlowRef on AutoDisposeProviderRef<Map<String, double>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _MonthlyCashFlowProviderElement
    extends AutoDisposeProviderElement<Map<String, double>>
    with MonthlyCashFlowRef {
  _MonthlyCashFlowProviderElement(super.provider);

  @override
  DateTime get month => (origin as MonthlyCashFlowProvider).month;
}

String _$smsSyncServiceHash() => r'90332136b2df49452b1a0caae3b384bd3d0d2b63';

/// See also [smsSyncService].
@ProviderFor(smsSyncService)
final smsSyncServiceProvider = Provider<SmsSyncService>.internal(
  smsSyncService,
  name: r'smsSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smsSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SmsSyncServiceRef = ProviderRef<SmsSyncService>;
String _$emailSyncServiceHash() => r'e85bd695da991ec350fd8adc0f5e32ffd99b24e2';

/// See also [emailSyncService].
@ProviderFor(emailSyncService)
final emailSyncServiceProvider = Provider<EmailSyncService>.internal(
  emailSyncService,
  name: r'emailSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$emailSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EmailSyncServiceRef = ProviderRef<EmailSyncService>;
String _$portfolioParserServiceHash() =>
    r'3abcd4d32ae6d5a89d5c9a8bb1a7a12d79d60145';

/// See also [portfolioParserService].
@ProviderFor(portfolioParserService)
final portfolioParserServiceProvider =
    Provider<PortfolioParserService>.internal(
  portfolioParserService,
  name: r'portfolioParserServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$portfolioParserServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PortfolioParserServiceRef = ProviderRef<PortfolioParserService>;
String _$investmentSyncServiceHash() =>
    r'64505d0cebf888fd000303728ce10b1040507b5e';

/// See also [investmentSyncService].
@ProviderFor(investmentSyncService)
final investmentSyncServiceProvider = Provider<InvestmentSyncService>.internal(
  investmentSyncService,
  name: r'investmentSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$investmentSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef InvestmentSyncServiceRef = ProviderRef<InvestmentSyncService>;
String _$syncServiceHash() => r'a35460784be0d29928c17ebfab552075f6131087';

/// See also [syncService].
@ProviderFor(syncService)
final syncServiceProvider = Provider<SyncService>.internal(
  syncService,
  name: r'syncServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyncServiceRef = ProviderRef<SyncService>;
String _$googleAuthManagerHash() => r'ba99301daec3d7fbfa0e0d8a3206811d1bbf4c71';

/// See also [googleAuthManager].
@ProviderFor(googleAuthManager)
final googleAuthManagerProvider = Provider<GoogleAuthManager>.internal(
  googleAuthManager,
  name: r'googleAuthManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$googleAuthManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GoogleAuthManagerRef = ProviderRef<GoogleAuthManager>;
String _$driveBackupServiceHash() =>
    r'ed5818305a21765ca08da88f86ed4a4c35610ac5';

/// See also [driveBackupService].
@ProviderFor(driveBackupService)
final driveBackupServiceProvider = Provider<DriveBackupService>.internal(
  driveBackupService,
  name: r'driveBackupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driveBackupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DriveBackupServiceRef = ProviderRef<DriveBackupService>;
String _$gmailSyncServiceHash() => r'20d60f893d2ffdfc056fc6ee4e2c0ed8a85eb979';

/// See also [gmailSyncService].
@ProviderFor(gmailSyncService)
final gmailSyncServiceProvider = Provider<GmailSyncService>.internal(
  gmailSyncService,
  name: r'gmailSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gmailSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GmailSyncServiceRef = ProviderRef<GmailSyncService>;
String _$backupOrchestratorHash() =>
    r'b40d04deaf6ffb5f3a565bc3757c0839881fbd41';

/// See also [backupOrchestrator].
@ProviderFor(backupOrchestrator)
final backupOrchestratorProvider = Provider<BackupOrchestrator>.internal(
  backupOrchestrator,
  name: r'backupOrchestratorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupOrchestratorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupOrchestratorRef = ProviderRef<BackupOrchestrator>;
String _$filteredTransactionsHash() =>
    r'8dfe59bf4ba331a599734554a19e362f74c11575';

/// See also [filteredTransactions].
@ProviderFor(filteredTransactions)
final filteredTransactionsProvider =
    AutoDisposeProvider<AsyncValue<List<Transaction>>>.internal(
  filteredTransactions,
  name: r'filteredTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredTransactionsRef
    = AutoDisposeProviderRef<AsyncValue<List<Transaction>>>;
String _$transactionsHash() => r'7c22b4c628bd34d3bf4d198355339f65c16ac7ed';

/// See also [Transactions].
@ProviderFor(Transactions)
final transactionsProvider =
    AsyncNotifierProvider<Transactions, List<Transaction>>.internal(
  Transactions.new,
  name: r'transactionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$transactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Transactions = AsyncNotifier<List<Transaction>>;
String _$creditCardsHash() => r'2bc2d61a2f3fd914c2cd0de02835d22812e1cfcb';

/// See also [CreditCards].
@ProviderFor(CreditCards)
final creditCardsProvider =
    AsyncNotifierProvider<CreditCards, List<CreditCard>>.internal(
  CreditCards.new,
  name: r'creditCardsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$creditCardsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreditCards = AsyncNotifier<List<CreditCard>>;
String _$bankAccountsHash() => r'2d31d99aeb24b3036473383aa595ebc8d07ebaf0';

/// See also [BankAccounts].
@ProviderFor(BankAccounts)
final bankAccountsProvider =
    AsyncNotifierProvider<BankAccounts, List<BankAccount>>.internal(
  BankAccounts.new,
  name: r'bankAccountsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bankAccountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BankAccounts = AsyncNotifier<List<BankAccount>>;
String _$loansHash() => r'ba91bf26667ae2a8f9869420508e5a0346e409f9';

/// See also [Loans].
@ProviderFor(Loans)
final loansProvider = AsyncNotifierProvider<Loans, List<Loan>>.internal(
  Loans.new,
  name: r'loansProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$loansHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Loans = AsyncNotifier<List<Loan>>;
String _$holdingsHash() => r'3750fdef7855b27665e2f92e79a077ee9c3bc96e';

/// See also [Holdings].
@ProviderFor(Holdings)
final holdingsProvider =
    AsyncNotifierProvider<Holdings, List<Holding>>.internal(
  Holdings.new,
  name: r'holdingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$holdingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Holdings = AsyncNotifier<List<Holding>>;
String _$budgetsHash() => r'6a2738abff5fb6d81ef0cf262ce7e74285ec8722';

/// See also [Budgets].
@ProviderFor(Budgets)
final budgetsProvider = AsyncNotifierProvider<Budgets, List<Budget>>.internal(
  Budgets.new,
  name: r'budgetsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$budgetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Budgets = AsyncNotifier<List<Budget>>;
String _$alertsHash() => r'ebcaaa7ef6168a6c8ba3035c0f62421feaa95680';

/// See also [Alerts].
@ProviderFor(Alerts)
final alertsProvider = AsyncNotifierProvider<Alerts, List<InAppAlert>>.internal(
  Alerts.new,
  name: r'alertsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$alertsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Alerts = AsyncNotifier<List<InAppAlert>>;
String _$subscriptionsHash() => r'fc19244d4bdef97b42ca40d5786cff68e6407e37';

/// See also [Subscriptions].
@ProviderFor(Subscriptions)
final subscriptionsProvider =
    AsyncNotifierProvider<Subscriptions, List<Subscription>>.internal(
  Subscriptions.new,
  name: r'subscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Subscriptions = AsyncNotifier<List<Subscription>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
