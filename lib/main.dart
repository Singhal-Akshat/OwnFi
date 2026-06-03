import 'dart:async';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterGemma.initialize();
  } catch (e) {
    print('Failed to initialize FlutterGemma: $e');
  }
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
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

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenModelOnboarding') ?? false;
    if (!hasSeen) {
      await prefs.setBool('hasSeenModelOnboarding', true);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModelOnboardingScreen()));
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
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  _buildNavBarItem(Icons.psychology_rounded, 'AI Advisor', 3),
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
              color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
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
    final bool isEmptyDb = (txsState.valueOrNull?.isEmpty ?? true) &&
        (cardsState.valueOrNull?.isEmpty ?? true) &&
        (loansState.valueOrNull?.isEmpty ?? true) &&
        (holdingsState.valueOrNull?.isEmpty ?? true);

    double cashAndBank = isEmptyDb ? 0.0 : 325820.0;
    txsState.whenData((txs) {
      for (final tx in txs) {
        if (tx.cardId == null) {
          if (tx.transactionType == 'income') {
            cashAndBank += tx.amount;
          } else if (tx.transactionType == 'expense') {
            cashAndBank -= tx.amount;
          }
        }
      }
    });

    final netWorth = isEmptyDb ? 0.0 : (totalHoldingsVal + cashAndBank + totalReceivables - totalCardOutstanding - totalDebts);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'MypersonalTracker',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
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
          const SizedBox(height: 20),

          // Glass Net Worth Card
          GlassBlur(
            borderRadius: 20,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET WORTH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(netWorth),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAssetMini('Investments', formatCurrency(totalHoldingsVal), AppColors.neonEmerald),
                      _buildAssetMini('Cash & Bank', formatCurrency(cashAndBank), AppColors.neonTeal),
                      _buildAssetMini('Outstanding', formatCurrency(-totalCardOutstanding), Colors.redAccent),
                    ],
                  ),
                ],
              ),
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
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

                    final formattedAmt = '${tx.transactionType == 'income' ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';
                    final dateStr = '${tx.timestamp.day} ${_getMonthName(tx.timestamp.month)}';

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
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
                      ),
                      onDismissed: (_) {
                        ref.read(transactionsProvider.notifier).removeTransaction(tx.id);
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
                            onTap: () => _showAddExpenseDialog(context, ref, existingTransaction: tx),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tx.transactionType == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              tx.description,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              '${tx.category} • ${tx.accountName ?? (tx.cardId != null ? 'Credit Card' : 'Cash')} • $dateStr',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            trailing: Text(
                              formattedAmt,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tx.transactionType == 'income' ? AppColors.neonEmerald : Colors.white,
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, {Transaction? existingTransaction}) {
    final amountController = TextEditingController(text: existingTransaction != null ? existingTransaction.amount.toStringAsFixed(0) : '');
    final descController = TextEditingController(text: existingTransaction?.description ?? '');
    final catController = TextEditingController(text: existingTransaction?.category ?? '');

    String selectedType = existingTransaction?.transactionType ?? 'expense';
    String selectedAccountType = 'Cash'; // Cash, Bank, CreditCard
    int? selectedCardId;
    if (existingTransaction != null) {
      if (existingTransaction.cardId != null) {
        selectedCardId = int.tryParse(existingTransaction.cardId!);
        selectedAccountType = 'card:${existingTransaction.cardId}';
      } else {
        selectedAccountType = existingTransaction.accountName ?? 'Cash';
      }
    }
    bool isSplit = existingTransaction?.isSplit ?? false;

    // Split Details controllers
    final splitFriendController = TextEditingController(
      text: (existingTransaction != null && existingTransaction.isSplit && existingTransaction.splitDetails.isNotEmpty)
          ? existingTransaction.splitDetails.first.friendName ?? ''
          : ''
    );
    final splitAmountController = TextEditingController(
      text: (existingTransaction != null && existingTransaction.isSplit && existingTransaction.splitDetails.isNotEmpty)
          ? existingTransaction.splitDetails.first.amount.toStringAsFixed(0)
          : ''
    );

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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingTransaction != null ? 'Edit Transaction' : 'Manual Transaction Entry',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // Transaction Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                          dropdownColor: AppColors.obsidianSurface,
                          items: const [
                            DropdownMenuItem(value: 'expense', child: Text('Expense')),
                            DropdownMenuItem(value: 'income', child: Text('Income')),
                            DropdownMenuItem(value: 'transfer', child: Text('Card Repayment (Transfer)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedType = val);
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                        // Category
                        TextField(
                          controller: catController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'e.g. Electronics, Food, Bills',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Payment Source / Account Selection
                        DropdownButtonFormField<String>(
                          value: selectedAccountType,
                          decoration: const InputDecoration(labelText: 'Account / Card', border: OutlineInputBorder()),
                          dropdownColor: AppColors.obsidianSurface,
                          items: [
                            const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            const DropdownMenuItem(value: 'Bank', child: Text('Bank Account')),
                            ...cardsState.maybeWhen(
                              data: (cards) => cards.map(
                                (card) => DropdownMenuItem(
                                  value: 'card:${card.id}',
                                  child: Text('${card.cardName} (..${card.last4})'),
                                ),
                              ),
                              orElse: () => [],
                            ),
                          ],
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
                        const SizedBox(height: 16),

                        // Split Toggle
                        CheckboxListTile(
                          title: const Text('Split Expense?', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Split bills with friends/contacts', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final amount = double.tryParse(amountController.text) ?? 0.0;
                                final desc = descController.text.trim();
                                final category = catController.text.trim();

                                if (amount <= 0 || desc.isEmpty || category.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all required fields')),
                                  );
                                  return;
                                }

                                final tx = existingTransaction ?? Transaction();
                                tx.amount = amount;
                                tx.description = desc;
                                tx.category = category;
                                if (existingTransaction == null) {
                                  tx.timestamp = DateTime.now();
                                  tx.source = 'manual';
                                }
                                tx.transactionType = selectedType;

                                if (selectedCardId != null) {
                                  tx.cardId = selectedCardId.toString();
                                  tx.accountName = 'Credit Card';
                                } else {
                                  tx.cardId = null;
                                  tx.accountName = selectedAccountType;
                                }

                                if (isSplit) {
                                  tx.isSplit = true;
                                  final splitAmt = double.tryParse(splitAmountController.text) ?? 0.0;
                                  final friend = splitFriendController.text.trim();
                                  if (splitAmt > 0 && friend.isNotEmpty) {
                                    tx.splitDetails = [
                                      TransactionSplitDetail()
                                        ..amount = splitAmt
                                        ..category = category
                                        ..friendName = friend
                                        ..description = 'Owed from split: $desc',
                                    ];

                                    // Add to borrowed/lent loans ledger!
                                    if (existingTransaction == null || !existingTransaction.isSplit) {
                                      final loan = Loan()
                                        ..contactName = friend
                                        ..isLent = true // they owe us money, so it is lent
                                        ..amount = splitAmt
                                        ..remainingBalance = splitAmt
                                        ..startDate = DateTime.now()
                                        ..interestRate = 0.0
                                        ..compoundInterval = 'none'
                                        ..emiAmount = 0.0;
                                      ref.read(loansProvider.notifier).addLoan(loan);
                                    }
                                  }
                                } else {
                                  tx.isSplit = false;
                                  tx.splitDetails = [];
                                }

                                ref.read(transactionsProvider.notifier).addTransaction(tx);
                                Navigator.pop(context);
                              },
                              child: Text(existingTransaction != null ? 'Save Changes' : 'Log Transaction'),
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
// VIEW 2: CARDS & LOANS VIEW
// ---------------------------------------------------------------------------
class CardsLoansView extends ConsumerWidget {
  const CardsLoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(creditCardsProvider);
    final loansState = ref.watch(loansProvider);

    return Padding(
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
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
                icon: const Icon(Icons.add, size: 16, color: AppColors.neonTeal),
                label: const Text('Add Loan', style: TextStyle(color: AppColors.neonTeal, fontSize: 13)),
                onPressed: () => _showAddLoanDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Loans items list
          Expanded(
            child: loansState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (loans) {
                if (loans.isEmpty) {
                  return const Center(
                    child: Text('No active loans. Click Add Loan to track!', style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final String typeStr = loan.isLent ? 'Lent (Receivable)' : 'Borrowed (Debt)';
                    final Color typeColor = loan.isLent ? AppColors.neonEmerald : Colors.redAccent;
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
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
                      ),
                      onDismissed: (_) {
                        ref.read(loansProvider.notifier).removeLoan(loan.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loan.contactName}\'s loan deleted'),
                            backgroundColor: AppColors.obsidianSurface,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () => _showAddLoanDialog(context, ref, existingLoan: loan),
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
          ),
        ],
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
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getMonthName(int day) {
    final now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month, day);
    
    if (now.day > day) {
      targetDate = DateTime(now.year, now.month + 1, day);
    }
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[targetDate.month - 1];
  }

  Widget _buildCreditCardItem(BuildContext context, WidgetRef ref, CreditCard card) {
    bool showSpent = true; // State for toggle
    bool isLongPressed = false; // State for edit/delete

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onLongPress: () => setState(() => isLongPressed = true),
          onTap: () {
            if (isLongPressed) setState(() => isLongPressed = false);
          },
          child: Container(
            width: 220,
            margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
            gradient: card.imageUrl.isEmpty
                ? LinearGradient(
                    colors: [AppColors.tealBlueGradient[0], AppColors.tealBlueGradient[1]],
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
                          fit: BoxFit.cover,
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
                            icon: const Icon(Icons.edit, color: Colors.white, size: 36),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              _showAddCardDialog(context, ref, existingCard: card);
                            },
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 36),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              ref.read(creditCardsProvider.notifier).removeCreditCard(card.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Card deleted'), backgroundColor: AppColors.obsidianSurface),
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
                    color: Colors.black.withOpacity(0.15), // Gentle global dimming
                  ),
                  padding: const EdgeInsets.all(20.0),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _authenticateAndShowCardDetails(context, card),
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
                      const Icon(Icons.visibility_rounded, color: Colors.white70, size: 24),
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.swap_horiz_rounded, color: AppColors.neonTeal, size: 16),
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
                            showSpent ? '₹${card.currentSpendings.toStringAsFixed(0)}' : '₹${card.statementAmount.toStringAsFixed(0)}',
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
          ),
        );
      }
    );
  }

  Future<void> _authenticateAndShowCardDetails(BuildContext context, CreditCard card) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric auth not available')));
        return;
      }
      
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view secure card details',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      
      if (didAuthenticate) {
        if (!context.mounted) return;
        _showSecureCardBottomSheet(context, card);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth error: $e')));
      }
    }
  }

  void _showSecureCardBottomSheet(BuildContext context, CreditCard card) {
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
              color: AppColors.obsidianSurface.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Secure Card Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                _buildSecureField(context, 'Card Number', card.fullCardNumber, true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSecureField(context, 'Expiry Date', card.expiryDate, false)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSecureField(context, 'CVV', card.cvv, false)),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecureField(BuildContext context, String label, String value, bool copyable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? 'Not set' : value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 2),
              ),
            ),
            if (copyable && value.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.neonTeal, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), backgroundColor: AppColors.neonTeal));
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFooter(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonTeal)),
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
                Icon(Icons.add_card_rounded, color: AppColors.neonTeal, size: 36),
                SizedBox(height: 8),
                Text('Add Card', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanItem(String title, String type, String principal, String emiInfo, Color typeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          subtitle: Text(emiInfo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
              ),
              const SizedBox(height: 4),
              Text(
                principal,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref, {CreditCard? existingCard}) {
    final nameController = TextEditingController(text: existingCard?.cardName ?? '');
    final last4Controller = TextEditingController(text: existingCard?.last4 ?? '');
    final stmtDayController = TextEditingController(text: existingCard?.statementDay.toString() ?? '15');
    final dueDayController = TextEditingController(text: existingCard?.dueDay.toString() ?? '5');
    
    // Secure Fields
    final fullCardNumberController = TextEditingController(text: existingCard?.fullCardNumber ?? '');
    final expiryDateController = TextEditingController(text: existingCard?.expiryDate ?? '');
    final cvvController = TextEditingController(text: existingCard?.cvv ?? '');
    
    // Financial metrics for card
    final currentSpendingsController = TextEditingController(text: existingCard?.currentSpendings.toStringAsFixed(0) ?? '0');
    final statementAmountController = TextEditingController(text: existingCard?.statementAmount.toStringAsFixed(0) ?? '0');

    String selectedBrand = existingCard?.brand.isNotEmpty == true ? existingCard!.brand : 'Visa';
    String selectedImage = existingCard?.imageUrl ?? '';
    
    final imageOptions = [
      '',
      'IDFC_Millennia_HQ.avif',
      'LIC_Axis_Cropped_Vector.svg',
      'SBI_SimplySave_Mobile.avif',
      'Scapia_Rupay.avif',
      'Scapia_Visa.avif',
      'Tata_NeuCard_FullFrame.avif',
      'UNI_YesBank_Vertical.avif',
      'hsbc_vertical_card_final.avif'
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => NfcScanDialog(
                                    nameController: nameController,
                                    last4Controller: last4Controller,
                                    fullCardNumberController: fullCardNumberController,
                                    expiryDateController: expiryDateController,
                                    onBrandDetected: (brand) {
                                      setState(() => selectedBrand = brand);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.nfc_rounded, size: 18),
                              label: const Text('Scan', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Card Name (e.g. HDFC Regalia)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: fullCardNumberController,
                                decoration: const InputDecoration(labelText: 'Full Card Number', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.length >= 4) {
                                    last4Controller.text = val.substring(val.length - 4);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: last4Controller,
                                decoration: const InputDecoration(labelText: 'Last 4', border: OutlineInputBorder()),
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
                                decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: cvvController,
                                decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedBrand,
                          decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                          items: ['Visa', 'Mastercard', 'RuPay', 'Amex'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() => selectedBrand = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedImage,
                          decoration: const InputDecoration(labelText: 'Card Background Image', border: OutlineInputBorder()),
                          isExpanded: true,
                          items: imageOptions.map((i) => DropdownMenuItem(value: i, child: Text(i.isEmpty ? 'None' : i, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => selectedImage = val!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: currentSpendingsController,
                                decoration: const InputDecoration(labelText: 'Current Spendings', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: statementAmountController,
                                decoration: const InputDecoration(labelText: 'Statement Amount', border: OutlineInputBorder()),
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
                                decoration: const InputDecoration(labelText: 'Statement Day (1-28)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: dueDayController,
                                decoration: const InputDecoration(labelText: 'Due Day (1-28)', border: OutlineInputBorder()),
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
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                              onPressed: () {
                                final name = nameController.text.trim();
                                final last4 = last4Controller.text.trim();
                                final stmt = int.tryParse(stmtDayController.text) ?? 15;
                                final due = int.tryParse(dueDayController.text) ?? 5;
                                final curSp = double.tryParse(currentSpendingsController.text) ?? 0.0;
                                final stmAm = double.tryParse(statementAmountController.text) ?? 0.0;

                                if (name.isEmpty || last4.length != 4) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill Name and Last 4 digits accurately')),
                                  );
                                  return;
                                }

                                // Duplicate Check
                                final existingCards = ref.read(creditCardsProvider).value ?? [];
                                if (existingCard == null) {
                                  final cardNumber = fullCardNumberController.text.trim();
                                  if (cardNumber.isNotEmpty) {
                                    final isDuplicate = existingCards.any((c) => c.fullCardNumber == cardNumber);
                                    if (isDuplicate) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Duplicate error: A card with this number already exists!')),
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
                                  ..fullCardNumber = fullCardNumberController.text.trim()
                                  ..expiryDate = expiryDateController.text.trim()
                                  ..cvv = cvvController.text.trim()
                                  ..brand = selectedBrand
                                  ..imageUrl = selectedImage
                                  ..currentSpendings = curSp
                                  ..statementAmount = stmAm;

                                if (existingCard == null) {
                                  ref.read(creditCardsProvider.notifier).addCreditCard(card);
                                } else {
                                  ref.read(creditCardsProvider.notifier).updateCreditCard(card);
                                }
                                Navigator.pop(context);
                              },
                              child: Text(existingCard == null ? 'Add Card' : 'Save Changes'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showAddLoanDialog(BuildContext context, WidgetRef ref, {Loan? existingLoan}) {
    final contactController = TextEditingController(text: existingLoan?.contactName ?? '');
    final amountController = TextEditingController(text: existingLoan != null ? existingLoan.amount.toStringAsFixed(0) : '');
    final rateController = TextEditingController(text: existingLoan != null ? existingLoan.interestRate.toString() : '0');
    final emiController = TextEditingController(text: existingLoan != null ? existingLoan.emiAmount.toStringAsFixed(0) : '0');
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existingLoan != null ? 'Edit Loan / Debt' : 'Track Loan / Debt',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<bool>(
                        value: isLent,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        dropdownColor: AppColors.obsidianSurface,
                        items: const [
                          DropdownMenuItem(value: false, child: Text('Borrowed (Debt)')),
                          DropdownMenuItem(value: true, child: Text('Lent (Receivable)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => isLent = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contactController,
                        decoration: const InputDecoration(labelText: 'Contact / Lender Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount (INR)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rateController,
                              decoration: const InputDecoration(labelText: 'Interest Rate (%)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: emiController,
                              decoration: const InputDecoration(labelText: 'Monthly EMI (0 if none)', border: OutlineInputBorder()),
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
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                            onPressed: () {
                              final contact = contactController.text.trim();
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              final rate = double.tryParse(rateController.text) ?? 0.0;
                              final emi = double.tryParse(emiController.text) ?? 0.0;

                              if (contact.isEmpty || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter name and valid amount')),
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
                                if (existingLoan.amount == existingLoan.remainingBalance) {
                                  loan.remainingBalance = amount;
                                }
                              }
                              loan.interestRate = rate;
                              loan.emiAmount = emi;

                              ref.read(loansProvider.notifier).addLoan(loan);
                              Navigator.pop(context);
                            },
                            child: Text(existingLoan != null ? 'Save Changes' : 'Add Loan'),
                          ),
                        ],
                      )
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
}

// ---------------------------------------------------------------------------
// VIEW 3: INVESTMENTS VIEW (Zerodha & Coin holdings)
// ---------------------------------------------------------------------------
class InvestmentsView extends ConsumerStatefulWidget {
  const InvestmentsView({super.key});

  @override
  ConsumerState<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends ConsumerState<InvestmentsView> with SingleTickerProviderStateMixin {
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
                    icon: const Icon(Icons.sync_rounded, color: AppColors.neonTeal, size: 20),
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
                border: Border.all(color: AppColors.neonEmerald.withOpacity(0.3)),
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
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
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
              final returnsPct = buyCost > 0 ? (returnsAmt / buyCost) * 100 : 0.0;
              final isNegative = returnsAmt < 0;

              final totalVal = stockVal + mfVal;
              final double stockPct = totalVal > 0 ? (stockVal / totalVal) * 100 : 0.0;
              final double mfPct = totalVal > 0 ? (mfVal / totalVal) * 100 : 0.0;

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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Valuation', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(formatCurrency(currentVal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Returns', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '${isNegative ? "" : "+"}${formatCurrency(returnsAmt)} (${isNegative ? "" : "+"}${returnsPct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNegative ? Colors.redAccent : AppColors.neonEmerald,
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
                                        title: '${stockPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    if (mfVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonEmerald,
                                        value: mfVal,
                                        title: '${mfPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
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
                                  _buildLegendItem('Stocks (Zerodha)', formatCurrency(stockVal), AppColors.neonTeal),
                                  const SizedBox(height: 8),
                                  _buildLegendItem('Mutual Funds (Coin)', formatCurrency(mfVal), AppColors.neonEmerald),
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (holdings) {
                final stocks = holdings.where((h) => h.assetType == 'stock').toList();
                final mutualFunds = holdings.where((h) => h.assetType == 'mutual_fund').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Stocks List
                    stocks.isEmpty
                        ? const Center(child: Text('No stocks. Click Import to add holdings!', style: TextStyle(color: AppColors.textMuted)))
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
                        ? const Center(child: Text('No mutual funds. Click Import to add holdings!', style: TextStyle(color: AppColors.textMuted)))
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
      String symbol, String name, String qty, String avg, String current, String returns) {
    final isNegative = returns.startsWith('-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(symbol, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
              Text('$qty • $avg', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(current, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                  Text('Import Portfolio holdings', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Select your holdings CSV or Excel export from Zerodha Console or Coin:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.show_chart_rounded, color: AppColors.neonTeal),
                    title: const Text('Zerodha Holdings (CSV/Excel)', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Upload Console holdings sheet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'zerodha');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(Icons.pie_chart_rounded, color: AppColors.neonEmerald),
                    title: const Text('Coin Mutual Funds (CSV/Excel)', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Upload Coin holdings sheet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'coin');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    title: const Text('Clear All Holdings', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                    subtitle: const Text('Reset local investments portfolio', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(holdingsProvider.notifier).clearAllHoldings();
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
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    ],
                  )
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
          const SnackBar(content: Text('No valid holdings found in the selected file.')),
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
          content: Text('Failed to import holdings: ${e.toString().replaceAll('Exception: ', '')}'),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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

class _AdvisorViewState extends ConsumerState<AdvisorView> with SingleTickerProviderStateMixin {
  late TabController _advisorTabController;
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _advisorTabController = TabController(length: 2, vsync: this);
    // Initialize welcome message
    _messages.add({
      'sender': 'AI',
      'text': 'Hello Akshat! I am your local privacy-first financial advisor. Ask me anything about rebalancing your portfolio, check your emergency fund status, or ask for home/car loan pre-payment guidance!'
    });
  }

  @override
  void dispose() {
    _advisorTabController.dispose();
    _chatInputController.dispose();
    super.dispose();
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
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
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
    final useLocalStr = await const FlutterSecureStorage().read(key: 'ai_use_local');
    final useLocal = useLocalStr == 'true';
    if (useLocal) {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selectedModelId') ?? 'gemma2_turbo_2b';
      final meta = await ModelRepository.instance.getMeta(selectedId);
      if (meta != null) {
        final localPath = await ModelRepository.instance.localModelPath(meta.assetPath);
        if (await File(localPath).exists()) {
          return 'Local LLM: ${meta.displayName}';
        }
      }
      return 'Local LLM (No downloaded model, using Quant Fallback)';
    }
    final geminiKey = await const FlutterSecureStorage().read(key: 'ai_gemini_key');
    if (geminiKey != null && geminiKey.isNotEmpty) {
      return 'Gemini Cloud API (Online)';
    }
    final host = await const FlutterSecureStorage().read(key: 'ai_ollama_host') ?? 'http://localhost:11434';
    return 'Ollama Local Host ($host)';
  }

  Widget _buildQuantDashboard(BuildContext context) {
    final forecastState = ref.watch(quantForecastResultProvider);

    return forecastState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonPurple)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
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

        double progress = forecast.projectedSpend > 0 ? (forecast.dailyVelocity * forecast.remainingDays) / 100000.0 : 0.0;
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
                        Text('Cash Flow Forecast', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Projected Spend: ${formatCurrency(forecast.projectedSpend)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on current velocity (${formatCurrency(forecast.dailyVelocity)}/day) over ${forecast.remainingDays} remaining days + monthly EMIs (${formatCurrency(forecast.recurringEmis)}) + rent (${formatCurrency(forecast.detectedRent)}).',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
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
                        Icon(Icons.pie_chart_outline_rounded, color: AppColors.neonEmerald),
                        SizedBox(width: 8),
                        Text('Advisor Recommendations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
            const Icon(Icons.chevron_right, color: AppColors.neonEmerald, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 2, bottom: 8),
          child: Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    return Column(
      children: [
        // Active AI Engine Status
        FutureBuilder<String>(
          future: _getActiveEngineStatus(),
          builder: (context, snapshot) {
            final engine = snapshot.data ?? 'Checking active engine...';
            final isLocal = engine.contains('Local LLM');
            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.2)),
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
                  Expanded(
                    child: Text(
                      'Active Engine: $engine',
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocal) ...[
                    const SizedBox(width: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.grey[900],
                      ),
                      child: ModelSelector(
                        onChanged: () {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
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
                    margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    child: GlassBlur(
                      borderRadius: 16,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Typing advisor recommendations...',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: GlassBlur(
                    borderRadius: 16,
                    cardColor: isAI ? AppColors.glassCard : AppColors.neonPurple.withOpacity(0.1),
                    borderColor: isAI ? AppColors.glassBorder : AppColors.neonPurple.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        msg['text']!,
                        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Text Input box
        Row(
          children: [
            Expanded(
              child: GlassBlur(
                borderRadius: 16,
                child: TextField(
                  controller: _chatInputController,
                  decoration: const InputDecoration(
                    hintText: 'Ask advisor (e.g. should I pre-pay home loan?)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GlassBlur(
              borderRadius: 16,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.neonTeal),
                onPressed: _sendMessage,
              ),
            ),
          ],
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
        double netWorth = totalHoldingsVal + forecast.cashAndBank + totalReceivables - totalCardOutstanding - totalDebts;

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
            'text': 'I am still loading your financial profile. Please wait a moment.'
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': 'Sorry, I encountered an error while processing your request: $e'
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
  int _smsLookbackValue = 180;
  String _smsLookbackUnit = 'days';

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.read(key: 'settings_biometrics') ?? 'true';
    final localLLM = await _storage.read(key: 'ai_use_local') ?? 'false';
    
    String? lookbackValStr = await _storage.read(key: 'settings_sms_lookback_value');
    String? lookbackUnitStr = await _storage.read(key: 'settings_sms_lookback_unit');
    
    if (lookbackValStr == null) {
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
      _smsLookbackValue = int.tryParse(lookbackValStr!) ?? 180;
      _smsLookbackUnit = lookbackUnitStr ?? 'days';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Security Group
          _buildGroupTitle('Security & Privacy'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Authentication', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Lock app using Fingerprint / FaceID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _biometricsEnabled,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) async {
                    setState(() => _biometricsEnabled = val);
                    await _storage.write(key: 'settings_biometrics', value: val.toString());
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Manage PDF Passwords', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Add decryption keys for CC Statements', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.textSecondary),
                  onTap: () => _showManagePasswordsDialog(context),
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
                  title: const Text('Configure Gmail IMAP', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Store email fetch credentials locally', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () => _showImapConfigDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('WebDAV Backup & Sync', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Configure encrypted Nextcloud or WebDAV backups', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.sync_alt_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () => _showSyncConfigDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('SMS Sync Lookback Window', style: TextStyle(fontSize: 14)),
                  subtitle: Text('Scan window: $_smsLookbackValue $_smsLookbackUnit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () => _showSmsLookbackDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Sync All Accounts Now', style: TextStyle(fontSize: 14, color: AppColors.neonTeal)),
                  subtitle: const Text('Directly fetch transactions from Gmail & SMS', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.sync_rounded, size: 20, color: AppColors.neonTeal),
                  onTap: () => _triggerAccountSync(context),
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
                  title: const Text('Enable On-Device LLM', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Run LLM locally on device via Flutter Gemma (Ollama on desktop)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _localLLMEnabled,
                  activeColor: AppColors.neonPurple,
                  onChanged: (val) async {
                    setState(() {
                      _localLLMEnabled = val;
                    });
                    await _storage.write(key: 'ai_use_local', value: val.toString());
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Manage Local Models', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Download or delete on-device model files', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.download_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModelDownloadPage()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Cloud AI API Keys', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Configure personal Gemini or OpenAI keys', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.api_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () => _showApiKeysDialog(context),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('HuggingFace Token', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Configure HuggingFace access token for gated models', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.key_rounded, size: 20, color: AppColors.textSecondary),
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
                  title: const Text('Clear All Data', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                  subtitle: const Text('Permanently erase all credit cards, loans, holdings, and transactions', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.redAccent),
                  onTap: () => _showClearDataConfirmDialog(context),
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
    _storage.read(key: 'imap_email').then((val) => emailController.text = val ?? '');
    _storage.read(key: 'imap_host').then((val) => hostController.text = val ?? 'imap.gmail.com');
    _storage.read(key: 'imap_port').then((val) => portController.text = val ?? '993');

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
                    Text('Configure Gmail IMAP', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    const Text(
                      'For Gmail, use a 16-digit Google App Password rather than your standard login password.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pwdController,
                      decoration: const InputDecoration(labelText: 'Google App Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hostController,
                            decoration: const InputDecoration(labelText: 'IMAP Host', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: portController,
                            decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
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
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                          onPressed: () async {
                            final email = emailController.text.trim();
                            final pwd = pwdController.text.trim();
                            final host = hostController.text.trim();
                            final port = int.tryParse(portController.text.trim()) ?? 993;

                            if (email.isEmpty || pwd.isEmpty || host.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill email and password')),
                              );
                              return;
                            }

                            await ref.read(emailSyncServiceProvider).saveCredentials(email, pwd, host, port);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('IMAP credentials saved locally')),
                            );
                          },
                          child: const Text('Save Config'),
                        ),
                      ],
                    )
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
    final valueController = TextEditingController(text: _smsLookbackValue.toString());

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
                        'SMS Lookback Window',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Define how far back the app will scan your SMS inbox for transactions. Changing this resets the last sync time to perform a full scan.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      // Unit Selector (Days vs Months)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedUnit = 'days'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      color: selectedUnit == 'days' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: selectedUnit == 'days' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedUnit = 'months'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      color: selectedUnit == 'months' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: selectedUnit == 'months' ? FontWeight.bold : FontWeight.normal,
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
                          labelText: selectedUnit == 'days' ? 'Number of Days' : 'Number of Months',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.neonTeal),
                          ),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.date_range_rounded, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
                              final text = valueController.text.trim();
                              final val = int.tryParse(text);
                              if (val == null || val <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid positive number'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              // Update secure storage
                              await _storage.write(key: 'settings_sms_lookback_value', value: val.toString());
                              await _storage.write(key: 'settings_sms_lookback_unit', value: selectedUnit);
                              // Force full scan on next sync
                              await _storage.delete(key: 'last_sms_sync_time');

                              // Update screen state
                              this.setState(() {
                                _smsLookbackValue = val;
                                _smsLookbackUnit = selectedUnit;
                              });

                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lookback set to $val $selectedUnit. Next SMS sync will perform a full scan.'),
                                  backgroundColor: AppColors.neonEmerald.withOpacity(0.9),
                                ),
                              );
                            },
                            child: const Text('Save Window'),
                          ),
                        ],
                      )
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
                      Text('Credit Card PDF Passwords', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      const Text(
                        'Stored locally to decrypt downloaded bank statement PDFs at month-end.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedCardId,
                        decoration: const InputDecoration(labelText: 'Select Credit Card', border: OutlineInputBorder()),
                        dropdownColor: AppColors.obsidianSurface,
                        items: cardsState.maybeWhen(
                          data: (cards) => cards.map(
                            (card) => DropdownMenuItem<int>(
                              value: card.id,
                              child: Text('${card.cardName} (..${card.last4})'),
                            ),
                          ).toList(),
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
                        decoration: const InputDecoration(labelText: 'Statement PDF Password', border: OutlineInputBorder()),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                            onPressed: () async {
                              final pwd = passwordController.text.trim();
                              if (selectedCardId == null || pwd.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select card and enter password')),
                                );
                                return;
                              }

                              await _storage.write(key: 'card_password_$selectedCardId', value: pwd);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF statement password saved securely')),
                              );
                            },
                            child: const Text('Save Password'),
                          ),
                        ],
                      )
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
    _storage.read(key: 'huggingface_token').then((val) => tokenController.text = val ?? '');

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
                  Text('HuggingFace Token', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text('Enter your HuggingFace API key to download gated models.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(labelText: 'HuggingFace Token', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                        onPressed: () async {
                          await _storage.write(key: 'huggingface_token', value: tokenController.text.trim());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HuggingFace Token saved.')));
                        },
                        child: const Text('Save Token'),
                      ),
                    ],
                  )
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
      final isAvailable = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      final bioEnabled = await _storage.read(key: 'settings_biometrics') ?? 'true';
      if (isAvailable && bioEnabled == 'true') {
        final didAuth = await auth.authenticate(
          localizedReason: 'Confirm authentication to permanently delete all data',
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
                  const Icon(Icons.lock_outline_rounded, color: AppColors.neonPurple, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Backup PIN',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter your 4-digit security PIN to authorize database wipe.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 12),
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
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
                                content: Text('Incorrect PIN. Please try again.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text('Confirm'),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
    return pinMatched ?? false;
  }

  void _showClearDataConfirmDialog(BuildContext context) {
    final textController = TextEditingController();
    bool canDelete = false;

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
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Erase All Data',
                            style: Theme.of(stateContext).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This will permanently delete all transactions, credit cards, active loans, and portfolios from this device. This operation cannot be undone.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Type the word CLEAR below in uppercase to confirm:',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'CLEAR',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.glassBorder),
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
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canDelete ? Colors.redAccent : Colors.redAccent.withOpacity(0.2),
                              foregroundColor: canDelete ? Colors.white : Colors.white.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: !canDelete
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(dialogContext); // Close confirm dialog
                                    
                                    // Trigger security authentication layer
                                    final authenticated = await _authenticateUserForClear(context);
                                    if (authenticated) {
                                      // Clear DB
                                      await ref.read(databaseServiceProvider).clearAllData();
                                      
                                      // Clear sync timestamps
                                      await _storage.delete(key: 'last_sms_sync_time');
                                      await _storage.delete(key: 'last_email_sync_time');
                                      
                                      // Reload providers to refresh UI immediately
                                      ref.read(transactionsProvider.notifier).loadTransactions();
                                      ref.read(creditCardsProvider.notifier).loadCreditCards();
                                      ref.read(loansProvider.notifier).loadLoans();
                                      ref.read(holdingsProvider.notifier).loadHoldings();
                                      
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('All data successfully cleared from the database.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Authentication failed. Data was not deleted.'),
                                          backgroundColor: Colors.orangeAccent,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Authenticate & Delete'),
                          ),
                        ],
                      )
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
                      'Fetching transactions from SMS inbox & Gmail folder...',
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
      int smsCount = 0;
      if (Platform.isAndroid) {
        smsCount = await ref.read(smsSyncServiceProvider).syncSmsInbox();
      }

      int emailCount = 0;
      final hasEmailCreds = await ref.read(emailSyncServiceProvider).hasCredentials();
      if (hasEmailCreds) {
        emailCount = await ref.read(emailSyncServiceProvider).syncEmails();
      }

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
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showApiKeysDialog(BuildContext context) {
    final geminiController = TextEditingController();
    final openaiController = TextEditingController();
    final ollamaController = TextEditingController(text: 'http://localhost:11434');

    // Pre-populate if exists
    _storage.read(key: 'ai_gemini_key').then((val) => geminiController.text = val ?? '');
    _storage.read(key: 'ai_openai_key').then((val) => openaiController.text = val ?? '');
    _storage.read(key: 'ai_ollama_host').then((val) => ollamaController.text = val ?? 'http://localhost:11434');

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
                    Text('AI Advisor API Keys', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    const Text(
                      'Provide keys for local Ollama host or cloud API fallbacks. Stored securely on-device.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ollamaController,
                      decoration: const InputDecoration(labelText: 'Local Ollama Host', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: geminiController,
                      decoration: const InputDecoration(labelText: 'Gemini API Key', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: openaiController,
                      decoration: const InputDecoration(labelText: 'OpenAI API Key (Optional)', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
                          onPressed: () async {
                            final gemini = geminiController.text.trim();
                            final openai = openaiController.text.trim();
                            final ollama = ollamaController.text.trim();

                            if (gemini.isNotEmpty) {
                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.neonPurple)),
                              );

                              try {
                                final model = GenerativeModel(
                                  model: 'gemini-1.5-flash',
                                  apiKey: gemini,
                                );
                                final content = [Content.text("Ping")];
                                final response = await model.generateContent(content).timeout(const Duration(seconds: 5));
                                if (response.text == null || response.text!.isEmpty) {
                                  throw Exception("Verification failed");
                                }
                                Navigator.pop(context); // Close loader
                              } catch (e) {
                                Navigator.pop(context); // Close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invalid Gemini API Key: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                            }

                            await _storage.write(key: 'ai_gemini_key', value: gemini);
                            await _storage.write(key: 'ai_openai_key', value: openai);
                            await _storage.write(key: 'ai_ollama_host', value: ollama);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI Advisor configuration saved locally')),
                              );
                            }
                          },
                          child: const Text('Save Config'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
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
                    Text('WebDAV Sync & Backup', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    const Text(
                      'All exports are fully encrypted locally using AES-256 with your master password before upload.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Master Encryption Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'WebDAV Server URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(labelText: 'WebDAV Username', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tokenController,
                      decoration: const InputDecoration(labelText: 'WebDAV App Password / Token', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
                          onPressed: () async {
                            final pw = passwordController.text.trim();
                            final url = urlController.text.trim();
                            final user = userController.text.trim();
                            final token = tokenController.text.trim();

                            if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill master password, URL and username')),
                              );
                              return;
                            }

                            await ref.read(syncServiceProvider).saveSyncConfig(
                              masterPassword: pw,
                              webdavUrl: url,
                              webdavUser: user,
                              webdavPassword: token,
                            );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sync configuration saved locally')),
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
                            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                            label: const Text('Backup Now', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal, foregroundColor: Colors.black),
                            onPressed: () async {
                              final pw = passwordController.text.trim();
                              final url = urlController.text.trim();
                              final user = userController.text.trim();

                              if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please configure and save settings first')),
                                );
                                return;
                              }

                              Navigator.pop(context); // close config dialog
                              
                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.neonTeal)),
                              );

                              try {
                                await ref.read(syncServiceProvider).uploadBackup();
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('AES-256 encrypted database backup uploaded successfully!')),
                                );
                              } catch (e) {
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_download_rounded, size: 16),
                            label: const Text('Restore Now', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                            onPressed: () async {
                              final pw = passwordController.text.trim();
                              final url = urlController.text.trim();
                              final user = userController.text.trim();

                              if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please configure and save settings first')),
                                );
                                return;
                              }

                              Navigator.pop(context); // close config dialog

                              // Show progress loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                              );

                              try {
                                await ref.read(syncServiceProvider).restoreBackup();
                                
                                // Reload all providers
                                await ref.read(transactionsProvider.notifier).loadTransactions();
                                await ref.read(creditCardsProvider.notifier).loadCreditCards();
                                await ref.read(loansProvider.notifier).loadLoans();
                                await ref.read(holdingsProvider.notifier).loadHoldings();

                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Encrypted backup successfully restored and database re-initialized!')),
                                );
                              } catch (e) {
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    )
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
                      const Icon(Icons.info_outline_rounded, color: AppColors.neonPurple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'On-Device LLM Preparing',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• AI Core will automatically download model files (~1GB) in the background.\n'
                    '• Please keep your device connected to Wi-Fi and power.\n'
                    '• The local AI advisor will automatically activate as soon as the system finishes downloading the model.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
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
