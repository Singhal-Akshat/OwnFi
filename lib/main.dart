import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'core/theme.dart';
import 'core/database_service.dart';
import 'core/providers.dart';
import 'features/expenses/models/transaction_model.dart';
import 'features/cards_loans/models/card_loan_models.dart';
import 'features/investments/models/holding_model.dart';
import 'package:my_personal_tracker/features/parser/services/sms_parser_service.dart';
import 'package:my_personal_tracker/features/parser/services/sms_sync_service.dart';
import 'features/advisor/services/quant_forecast_service.dart';
import 'features/advisor/services/ai_advisor_service.dart';
import 'features/advisor/providers/advisor_providers.dart';
import 'ui/settings/model_download_page.dart';
import 'ui/chat/model_selector.dart';
import 'services/model_repository.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'core/lock_screen.dart';
import 'core/sync_service.dart';
import 'core/animated_gradient_background.dart';
import 'features/cards_loans/widgets/nfc_scan_radar.dart';
import 'ui/onboarding/model_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:isar/isar.dart';
import 'core/google_sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dbService = DatabaseService();
      await dbService.init();
      final syncService = GoogleSyncService();
      await syncService.backupToCloud(dbService);
      await syncService.syncTransactionsFromGmail(dbService);
    } catch (_) {}
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterGemma.initialize();
  } catch (e) {
    print('Failed to initialize FlutterGemma: $e');
  }

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "nightly-backup-task",
      "nightlyBackupSync",
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresCharging: true,
        requiresDeviceIdle: true,
      ),
    );
  } catch (_) {}

  final dbService = DatabaseService();
  await dbService.init();

  // Perform startup cloud sync pull check
  final syncService = GoogleSyncService();
  try {
    await syncService.syncOnStartup(dbService);
  } catch (e) {
    debugPrint('Cloud sync on startup failed: $e');
  }

  // Hook up automatic backups on database changes
  dbService.onChanged = () {
    syncService.triggerAutoBackup(dbService);
  };

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MypersonalTracker',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const AppStartupLockGate(),
    );
  }
}

class AppStartupLockGate extends ConsumerStatefulWidget {
  const AppStartupLockGate({super.key});

  @override
  ConsumerState<AppStartupLockGate> createState() => _AppStartupLockGateState();
}

class _AppStartupLockGateState extends ConsumerState<AppStartupLockGate> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return const MainNavigationShell();
    }
    return LockScreen(
      onAuthenticated: () {
        setState(() {
          _isUnlocked = true;
        });
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenModelOnboarding') ?? false;
    if (!hasSeen) {
      await prefs.setBool('hasSeenModelOnboarding', true);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ModelOnboardingScreen()));
    }
  }

  final List<Widget> _screens = const [
    DashboardView(),
    CardsLoansView(),
    InvestmentsView(),
    AdvisorView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: View.of(context).viewInsets.bottom > 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: GlassBlur(
                  borderRadius: 24,
                  blurX: 20,
                  blurY: 20,
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavBarItem(Icons.dashboard_rounded, 'Home', 0),
                        _buildNavBarItem(Icons.credit_card_rounded, 'Cards', 1),
                        _buildNavBarItem(Icons.show_chart_rounded, 'Invest', 2),
                        _buildNavBarItem(
                          Icons.psychology_rounded,
                          'AI Advisor',
                          3,
                        ),
                        _buildNavBarItem(Icons.settings_rounded, 'Settings', 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.neonTeal;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 1: HOME DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Bills': return Icons.receipt_long_rounded;
      case 'Entertainment': return Icons.movie_rounded;
      case 'Travel': return Icons.directions_car_rounded;
      case 'Salary': return Icons.wallet_rounded;
      case 'Investment': return Icons.trending_up_rounded;
      case 'Health': return Icons.health_and_safety_rounded;
      case 'Education': return Icons.school_rounded;
      default: return Icons.category_rounded;
    }
  }

  static Color _getCategoryColor(String category, Color defaultColor) {
    switch (category) {
      case 'Food': return Colors.orangeAccent;
      case 'Shopping': return Colors.pinkAccent;
      case 'Bills': return AppColors.neonTeal;
      case 'Entertainment': return AppColors.neonPurple;
      case 'Travel': return Colors.blueAccent;
      case 'Salary': return AppColors.neonEmerald;
      case 'Investment': return Colors.amberAccent;
      case 'Health': return Colors.redAccent;
      case 'Education': return Colors.indigoAccent;
      default: return defaultColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsState = ref.watch(transactionsProvider);
    final cardsState = ref.watch(creditCardsProvider);
    final loansState = ref.watch(loansProvider);
    final holdingsState = ref.watch(holdingsProvider);

    // Dynamic Net Worth Calculation
    double totalHoldingsVal = 0.0;
    holdingsState.whenData((holdings) {
      for (final h in holdings) {
        totalHoldingsVal += h.currentPrice * h.quantity;
      }
    });

    double totalCardOutstanding = 0.0;
    cardsState.whenData((cards) {
      for (final c in cards) {
        totalCardOutstanding += c.balance;
      }
    });

    double totalDebts = 0.0;
    double totalReceivables = 0.0;
    loansState.whenData((loans) {
      for (final l in loans) {
        if (l.isLent) {
          totalReceivables += l.remainingBalance;
        } else {
          totalDebts += l.remainingBalance;
        }
      }
    });

    // Baseline Cash/Bank is ₹3,25,820. We adjust it by manual cash/bank transactions.
    // If the database is completely empty, cashAndBank and netWorth should be exactly 0.
    final bool isEmptyDb =
        (txsState.valueOrNull?.isEmpty ?? true) &&
        (cardsState.valueOrNull?.isEmpty ?? true) &&
        (loansState.valueOrNull?.isEmpty ?? true) &&
        (holdingsState.valueOrNull?.isEmpty ?? true);

    final bankAccountsState = ref.watch(bankAccountsProvider);

    double cashAndBank = 0.0;
    txsState.whenData((txs) {
      for (final tx in txs) {
        // Only adjust dynamic cash balance for manual Cash transactions
        if (tx.cardId == null &&
            (tx.accountName == 'Cash' ||
                tx.accountName == null ||
                (!tx.accountName!.startsWith('bank:') &&
                    tx.accountName != 'Credit Card'))) {
          if (tx.transactionType == 'income') {
            cashAndBank += tx.amount;
          } else if (tx.transactionType == 'expense') {
            cashAndBank -= tx.amount;
          }
        }
      }
    });

    bankAccountsState.whenData((accounts) {
      for (final acc in accounts) {
        cashAndBank += acc.balance;
      }
    });

    final netWorth =
        totalHoldingsVal +
        cashAndBank +
        totalReceivables -
        totalCardOutstanding -
        totalDebts;

    String formatCurrency(double val) {
      final sign = val < 0 ? '-' : '';
      final absVal = val.abs();
      final str = absVal.toStringAsFixed(0);
      String result = str;
      if (str.length > 3) {
        // Group last 3 digits, then groups of 2 for Indian Lakhs/Crores grouping
        final last3 = str.substring(str.length - 3);
        final rest = str.substring(0, str.length - 3);
        final restGrouped = rest.replaceAllMapped(
          RegExp(r'(\d+?)(?=(\d{2})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        result = '$restGrouped,$last3';
      }
      return '$sign₹$result';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Akshat',
                      style: Theme.of(context).textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassBlur(
                    borderRadius: 14,
                    child: IconButton(
                      icon: const Icon(
                        Icons.sync_rounded,
                        color: AppColors.neonTeal,
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checking cloud backup status...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        try {
                          final restored = await ref
                              .read(googleSyncServiceProvider)
                              .syncOnStartup(ref.read(databaseServiceProvider));
                          if (restored) {
                            ref
                                .read(transactionsProvider.notifier)
                                .loadTransactions();
                            ref
                                .read(creditCardsProvider.notifier)
                                .loadCreditCards();
                            ref
                                .read(bankAccountsProvider.notifier)
                                .loadBankAccounts();
                            ref.read(loansProvider.notifier).loadLoans();
                            ref.read(holdingsProvider.notifier).loadHoldings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sync completed. Newer data restored from Google Drive.',
                                ),
                                backgroundColor: AppColors.neonEmerald,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your database is already in sync with Google Drive.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync failed: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassBlur(
                    borderRadius: 14,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.neonTeal),
                      onPressed: () {
                        _showAddExpenseDialog(context, ref);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Balance Cards Slider
          SizedBox(
            height: 185,
            child: bankAccountsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (accounts) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildNetWorthCard(
                      context,
                      netWorth,
                      totalHoldingsVal,
                      cashAndBank,
                      totalCardOutstanding + totalDebts,
                      totalReceivables,
                      formatCurrency,
                    ),

                    // Card 2+: Bank Accounts
                    ...accounts.map((account) {
                      return _buildBankAccountCard(
                        context,
                        ref,
                        account,
                        formatCurrency,
                      );
                    }),

                    // Card Last: Add Bank Account Button Card
                    _buildAddBankAccountCardButton(context, ref),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 25),

          // Title
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Transactions List
          Expanded(
            child: txsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions yet. Click + to add one!',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    Color iconColor = AppColors.neonTeal;
                    if (tx.transactionType == 'income') {
                      iconColor = AppColors.neonEmerald;
                    } else if (tx.transactionType == 'transfer') {
                      iconColor = AppColors.neonPink;
                    } else if (tx.category == 'Entertainment') {
                      iconColor = AppColors.neonPurple;
                    }

                    final formattedAmt =
                        '${tx.transactionType == 'income' ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';
                    final dateStr =
                        '${tx.timestamp.day} ${_getMonthName(tx.timestamp.month)}';

                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(transactionsProvider.notifier)
                            .removeTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${tx.description} deleted'),
                            backgroundColor: AppColors.obsidianSurface,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassBlur(
                          borderRadius: 16,
                          child: ListTile(
                            onTap: () => _showAddExpenseDialog(
                              context,
                              ref,
                              existingTransaction: tx,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(tx.category, iconColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getCategoryIcon(tx.category),
                                    color: _getCategoryColor(tx.category, iconColor),
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  () {
                                    Widget accountIcon = Icon(
                                      tx.cardId != null
                                          ? Icons.credit_card_rounded
                                          : (tx.accountName != null &&
                                                  (tx.accountName!.startsWith('bank:') ||
                                                      tx.accountName == 'Bank')
                                              ? Icons.account_balance_rounded
                                              : Icons.wallet_rounded),
                                      color: tx.cardId != null
                                          ? Colors.white70
                                          : (tx.accountName != null &&
                                                  (tx.accountName!.startsWith('bank:') ||
                                                      tx.accountName == 'Bank')
                                              ? Colors.white70
                                              : AppColors.neonEmerald),
                                      size: 16,
                                    );
                                    if (tx.cardId != null) {
                                      final cardId = int.tryParse(tx.cardId!);
                                      final card = cardsState.valueOrNull?.firstWhere(
                                        (c) => c.id == cardId,
                                        orElse: () => CreditCard(),
                                      );
                                      if (card != null && card.imageUrl.isNotEmpty) {
                                        accountIcon = ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: SizedBox(
                                            width: 20,
                                            height: 14,
                                            child: card.imageUrl
                                                    .toLowerCase()
                                                    .endsWith('.svg')
                                                ? SvgPicture.asset(
                                                    'assets/credit_card_images/${card.imageUrl}',
                                                    fit: BoxFit.fill,
                                                  )
                                                : Image.asset(
                                                    'assets/credit_card_images/${card.imageUrl}',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        );
                                      } else {
                                        accountIcon = Container(
                                          width: 20,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Icon(
                                            Icons.credit_card_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        );
                                      }
                                    } else if (tx.accountName != null &&
                                        tx.accountName!.startsWith('bank:')) {
                                      final bankId = int.tryParse(
                                        tx.accountName!.substring(5),
                                      );
                                      final bank = bankAccountsState.valueOrNull?.firstWhere(
                                        (b) => b.id == bankId,
                                        orElse: () => BankAccount(),
                                      );
                                      if (bank != null && bank.logoAsset.isNotEmpty) {
                                        accountIcon = SvgPicture.asset(
                                          'assets/bank_logos/${bank.logoAsset}',
                                          width: 18,
                                          height: 18,
                                        );
                                      } else {
                                        accountIcon = const Icon(
                                          Icons.account_balance_rounded,
                                          color: Colors.white70,
                                          size: 18,
                                        );
                                      }
                                    }
                                    return accountIcon;
                                  }(),
                                ],
                              ),
                            ),
                            title: Text(
                              tx.description,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: () {
                              String accountDisplayName = 'Cash';
                              if (tx.cardId != null) {
                                accountDisplayName = 'Credit Card';
                              } else if (tx.accountName != null) {
                                if (tx.accountName!.startsWith('bank:')) {
                                  final bankId = int.tryParse(
                                    tx.accountName!.substring(5),
                                  );
                                  final bank = bankAccountsState.valueOrNull
                                      ?.firstWhere(
                                        (b) => b.id == bankId,
                                        orElse: () => BankAccount(),
                                      );
                                  accountDisplayName =
                                      bank != null && bank.bankName.isNotEmpty
                                      ? bank.bankName
                                      : 'Bank';
                                } else {
                                  accountDisplayName = tx.accountName!;
                                }
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tx.category} • $accountDisplayName • $dateStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (tx.source != 'manual' || tx.parserSource != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          if (tx.source == 'sms') const Text('📱 SMS', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          if (tx.source == 'email') const Text('📧 Email', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          if (tx.source != 'manual' && tx.parserSource != null) const Text(' • ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          if (tx.parserSource != null)
                                            Text(
                                              tx.parserSource == 'gemini' ? '✨ Gemini' : (tx.parserSource == 'gemma' ? '🧠 Gemma' : '⚙️ Regex'),
                                              style: TextStyle(
                                                fontSize: 10, 
                                                color: tx.parserSource == 'gemini' ? AppColors.neonPurple : (tx.parserSource == 'gemma' ? AppColors.neonTeal : AppColors.textMuted),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }(),
                            trailing: Text(
                              formattedAmt,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tx.transactionType == 'income'
                                    ? AppColors.neonEmerald
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildAssetMini(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard(
    BuildContext context,
    double netWorth,
    double totalHoldingsVal,
    double cashAndBank,
    double liabilities,
    double receivables,
    String Function(double) formatCurrency,
  ) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16),
      child: GlassBlur(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NET WORTH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrency(netWorth),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildAssetMini(
                      'Investments',
                      formatCurrency(totalHoldingsVal),
                      AppColors.neonEmerald,
                    ),
                  ),
                  Expanded(
                    child: _buildAssetMini(
                      'Cash/Bank',
                      formatCurrency(cashAndBank),
                      AppColors.neonTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildAssetMini(
                      'Liabilities',
                      formatCurrency(-liabilities),
                      Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildAssetMini(
                      'Receivables',
                      formatCurrency(receivables),
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(
    BuildContext context,
    WidgetRef ref,
    BankAccount account,
    String Function(double) formatCurrency,
  ) {
    return BankAccountCard(
      account: account,
      ref: ref,
      formatCurrency: formatCurrency,
      onOptionsPressed: _showBankAccountOptions,
    );
  }

  Widget _buildAddBankAccountCardButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showAddBankAccountDialog(context, ref),
        child: GlassBlur(
          borderRadius: 20,
          cardColor: Colors.white.withOpacity(0.02),
          borderColor: Colors.white.withOpacity(0.08),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_card_rounded,
                  color: AppColors.neonTeal,
                  size: 28,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Bank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBankAccountDetailsBottomSheet(
    BuildContext context,
    BankAccount account,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassBlur(
          borderRadius: 24,
          blurX: 30,
          blurY: 30,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.neonTeal,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Account Holder', account.accountHolderName),
                const SizedBox(height: 12),
                _buildDetailRow('Account Number', account.fullAccountNumber),
                const SizedBox(height: 12),
                _buildDetailRow('IFSC Code', account.ifscCode),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Balance',
                  '₹${account.balance.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showBankAccountOptions(
    BuildContext context,
    WidgetRef ref,
    BankAccount account,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassBlur(
          borderRadius: 24,
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.white),
                  title: const Text(
                    'Edit Account',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddBankAccountDialog(
                      context,
                      ref,
                      existingAccount: account,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.obsidianSurface,
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Are you sure you want to delete ${account.bankName} account?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(bankAccountsProvider.notifier)
                                  .removeBankAccount(account.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account deleted'),
                                  backgroundColor: AppColors.obsidianSurface,
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBankAccountDialog(
    BuildContext context,
    WidgetRef ref, {
    BankAccount? existingAccount,
  }) {
    final nameController = TextEditingController(
      text: existingAccount?.bankName ?? '',
    );
    final holderController = TextEditingController(
      text: existingAccount?.accountHolderName ?? 'Akshat',
    );
    final fullNumberController = TextEditingController(
      text: existingAccount?.fullAccountNumber ?? '',
    );
    final last4Controller = TextEditingController(
      text: existingAccount?.last4 ?? '',
    );
    final ifscController = TextEditingController(
      text: existingAccount?.ifscCode ?? '',
    );
    final balanceController = TextEditingController(
      text: existingAccount?.balance.toStringAsFixed(0) ?? '0',
    );

    String selectedLogo = existingAccount?.logoAsset ?? '';
    String selectedCardColor = existingAccount?.colorHex ?? '#0D47A1';

    final logoOptions = {
      '': 'None',
      'HDB.svg': 'HDFC Bank',
      'SBI-logo.svg': 'State Bank of India',
    };

    final colorOptions = {
      '#0D47A1': 'HDFC Blue',
      '#0084B4': 'SBI Sky Blue',
      '#FF9933': 'ICICI Orange',
      '#900A36': 'Axis Maroon',
      '#006064': 'Teal Slate',
      '#263238': 'Carbon Obsidian',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingAccount == null
                              ? 'Register Bank Account'
                              : 'Edit Bank Account',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Bank Name (e.g. HDFC Bank)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final lower = val.toLowerCase();
                            if (lower.contains('hdfc')) {
                              setState(() {
                                selectedLogo = 'HDB.svg';
                                selectedCardColor = '#0D47A1';
                              });
                            } else if (lower.contains('sbi') ||
                                lower.contains('state bank')) {
                              setState(() {
                                selectedLogo = 'SBI-logo.svg';
                                selectedCardColor = '#0084B4';
                              });
                            } else if (lower.contains('icici')) {
                              setState(() {
                                selectedCardColor = '#FF9933';
                              });
                            } else if (lower.contains('axis')) {
                              setState(() {
                                selectedCardColor = '#900A36';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: holderController,
                          decoration: const InputDecoration(
                            labelText: 'Account Holder Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: fullNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Account Number',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.length >= 4) {
                                    last4Controller.text = val.substring(
                                      val.length - 4,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: last4Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Last 4',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: ifscController,
                          decoration: const InputDecoration(
                            labelText: 'IFSC Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: balanceController,
                          decoration: const InputDecoration(
                            labelText: 'Current Balance',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedLogo,
                          decoration: const InputDecoration(
                            labelText: 'Bank Logo',
                            border: OutlineInputBorder(),
                          ),
                          items: logoOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedLogo = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCardColor,
                          decoration: const InputDecoration(
                            labelText: 'Card Color Accent',
                            border: OutlineInputBorder(),
                          ),
                          items: colorOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCardColor = val!),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final bank = nameController.text.trim();
                                final holder = holderController.text.trim();
                                final fullNum = fullNumberController.text
                                    .trim();
                                final l4 = last4Controller.text.trim();
                                final ifsc = ifscController.text.trim();
                                final bal =
                                    double.tryParse(balanceController.text) ??
                                    0.0;

                                if (bank.isEmpty || l4.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          AppColors.obsidianSurface,
                                      title: const Text(
                                        'Invalid Input',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'Please fill Bank Name and Account Number.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(
                                              color: AppColors.neonTeal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final account =
                                    existingAccount ?? BankAccount();
                                account
                                  ..bankName = bank
                                  ..accountHolderName = holder
                                  ..fullAccountNumber = fullNum
                                  ..last4 = l4
                                  ..ifscCode = ifsc
                                  ..balance = bal
                                  ..logoAsset = selectedLogo
                                  ..colorHex = selectedCardColor;

                                if (existingAccount == null) {
                                  ref
                                      .read(bankAccountsProvider.notifier)
                                      .addBankAccount(account);
                                } else {
                                  ref
                                      .read(bankAccountsProvider.notifier)
                                      .updateBankAccount(account);
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingAccount == null
                                    ? 'Add Account'
                                    : 'Save Changes',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog(
    BuildContext context,
    WidgetRef ref, {
    Transaction? existingTransaction,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    final expenseCats = prefs.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Investment', 'Health', 'Education', 'Other'];
    final incomeCats = prefs.getStringList('categories_income') ?? ['Salary', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other'];
    final transferCats = prefs.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Other'];

    final amountController = TextEditingController(
      text: existingTransaction != null
          ? existingTransaction.amount.toStringAsFixed(0)
          : '',
    );
    final descController = TextEditingController(
      text: existingTransaction?.description ?? '',
    );

    // Dynamic Category metadata mapping for fallback icons/colors
    final Map<String, Map<String, dynamic>> categoryMetadata = {
      'Food': {'icon': Icons.fastfood_rounded, 'color': Colors.orangeAccent},
      'Shopping': {
        'icon': Icons.shopping_bag_rounded,
        'color': Colors.pinkAccent,
      },
      'Bills': {
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.neonTeal,
      },
      'Entertainment': {
        'icon': Icons.movie_rounded,
        'color': AppColors.neonPurple,
      },
      'Travel': {
        'icon': Icons.directions_car_rounded,
        'color': Colors.blueAccent,
      },
      'Salary': {'icon': Icons.wallet_rounded, 'color': AppColors.neonEmerald},
      'Investment': {
        'icon': Icons.trending_up_rounded,
        'color': Colors.amberAccent,
      },
      'Health': {
        'icon': Icons.health_and_safety_rounded,
        'color': Colors.redAccent,
      },
      'Education': {'icon': Icons.school_rounded, 'color': Colors.indigoAccent},
      'Others': {
        'icon': Icons.more_horiz_rounded,
        'color': AppColors.textSecondary,
      },
      'Other': {
        'icon': Icons.more_horiz_rounded,
        'color': AppColors.textSecondary,
      },
    };

    String selectedCategory = existingTransaction?.category ?? 'Other';
    String selectedType = existingTransaction?.transactionType ?? 'expense';
    String selectedAccountType = 'Cash'; // Cash, bank:ID, card:ID
    int? selectedCardId;
    if (existingTransaction != null) {
      if (existingTransaction.cardId != null) {
        selectedCardId = int.tryParse(existingTransaction.cardId!);
        selectedAccountType = 'card:${existingTransaction.cardId}';
      } else {
        selectedAccountType = existingTransaction.accountName ?? 'Cash';
      }
    }

    // Payback & repayment state
    bool isPayback = false;
    final paybackContactController = TextEditingController();
    DateTime paybackDate = DateTime.now().add(const Duration(days: 30));
    int? selectedDebtId;
    int? selectedLinkedLoanId = existingTransaction?.linkedLoanId;

    if (existingTransaction != null && existingTransaction.linkedLoanId != null) {
      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
      try {
        final linkedLoan = allLoans.firstWhere((l) => l.id == existingTransaction.linkedLoanId);
        if (existingTransaction.transactionType == 'income' && !linkedLoan.isLent) {
          isPayback = true;
          paybackContactController.text = linkedLoan.contactName;
          paybackDate = linkedLoan.paybackDate ?? DateTime.now().add(const Duration(days: 30));
        } else if (existingTransaction.transactionType == 'expense' || existingTransaction.transactionType == 'transfer') {
          selectedDebtId = linkedLoan.id;
        }
      } catch (_) {}
    }

    // To Account for transfer type
    String selectedToAccountType = 'Cash';
    if (existingTransaction != null && existingTransaction.transactionType == 'transfer') {
      if (existingTransaction.cardId != null) {
        if (existingTransaction.cardId!.startsWith('bank:')) {
          selectedToAccountType = existingTransaction.cardId!;
        } else {
          selectedToAccountType = 'card:${existingTransaction.cardId}';
        }
      } else {
        selectedToAccountType = 'Cash';
      }
    }

    bool isSplit = existingTransaction?.isSplit ?? false;

    // Split Details controllers
    final splitFriendController = TextEditingController(
      text:
          (existingTransaction != null &&
              existingTransaction.isSplit &&
              existingTransaction.splitDetails.isNotEmpty)
          ? existingTransaction.splitDetails.first.friendName ?? ''
          : '',
    );
    final splitAmountController = TextEditingController(
      text:
          (existingTransaction != null &&
              existingTransaction.isSplit &&
              existingTransaction.splitDetails.isNotEmpty)
          ? existingTransaction.splitDetails.first.amount.toStringAsFixed(0)
          : '',
    );
    DateTime selectedDateTime =
        existingTransaction?.timestamp ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                final cardsState = ref.watch(creditCardsProvider);
                final bankAccountsState = ref.watch(bankAccountsProvider);
                final loansState = ref.watch(loansProvider);

                final currentCats = selectedType == 'expense'
                    ? expenseCats
                    : (selectedType == 'income' ? incomeCats : transferCats);

                if (!currentCats.contains(selectedCategory)) {
                  if (currentCats.contains('Other')) {
                    selectedCategory = 'Other';
                  } else if (currentCats.isNotEmpty) {
                    selectedCategory = currentCats.first;
                  } else {
                    selectedCategory = '';
                  }
                }

                List<DropdownMenuItem<String>> buildDropdownItems(String valueToVerify) {
                  final List<DropdownMenuItem<String>> menu = [
                    DropdownMenuItem(
                      value: 'Cash',
                      child: Row(
                        children: [
                          const Icon(Icons.wallet_rounded, color: AppColors.neonEmerald, size: 18),
                          const SizedBox(width: 8),
                          const Text('Cash'),
                        ],
                      ),
                    ),
                  ];

                  bankAccountsState.maybeWhen(
                    data: (accounts) {
                      menu.addAll(accounts.map((acc) {
                        Widget logoWidget = const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 18);
                        if (acc.logoAsset.isNotEmpty) {
                          logoWidget = SvgPicture.asset('assets/bank_logos/${acc.logoAsset}', width: 18, height: 18);
                        }
                        return DropdownMenuItem(
                          value: 'bank:${acc.id}',
                          child: Row(
                            children: [
                              logoWidget,
                              const SizedBox(width: 8),
                              Expanded(child: Text('${acc.bankName} (..${acc.last4})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                          ),
                        );
                      }));
                    },
                    orElse: () {},
                  );

                  cardsState.maybeWhen(
                    data: (cards) {
                      menu.addAll(cards.map((card) {
                        Widget cardVisual = Container(width: 20, height: 14, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(3)));
                        if (card.imageUrl.isNotEmpty) {
                          cardVisual = ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              width: 20,
                              height: 14,
                              child: card.imageUrl.toLowerCase().endsWith('.svg')
                                  ? SvgPicture.asset('assets/credit_card_images/${card.imageUrl}', fit: BoxFit.fill)
                                  : Image.asset('assets/credit_card_images/${card.imageUrl}', fit: BoxFit.cover),
                            ),
                          );
                        }
                        return DropdownMenuItem(
                          value: 'card:${card.id}',
                          child: Row(
                            children: [
                              cardVisual,
                              const SizedBox(width: 8),
                              Expanded(child: Text('${card.cardName} (..${card.last4})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                          ),
                        );
                      }));
                    },
                    orElse: () {},
                  );

                  final hasSel = menu.any((item) => item.value == valueToVerify);
                  if (!hasSel) {
                    menu.add(
                      DropdownMenuItem(
                        value: valueToVerify,
                        child: Text(
                          valueToVerify.startsWith('bank:')
                              ? 'Deleted Bank Account'
                              : valueToVerify.startsWith('card:')
                                  ? 'Deleted Card'
                                  : valueToVerify,
                        ),
                      ),
                    );
                  }
                  return menu;
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassBlur(
                    borderRadius: 24,
                    blurX: 30,
                    blurY: 30,
                    child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingTransaction != null
                              ? 'Edit Transaction'
                              : 'Manual Transaction Entry',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // Transaction Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.obsidianSurface,
                          items: const [
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text('Expense'),
                            ),
                            DropdownMenuItem(
                              value: 'income',
                              child: Text('Income'),
                            ),
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Text('Transfer'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedType = val;
                                final newCats = val == 'expense'
                                    ? expenseCats
                                    : (val == 'income' ? incomeCats : transferCats);
                                if (!newCats.contains(selectedCategory)) {
                                  if (newCats.contains('Other')) {
                                    selectedCategory = 'Other';
                                  } else if (newCats.isNotEmpty) {
                                    selectedCategory = newCats.first;
                                  } else {
                                    selectedCategory = '';
                                  }
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Amount
                        TextField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (INR)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g. Croma Store',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Dropdown with Rich Icons
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.obsidianSurface,
                          items: currentCats.map((cat) {
                            final meta =
                                categoryMetadata[cat] ??
                                {
                                  'icon': Icons.category_rounded,
                                  'color': AppColors.textSecondary,
                                };
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: (meta['color'] as Color)
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      meta['icon'] as IconData,
                                      color: meta['color'] as Color,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(cat),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Account Selection (Dual for Transfer, Single for other types)
                        if (selectedType == 'transfer') ...[
                          DropdownButtonFormField<String>(
                            value: selectedAccountType,
                            decoration: const InputDecoration(
                              labelText: 'From Account (Source)',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedAccountType),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedAccountType = val;
                                  if (val.startsWith('card:')) {
                                    selectedCardId = int.tryParse(val.substring(5));
                                  } else {
                                    selectedCardId = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedToAccountType,
                            decoration: const InputDecoration(
                              labelText: 'To Account (Destination)',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedToAccountType),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedToAccountType = val;
                                });
                              }
                            },
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: selectedAccountType,
                            decoration: const InputDecoration(
                              labelText: 'Account / Card',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedAccountType),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedAccountType = val;
                                  if (val.startsWith('card:')) {
                                    selectedCardId = int.tryParse(val.substring(5));
                                  } else {
                                    selectedCardId = null;
                                  }
                                });
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Payback Toggle for Income
                        if (selectedType == 'income') ...[
                          CheckboxListTile(
                            title: const Text('Is this a borrowed loan to payback?'),
                            subtitle: const Text('Creates a debt entry in the ledger'),
                            value: isPayback,
                            activeColor: AppColors.neonEmerald,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  isPayback = val;
                                  if (val && paybackContactController.text.isEmpty) {
                                    paybackContactController.text = descController.text.trim();
                                  }
                                });
                              }
                            },
                          ),
                          if (isPayback) ...[
                            const SizedBox(height: 8),
                            Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final borrowedContacts = loansState.maybeWhen(
                                  data: (allLoans) => allLoans
                                      .where((l) => !l.isLent && l.remainingBalance > 0)
                                      .map((l) => l.contactName)
                                      .toSet()
                                      .toList(),
                                  orElse: () => <String>[],
                                );
                                if (textEditingValue.text.isEmpty) {
                                  return borrowedContacts;
                                }
                                return borrowedContacts.where((String option) {
                                  return option
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (String selection) {
                                paybackContactController.text = selection;
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                if (textEditingController.text != paybackContactController.text) {
                                  textEditingController.text = paybackContactController.text;
                                }
                                textEditingController.addListener(() {
                                  paybackContactController.text = textEditingController.text;
                                });
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact / Friend Name',
                                    border: OutlineInputBorder(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payback Date', style: TextStyle(color: Colors.white70)),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: paybackDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.neonEmerald,
                                              onPrimary: Colors.black,
                                              surface: AppColors.obsidianSurface,
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() => paybackDate = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today_rounded, color: AppColors.neonEmerald, size: 16),
                                  label: Text(
                                    '${paybackDate.day}/${paybackDate.month}/${paybackDate.year}',
                                    style: const TextStyle(color: AppColors.neonEmerald, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        // Repay Debt Selector for Expense / Transfer
                        if (selectedType == 'expense' || selectedType == 'transfer') ...[
                          loansState.maybeWhen(
                            data: (allLoans) {
                              final borrowedDebts = allLoans.where((l) => !l.isLent && l.remainingBalance > 0).toList();
                              if (borrowedDebts.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<int?>(
                                    value: selectedDebtId,
                                    decoration: const InputDecoration(
                                      labelText: 'Link to repay active debt?',
                                      border: OutlineInputBorder(),
                                    ),
                                    dropdownColor: AppColors.obsidianSurface,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Do not link to a debt'),
                                      ),
                                      ...borrowedDebts.map((loan) => DropdownMenuItem<int?>(
                                        value: loan.id,
                                        child: Text('${loan.contactName} (Remaining: ₹${loan.remainingBalance.toStringAsFixed(0)})'),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => selectedDebtId = val);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],

                        // Link to any Loan (all loans dropdown)
                        // Only shown when not using isPayback or debt repayment (those auto-link)
                        if (!isPayback && selectedDebtId == null)
                        loansState.maybeWhen(
                          data: (allLoans) {
                            final activeLoansList = allLoans.where((l) => l.remainingBalance > 0).toList();
                            if (activeLoansList.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<int?>(
                                  value: selectedLinkedLoanId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Link to Loan / Debt',
                                    hintText: 'Optionally associate with a loan',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.link_rounded,
                                      color: selectedLinkedLoanId != null
                                          ? AppColors.neonPurple
                                          : AppColors.textMuted,
                                      size: 18,
                                    ),
                                  ),
                                  dropdownColor: AppColors.obsidianSurface,
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('No linked loan'),
                                    ),
                                    ...activeLoansList.map((loan) => DropdownMenuItem<int?>(
                                      value: loan.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            loan.isLent
                                                ? Icons.call_made_rounded
                                                : Icons.call_received_rounded,
                                            color: loan.isLent
                                                ? AppColors.neonEmerald
                                                : Colors.redAccent,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '${loan.contactName} (₹${loan.remainingBalance.toStringAsFixed(0)})',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                  onChanged: (val) {
                                    setState(() => selectedLinkedLoanId = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),

                        // Date & Time Picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final datePicked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDateTime,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: AppColors.neonTeal,
                                          onPrimary: Colors.black,
                                          surface: AppColors.obsidianSurface,
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (datePicked != null) {
                                  final timePicked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      selectedDateTime,
                                    ),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppColors.neonTeal,
                                            onPrimary: Colors.black,
                                            surface: AppColors.obsidianSurface,
                                            onSurface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (timePicked != null) {
                                    setState(() {
                                      selectedDateTime = DateTime(
                                        datePicked.year,
                                        datePicked.month,
                                        datePicked.day,
                                        timePicked.hour,
                                        timePicked.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.neonTeal,
                                size: 16,
                              ),
                              label: Text(
                                '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}  ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.neonTeal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Split Toggle
                        CheckboxListTile(
                          title: const Text(
                            'Split Expense?',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Split bills with friends/contacts',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: isSplit,
                          activeColor: AppColors.neonTeal,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            if (val != null) setState(() => isSplit = val);
                          },
                        ),

                        if (isSplit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: splitFriendController,
                                  decoration: const InputDecoration(
                                    labelText: 'Friend Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: splitAmountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Owed Amount',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (existingTransaction?.aiComparisonNotes != null &&
                            existingTransaction!.aiComparisonNotes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neonPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.science_rounded, size: 16, color: AppColors.neonPurple),
                                    SizedBox(width: 8),
                                    Text('AI Parser Comparison', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  existingTransaction!.aiComparisonNotes!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (existingTransaction?.rawMessage != null &&
                            existingTransaction!.rawMessage!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neonTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonTeal.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(existingTransaction!.source == 'email' ? Icons.email_rounded : Icons.sms_rounded, size: 16, color: AppColors.neonTeal),
                                    const SizedBox(width: 8),
                                    Text(existingTransaction!.source == 'email' ? 'Original Email' : 'Original SMS', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonTeal)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  existingTransaction!.rawMessage!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                final amount =
                                    double.tryParse(amountController.text) ??
                                    0.0;
                                final desc = descController.text.trim();
                                final category = selectedCategory;

                                if (amount <= 0 ||
                                    desc.isEmpty ||
                                    category.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill all required fields',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final tx = existingTransaction ?? Transaction();
                                tx.amount = amount;
                                tx.description = desc;
                                tx.category = category;
                                tx.timestamp = selectedDateTime;
                                if (existingTransaction == null) {
                                  tx.source = 'manual';
                                }
                                tx.transactionType = selectedType;

                                if (selectedType == 'transfer') {
                                  tx.accountName = selectedAccountType;
                                  if (selectedToAccountType.startsWith('card:')) {
                                    tx.cardId = selectedToAccountType.substring(5);
                                  } else if (selectedToAccountType.startsWith('bank:')) {
                                    tx.cardId = selectedToAccountType;
                                  } else {
                                    tx.cardId = null;
                                  }
                                } else {
                                  if (selectedCardId != null) {
                                    tx.cardId = selectedCardId.toString();
                                    tx.accountName = 'Credit Card';
                                  } else {
                                    tx.cardId = null;
                                    tx.accountName = selectedAccountType;
                                  }
                                }

                                if (isSplit) {
                                  tx.isSplit = true;
                                  final splitAmt =
                                      double.tryParse(
                                        splitAmountController.text,
                                      ) ??
                                      0.0;
                                  final friend = splitFriendController.text
                                      .trim();
                                  if (splitAmt > 0 && friend.isNotEmpty) {
                                    tx.splitDetails = [
                                      TransactionSplitDetail()
                                        ..amount = splitAmt
                                        ..category = category
                                        ..friendName = friend
                                        ..description =
                                            'Owed from split: $desc',
                                    ];

                                    // Add to borrowed/lent loans ledger!
                                    if (existingTransaction == null ||
                                        !existingTransaction.isSplit) {
                                      final loan = Loan()
                                        ..contactName = friend
                                        ..isLent =
                                            true // they owe us money, so it is lent
                                        ..amount = splitAmt
                                        ..remainingBalance = splitAmt
                                        ..startDate = DateTime.now()
                                        ..interestRate = 0.0
                                        ..compoundInterval = 'none'
                                        ..emiAmount = 0.0;
                                      ref
                                          .read(loansProvider.notifier)
                                          .addLoan(loan);
                                    }
                                  }
                                } else {
                                  tx.isSplit = false;
                                  tx.splitDetails = [];

                                  if (selectedType == 'income' && isPayback) {
                                    final contact = paybackContactController.text.trim();
                                    if (contact.isNotEmpty) {
                                      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                      try {
                                        final existing = allLoans.firstWhere(
                                          (l) => !l.isLent && l.remainingBalance > 0 && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                        );
                                        existing.amount += amount;
                                        existing.remainingBalance += amount;
                                        existing.paybackDate = paybackDate;
                                        final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                        tx.linkedLoanId = savedId; // auto-link
                                      } catch (_) {
                                        final loan = Loan()
                                          ..contactName = contact
                                          ..isLent = false // borrowed debt
                                          ..amount = amount
                                          ..remainingBalance = amount
                                          ..startDate = DateTime.now()
                                          ..paybackDate = paybackDate
                                          ..interestRate = 0.0
                                          ..compoundInterval = 'none'
                                          ..emiAmount = 0.0;
                                        final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                        tx.linkedLoanId = savedId; // auto-link new loan
                                      }
                                    }
                                  } else if ((selectedType == 'expense' || selectedType == 'transfer') && selectedDebtId != null) {
                                    // Repaying a debt — link and reduce balance
                                    final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                    try {
                                      final target = allLoans.firstWhere((l) => l.id == selectedDebtId);
                                      target.remainingBalance = (target.remainingBalance - amount).clamp(0.0, double.infinity);
                                      await ref.read(loansProvider.notifier).addLoan(target);
                                    } catch (_) {}
                                    tx.linkedLoanId = selectedDebtId; // auto-link repaid loan
                                  } else {
                                    // Use manual dropdown selection only when no auto-linking applies
                                    tx.linkedLoanId = selectedLinkedLoanId;
                                  }
                                }

                                ref
                                    .read(transactionsProvider.notifier)
                                    .addTransaction(tx);
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingTransaction != null
                                    ? 'Save Changes'
                                    : 'Log Transaction',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 2: CARDS & LOANS VIEW
// ---------------------------------------------------------------------------
class CardsLoansView extends ConsumerWidget {
  const CardsLoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(creditCardsProvider);
    final loansState = ref.watch(loansProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cards & Debts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Cards horizontal scroll list
            SizedBox(
              height: 340,
              child: cardsState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonTeal),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (cards) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...cards.map((card) {
                        return _buildCreditCardItem(context, ref, card);
                      }),
                      _buildAddCardButton(context, ref),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Loans section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Loans & Ledgers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.neonTeal,
                  ),
                  label: const Text(
                    'Add Loan',
                    style: TextStyle(color: AppColors.neonTeal, fontSize: 13),
                  ),
                  onPressed: () => _showAddLoanDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Loans items list
            loansState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allLoans) {
                final loans = allLoans.where((l) => l.remainingBalance > 0).toList();
                if (loans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No active loans. Click Add Loan to track!',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final String typeStr = loan.isLent
                        ? 'Lent (Receivable)'
                        : 'Borrowed (Debt)';
                    final Color typeColor = loan.isLent
                        ? AppColors.neonEmerald
                        : Colors.redAccent;
                    final String emiInfo = loan.emiAmount > 0
                        ? 'EMI: ₹${loan.emiAmount.toStringAsFixed(0)} (${loan.interestRate}%)'
                        : 'Friendly Loan (${loan.interestRate}%)';

                    return Dismissible(
                      key: ValueKey(loan.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(loansProvider.notifier).removeLoan(loan.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${loan.contactName}\'s loan deleted',
                            ),
                            backgroundColor: AppColors.obsidianSurface,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoanDetailPage(
                              loan: loan,
                              onEdit: () => _showAddLoanDialog(context, ref, existingLoan: loan),
                            ),
                          ),
                        ),
                        child: _buildLoanItem(
                          loan.contactName,
                          typeStr,
                          '₹${loan.remainingBalance.toStringAsFixed(0)}',
                          emiInfo,
                          typeColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _getOrdinalSuffix(int value) {
    if (value >= 11 && value <= 13) {
      return 'th';
    }
    switch (value % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _getMonthName(int day) {
    final now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month, day);

    if (now.day > day) {
      targetDate = DateTime(now.year, now.month + 1, day);
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[targetDate.month - 1];
  }

  Widget _buildSecureFieldCompact(
    BuildContext context,
    String label,
    String value,
    bool copyable,
  ) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (copyable && value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      backgroundColor: AppColors.obsidianSurface,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.neonTeal,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditCardItem(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
  ) {
    bool showSpent = true; // State for toggle
    bool isLongPressed = false; // State for edit/delete
    bool isFlipped = false; // State for flip

    return StatefulBuilder(
      builder: (context, setState) {
        Future<void> authenticateAndFlipCard() async {
          final LocalAuthentication auth = LocalAuthentication();
          try {
            final bool canAuthenticateWithBiometrics =
                await auth.canCheckBiometrics;
            final bool canAuthenticate =
                canAuthenticateWithBiometrics || await auth.isDeviceSupported();

            if (!canAuthenticate) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biometric auth not available')),
              );
              return;
            }

            final bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Authenticate to view secure card details',
              options: const AuthenticationOptions(biometricOnly: true),
            );

            if (didAuthenticate) {
              setState(() => isFlipped = true);
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
          }
        }

        final frontSide = Container(
          key: const ValueKey('front'),
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            gradient: card.imageUrl.isEmpty
                ? LinearGradient(
                    colors: [
                      AppColors.tealBlueGradient[0],
                      AppColors.tealBlueGradient[1],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image layer (supports SVG and raster images)
              if (card.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: card.imageUrl.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.cover,
                        ),
                ),

              // Foreground content
              if (isLongPressed)
                GlassBlur(
                  borderRadius: 20,
                  blurX: 25.0,
                  blurY: 25.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              _showAddCardDialog(
                                context,
                                ref,
                                existingCard: card,
                              );
                            },
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              ref
                                  .read(creditCardsProvider.notifier)
                                  .removeCreditCard(card.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Card deleted'),
                                  backgroundColor: AppColors.obsidianSurface,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(
                      0.15,
                    ), // Gentle global dimming
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: authenticateAndFlipCard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.last4.isNotEmpty ? card.last4 : "****",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),

                      // Bottom area: Spent/Statement Toggle
                      GestureDetector(
                        onTap: () => setState(() => showSpent = !showSpent),
                        child: GlassBlur(
                          borderRadius: 16.0,
                          blurX: 12.0,
                          blurY: 12.0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: AppColors.neonTeal,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      showSpent ? 'SPENT' : 'STATEMENT',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: AppColors.neonTeal,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  showSpent
                                      ? '₹${card.balance.toStringAsFixed(0)}'
                                      : '₹${card.statementAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  showSpent
                                      ? '${card.statementDay} ${_getMonthName(card.statementDay)}'
                                      : '${card.dueDay} ${_getMonthName(card.dueDay)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        );

        final backSide = Container(
          key: const ValueKey('back'),
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            gradient: card.imageUrl.isEmpty
                ? LinearGradient(
                    colors: [
                      AppColors.tealBlueGradient[0],
                      AppColors.tealBlueGradient[1],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image layer (supports SVG and raster images)
              if (card.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: card.imageUrl.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.cover,
                        ),
                ),
              GlassBlur(
                borderRadius: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.65,
                    ), // slightly darker for visibility on back
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SECURE DETAILS',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonTeal,
                              letterSpacing: 1.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => isFlipped = false),
                            child: const Icon(
                              Icons.visibility_off_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildSecureFieldCompact(
                        context,
                        'Card Number',
                        card.fullCardNumber,
                        true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecureFieldCompact(
                              context,
                              'Expiry Date',
                              card.expiryDate,
                              false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecureFieldCompact(
                              context,
                              'CVV',
                              card.cvv,
                              false,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return GestureDetector(
          onLongPress: () => setState(() => isLongPressed = true),
          onTap: () {
            if (isLongPressed) {
              setState(() => isLongPressed = false);
            } else if (!isFlipped) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreditCardDetailView(card: card),
                ),
              );
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );
              return AnimatedBuilder(
                animation: flipAnimation,
                child: child,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..scale(flipAnimation.value, 1.0),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: isFlipped ? backSide : frontSide,
          ),
        );
      },
    );
  }

  Widget _buildCardFooter(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.neonTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildAddCardButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showAddCardDialog(context, ref),
        child: GlassBlur(
          borderRadius: 20,
          borderColor: AppColors.glassBorder.withOpacity(0.05),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_card_rounded,
                  color: AppColors.neonTeal,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Card',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanItem(
    String title,
    String type,
    String principal,
    String emiInfo,
    Color typeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            emiInfo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                principal,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog(
    BuildContext context,
    WidgetRef ref, {
    CreditCard? existingCard,
  }) {
    final nameController = TextEditingController(
      text: existingCard?.cardName ?? '',
    );
    final last4Controller = TextEditingController(
      text: existingCard?.last4 ?? '',
    );
    final stmtDayController = TextEditingController(
      text: existingCard?.statementDay.toString() ?? '15',
    );
    final dueDayController = TextEditingController(
      text: existingCard?.dueDay.toString() ?? '5',
    );

    // Secure Fields
    final fullCardNumberController = TextEditingController(
      text: existingCard?.fullCardNumber ?? '',
    );
    final expiryDateController = TextEditingController(
      text: existingCard?.expiryDate ?? '',
    );
    final cvvController = TextEditingController(text: existingCard?.cvv ?? '');

    // Financial metrics for card
    final currentSpendingsController = TextEditingController(
      text: existingCard?.currentSpendings.toStringAsFixed(0) ?? '0',
    );
    final statementAmountController = TextEditingController(
      text: existingCard?.statementAmount.toStringAsFixed(0) ?? '0',
    );

    String selectedBrand = existingCard?.brand.isNotEmpty == true
        ? existingCard!.brand
        : 'Visa';
    String selectedImage = existingCard?.imageUrl ?? '';

    final imageOptions = [
      '',
      'HDFC_MoneyBack_Vertical_HQ.avif',
      'IDFC_Millennia_HQ.avif',
      'LIC_Axis_Cropped_Vector.svg',
      'RBL_Bank_Fitted.avif',
      'SBI_SimplySave_Mobile.avif',
      'Scapia_Rupay.avif',
      'Scapia_Visa.avif',
      'Tata_NeuCard_FullFrame.avif',
      'UNI_YesBank_Vertical.avif',
      'hsbc_vertical_card_final.avif',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Register Credit Card',
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.neonTeal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => NfcScanDialog(
                                    nameController: nameController,
                                    last4Controller: last4Controller,
                                    fullCardNumberController:
                                        fullCardNumberController,
                                    expiryDateController: expiryDateController,
                                    onBrandDetected: (brand) {
                                      setState(() => selectedBrand = brand);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.nfc_rounded, size: 18),
                              label: const Text(
                                'Scan',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Card Name (e.g. HDFC Regalia)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: fullCardNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Card Number',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.length >= 4) {
                                    last4Controller.text = val.substring(
                                      val.length - 4,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: last4Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Last 4',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry (MM/YY)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedBrand,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Visa', 'Mastercard', 'RuPay', 'Amex']
                              .map(
                                (b) =>
                                    DropdownMenuItem(value: b, child: Text(b)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedBrand = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedImage,
                          decoration: const InputDecoration(
                            labelText: 'Card Background Image',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: imageOptions
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    i.isEmpty ? 'None' : i,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedImage = val!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: currentSpendingsController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Spendings',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: statementAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'Statement Amount',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stmtDayController,
                                decoration: const InputDecoration(
                                  labelText: 'Statement Day (1-28)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: dueDayController,
                                decoration: const InputDecoration(
                                  labelText: 'Due Day (1-28)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final name = nameController.text.trim();
                                final last4 = last4Controller.text.trim();
                                final stmt =
                                    int.tryParse(stmtDayController.text) ?? 15;
                                final due =
                                    int.tryParse(dueDayController.text) ?? 5;
                                final curSp =
                                    double.tryParse(
                                      currentSpendingsController.text,
                                    ) ??
                                    0.0;
                                final stmAm =
                                    double.tryParse(
                                      statementAmountController.text,
                                    ) ??
                                    0.0;

                                if (name.isEmpty || last4.length != 4) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          AppColors.obsidianSurface,
                                      title: const Text(
                                        'Invalid Input',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'Please fill Name and Last 4 digits accurately.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(
                                              color: AppColors.neonTeal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                // Duplicate Check
                                final existingCards =
                                    ref.read(creditCardsProvider).value ?? [];
                                if (existingCard == null) {
                                  final cardNumber = fullCardNumberController
                                      .text
                                      .trim();
                                  if (cardNumber.isNotEmpty) {
                                    final isDuplicate = existingCards.any(
                                      (c) => c.fullCardNumber == cardNumber,
                                    );
                                    if (isDuplicate) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              AppColors.obsidianSurface,
                                          title: const Text(
                                            'Duplicate Card',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: const Text(
                                            'A card with this number already exists!',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: AppColors.neonTeal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }

                                final card = existingCard ?? CreditCard();
                                card
                                  ..cardName = name
                                  ..last4 = last4
                                  ..statementDay = stmt
                                  ..dueDay = due
                                  ..fullCardNumber = fullCardNumberController
                                      .text
                                      .trim()
                                  ..expiryDate = expiryDateController.text
                                      .trim()
                                  ..cvv = cvvController.text.trim()
                                  ..brand = selectedBrand
                                  ..imageUrl = selectedImage
                                  ..currentSpendings = curSp
                                  ..statementAmount = stmAm;

                                if (existingCard == null) {
                                  ref
                                      .read(creditCardsProvider.notifier)
                                      .addCreditCard(card);
                                } else {
                                  ref
                                      .read(creditCardsProvider.notifier)
                                      .updateCreditCard(card);
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingCard == null
                                    ? 'Add Card'
                                    : 'Save Changes',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddLoanDialog(
    BuildContext context,
    WidgetRef ref, {
    Loan? existingLoan,
  }) {
    final contactController = TextEditingController(
      text: existingLoan?.contactName ?? '',
    );
    final amountController = TextEditingController(
      text: existingLoan != null ? existingLoan.amount.toStringAsFixed(0) : '',
    );
    final rateController = TextEditingController(
      text: existingLoan != null ? existingLoan.interestRate.toString() : '0',
    );
    final emiController = TextEditingController(
      text: existingLoan != null
          ? existingLoan.emiAmount.toStringAsFixed(0)
          : '0',
    );
    bool isLent = existingLoan?.isLent ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingLoan != null
                              ? 'Edit Loan / Debt'
                              : 'Track Loan / Debt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<bool>(
                          value: isLent,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.obsidianSurface,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Borrowed (Debt)'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Lent (Receivable)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => isLent = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact / Lender Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (INR)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: rateController,
                                decoration: const InputDecoration(
                                  labelText: 'Interest Rate (%)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: emiController,
                                decoration: const InputDecoration(
                                  labelText: 'Monthly EMI (0 if none)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final contact = contactController.text.trim();
                                final amount =
                                    double.tryParse(amountController.text) ??
                                    0.0;
                                final rate =
                                    double.tryParse(rateController.text) ?? 0.0;
                                final emi =
                                    double.tryParse(emiController.text) ?? 0.0;

                                if (contact.isEmpty || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter name and valid amount',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final loan = existingLoan ?? Loan();
                                loan.contactName = contact;
                                loan.isLent = isLent;
                                loan.amount = amount;
                                if (existingLoan == null) {
                                  loan.remainingBalance = amount;
                                  loan.startDate = DateTime.now();
                                } else {
                                  if (existingLoan.amount ==
                                      existingLoan.remainingBalance) {
                                    loan.remainingBalance = amount;
                                  }
                                }
                                loan.interestRate = rate;
                                loan.emiAmount = emi;

                                ref.read(loansProvider.notifier).addLoan(loan);
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingLoan != null
                                    ? 'Save Changes'
                                    : 'Add Loan',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// LOAN DETAIL PAGE
// ---------------------------------------------------------------------------
class LoanDetailPage extends ConsumerWidget {
  final Loan loan;
  final VoidCallback onEdit;

  const LoanDetailPage({super.key, required this.loan, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsState = ref.watch(transactionsProvider);
    final typeColor = loan.isLent ? AppColors.neonEmerald : Colors.redAccent;
    final typeLabel = loan.isLent ? 'Lent (Receivable)' : 'Borrowed (Debt)';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          loan.contactName,
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.neonTeal, size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ],
                  ),
                ),

                // Loan summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassBlur(
                    borderRadius: 20,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (loan.interestRate > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${loan.interestRate}% APR',
                                    style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Original Amount', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${loan.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Remaining Balance', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${loan.remainingBalance.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (loan.emiAmount > 0) ...[
                            const SizedBox(height: 8),
                            Divider(color: Colors.white.withOpacity(0.08)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monthly EMI: ₹${loan.emiAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                if (loan.paybackDate != null)
                                  Text(
                                    'Due: ${loan.paybackDate!.day}/${loan.paybackDate!.month}/${loan.paybackDate!.year}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ],
                          if (loan.paybackDate != null && loan.emiAmount == 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Due by: ${loan.paybackDate!.day}/${loan.paybackDate!.month}/${loan.paybackDate!.year}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Linked transactions section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppColors.neonPurple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Linked Transactions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.neonPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Linked transactions list
                Expanded(
                  child: txsState.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonPurple)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                    data: (allTxs) {
                      final linked = allTxs.where((t) => t.linkedLoanId == loan.id).toList();
                      if (linked.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_off_rounded, color: AppColors.textMuted, size: 40),
                              SizedBox(height: 10),
                              Text(
                                'No transactions linked to this loan yet.',
                                style: TextStyle(color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Link transactions using the "Link to Loan" option\nwhen adding or editing a transaction.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Summary strip
                      final totalLinked = linked.fold<double>(0.0, (sum, t) => sum + t.amount);

                      return Column(
                        children: [
                          // Summary banner
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GlassBlur(
                              borderRadius: 12,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${linked.length} transaction${linked.length == 1 ? '' : 's'}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'Total: ₹${totalLinked.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neonPurple),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Transaction list
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: linked.length,
                              itemBuilder: (context, index) {
                                final tx = linked[index];
                                final isIncome = tx.transactionType == 'income';
                                final amtColor = isIncome ? AppColors.neonEmerald : Colors.redAccent;
                                final amtStr = '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';
                                final dateStr = '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassBlur(
                                    borderRadius: 14,
                                    child: ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: amtColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          color: amtColor,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        tx.description,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${tx.category} • $dateStr',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      trailing: Text(
                                        amtStr,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: amtColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 3: INVESTMENTS VIEW (Zerodha & Coin holdings)
// ---------------------------------------------------------------------------
class InvestmentsView extends ConsumerStatefulWidget {
  const InvestmentsView({super.key});

  @override
  ConsumerState<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends ConsumerState<InvestmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdingsState = ref.watch(holdingsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Investments',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.neonTeal,
                      size: 20,
                    ),
                    tooltip: 'Refresh Prices',
                    onPressed: () => _refreshPrices(context),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonEmerald.withOpacity(0.12),
                  foregroundColor: AppColors.neonEmerald,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                icon: const Icon(Icons.file_upload_rounded, size: 16),
                label: const Text('Import CSV', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  _showImportDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.neonEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonEmerald.withOpacity(0.3),
                ),
              ),
              labelColor: AppColors.neonEmerald,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Stocks (Zerodha)'),
                Tab(text: 'Mutual Funds (Coin)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total valuation banner & Asset Allocation Pie Chart
          holdingsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.neonTeal),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (holdings) {
              double currentVal = 0.0;
              double buyCost = 0.0;
              double stockVal = 0.0;
              double mfVal = 0.0;

              for (final h in holdings) {
                final val = h.currentPrice * h.quantity;
                currentVal += val;
                buyCost += h.buyAvgPrice * h.quantity;
                if (h.assetType == 'stock') {
                  stockVal += val;
                } else {
                  mfVal += val;
                }
              }

              final returnsAmt = currentVal - buyCost;
              final returnsPct = buyCost > 0
                  ? (returnsAmt / buyCost) * 100
                  : 0.0;
              final isNegative = returnsAmt < 0;

              final totalVal = stockVal + mfVal;
              final double stockPct = totalVal > 0
                  ? (stockVal / totalVal) * 100
                  : 0.0;
              final double mfPct = totalVal > 0
                  ? (mfVal / totalVal) * 100
                  : 0.0;

              String formatCurrency(double val) {
                final sign = val < 0 ? '-' : '';
                return '$sign₹${val.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
              }

              return Column(
                children: [
                  GlassBlur(
                    borderRadius: 16,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Valuation',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(currentVal),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Returns',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${isNegative ? "" : "+"}${formatCurrency(returnsAmt)} (${isNegative ? "" : "+"}${returnsPct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNegative
                                      ? Colors.redAccent
                                      : AppColors.neonEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (totalVal > 0) ...[
                    const SizedBox(height: 12),
                    GlassBlur(
                      borderRadius: 16,
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    if (stockVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonTeal,
                                        value: stockVal,
                                        title:
                                            '${stockPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    if (mfVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonEmerald,
                                        value: mfVal,
                                        title: '${mfPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem(
                                    'Stocks (Zerodha)',
                                    formatCurrency(stockVal),
                                    AppColors.neonTeal,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLegendItem(
                                    'Mutual Funds (Coin)',
                                    formatCurrency(mfVal),
                                    AppColors.neonEmerald,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: holdingsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (holdings) {
                final stocks = holdings
                    .where((h) => h.assetType == 'stock')
                    .toList();
                final mutualFunds = holdings
                    .where((h) => h.assetType == 'mutual_fund')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Stocks List
                    stocks.isEmpty
                        ? const Center(
                            child: Text(
                              'No stocks. Click Import to add holdings!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: stocks.length,
                            itemBuilder: (context, index) {
                              final h = stocks[index];
                              final cost = h.buyAvgPrice * h.quantity;
                              final curVal = h.currentPrice * h.quantity;
                              final ret = curVal - cost;
                              final pct = cost > 0 ? (ret / cost) * 100 : 0.0;
                              final isNegative = ret < 0;

                              return _buildHoldingItem(
                                h.symbol,
                                h.name,
                                '${h.quantity.toStringAsFixed(0)} Qty',
                                'Avg: ₹${h.buyAvgPrice.toStringAsFixed(0)}',
                                'Current: ₹${h.currentPrice.toStringAsFixed(0)}',
                                '${isNegative ? "" : "+"}${pct.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                    // Mutual Funds List
                    mutualFunds.isEmpty
                        ? const Center(
                            child: Text(
                              'No mutual funds. Click Import to add holdings!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: mutualFunds.length,
                            itemBuilder: (context, index) {
                              final h = mutualFunds[index];
                              final cost = h.buyAvgPrice * h.quantity;
                              final curVal = h.currentPrice * h.quantity;
                              final ret = curVal - cost;
                              final pct = cost > 0 ? (ret / cost) * 100 : 0.0;
                              final isNegative = ret < 0;

                              return _buildHoldingItem(
                                h.symbol,
                                h.name,
                                '${h.quantity.toStringAsFixed(0)} Units',
                                'Avg NAV: ₹${h.buyAvgPrice.toStringAsFixed(1)}',
                                'Current NAV: ₹${h.currentPrice.toStringAsFixed(1)}',
                                '${isNegative ? "" : "+"}${pct.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingItem(
    String symbol,
    String name,
    String qty,
    String avg,
    String current,
    String returns,
  ) {
    final isNegative = returns.startsWith('-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                returns,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? Colors.redAccent : AppColors.neonEmerald,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$qty • $avg',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                current,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Portfolio holdings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select your holdings CSV or Excel export from Zerodha Console or Coin:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.neonTeal,
                    ),
                    title: const Text(
                      'Zerodha Holdings (CSV/Excel)',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Upload Console holdings sheet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'zerodha');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.neonEmerald,
                    ),
                    title: const Text(
                      'Coin Mutual Funds (CSV/Excel)',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Upload Coin holdings sheet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'coin');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Clear All Holdings',
                      style: TextStyle(fontSize: 14, color: Colors.redAccent),
                    ),
                    subtitle: const Text(
                      'Reset local investments portfolio',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref
                          .read(holdingsProvider.notifier)
                          .clearAllHoldings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All holdings cleared.')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndParseFile(BuildContext context, String broker) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes == null) {
        throw Exception('Could not read file bytes.');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.neonEmerald),
        ),
      );

      final parser = ref.read(portfolioParserServiceProvider);
      List<Holding> holdings;

      if (broker == 'zerodha') {
        holdings = await parser.parseZerodha(fileBytes, file.name);
      } else {
        holdings = await parser.parseCoin(fileBytes, file.name);
      }

      if (holdings.isEmpty) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid holdings found in the selected file.'),
          ),
        );
        return;
      }

      await parser.importHoldings(holdings);
      await ref.read(holdingsProvider.notifier).loadHoldings();

      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${holdings.length} holdings successfully!'),
          backgroundColor: AppColors.neonEmerald.withOpacity(0.8),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to import holdings: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _refreshPrices(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircularProgressIndicator(color: AppColors.neonEmerald),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Fetching latest market prices from Yahoo Finance & AMFI...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final syncService = ref.read(investmentSyncServiceProvider);
      final count = await syncService.syncAllPrices();

      // Reload holdings provider
      await ref.read(holdingsProvider.notifier).loadHoldings();

      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated $count asset prices!'),
          backgroundColor: AppColors.neonEmerald.withOpacity(0.8),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update prices: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 4: AI FINANCIAL ADVISOR (Quant Engine + LLM Chat)
// ---------------------------------------------------------------------------
class AdvisorView extends ConsumerStatefulWidget {
  const AdvisorView({super.key});

  @override
  ConsumerState<AdvisorView> createState() => _AdvisorViewState();
}

class _AdvisorViewState extends ConsumerState<AdvisorView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _advisorTabController;
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _advisorTabController = TabController(length: 2, vsync: this);
    // Initialize welcome message
    _messages.add({
      'sender': 'AI',
      'text':
          'Hello Akshat! I am your local privacy-first financial advisor. Ask me anything about rebalancing your portfolio, check your emergency fund status, or ask for home/car loan pre-payment guidance!',
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _advisorTabController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'AI Advisor & Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),

          // Selection tab
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _advisorTabController,
              indicator: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonPurple.withOpacity(0.3),
                ),
              ),
              labelColor: AppColors.neonPurple,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Quant Dashboard'),
                Tab(text: 'AI Finance Chat'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: TabBarView(
              controller: _advisorTabController,
              children: [
                // Quant Dashboard
                _buildQuantDashboard(context),

                // AI Finance Chat
                _buildChatInterface(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getActiveEngineStatus() async {
    final useLocalStr = await const FlutterSecureStorage().read(
      key: 'ai_use_local',
    );
    final useLocal = useLocalStr == 'true';
    if (useLocal) {
      final prefs = await SharedPreferences.getInstance();
      final selectedId =
          prefs.getString('selectedModelId') ?? 'gemma2_turbo_2b';
      final meta = await ModelRepository.instance.getMeta(selectedId);
      if (meta != null) {
        final localPath = await ModelRepository.instance.localModelPath(
          meta.assetPath,
        );
        if (await File(localPath).exists()) {
          return 'Local LLM: ${meta.displayName}';
        }
      }
      return 'Local LLM (No downloaded model, using Quant Fallback)';
    }
    final geminiKey = await const FlutterSecureStorage().read(
      key: 'ai_gemini_key',
    );
    if (geminiKey != null && geminiKey.isNotEmpty) {
      return 'Gemini Cloud API (Online)';
    }
    final host =
        await const FlutterSecureStorage().read(key: 'ai_ollama_host') ??
        'http://localhost:11434';
    return 'Ollama Local Host ($host)';
  }

  Widget _buildQuantDashboard(BuildContext context) {
    final forecastState = ref.watch(quantForecastResultProvider);

    return forecastState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonPurple),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (forecast) {
        String formatCurrency(double val) {
          final sign = val < 0 ? '-' : '';
          final absVal = val.abs();
          final str = absVal.toStringAsFixed(0);
          String result = str;
          if (str.length > 3) {
            final last3 = str.substring(str.length - 3);
            final rest = str.substring(0, str.length - 3);
            final restGrouped = rest.replaceAllMapped(
              RegExp(r'(\d+?)(?=(\d{2})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
            result = '$restGrouped,$last3';
          }
          return '$sign₹$result';
        }

        double progress = forecast.projectedSpend > 0
            ? (forecast.dailyVelocity * forecast.remainingDays) / 100000.0
            : 0.0;
        if (progress > 1.0) progress = 1.0;
        if (progress < 0.0) progress = 0.0;

        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Forecaster card
            GlassBlur(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline_rounded, color: AppColors.neonTeal),
                        SizedBox(width: 8),
                        Text(
                          'Cash Flow Forecast',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Projected Spend: ${formatCurrency(forecast.projectedSpend)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on current velocity (${formatCurrency(forecast.dailyVelocity)}/day) over ${forecast.remainingDays} remaining days + monthly EMIs (${formatCurrency(forecast.recurringEmis)}) + rent (${formatCurrency(forecast.detectedRent)}).',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonTeal,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Allocation advice card
            GlassBlur(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          color: AppColors.neonEmerald,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Advisor Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (forecast.rebalanceAmount > 0)
                      _buildRecommendationBullet(
                        'Asset Allocation Rebalancing',
                        'Your current holdings are ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds. Consider shifting ${formatCurrency(forecast.rebalanceAmount)} to Mutual Funds to align with a balanced 70% direct stocks / 30% mutual funds allocation.',
                      )
                    else
                      _buildRecommendationBullet(
                        'Asset Allocation Healthy',
                        'Your direct stocks (${forecast.stocksPercentage.toStringAsFixed(0)}%) and mutual funds (${forecast.mfsPercentage.toStringAsFixed(0)}%) ratio is healthy. SIP inputs are recommended to grow your portfolio.',
                      ),
                    const SizedBox(height: 8),
                    if (forecast.emergencyFundMonths < 6.0)
                      _buildRecommendationBullet(
                        'Emergency Fund Shortfall',
                        'Your savings of ${formatCurrency(forecast.cashAndBank)} cover ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of outflow. We recommend building this up to ${formatCurrency(forecast.recommendedEmergencyFund)} to cover 6 months of basic living needs.',
                      )
                    else
                      _buildRecommendationBullet(
                        'Emergency Fund Secure',
                        'Your savings cover ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of monthly outflow. This is a very secure buffer.',
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationBullet(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.chevron_right,
              color: AppColors.neonEmerald,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 2, bottom: 8),
          child: Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    return Column(
      children: [
        // Active AI Engine Status
        Container(
          margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonPurple.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.neonPurple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Active Engine:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.grey[900]),
                child: ModelSelector(
                  onChanged: () {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),

        // Chat History
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                // Show typing bubble
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                      left: 4,
                      right: 4,
                    ),
                    child: GlassBlur(
                      borderRadius: 16,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Typing advisor recommendations...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final msg = _messages[index];
              final isAI = msg['sender'] == 'AI';
              return Align(
                alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: GlassBlur(
                    borderRadius: 16,
                    cardColor: isAI
                        ? AppColors.glassCard
                        : AppColors.neonPurple.withOpacity(0.1),
                    borderColor: isAI
                        ? AppColors.glassBorder
                        : AppColors.neonPurple.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        msg['text']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Text Input box
        Padding(
          padding: EdgeInsets.only(
            bottom: View.of(context).viewInsets.bottom > 0 ? 12.0 : 90.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: GlassBlur(
                  borderRadius: 16,
                  child: TextField(
                    controller: _chatInputController,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask advisor (e.g. should I pre-pay home loan?)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassBlur(
                borderRadius: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.neonTeal,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'User', 'text': text});
      _isTyping = true;
      _chatInputController.clear();
    });

    try {
      final forecastState = ref.read(quantForecastResultProvider);

      if (forecastState.hasValue) {
        final forecast = forecastState.value!;
        final txs = ref.read(transactionsProvider).value ?? [];
        final cards = ref.read(creditCardsProvider).value ?? [];
        final loans = ref.read(loansProvider).value ?? [];
        final holdings = ref.read(holdingsProvider).value ?? [];

        double totalHoldingsVal = forecast.stocksVal + forecast.mfVal;
        double totalCardOutstanding = 0.0;
        for (final c in cards) {
          totalCardOutstanding += c.balance;
        }
        double totalDebts = 0.0;
        double totalReceivables = 0.0;
        for (final l in loans) {
          if (l.isLent) {
            totalReceivables += l.remainingBalance;
          } else {
            totalDebts += l.remainingBalance;
          }
        }
        double netWorth =
            totalHoldingsVal +
            forecast.cashAndBank +
            totalReceivables -
            totalCardOutstanding -
            totalDebts;

        final advisorService = ref.read(aiAdvisorServiceProvider);

        final sanitizedProfile = advisorService.generateSanitizedProfile(
          transactions: txs,
          cards: cards,
          loans: loans,
          holdings: holdings,
          netWorth: netWorth,
          cashAndBank: forecast.cashAndBank,
          forecast: forecast,
        );

        final reply = await advisorService.queryAdvisor(
          userQuery: text,
          sanitizedProfile: sanitizedProfile,
          forecast: forecast,
        );

        setState(() {
          _messages.add({'sender': 'AI', 'text': reply});
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'AI',
            'text':
                'I am still loading your financial profile. Please wait a moment.',
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text':
              'Sorry, I encountered an error while processing your request: $e',
        });
        _isTyping = false;
      });
    }
  }
}

// ---------------------------------------------------------------------------
// VIEW 5: SETTINGS SCREEN
// ---------------------------------------------------------------------------
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _biometricsEnabled = true;
  bool _localLLMEnabled = false;
  bool _checkingLocalLLM = false;
  bool _interactiveReviewEnabled = false;
  bool _allowSyncDuplicates = false;
  int _smsLookbackValue = 180;
  String _smsLookbackUnit = 'days';
  DateTime? _syncStartDate;
  DateTime? _syncEndDate;

  final _storage = const FlutterSecureStorage();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.read(key: 'settings_biometrics') ?? 'true';
    final localLLM = await _storage.read(key: 'ai_use_local') ?? 'false';
    final review = await _storage.read(key: 'settings_interactive_review') ?? 'false';
    final allowDuplicates = await _storage.read(key: 'settings_sms_sync_allow_duplicates') ?? 'false';

    String? lookbackValStr = await _storage.read(
      key: 'settings_sms_lookback_value',
    );
    String? lookbackUnitStr = await _storage.read(
      key: 'settings_sms_lookback_unit',
    );
    final startStr = await _storage.read(key: 'settings_sync_start_date');
    final endStr = await _storage.read(key: 'settings_sync_end_date');

    if (lookbackValStr == null && startStr == null) {
      final legacy = await _storage.read(key: 'settings_sms_lookback_days');
      if (legacy != null) {
        lookbackValStr = legacy;
        lookbackUnitStr = 'days';
      } else {
        lookbackValStr = '180';
        lookbackUnitStr = 'days';
      }
    }

    setState(() {
      _biometricsEnabled = bio == 'true';
      _localLLMEnabled = localLLM == 'true';
      _interactiveReviewEnabled = review == 'true';
      _allowSyncDuplicates = allowDuplicates == 'true';
      if (lookbackValStr != null) {
        _smsLookbackValue = int.tryParse(lookbackValStr) ?? 180;
      }
      _smsLookbackUnit = lookbackUnitStr ?? 'days';
      if (startStr != null) _syncStartDate = DateTime.parse(startStr);
      if (endStr != null) _syncEndDate = DateTime.parse(endStr);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Security Group
          _buildGroupTitle('Security & Privacy'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Biometric Authentication',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Lock app using Fingerprint / FaceID',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _biometricsEnabled,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) async {
                    setState(() => _biometricsEnabled = val);
                    await _storage.write(
                      key: 'settings_biometrics',
                      value: val.toString(),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Manage PDF Passwords',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Add decryption keys for CC Statements',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.vpn_key_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showManagePasswordsDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Recovery Bin',
                    style: TextStyle(fontSize: 14, color: AppColors.neonTeal),
                  ),
                  subtitle: const Text(
                    'Restore recently deleted transactions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.restore_from_trash_rounded,
                    size: 20,
                    color: AppColors.neonTeal,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecoveryBinPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Integrations Group
          _buildGroupTitle('Integrations & Fetching'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Linked Google Accounts',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Manage backup, sync, and Gmail scanning accounts',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.account_tree_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showGoogleAccountsDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'SMS Sync Lookback Window',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _syncStartDate != null && _syncEndDate != null
                        ? 'Custom Range: ${_formatDate(_syncStartDate!)} to ${_formatDate(_syncEndDate!)}'
                        : 'Scan window: $_smsLookbackValue $_smsLookbackUnit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_calendar_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showSmsLookbackDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                SwitchListTile(
                  title: const Text(
                    'Interactive Sync Review',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Verify parsed SMS/email transactions before saving',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _interactiveReviewEnabled,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) async {
                    setState(() => _interactiveReviewEnabled = val);
                    await _storage.write(
                      key: 'settings_interactive_review',
                      value: val.toString(),
                    );
                  },
                 ),
                const Divider(height: 1, color: AppColors.glassBorder),
                SwitchListTile(
                  title: const Text(
                    'Allow Duplicate Sync Alerts',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Allow parsing already imported/processed SMS alerts',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _allowSyncDuplicates,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) async {
                    setState(() => _allowSyncDuplicates = val);
                    await _storage.write(
                      key: 'settings_sms_sync_allow_duplicates',
                      value: val.toString(),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Sync All Accounts Now',
                    style: TextStyle(fontSize: 14, color: AppColors.neonTeal),
                  ),
                  subtitle: const Text(
                    'Directly fetch transactions from Gmail & SMS',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.sync_rounded,
                    size: 20,
                    color: AppColors.neonTeal,
                  ),
                  onTap: () => _triggerAccountSync(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Manage Categories',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Add or remove custom categories for Expense, Income, and Transfer',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neonPurple,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.category_rounded,
                    size: 20,
                    color: AppColors.neonPurple,
                  ),
                  onTap: () => _showManageCategoriesDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Config Group
          _buildGroupTitle('AI Model Configuration'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Enable On-Device LLM',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Run LLM locally on device via Flutter Gemma (Ollama on desktop)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _localLLMEnabled,
                  activeColor: AppColors.neonPurple,
                  onChanged: (val) async {
                    setState(() {
                      _localLLMEnabled = val;
                    });
                    await _storage.write(
                      key: 'ai_use_local',
                      value: val.toString(),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Manage Local Models',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Download or delete on-device model files',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModelDownloadPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Cloud AI API Keys',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Configure personal Gemini or OpenAI keys',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.api_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showApiKeysDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'HuggingFace Token',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Configure HuggingFace access token for gated models',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.key_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showHuggingFaceDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Danger Zone
          _buildGroupTitle('Danger Zone'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Clear All Transactions',
                    style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                  ),
                  subtitle: const Text(
                    'Erases transaction history. Cards & Bank Accounts remain intact.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: Colors.orangeAccent,
                  ),
                  onTap: () => _showClearDataConfirmDialog(
                    context,
                    type: 'transactions',
                  ),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Clear All Debts & Loans',
                    style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                  ),
                  subtitle: const Text(
                    'Erases loan history and tracking. Cards & Bank Accounts remain intact.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: Colors.orangeAccent,
                  ),
                  onTap: () =>
                      _showClearDataConfirmDialog(context, type: 'loans'),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Reset Sync History',
                    style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                  ),
                  subtitle: const Text(
                    'Resets sync timestamps and erases records of skipped/ignored messages to trigger a clean re-scan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 20,
                    color: Colors.orangeAccent,
                  ),
                  onTap: () => _showClearDataConfirmDialog(
                    context,
                    type: 'sync_history',
                  ),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text(
                    'Clear All Data',
                    style: TextStyle(fontSize: 14, color: Colors.redAccent),
                  ),
                  subtitle: const Text(
                    'Permanently erase all credit cards, loans, holdings, and transactions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onTap: () =>
                      _showClearDataConfirmDialog(context, type: 'all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Version Footer
          const Center(
            child: Text(
              'MypersonalTracker v1.0.0 • 100% Local Encryption',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showImapConfigDialog(BuildContext context) {
    final emailController = TextEditingController();
    final pwdController = TextEditingController();
    final hostController = TextEditingController(text: 'imap.gmail.com');
    final portController = TextEditingController(text: '993');

    // Pre-populate if exists
    _storage
        .read(key: 'imap_email')
        .then((val) => emailController.text = val ?? '');
    _storage
        .read(key: 'imap_host')
        .then((val) => hostController.text = val ?? 'imap.gmail.com');
    _storage
        .read(key: 'imap_port')
        .then((val) => portController.text = val ?? '993');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure Gmail IMAP',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'For Gmail, use a 16-digit Google App Password rather than your standard login password.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pwdController,
                      decoration: const InputDecoration(
                        labelText: 'Google App Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hostController,
                            decoration: const InputDecoration(
                              labelText: 'IMAP Host',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonTeal,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final email = emailController.text.trim();
                            final pwd = pwdController.text.trim();
                            final host = hostController.text.trim();
                            final port =
                                int.tryParse(portController.text.trim()) ?? 993;

                            if (email.isEmpty || pwd.isEmpty || host.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill email and password',
                                  ),
                                ),
                              );
                              return;
                            }

                            await ref
                                .read(emailSyncServiceProvider)
                                .saveCredentials(email, pwd, host, port);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IMAP credentials saved locally'),
                              ),
                            );
                          },
                          child: const Text('Save Config'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSmsLookbackDialog(BuildContext context) {
    String selectedUnit = _smsLookbackUnit;
    final valueController = TextEditingController(
      text: _smsLookbackValue.toString(),
    );
    DateTime? tempStart = _syncStartDate;
    DateTime? tempEnd = _syncEndDate;
    bool useCalendar = tempStart != null && tempEnd != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Scan Window',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Define how far back the app will scan your SMS and Gmail inbox for transactions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toggle Lookback Type
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => useCalendar = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !useCalendar
                                      ? AppColors.neonTeal.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !useCalendar
                                        ? AppColors.neonTeal
                                        : AppColors.glassBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Relative Window',
                                    style: TextStyle(
                                      color: !useCalendar
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: !useCalendar
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => useCalendar = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: useCalendar
                                      ? AppColors.neonTeal.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: useCalendar
                                        ? AppColors.neonTeal
                                        : AppColors.glassBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Calendar Range',
                                    style: TextStyle(
                                      color: useCalendar
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: useCalendar
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (!useCalendar) ...[
                        // Unit Selector (Days vs Months)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedUnit = 'days'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedUnit == 'days'
                                        ? AppColors.neonTeal.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedUnit == 'days'
                                          ? AppColors.neonTeal
                                          : AppColors.glassBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Days',
                                      style: TextStyle(
                                        color: selectedUnit == 'days'
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: selectedUnit == 'days'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedUnit = 'months'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedUnit == 'months'
                                        ? AppColors.neonTeal.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedUnit == 'months'
                                          ? AppColors.neonTeal
                                          : AppColors.glassBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Months',
                                      style: TextStyle(
                                        color: selectedUnit == 'months'
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: selectedUnit == 'months'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Value Input
                        TextField(
                          controller: valueController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: selectedUnit == 'days'
                                ? 'Number of Days'
                                : 'Number of Months',
                            labelStyle: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.glassBorder,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.neonTeal),
                            ),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(
                              Icons.date_range_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Calendar Picker UI
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.glassCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.neonTeal,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tempStart != null && tempEnd != null
                                    ? '${_formatDate(tempStart!)}  ➔  ${_formatDate(tempEnd!)}'
                                    : 'No range selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonTeal
                                      .withOpacity(0.2),
                                  foregroundColor: AppColors.neonTeal,
                                  side: const BorderSide(
                                    color: AppColors.neonTeal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    initialDateRange:
                                        tempStart != null && tempEnd != null
                                        ? DateTimeRange(
                                            start: tempStart!,
                                            end: tempEnd!,
                                          )
                                        : null,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: AppColors.neonTeal,
                                            onPrimary: Colors.black,
                                            surface: AppColors.obsidianSurface,
                                            onSurface: Colors.white,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.neonTeal,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      tempStart = picked.start;
                                      tempEnd = picked.end;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.edit_calendar_rounded),
                                label: const Text('Select Date Range'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonTeal,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (useCalendar) {
                                if (tempStart == null || tempEnd == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a date range first',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                await _storage.write(
                                  key: 'settings_sync_start_date',
                                  value: tempStart!.toIso8601String(),
                                );
                                await _storage.write(
                                  key: 'settings_sync_end_date',
                                  value: tempEnd!.toIso8601String(),
                                );
                                await _storage.delete(
                                  key: 'settings_sms_lookback_value',
                                );
                                await _storage.delete(
                                  key: 'settings_sms_lookback_unit',
                                );

                                this.setState(() {
                                  _syncStartDate = tempStart;
                                  _syncEndDate = tempEnd;
                                });
                              } else {
                                final text = valueController.text.trim();
                                final val = int.tryParse(text);
                                if (val == null || val <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid positive number',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                await _storage.write(
                                  key: 'settings_sms_lookback_value',
                                  value: val.toString(),
                                );
                                await _storage.write(
                                  key: 'settings_sms_lookback_unit',
                                  value: selectedUnit,
                                );
                                await _storage.delete(
                                  key: 'settings_sync_start_date',
                                );
                                await _storage.delete(
                                  key: 'settings_sync_end_date',
                                );

                                this.setState(() {
                                  _smsLookbackValue = val;
                                  _smsLookbackUnit = selectedUnit;
                                  _syncStartDate = null;
                                  _syncEndDate = null;
                                });
                              }

                              // Force full scan on next sync
                              await _storage.delete(key: 'last_sms_sync_time');
                              final accounts = await ref
                                  .read(googleSyncServiceProvider)
                                  .getLinkedAccounts();
                              for (var acc in accounts) {
                                await _storage.delete(
                                  key: 'last_gmail_sync_time_${acc.email}',
                                );
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    useCalendar
                                        ? 'Lookback range set to ${_formatDate(tempStart!)} - ${_formatDate(tempEnd!)}.'
                                        : 'Lookback set to ${valueController.text.trim()} $selectedUnit. Next sync will perform a full scan.',
                                  ),
                                  backgroundColor: AppColors.neonEmerald
                                      .withOpacity(0.9),
                                ),
                              );
                            },
                            child: const Text('Save Window'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManagePasswordsDialog(BuildContext context) {
    int? selectedCardId;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final cardsState = ref.watch(creditCardsProvider);

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Card PDF Passwords',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Stored locally to decrypt downloaded bank statement PDFs at month-end.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedCardId,
                        decoration: const InputDecoration(
                          labelText: 'Select Credit Card',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: AppColors.obsidianSurface,
                        items: cardsState.maybeWhen(
                          data: (cards) => cards
                              .map(
                                (card) => DropdownMenuItem<int>(
                                  value: card.id,
                                  child: Text(
                                    '${card.cardName} (..${card.last4})',
                                  ),
                                ),
                              )
                              .toList(),
                          orElse: () => [],
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCardId = val);
                            // Read existing if any
                            _storage.read(key: 'card_password_$val').then((pw) {
                              if (pw != null) passwordController.text = pw;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Statement PDF Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonTeal,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              final pwd = passwordController.text.trim();
                              if (selectedCardId == null || pwd.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select card and enter password',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await _storage.write(
                                key: 'card_password_$selectedCardId',
                                value: pwd,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'PDF statement password saved securely',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Save Password'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    String currentType = 'expense';
    final newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Categories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Expense', style: TextStyle(fontSize: 12)),
                              selected: currentType == 'expense',
                              selectedColor: AppColors.neonPurple.withOpacity(0.2),
                              checkmarkColor: AppColors.neonPurple,
                              labelStyle: TextStyle(
                                color: currentType == 'expense' ? AppColors.neonPurple : Colors.white70,
                                fontWeight: currentType == 'expense' ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => currentType = 'expense');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Income', style: TextStyle(fontSize: 12)),
                              selected: currentType == 'income',
                              selectedColor: AppColors.neonEmerald.withOpacity(0.2),
                              checkmarkColor: AppColors.neonEmerald,
                              labelStyle: TextStyle(
                                color: currentType == 'income' ? AppColors.neonEmerald : Colors.white70,
                                fontWeight: currentType == 'income' ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => currentType = 'income');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                              selected: currentType == 'transfer',
                              selectedColor: AppColors.neonTeal.withOpacity(0.2),
                              checkmarkColor: AppColors.neonTeal,
                              labelStyle: TextStyle(
                                color: currentType == 'transfer' ? AppColors.neonTeal : Colors.white70,
                                fontWeight: currentType == 'transfer' ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => currentType = 'transfer');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.neonTeal));
                          }
                          final prefs = snapshot.data!;
                          final key = 'categories_$currentType';
                          final defaultCats = currentType == 'expense'
                              ? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Investment', 'Health', 'Education', 'Other']
                              : (currentType == 'income'
                                  ? ['Salary', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other']
                                  : ['Internal transfer', 'Credit card payment', 'Other']);
                          final cats = prefs.getStringList(key) ?? defaultCats;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: cats.length,
                                  itemBuilder: (context, index) {
                                    final cat = cats[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(cat, style: const TextStyle(fontSize: 14)),
                                      trailing: cat.toLowerCase() == 'other' || cat.toLowerCase() == 'others'
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                              onPressed: () async {
                                                final updated = List<String>.from(cats)..removeAt(index);
                                                await prefs.setStringList(key, updated);
                                                setState(() {});
                                              },
                                            ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: newCategoryController,
                                      decoration: const InputDecoration(
                                        hintText: 'New category name',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.neonTeal, size: 28),
                                    onPressed: () async {
                                      final newCat = newCategoryController.text.trim();
                                      if (newCat.isNotEmpty && !cats.contains(newCat)) {
                                        final updated = List<String>.from(cats)..add(newCat);
                                        // Keep "Other" at the end if it's there
                                        if (updated.contains('Other')) {
                                          updated.remove('Other');
                                          updated.add('Other');
                                        }
                                        await prefs.setStringList(key, updated);
                                        newCategoryController.clear();
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHuggingFaceDialog(BuildContext context) {
    final tokenController = TextEditingController();
    _storage
        .read(key: 'huggingface_token')
        .then((val) => tokenController.text = val ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HuggingFace Token',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your HuggingFace API key to download gated models.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      labelText: 'HuggingFace Token',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          await _storage.write(
                            key: 'huggingface_token',
                            value: tokenController.text.trim(),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('HuggingFace Token saved.'),
                            ),
                          );
                        },
                        child: const Text('Save Token'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _authenticateUserForClear(BuildContext context) async {
    final auth = LocalAuthentication();
    try {
      final isAvailable =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      final bioEnabled =
          await _storage.read(key: 'settings_biometrics') ?? 'true';
      if (isAvailable && bioEnabled == 'true') {
        final didAuth = await auth.authenticate(
          localizedReason:
              'Confirm authentication to permanently delete all data',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (didAuth) return true;
      }
    } catch (e) {
      print('Biometrics failed: $e');
    }

    // Fallback to PIN dialog
    final storedPin = await _storage.read(key: 'settings_backup_pin') ?? '1234';
    final pinController = TextEditingController();

    final pinMatched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.neonPurple,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Backup PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter your 4-digit security PIN to authorize database wipe.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 12,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonTeal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          if (pinController.text.trim() == storedPin) {
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Incorrect PIN. Please try again.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return pinMatched ?? false;
  }

  void _showClearDataConfirmDialog(
    BuildContext context, {
    String type = 'all',
  }) {
    final textController = TextEditingController();
    bool canDelete = false;

    String title = 'Erase All Data';
    String warning =
        'This will permanently delete all transactions, credit cards, active loans, and portfolios from this device. This operation cannot be undone.';
    if (type == 'transactions') {
      title = 'Clear All Transactions';
      warning =
          'This will permanently delete all transaction history from this device. Your cards and bank accounts will remain intact.';
    } else if (type == 'loans') {
      title = 'Clear All Debts & Loans';
      warning =
          'This will permanently delete all active loans and debtor/creditor ledgers. Your cards and bank accounts will remain intact.';
    } else if (type == 'sync_history') {
      title = 'Reset Sync History';
      warning =
          'This will clear all records of skipped/ignored messages and delete the last sync timestamps for all accounts. The next sync will perform a complete scan from the beginning.';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: Theme.of(stateContext).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        warning,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Type the word CLEAR below in uppercase to confirm:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'CLEAR',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            canDelete = val == 'CLEAR';
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canDelete
                                  ? Colors.redAccent
                                  : Colors.redAccent.withOpacity(0.2),
                              foregroundColor: canDelete
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: !canDelete
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    Navigator.pop(
                                      dialogContext,
                                    ); // Close confirm dialog

                                    // Trigger security authentication layer
                                    final authenticated =
                                        await _authenticateUserForClear(
                                          context,
                                        );
                                    if (authenticated) {
                                      // Clear DB based on type
                                      if (type == 'sync_history') {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.remove('skipped_sms_messages');

                                        await _storage.delete(key: 'last_sms_sync_time');
                                        await _storage.delete(key: 'last_email_sync_time');
                                        final accounts = await ref.read(googleSyncServiceProvider).getLinkedAccounts();
                                        for (var acc in accounts) {
                                          await _storage.delete(key: 'last_gmail_sync_time_${acc.email}');
                                        }

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Sync history and skipped messages cleared successfully!'),
                                            backgroundColor: AppColors.neonEmerald,
                                          ),
                                        );
                                      } else if (type == 'transactions') {
                                        await ref
                                            .read(databaseServiceProvider)
                                            .clearAllTransactions();
                                        await _storage.delete(
                                          key: 'last_sms_sync_time',
                                        );
                                        await _storage.delete(
                                          key: 'last_email_sync_time',
                                        );
                                        ref
                                            .read(transactionsProvider.notifier)
                                            .loadTransactions();
                                        ref
                                            .read(creditCardsProvider.notifier)
                                            .loadCreditCards();
                                        ref
                                            .read(bankAccountsProvider.notifier)
                                            .loadBankAccounts();
                                      } else if (type == 'loans') {
                                        await ref
                                            .read(databaseServiceProvider)
                                            .clearAllLoans();
                                        ref
                                            .read(loansProvider.notifier)
                                            .loadLoans();
                                      } else {
                                        await ref
                                            .read(databaseServiceProvider)
                                            .clearAllData();
                                        await _storage.delete(
                                          key: 'last_sms_sync_time',
                                        );
                                        await _storage.delete(
                                          key: 'last_email_sync_time',
                                        );
                                        ref
                                            .read(transactionsProvider.notifier)
                                            .loadTransactions();
                                        ref
                                            .read(creditCardsProvider.notifier)
                                            .loadCreditCards();
                                        ref
                                            .read(bankAccountsProvider.notifier)
                                            .loadBankAccounts();
                                        ref
                                            .read(loansProvider.notifier)
                                            .loadLoans();
                                        ref
                                            .read(holdingsProvider.notifier)
                                            .loadHoldings();
                                      }

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Selected data successfully cleared from the database.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Authentication failed. Data was not deleted.',
                                          ),
                                          backgroundColor: Colors.orangeAccent,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text(
                              'Authenticate & Delete',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoogleAccountsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return FutureBuilder<List<LinkedGoogleAccount>>(
              future: ref.read(googleSyncServiceProvider).getLinkedAccounts(),
              builder: (context, snapshot) {
                final accounts = snapshot.data ?? [];
                final primary = accounts.firstWhere(
                  (e) => e.isPrimary,
                  orElse: () =>
                      LinkedGoogleAccount(email: 'Not Linked', isPrimary: true),
                );
                final secondaries = accounts
                    .where((e) => !e.isPrimary)
                    .toList();

                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassBlur(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_tree_rounded,
                                color: AppColors.neonTeal,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Linked Google Accounts',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Primary backup section
                          const Text(
                            'PRIMARY SYNC & BACKUP ACCOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassBlur(
                            borderRadius: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          primary.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          primary.email == 'Not Linked'
                                              ? 'Sync and Cloud Backup disabled'
                                              : 'Sync & backups enabled',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: primary.email == 'Not Linked'
                                                ? Colors.redAccent
                                                : AppColors.neonEmerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (primary.email == 'Not Linked')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neonTeal,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final acc = await ref
                                              .read(googleSyncServiceProvider)
                                              .authenticateAccount(true);
                                          if (acc != null) {
                                            setState(() {});
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Google Sign-In failed: $e',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        'Link',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: AppColors.neonTeal,
                                      ),
                                      onPressed: () async {
                                        final error = await ref
                                            .read(googleSyncServiceProvider)
                                            .backupToCloud(
                                              ref.read(databaseServiceProvider),
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              error == null
                                                  ? 'Backup saved successfully to Google Drive'
                                                  : 'Backup failed: $error',
                                            ),
                                            backgroundColor: error == null
                                                ? AppColors.neonEmerald
                                                : Colors.redAccent,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.sync_rounded,
                                        color: AppColors.neonTeal,
                                      ),
                                      onPressed: () async {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Checking cloud backup status...',
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                        try {
                                          final restored = await ref
                                              .read(googleSyncServiceProvider)
                                              .syncOnStartup(
                                                ref.read(
                                                  databaseServiceProvider,
                                                ),
                                              );
                                          if (restored) {
                                            ref
                                                .read(
                                                  transactionsProvider.notifier,
                                                )
                                                .loadTransactions();
                                            ref
                                                .read(
                                                  creditCardsProvider.notifier,
                                                )
                                                .loadCreditCards();
                                            ref
                                                .read(
                                                  bankAccountsProvider.notifier,
                                                )
                                                .loadBankAccounts();
                                            ref
                                                .read(loansProvider.notifier)
                                                .loadLoans();
                                            ref
                                                .read(holdingsProvider.notifier)
                                                .loadHoldings();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Sync completed. Newer data restored from Google Drive.',
                                                ),
                                                backgroundColor:
                                                    AppColors.neonEmerald,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Your database is already in sync with Google Drive.',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Sync failed: $e'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cloud_download_rounded,
                                        color: AppColors.neonPurple,
                                      ),
                                      onPressed: () async {
                                        final error = await ref
                                            .read(googleSyncServiceProvider)
                                            .restoreFromCloud(
                                              ref.read(databaseServiceProvider),
                                            );
                                        if (error == null) {
                                          ref
                                              .read(
                                                transactionsProvider.notifier,
                                              )
                                              .loadTransactions();
                                          ref
                                              .read(
                                                creditCardsProvider.notifier,
                                              )
                                              .loadCreditCards();
                                          ref
                                              .read(
                                                bankAccountsProvider.notifier,
                                              )
                                              .loadBankAccounts();
                                          ref
                                              .read(loansProvider.notifier)
                                              .loadLoans();
                                          ref
                                              .read(holdingsProvider.notifier)
                                              .loadHoldings();
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              error == null
                                                  ? 'Database restored from Google Drive'
                                                  : 'Restore failed: $error',
                                            ),
                                            backgroundColor: error == null
                                                ? AppColors.neonEmerald
                                                : Colors.redAccent,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.logout_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(googleSyncServiceProvider)
                                            .removeAccount(primary.email);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Secondary accounts section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SECONDARY SCANNING ACCOUNTS',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColors.neonTeal,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  try {
                                    final acc = await ref
                                        .read(googleSyncServiceProvider)
                                        .authenticateAccount(false);
                                    if (acc != null) {
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Google Sign-In failed: $e',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (secondaries.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No secondary emails linked.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 120),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: secondaries.length,
                                itemBuilder: (context, index) {
                                  final sec = secondaries[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: GlassBlur(
                                      borderRadius: 10,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sec.email,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () async {
                                                await ref
                                                    .read(
                                                      googleSyncServiceProvider,
                                                    )
                                                    .removeAccount(sec.email);
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: AppColors.neonTeal),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _triggerAccountSync(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircularProgressIndicator(color: AppColors.neonTeal),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Checking for new transactions...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final review = await _storage.read(key: 'settings_interactive_review') ?? 'false';
      final bool interactiveReview = review == 'true';

      if (interactiveReview) {
        List<Map<String, dynamic>> itemsForReview = [];
        if (Platform.isAndroid) {
          itemsForReview = await ref.read(smsSyncServiceProvider).fetchNewSmsForReview();
        }

        Navigator.pop(context); // Close loading dialog

        if (itemsForReview.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new transactions found to review!'),
            ),
          );
        } else {
          _showSyncReviewDialog(context, itemsForReview);
        }
      } else {
        int smsCount = 0;
        if (Platform.isAndroid) {
          smsCount = await ref.read(smsSyncServiceProvider).syncSmsInbox();
        }

        int emailCount = 0;
        final parsedTxs = await ref
            .read(googleSyncServiceProvider)
            .syncTransactionsFromGmail(ref.read(databaseServiceProvider));
        emailCount = parsedTxs.length;

        // Reload database providers
        ref.read(transactionsProvider.notifier).loadTransactions();
        ref.read(creditCardsProvider.notifier).loadCreditCards();
        ref.read(loansProvider.notifier).loadLoans();

        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync Complete! Imported $smsCount SMS alerts & $emailCount email transactions.',
            ),
            backgroundColor: AppColors.neonEmerald.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSyncReviewDialog(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    int currentIndex = 0;
    int importedCount = 0;
    int skippedCount = 0;

    final parser = SmsParserService();
    final Map<int, ParsedSmsTransaction?> regexCache = {};
    final Map<int, ParsedSmsTransaction?> geminiCache = {};
    final Map<int, bool> geminiLoading = {};
    final Map<int, bool> forceGemini = {};
    final Map<int, bool> disagreed = {};

    int? lastInitializedIndex;
    ParsedSmsTransaction? lastGemini;
    ParsedSmsTransaction? lastRegex;

    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Other';
    String selectedAccount = 'Cash';

    // State for payback and repayments
    bool isPayback = false;
    final paybackContactController = TextEditingController();
    DateTime paybackDate = DateTime.now().add(const Duration(days: 30));
    int? selectedDebtId;
    String selectedToAccount = 'Cash';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            if (currentIndex >= items.length) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: GlassBlur(
                  borderRadius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.neonEmerald,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sync Review Finished!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Imported: $importedCount\nSkipped: $skippedCount',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            const storage = FlutterSecureStorage();
                            await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                            ref.read(transactionsProvider.notifier).loadTransactions();
                            ref.read(creditCardsProvider.notifier).loadCreditCards();
                            ref.read(loansProvider.notifier).loadLoans();
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonTeal,
                          ),
                          child: const Text('Back to Settings', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final item = items[currentIndex];
            final String rawBody = item['body'] ?? '';
            final DateTime date = item['date'] ?? DateTime.now();

            final cardsState = ref.watch(creditCardsProvider);
            final bankAccountsState = ref.watch(bankAccountsProvider);
            final loansState = ref.watch(loansProvider);

            void ensureParsed(int index) {
              if (index < 0 || index >= items.length) return;
              final bodyText = items[index]['body'] as String;
              final isApproved = items[index]['approvedByRegex'] ?? false;

              if (!regexCache.containsKey(index)) {
                regexCache[index] = parser.parseRegexOnly(bodyText);
              }

              final shouldCallGemini = isApproved || (forceGemini[index] ?? false);

              if (index == currentIndex && shouldCallGemini && !geminiCache.containsKey(index) && !(geminiLoading[index] ?? false)) {
                geminiLoading[index] = true;
                final activeCards = cardsState.valueOrNull;
                final activeBanks = bankAccountsState.valueOrNull;
                parser.parseGeminiOnly(bodyText, cards: activeCards, bankAccounts: activeBanks).then((geminiResult) {
                  if (geminiResult != null) {
                    setState(() {
                      geminiCache[index] = geminiResult;
                      geminiLoading[index] = false;
                      if (lastInitializedIndex != currentIndex) {
                        isPayback = false;
                        paybackContactController.clear();
                        paybackDate = DateTime.now().add(const Duration(days: 30));
                        selectedDebtId = null;
                        selectedToAccount = 'Cash';
                      }
                      
                      if (currentIndex == index) {
                        amountController.text = geminiResult.amount.toStringAsFixed(0);
                        merchantController.text = geminiResult.merchant;
                        selectedType = geminiResult.transactionType;
                        selectedCategory = geminiResult.category;
                        if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
                        const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
                        if (!allowedCategories.contains(selectedCategory)) {
                          selectedCategory = 'Other';
                        }

                        selectedAccount = 'Cash';
                        if (geminiResult.matchedAccountId != null) {
                          selectedAccount = geminiResult.matchedAccountId!;
                        } else {
                          final bodyLower = bodyText.toLowerCase();
                          if (bodyLower.contains('hdfc')) {
                            cardsState.whenData((cards) {}); // just force reload
                            bankAccountsState.whenData((banks) {
                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                              if (match.id != Isar.autoIncrement) {
                                selectedAccount = 'bank:${match.id}';
                              }
                            });
                          } else if (bodyLower.contains('sbi')) {
                            bankAccountsState.whenData((banks) {
                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                              if (match.id != Isar.autoIncrement) {
                                selectedAccount = 'bank:${match.id}';
                              }
                            });
                          }
                          
                          if (selectedAccount == 'Cash') {
                            if (geminiResult.cardLast4 != null) {
                              cardsState.whenData((cards) {
                                final match = cards.firstWhere((c) => c.last4 == geminiResult.cardLast4, orElse: () => CreditCard());
                                if (match.id != Isar.autoIncrement) {
                                  selectedAccount = 'card:${match.id}';
                                }
                              });
                            } else if (geminiResult.accountLast4 != null) {
                              bankAccountsState.whenData((banks) {
                                final match = banks.firstWhere((b) => b.last4 == geminiResult.accountLast4, orElse: () => BankAccount());
                                if (match.id != Isar.autoIncrement) {
                                  selectedAccount = 'bank:${match.id}';
                                }
                              });
                            }
                          }
                        }
                      }
                    });
                  } else {
                    setState(() {
                      geminiLoading[index] = false;
                    });
                  }
                }).catchError((e) {
                  setState(() {
                    geminiLoading[index] = false;
                  });
                  parser.logDebug('Gemini parse error: $e');
                });
              }
            }

            ensureParsed(currentIndex);
            ensureParsed(currentIndex + 1);
            ensureParsed(currentIndex + 2);

            final regexResult = regexCache[currentIndex];
            final geminiResult = geminiCache[currentIndex];

            if (lastInitializedIndex != currentIndex || lastGemini != geminiResult || lastRegex != regexResult) {
              if (lastInitializedIndex != currentIndex) {
                isPayback = false;
                paybackContactController.clear();
                paybackDate = DateTime.now().add(const Duration(days: 30));
                selectedDebtId = null;
                selectedToAccount = 'Cash';
              }
              lastInitializedIndex = currentIndex;
              lastGemini = geminiResult;
              lastRegex = regexResult;

              final initialSource = geminiResult ?? regexResult;
              amountController.text = (initialSource?.amount ?? 0.0).toStringAsFixed(0);
              merchantController.text = initialSource?.merchant ?? 'Unknown Merchant';
              selectedType = initialSource?.transactionType ?? 'expense';
              selectedCategory = initialSource?.category ?? 'Other';
              if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
              const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
              if (!allowedCategories.contains(selectedCategory)) {
                selectedCategory = 'Other';
              }

              selectedAccount = 'Cash';
              if (initialSource?.matchedAccountId != null) {
                selectedAccount = initialSource!.matchedAccountId!;
              } else {
                final bodyLower = rawBody.toLowerCase();
                if (bodyLower.contains('hdfc')) {
                  bankAccountsState.whenData((banks) {
                    final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                    if (match.id != Isar.autoIncrement) {
                      selectedAccount = 'bank:${match.id}';
                    }
                  });
                } else if (bodyLower.contains('sbi')) {
                  bankAccountsState.whenData((banks) {
                    final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                    if (match.id != Isar.autoIncrement) {
                      selectedAccount = 'bank:${match.id}';
                    }
                  });
                }

                if (selectedAccount == 'Cash') {
                  final last4 = initialSource?.cardLast4 ?? initialSource?.accountLast4;
                  if (last4 != null) {
                    if (initialSource?.cardLast4 != null) {
                      cardsState.whenData((cards) {
                        final match = cards.firstWhere((c) => c.last4 == last4, orElse: () => CreditCard());
                        if (match.id != Isar.autoIncrement) {
                          selectedAccount = 'card:${match.id}';
                        }
                      });
                    } else {
                      bankAccountsState.whenData((banks) {
                        final match = banks.firstWhere((b) => b.last4 == last4, orElse: () => BankAccount());
                        if (match.id != Isar.autoIncrement) {
                          selectedAccount = 'bank:${match.id}';
                        }
                      });
                    }
                  }
                }
              }
            }

            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, prefsSnapshot) {
                if (!prefsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonTeal));
                }
                final prefs = prefsSnapshot.data!;
                final expenseCats = prefs.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Investment', 'Health', 'Education', 'Other'];
                final incomeCats = prefs.getStringList('categories_income') ?? ['Salary', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other'];
                final transferCats = prefs.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Other'];

                final currentCats = selectedType == 'expense'
                    ? expenseCats
                    : (selectedType == 'income' ? incomeCats : transferCats);

                if (!currentCats.contains(selectedCategory)) {
                  if (currentCats.contains('Other')) {
                    selectedCategory = 'Other';
                  } else if (currentCats.isNotEmpty) {
                    selectedCategory = currentCats.first;
                  } else {
                    selectedCategory = '';
                  }
                }

                List<DropdownMenuItem<String>> buildDropdownItems(String valueToVerify) {
                  final List<DropdownMenuItem<String>> menu = [
                    const DropdownMenuItem(
                      value: 'Cash',
                      child: Text('Cash', overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ];
                  bankAccountsState.maybeWhen(
                    data: (banks) {
                      menu.addAll(banks.map((b) => DropdownMenuItem(
                        value: 'bank:${b.id}',
                        child: Text(b.bankName, overflow: TextOverflow.ellipsis, maxLines: 1),
                      )));
                    },
                    orElse: () {},
                  );
                  cardsState.maybeWhen(
                    data: (cards) {
                      menu.addAll(cards.map((c) => DropdownMenuItem(
                        value: 'card:${c.id}',
                        child: Text(c.cardName, overflow: TextOverflow.ellipsis, maxLines: 1),
                      )));
                    },
                    orElse: () {},
                  );
                  final hasSel = menu.any((item) => item.value == valueToVerify);
                  if (!hasSel) {
                    menu.add(
                      DropdownMenuItem(
                        value: valueToVerify,
                        child: Text(
                          valueToVerify.startsWith('bank:')
                              ? 'Deleted Bank Account'
                              : valueToVerify.startsWith('card:')
                                  ? 'Deleted Card'
                                  : valueToVerify,
                        ),
                      ),
                    );
                  }
                  return menu;
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassBlur(
                    borderRadius: 24,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Review Sync (${currentIndex + 1}/${items.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neonTeal,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['source'] == 'sms' ? '📱 SMS' : '📧 Email',
                                style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald : Colors.redAccent,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (item['approvedByRegex'] ?? false) ? 'Regex: Approved' : 'Regex: Rejected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald : Colors.redAccent,
                                ),
                              ),
                            ),
                            if (!(item['approvedByRegex'] ?? false) && !(forceGemini[currentIndex] ?? false) && geminiCache[currentIndex] == null) ...[
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    forceGemini[currentIndex] = true;
                                  });
                                  parser.logDebug('Manual Gemini request triggered for index $currentIndex: "$rawBody"');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonTeal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.neonTeal, width: 1),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 10, color: AppColors.neonTeal),
                                      SizedBox(width: 4),
                                      Text(
                                        'Run Gemini anyway',
                                        style: TextStyle(fontSize: 10, color: AppColors.neonTeal, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Raw Message Context:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              rawBody,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (!(item['approvedByRegex'] ?? false) && !(disagreed[currentIndex] ?? false)) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This message was classified as Non-Transactional (like an OTP, alert, or spam). Do you agree?',
                                    style: TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  parser.logDebug('Agreed with rejection (Spam/Non-Tx) for index $currentIndex: "$rawBody"');
                                  final prefs = await SharedPreferences.getInstance();
                                  final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
                                  if (!skippedList.contains(rawBody)) {
                                    skippedList.add(rawBody);
                                    await prefs.setStringList('skipped_sms_messages', skippedList);
                                  }
                                  setState(() {
                                    skippedCount++;
                                    currentIndex++;
                                  });
                                },
                                icon: const Icon(Icons.check_circle_outline, color: AppColors.neonEmerald, size: 14),
                                label: const Text('Agree (Reject)', style: TextStyle(color: AppColors.neonEmerald, fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.neonEmerald),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  parser.logDebug('Disagreed with rejection (Message is transaction) for index $currentIndex: "$rawBody"');
                                  setState(() {
                                    disagreed[currentIndex] = true;
                                    forceGemini[currentIndex] = true;
                                  });
                                },
                                icon: const Icon(Icons.close_rounded, color: Colors.black, size: 14),
                                label: const Text('Disagree (Approve)', style: TextStyle(color: Colors.black, fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                        if (geminiLoading[currentIndex] ?? false)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Gemini AI parsing in background...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.neonTeal,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        if (regexResult != null || geminiResult != null)
                          Row(
                            children: [
                              if (regexResult != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      amountController.text = regexResult.amount.toStringAsFixed(0);
                                      merchantController.text = regexResult.merchant;
                                      setState(() {
                                        selectedType = regexResult.transactionType;
                                        selectedCategory = regexResult.category;
                                        if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
                                        const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
                                        if (!allowedCategories.contains(selectedCategory)) {
                                          selectedCategory = 'Other';
                                        }

                                        selectedAccount = 'Cash';
                                        if (regexResult.matchedAccountId != null) {
                                          selectedAccount = regexResult.matchedAccountId!;
                                        } else {
                                          final bodyLower = rawBody.toLowerCase();
                                          if (bodyLower.contains('hdfc')) {
                                            bankAccountsState.whenData((banks) {
                                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                                              if (match.id != Isar.autoIncrement) {
                                                selectedAccount = 'bank:${match.id}';
                                              }
                                            });
                                          } else if (bodyLower.contains('sbi')) {
                                            bankAccountsState.whenData((banks) {
                                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                                              if (match.id != Isar.autoIncrement) {
                                                selectedAccount = 'bank:${match.id}';
                                              }
                                            });
                                          }

                                          if (selectedAccount == 'Cash') {
                                            final last4 = regexResult.cardLast4 ?? regexResult.accountLast4;
                                            if (last4 != null) {
                                              if (regexResult.cardLast4 != null) {
                                                cardsState.whenData((cards) {
                                                  final match = cards.firstWhere((c) => c.last4 == last4, orElse: () => CreditCard());
                                                  if (match.id != Isar.autoIncrement) {
                                                    selectedAccount = 'card:${match.id}';
                                                  }
                                                });
                                              } else {
                                                bankAccountsState.whenData((banks) {
                                                  final match = banks.firstWhere((b) => b.last4 == last4, orElse: () => BankAccount());
                                                  if (match.id != Isar.autoIncrement) {
                                                    selectedAccount = 'bank:${match.id}';
                                                  }
                                                });
                                              }
                                            }
                                          }
                                        }
                                      });
                                    },
                                    child: const Text('Use Regex Guess', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              if (geminiResult != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      amountController.text = geminiResult.amount.toStringAsFixed(0);
                                      merchantController.text = geminiResult.merchant;
                                      setState(() {
                                        selectedType = geminiResult.transactionType;
                                        selectedCategory = geminiResult.category;
                                        if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
                                        const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
                                        if (!allowedCategories.contains(selectedCategory)) {
                                          selectedCategory = 'Other';
                                        }

                                        selectedAccount = 'Cash';
                                        if (geminiResult.matchedAccountId != null) {
                                          selectedAccount = geminiResult.matchedAccountId!;
                                        } else {
                                          final bodyLower = rawBody.toLowerCase();
                                          if (bodyLower.contains('hdfc')) {
                                            bankAccountsState.whenData((banks) {
                                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                                              if (match.id != Isar.autoIncrement) {
                                                selectedAccount = 'bank:${match.id}';
                                              }
                                            });
                                          } else if (bodyLower.contains('sbi')) {
                                            bankAccountsState.whenData((banks) {
                                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                                              if (match.id != Isar.autoIncrement) {
                                                selectedAccount = 'bank:${match.id}';
                                              }
                                            });
                                          }

                                          if (selectedAccount == 'Cash') {
                                            if (geminiResult.cardLast4 != null) {
                                              cardsState.whenData((cards) {
                                                final match = cards.firstWhere((c) => c.last4 == geminiResult.cardLast4, orElse: () => CreditCard());
                                                if (match.id != Isar.autoIncrement) {
                                                  selectedAccount = 'card:${match.id}';
                                                }
                                              });
                                            } else if (geminiResult.accountLast4 != null) {
                                              bankAccountsState.whenData((banks) {
                                                final match = banks.firstWhere((b) => b.last4 == geminiResult.accountLast4, orElse: () => BankAccount());
                                                if (match.id != Isar.autoIncrement) {
                                                  selectedAccount = 'bank:${match.id}';
                                                }
                                              });
                                            }
                                          }
                                        }
                                      });
                                    },
                                    child: const Text('Use Gemini Guess', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (INR)',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(),
                                ),
                                dropdownColor: AppColors.obsidianSurface,
                                items: const [
                                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                                  DropdownMenuItem(value: 'income', child: Text('Income')),
                                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: merchantController,
                          decoration: const InputDecoration(
                            labelText: 'Merchant / Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.obsidianSurface,
                          isExpanded: true,
                          items: currentCats.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Account Selection (Dual for Transfer, Single for other types)
                        if (selectedType == 'transfer') ...[
                          DropdownButtonFormField<String>(
                            value: selectedAccount,
                            decoration: const InputDecoration(
                              labelText: 'From Account (Source)',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedAccount),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedAccount = val);
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedToAccount,
                            decoration: const InputDecoration(
                              labelText: 'To Account (Destination)',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedToAccount),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedToAccount = val);
                            },
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: selectedAccount,
                            decoration: const InputDecoration(
                              labelText: 'Account / Card',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppColors.obsidianSurface,
                            isExpanded: true,
                            items: buildDropdownItems(selectedAccount),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedAccount = val);
                            },
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Payback Toggle for Income
                        if (selectedType == 'income') ...[
                          CheckboxListTile(
                            title: const Text('Is this a borrowed loan to payback?'),
                            subtitle: const Text('Creates a debt entry in the ledger'),
                            value: isPayback,
                            activeColor: AppColors.neonEmerald,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  isPayback = val;
                                  if (val && paybackContactController.text.isEmpty) {
                                    paybackContactController.text = merchantController.text.trim();
                                  }
                                });
                              }
                            },
                          ),
                          if (isPayback) ...[
                            const SizedBox(height: 8),
                            Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final borrowedContacts = loansState.maybeWhen(
                                  data: (allLoans) => allLoans
                                      .where((l) => !l.isLent && l.remainingBalance > 0)
                                      .map((l) => l.contactName)
                                      .toSet()
                                      .toList(),
                                  orElse: () => <String>[],
                                );
                                if (textEditingValue.text.isEmpty) {
                                  return borrowedContacts;
                                }
                                return borrowedContacts.where((String option) {
                                  return option
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (String selection) {
                                paybackContactController.text = selection;
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                if (textEditingController.text != paybackContactController.text) {
                                  textEditingController.text = paybackContactController.text;
                                }
                                textEditingController.addListener(() {
                                  paybackContactController.text = textEditingController.text;
                                });
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact / Friend Name',
                                    border: OutlineInputBorder(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payback Date', style: TextStyle(color: Colors.white70)),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: paybackDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.neonEmerald,
                                              onPrimary: Colors.black,
                                              surface: AppColors.obsidianSurface,
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() => paybackDate = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today_rounded, color: AppColors.neonEmerald, size: 16),
                                  label: Text(
                                    '${paybackDate.day}/${paybackDate.month}/${paybackDate.year}',
                                    style: const TextStyle(color: AppColors.neonEmerald, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        // Repay Debt Selector for Expense / Transfer
                        if (selectedType == 'expense' || selectedType == 'transfer') ...[
                          loansState.maybeWhen(
                            data: (allLoans) {
                              final borrowedDebts = allLoans.where((l) => !l.isLent && l.remainingBalance > 0).toList();
                              if (borrowedDebts.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<int?>(
                                    value: selectedDebtId,
                                    decoration: const InputDecoration(
                                      labelText: 'Link to repay active debt?',
                                      border: OutlineInputBorder(),
                                    ),
                                    dropdownColor: AppColors.obsidianSurface,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Do not link to a debt'),
                                      ),
                                      ...borrowedDebts.map((loan) => DropdownMenuItem<int?>(
                                        value: loan.id,
                                        child: Text('${loan.contactName} (Remaining: ₹${loan.remainingBalance.toStringAsFixed(0)})'),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => selectedDebtId = val);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showFlagKeywordsDialog(context, rawBody);
                              },
                              icon: const Icon(Icons.flag_rounded, color: Colors.orangeAccent, size: 16),
                              label: const Text(
                                'Mark Wrong / Flags',
                                style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    parser.logDebug('Skip clicked for index $currentIndex. Raw body: "$rawBody"');
                                    final prefs = await SharedPreferences.getInstance();
                                    final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
                                    if (!skippedList.contains(rawBody)) {
                                      skippedList.add(rawBody);
                                      await prefs.setStringList('skipped_sms_messages', skippedList);
                                    }
                                    setState(() {
                                      skippedCount++;
                                      currentIndex++;
                                    });
                                  },
                                  child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final double amt = double.tryParse(amountController.text) ?? 0.0;
                                    final merchant = merchantController.text.trim();

                                    final tx = Transaction()
                                      ..amount = amt
                                      ..description = selectedType == 'income' ? 'Received from $merchant' : 'Spent at $merchant'
                                      ..transactionType = selectedType
                                      ..category = selectedCategory
                                      ..timestamp = date
                                      ..source = item['source'] ?? 'sms'
                                      ..parserSource = geminiResult != null ? 'gemini' : 'regex'
                                      ..rawMessage = rawBody;

                                    if (selectedType == 'transfer') {
                                      tx.accountName = selectedAccount;
                                      if (selectedToAccount.startsWith('card:')) {
                                        tx.cardId = selectedToAccount.substring(5);
                                      } else if (selectedToAccount.startsWith('bank:')) {
                                        tx.cardId = selectedToAccount;
                                      } else {
                                        tx.cardId = null;
                                      }
                                    } else {
                                      if (selectedAccount.startsWith('card:')) {
                                        tx.cardId = selectedAccount.substring(5);
                                        tx.accountName = 'Credit Card';
                                      } else {
                                        tx.cardId = null;
                                        tx.accountName = selectedAccount;
                                      }
                                    }

                                    if (selectedType == 'income' && isPayback) {
                                      final contact = paybackContactController.text.trim();
                                      if (contact.isNotEmpty) {
                                        final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                        try {
                                          final existing = allLoans.firstWhere(
                                            (l) => !l.isLent && l.remainingBalance > 0 && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                          );
                                          existing.amount += amt;
                                          existing.remainingBalance += amt;
                                          existing.paybackDate = paybackDate;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                          tx.linkedLoanId = savedId;
                                        } catch (_) {
                                          final loan = Loan()
                                            ..contactName = contact
                                            ..isLent = false // borrowed debt
                                            ..amount = amt
                                            ..remainingBalance = amt
                                            ..startDate = DateTime.now()
                                            ..paybackDate = paybackDate
                                            ..interestRate = 0.0
                                            ..compoundInterval = 'none'
                                            ..emiAmount = 0.0;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                          tx.linkedLoanId = savedId;
                                        }
                                      }
                                    }

                                    if ((selectedType == 'expense' || selectedType == 'transfer') && selectedDebtId != null) {
                                      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                      try {
                                        final target = allLoans.firstWhere((l) => l.id == selectedDebtId);
                                        target.remainingBalance = (target.remainingBalance - amt).clamp(0.0, double.infinity);
                                        await ref.read(loansProvider.notifier).addLoan(target);
                                      } catch (_) {}
                                      tx.linkedLoanId = selectedDebtId;
                                    }

                                    await ref.read(transactionsProvider.notifier).addTransaction(tx);

                                    parser.logDebug('Approve clicked for index $currentIndex. Parsed: Amount=$amt, Merchant="$merchant", Type="$selectedType", Category="$selectedCategory", Account="$selectedAccount", Source="${geminiResult != null ? "gemini" : "regex"}". Raw body: "$rawBody"');
                                    setState(() {
                                      importedCount++;
                                      currentIndex++;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonEmerald),
                                  child: const Text('Approve', style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  },
);
}

  void _showFlagKeywordsDialog(BuildContext context, String rawBody) {
    final flagController = TextEditingController();
    final parser = SmsParserService();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parser Tuning & Logs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonTeal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add keywords to train the Regex parser. Red flags exclude similar messages (e.g. OTPs). Green flags force match them.',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: flagController,
                    decoration: const InputDecoration(
                      labelText: 'Keyword / Phrase',
                      hintText: 'e.g. "otp", "pre-approved"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final word = flagController.text.trim().toLowerCase();
                          if (word.isEmpty) return;

                          final prefs = await SharedPreferences.getInstance();
                          final list = prefs.getStringList('custom_red_flags') ?? [];
                          if (!list.contains(word)) {
                            list.add(word);
                            await prefs.setStringList('custom_red_flags', list);
                          }
                          await parser.logDebug('Added Red Flag keyword: "$word" for message: "$rawBody"');
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added Red Flag: "$word"'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Add Red Flag', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final word = flagController.text.trim().toLowerCase();
                          if (word.isEmpty) return;

                          final prefs = await SharedPreferences.getInstance();
                          final list = prefs.getStringList('custom_green_flags') ?? [];
                          if (!list.contains(word)) {
                            list.add(word);
                            await prefs.setStringList('custom_green_flags', list);
                          }
                          await parser.logDebug('Added Green Flag keyword: "$word" for message: "$rawBody"');
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added Green Flag: "$word"'),
                              backgroundColor: AppColors.neonEmerald,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonEmerald),
                        child: const Text('Add Green Flag', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApiKeysDialog(BuildContext context) {
    final geminiController = TextEditingController();
    final openaiController = TextEditingController();
    final ollamaController = TextEditingController(
      text: 'http://localhost:11434',
    );

    // Pre-populate if exists
    _storage
        .read(key: 'ai_gemini_key')
        .then((val) => geminiController.text = val ?? '');
    _storage
        .read(key: 'ai_openai_key')
        .then((val) => openaiController.text = val ?? '');
    _storage
        .read(key: 'ai_ollama_host')
        .then((val) => ollamaController.text = val ?? 'http://localhost:11434');

    showDialog(
      context: context,
      builder: (context) {
        bool obscureGemini = true;
        bool obscureOpenAI = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Advisor API Keys',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Provide keys for local Ollama host or cloud API fallbacks. Stored securely on-device.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ollamaController,
                      decoration: const InputDecoration(
                        labelText: 'Local Ollama Host',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: geminiController,
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureGemini ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () async {
                            if (obscureGemini) {
                              final LocalAuthentication auth = LocalAuthentication();
                              final bool didAuthenticate = await auth.authenticate(
                                localizedReason: 'Please authenticate to view API Key',
                                options: const AuthenticationOptions(biometricOnly: false),
                              );
                              if (didAuthenticate) {
                                setState(() {
                                  obscureGemini = false;
                                });
                              }
                            } else {
                              setState(() {
                                obscureGemini = true;
                              });
                            }
                          },
                        ),
                      ),
                      obscureText: obscureGemini,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: openaiController,
                      decoration: InputDecoration(
                        labelText: 'OpenAI API Key (Optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOpenAI ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () async {
                            if (obscureOpenAI) {
                              final LocalAuthentication auth = LocalAuthentication();
                              final bool didAuthenticate = await auth.authenticate(
                                localizedReason: 'Please authenticate to view API Key',
                                options: const AuthenticationOptions(biometricOnly: false),
                              );
                              if (didAuthenticate) {
                                setState(() {
                                  obscureOpenAI = false;
                                });
                              }
                            } else {
                              setState(() {
                                obscureOpenAI = true;
                              });
                            }
                          },
                        ),
                      ),
                      obscureText: obscureOpenAI,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final gemini = geminiController.text.trim();
                            final openai = openaiController.text.trim();
                            final ollama = ollamaController.text.trim();

                            if (gemini.isNotEmpty) {
                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.neonPurple,
                                  ),
                                ),
                              );

                              try {
                                final model = GenerativeModel(
                                  model: 'gemini-3.1-flash-lite',
                                  apiKey: gemini,
                                );
                                final content = [Content.text("Ping")];
                                final response = await model
                                    .generateContent(content)
                                    .timeout(const Duration(seconds: 15));
                                if (response.text == null ||
                                    response.text!.isEmpty) {
                                  throw Exception("Verification failed");
                                }
                                Navigator.pop(context); // Close loader
                              } catch (e) {
                                Navigator.pop(context); // Close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invalid Gemini API Key: ${e.toString().replaceAll('Exception: ', '')}',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                            }

                            await _storage.write(
                              key: 'ai_gemini_key',
                              value: gemini,
                            );
                            await _storage.write(
                              key: 'ai_openai_key',
                              value: openai,
                            );
                            await _storage.write(
                              key: 'ai_ollama_host',
                              value: ollama,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'AI Advisor configuration saved locally',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Save Keys'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSyncConfigDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final urlController = TextEditingController(text: 'https://');
    final userController = TextEditingController();
    final tokenController = TextEditingController();

    // Pre-populate config
    ref.read(syncServiceProvider).getSyncConfig().then((config) {
      passwordController.text = config['masterPassword'] ?? '';
      urlController.text = config['webdavUrl'] ?? 'https://';
      userController.text = config['webdavUser'] ?? '';
      tokenController.text = config['webdavPassword'] ?? '';
    });

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WebDAV Sync & Backup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'All exports are fully encrypted locally using AES-256 with your master password before upload.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Master Encryption Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV Server URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tokenController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV App Password / Token',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final pw = passwordController.text.trim();
                            final url = urlController.text.trim();
                            final user = userController.text.trim();
                            final token = tokenController.text.trim();

                            if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill master password, URL and username',
                                  ),
                                ),
                              );
                              return;
                            }

                            await ref
                                .read(syncServiceProvider)
                                .saveSyncConfig(
                                  masterPassword: pw,
                                  webdavUrl: url,
                                  webdavUser: user,
                                  webdavPassword: token,
                                );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sync configuration saved locally',
                                ),
                              ),
                            );
                          },
                          child: const Text('Save Settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.glassBorder),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.cloud_upload_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Backup Now',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonTeal,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              final pw = passwordController.text.trim();
                              final url = urlController.text.trim();
                              final user = userController.text.trim();

                              if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please configure and save settings first',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context); // close config dialog

                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.neonTeal,
                                  ),
                                ),
                              );

                              try {
                                await ref
                                    .read(syncServiceProvider)
                                    .uploadBackup();
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'AES-256 encrypted database backup uploaded successfully!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Backup failed: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.cloud_download_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Restore Now',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              final pw = passwordController.text.trim();
                              final url = urlController.text.trim();
                              final user = userController.text.trim();

                              if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please configure and save settings first',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context); // close config dialog

                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                ),
                              );

                              try {
                                await ref
                                    .read(syncServiceProvider)
                                    .restoreBackup();

                                // Reload all providers
                                await ref
                                    .read(transactionsProvider.notifier)
                                    .loadTransactions();
                                await ref
                                    .read(creditCardsProvider.notifier)
                                    .loadCreditCards();
                                await ref
                                    .read(loansProvider.notifier)
                                    .loadLoans();
                                await ref
                                    .read(holdingsProvider.notifier)
                                    .loadHoldings();

                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Encrypted backup successfully restored and database re-initialized!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Restore failed: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGeminiNanoInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            blurX: 30,
            blurY: 30,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.neonPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'On-Device LLM Preparing',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Samsung S24 Ultra supports running Gemini Nano locally on-device. Google AI Core is now preparing the model in the background.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• AI Core will automatically download model files (~1GB) in the background.\n'
                    '• Please keep your device connected to Wi-Fi and power.\n'
                    '• The local AI advisor will automatically activate as soon as the system finishes downloading the model.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Got it',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BankAccountCard extends StatefulWidget {
  final BankAccount account;
  final WidgetRef ref;
  final String Function(double) formatCurrency;
  final Function(BuildContext, WidgetRef, BankAccount) onOptionsPressed;

  const BankAccountCard({
    super.key,
    required this.account,
    required this.ref,
    required this.formatCurrency,
    required this.onOptionsPressed,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  bool _isFlipped = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.obsidianSurface,
      ),
    );
  }

  Future<void> _authenticateAndFlip() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric auth not available')),
          );
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view secure bank details',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate && mounted) {
        setState(() => _isFlipped = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = AppColors.glassCard;
    if (widget.account.colorHex.isNotEmpty) {
      try {
        cardColor = Color(
          int.parse(widget.account.colorHex.replaceFirst('#', '0xff')),
        ).withOpacity(0.18);
      } catch (_) {}
    }

    return Container(
      width: 165,
      height: 185,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onLongPress: () =>
            widget.onOptionsPressed(context, widget.ref, widget.account),
        onTap: () {
          if (!_isFlipped) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BankAccountDetailView(account: widget.account),
              ),
            );
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );
            return AnimatedBuilder(
              animation: flipAnimation,
              child: child,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..scale(flipAnimation.value, 1.0),
                  alignment: Alignment.center,
                  child: child,
                );
              },
            );
          },
          child: _isFlipped
              ? _buildBackSide(cardColor)
              : _buildFrontSide(cardColor),
        ),
      ),
    );
  }

  Widget _buildFrontSide(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.bankName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '•••• ${widget.account.last4}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.account.logoAsset.isNotEmpty)
                  SvgPicture.asset(
                    'assets/bank_logos/${widget.account.logoAsset}',
                    width: 20,
                    height: 20,
                  )
                else
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BALANCE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.formatCurrency(widget.account.balance),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_rounded,
                        color: AppColors.neonTeal,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _authenticateAndFlip,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonTeal,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isFlipped = false),
                  child: const Icon(
                    Icons.visibility_off_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildBackDetailRow('Holder', widget.account.accountHolderName),
            const SizedBox(height: 4),
            _buildBackDetailRow('A/C No', widget.account.fullAccountNumber),
            const SizedBox(height: 4),
            _buildBackDetailRow('IFSC', widget.account.ifscCode),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackDetailRow(String label, String value) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          GestureDetector(
            onTap: () => _copyToClipboard(value, label),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: AppColors.neonTeal,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class BankAccountDetailView extends ConsumerStatefulWidget {
  final BankAccount account;

  const BankAccountDetailView({super.key, required this.account});

  @override
  ConsumerState<BankAccountDetailView> createState() =>
      _BankAccountDetailViewState();
}

class _BankAccountDetailViewState extends ConsumerState<BankAccountDetailView> {
  late TextEditingController _balanceController;
  bool _isEditingBalance = false;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: widget.account.balance.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _saveBalance() async {
    final newBal = double.tryParse(_balanceController.text) ?? 0.0;
    final updatedAcc = widget.account..balance = newBal;

    await ref.read(bankAccountsProvider.notifier).updateBankAccount(updatedAcc);

    setState(() => _isEditingBalance = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance updated successfully'),
          backgroundColor: AppColors.obsidianSurface,
        ),
      );
    }
  }

  void _showBankAccountDetailsBottomSheet(
    BuildContext context,
    BankAccount account,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassBlur(
          borderRadius: 24,
          blurX: 30,
          blurY: 30,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.neonTeal,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Account Holder', account.accountHolderName),
                const SizedBox(height: 12),
                _buildDetailRow('Account Number', account.fullAccountNumber),
                const SizedBox(height: 12),
                _buildDetailRow('IFSC Code', account.ifscCode),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Balance',
                  '₹${account.balance.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SizedBox(
          height: 148,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.bankName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'A/C: •••• ${widget.account.last4}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_rounded,
                              color: AppColors.neonTeal,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final LocalAuthentication auth =
                                  LocalAuthentication();
                              try {
                                final bool canAuthenticateWithBiometrics =
                                    await auth.canCheckBiometrics;
                                final bool canAuthenticate =
                                    canAuthenticateWithBiometrics ||
                                    await auth.isDeviceSupported();
                                if (!canAuthenticate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometric auth not available',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final bool
                                didAuthenticate = await auth.authenticate(
                                  localizedReason:
                                      'Authenticate to view secure bank details',
                                  options: const AuthenticationOptions(
                                    biometricOnly: true,
                                  ),
                                );
                                if (didAuthenticate && mounted) {
                                  setState(() => _isFlipped = true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Auth error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.account.logoAsset.isNotEmpty)
                    SvgPicture.asset(
                      'assets/bank_logos/${widget.account.logoAsset}',
                      width: 32,
                      height: 32,
                    )
                  else
                    const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                ],
              ),
              const Spacer(),

              const Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (!_isEditingBalance) ...[
                    Text(
                      '₹${widget.account.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.neonTeal,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isEditingBalance = true),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.neonTeal),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.neonTeal,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.neonEmerald,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _saveBalance,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _balanceController.text = widget.account.balance
                              .toStringAsFixed(0);
                          _isEditingBalance = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SizedBox(
          height: 148,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECURE DETAILS',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonTeal,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFlipped = false),
                    child: const Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildBackDetailRow(
                'Holder Name',
                widget.account.accountHolderName,
              ),
              const SizedBox(height: 12),
              _buildBackDetailRow(
                'Account Number',
                widget.account.fullAccountNumber,
              ),
              const SizedBox(height: 12),
              _buildBackDetailRow('IFSC Code', widget.account.ifscCode),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackDetailRow(String label, String value) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.obsidianSurface,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: AppColors.neonTeal,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final txsState = ref.watch(transactionsProvider);

    Color cardColor = AppColors.glassCard;
    if (widget.account.colorHex.isNotEmpty) {
      try {
        cardColor = Color(
          int.parse(widget.account.colorHex.replaceFirst('#', '0xff')),
        ).withOpacity(0.18);
      } catch (_) {}
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Account Detail',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final flipAnimation =
                              Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              );
                          return AnimatedBuilder(
                            animation: flipAnimation,
                            child: child,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..scale(flipAnimation.value, 1.0),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                          );
                        },
                    child: _isFlipped
                        ? _buildBackCard(cardColor)
                        : _buildFrontCard(cardColor),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: txsState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.neonTeal,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (txs) {
                        final accountTxs = txs
                            .where(
                              (t) =>
                                  t.accountName == 'bank:${widget.account.id}',
                            )
                            .toList();
                        accountTxs.sort(
                          (a, b) => b.timestamp.compareTo(a.timestamp),
                        ); // recent to previous

                        if (accountTxs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No transactions associated with this bank.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: accountTxs.length,
                          itemBuilder: (context, index) {
                            final tx = accountTxs[index];
                            final isIncome = tx.transactionType == 'income';
                            final formattedAmt =
                                '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';

                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            final dateStr =
                                '${tx.timestamp.day} ${months[tx.timestamp.month - 1]}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassBlur(
                                borderRadius: 16,
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (isIncome
                                                  ? AppColors.neonEmerald
                                                  : AppColors.neonTeal)
                                              .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isIncome
                                          ? AppColors.neonEmerald
                                          : AppColors.neonTeal,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tx.category} • $dateStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    formattedAmt,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? AppColors.neonEmerald
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreditCardDetailView extends ConsumerStatefulWidget {
  final CreditCard card;

  const CreditCardDetailView({super.key, required this.card});

  @override
  ConsumerState<CreditCardDetailView> createState() =>
      _CreditCardDetailViewState();
}

class _CreditCardDetailViewState extends ConsumerState<CreditCardDetailView> {
  late TextEditingController _spendController;
  late TextEditingController _statementController;
  bool _isEditing = false;
  bool _isFlipped = false;
  String _selectedFilter = 'spent'; // 'spent' or 'statement'

  @override
  void initState() {
    super.initState();
    _spendController = TextEditingController(
      text: widget.card.currentSpendings.toStringAsFixed(0),
    );
    _statementController = TextEditingController(
      text: widget.card.statementAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _spendController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    final newSpend = double.tryParse(_spendController.text) ?? 0.0;
    final newStatement = double.tryParse(_statementController.text) ?? 0.0;
    final updatedCard = widget.card
      ..currentSpendings = newSpend
      ..statementAmount = newStatement;

    await ref.read(creditCardsProvider.notifier).updateCreditCard(updatedCard);

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card details updated successfully'),
          backgroundColor: AppColors.obsidianSurface,
        ),
      );
    }
  }

  Widget _buildSecureFieldCompact(String label, String value, bool copyable) {
    final displayValue = value.isEmpty ? 'Not set' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (copyable && value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      backgroundColor: AppColors.obsidianSurface,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.neonTeal,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrontCardContent() {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: Colors.black.withOpacity(0.25),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.cardName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'A/C: •••• ${widget.card.last4}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_rounded,
                              color: AppColors.neonTeal,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final LocalAuthentication auth =
                                  LocalAuthentication();
                              try {
                                final bool canAuthenticateWithBiometrics =
                                    await auth.canCheckBiometrics;
                                final bool canAuthenticate =
                                    canAuthenticateWithBiometrics ||
                                    await auth.isDeviceSupported();
                                if (!canAuthenticate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometric auth not available',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final bool
                                didAuthenticate = await auth.authenticate(
                                  localizedReason:
                                      'Authenticate to view secure card details',
                                  options: const AuthenticationOptions(
                                    biometricOnly: true,
                                  ),
                                );
                                if (didAuthenticate && mounted) {
                                  setState(() => _isFlipped = true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Auth error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.card.imageUrl.isEmpty)
                    const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                ],
              ),
              const Spacer(),
              if (!_isEditing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'spent'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilter == 'spent'
                              ? AppColors.neonTeal.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedFilter == 'spent'
                                ? AppColors.neonTeal
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT SPENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '₹${widget.card.currentSpendings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = 'statement'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilter == 'statement'
                              ? AppColors.neonTeal.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedFilter == 'statement'
                                ? AppColors.neonTeal
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STATEMENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '₹${widget.card.statementAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.neonTeal,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _spendController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Spent',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _statementController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Statement',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.neonEmerald,
                        size: 28,
                      ),
                      onPressed: _saveDetails,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _spendController.text = widget.card.currentSpendings
                              .toStringAsFixed(0);
                          _statementController.text = widget
                              .card
                              .statementAmount
                              .toStringAsFixed(0);
                          _isEditing = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCardContent() {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: Colors.black.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECURE DETAILS',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonTeal,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFlipped = false),
                    child: const Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildSecureFieldCompact(
                'Card Number',
                widget.card.fullCardNumber,
                true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSecureFieldCompact(
                      'Expiry Date',
                      widget.card.expiryDate,
                      false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecureFieldCompact(
                      'CVV',
                      widget.card.cvv,
                      false,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txsState = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Card Detail',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                        gradient: widget.card.imageUrl.isEmpty
                            ? LinearGradient(
                                colors: [
                                  AppColors.tealBlueGradient[0],
                                  AppColors.tealBlueGradient[1],
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (widget.card.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  widget.card.imageUrl.toLowerCase().endsWith(
                                    '.svg',
                                  )
                                  ? SvgPicture.asset(
                                      'assets/credit_card_images/${widget.card.imageUrl}',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.fill,
                                    )
                                  : Image.asset(
                                      'assets/credit_card_images/${widget.card.imageUrl}',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  final flipAnimation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOut,
                                        ),
                                      );
                                  return AnimatedBuilder(
                                    animation: flipAnimation,
                                    child: child,
                                    builder: (context, child) {
                                      return Transform(
                                        transform: Matrix4.identity()
                                          ..scale(flipAnimation.value, 1.0),
                                        alignment: Alignment.center,
                                        child: child,
                                      );
                                    },
                                  );
                                },
                            child: _isFlipped
                                ? _buildBackCardContent()
                                : _buildFrontCardContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'spent'
                            ? 'Spent Transactions'
                            : 'Statement Contributions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Stmt Day: ${widget.card.statementDay}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: txsState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.neonTeal,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (txs) {
                        var cardTxs = txs
                            .where((t) => t.cardId == widget.card.id.toString())
                            .toList();

                        // Calculate statement date cycle bounds
                        final now = DateTime.now();
                        DateTime mostRecentStatementDate;
                        DateTime previousStatementDate;

                        if (now.day >= widget.card.statementDay) {
                          mostRecentStatementDate = DateTime(
                            now.year,
                            now.month,
                            widget.card.statementDay,
                          );
                          previousStatementDate = DateTime(
                            now.month == 1 ? now.year - 1 : now.year,
                            now.month == 1 ? 12 : now.month - 1,
                            widget.card.statementDay,
                          );
                        } else {
                          mostRecentStatementDate = DateTime(
                            now.month == 1 ? now.year - 1 : now.year,
                            now.month == 1 ? 12 : now.month - 1,
                            widget.card.statementDay,
                          );
                          final prevMonth = mostRecentStatementDate.month;
                          final prevYear = mostRecentStatementDate.year;
                          previousStatementDate = DateTime(
                            prevMonth == 1 ? prevYear - 1 : prevYear,
                            prevMonth == 1 ? 12 : prevMonth - 1,
                            widget.card.statementDay,
                          );
                        }

                        if (_selectedFilter == 'spent') {
                          // transactions after the statement was generated
                          cardTxs = cardTxs
                              .where(
                                (t) => t.timestamp.isAfter(
                                  mostRecentStatementDate,
                                ),
                              )
                              .toList();
                        } else {
                          // transactions linked with the statement contribution (between previousStatementDate and mostRecentStatementDate)
                          cardTxs = cardTxs
                              .where(
                                (t) =>
                                    t.timestamp.isAfter(
                                      previousStatementDate,
                                    ) &&
                                    t.timestamp.isBefore(
                                      mostRecentStatementDate.add(
                                        const Duration(seconds: 1),
                                      ),
                                    ),
                              )
                              .toList();
                        }

                        cardTxs.sort(
                          (a, b) => b.timestamp.compareTo(a.timestamp),
                        ); // recent to previous

                        if (cardTxs.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedFilter == 'spent'
                                  ? 'No transactions since the last statement.'
                                  : 'No transactions in this statement period.',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: cardTxs.length,
                          itemBuilder: (context, index) {
                            final tx = cardTxs[index];
                            final formattedAmt =
                                '-₹${tx.amount.toStringAsFixed(0)}';

                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            final dateStr =
                                '${tx.timestamp.day} ${months[tx.timestamp.month - 1]}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassBlur(
                                borderRadius: 16,
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonTeal.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward,
                                      color: AppColors.neonTeal,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tx.category} • $dateStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    formattedAmt,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryBinPage extends ConsumerStatefulWidget {
  const RecoveryBinPage({super.key});

  @override
  ConsumerState<RecoveryBinPage> createState() => _RecoveryBinPageState();
}

class _RecoveryBinPageState extends ConsumerState<RecoveryBinPage> {
  List<Transaction> _deletedTxs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedTransactions();
  }

  Future<void> _loadDeletedTransactions() async {
    setState(() => _isLoading = true);
    final txs = await ref
        .read(databaseServiceProvider)
        .getDeletedTransactions();
    if (mounted) {
      setState(() {
        _deletedTxs = txs;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreTx(Transaction tx) async {
    await ref.read(databaseServiceProvider).restoreTransaction(tx.id);
    ref.read(transactionsProvider.notifier).loadTransactions();
    ref.read(creditCardsProvider.notifier).loadCreditCards();
    ref.read(bankAccountsProvider.notifier).loadBankAccounts();
    ref.read(loansProvider.notifier).loadLoans();
    _loadDeletedTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction successfully restored'),
          backgroundColor: AppColors.neonEmerald,
        ),
      );
    }
  }

  Future<void> _purgeTx(Transaction tx) async {
    await ref.read(databaseServiceProvider).permanentlyDeleteTransaction(tx.id);
    _loadDeletedTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction permanently deleted'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recovery Bin',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.neonTeal,
                            ),
                          )
                        : _deletedTxs.isEmpty
                        ? const Center(
                            child: Text(
                              'No recently deleted transactions.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _deletedTxs.length,
                            itemBuilder: (context, index) {
                              final tx = _deletedTxs[index];
                              final isIncome = tx.transactionType == 'income';
                              final formattedAmt =
                                  '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';

                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ];
                              final dateStr =
                                  '${tx.timestamp.day} ${months[tx.timestamp.month - 1]}';
                              final deletedStr = tx.deletedAt != null
                                  ? 'Deleted: ${tx.deletedAt!.day} ${months[tx.deletedAt!.month - 1]}'
                                  : '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassBlur(
                                  borderRadius: 16,
                                  child: ListTile(
                                    title: Text(
                                      tx.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tx.category} • $dateStr\n$deletedStr',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedAmt,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isIncome
                                                ? AppColors.neonEmerald
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.restore_rounded,
                                            color: AppColors.neonTeal,
                                            size: 20,
                                          ),
                                          onPressed: () => _restoreTx(tx),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_forever_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () => _purgeTx(tx),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
