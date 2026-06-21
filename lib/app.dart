import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'core/theme.dart';
import 'core/lock_screen.dart';
import 'core/animated_gradient_background.dart';
import 'core/utils/asset_precacher.dart';
import 'core/google_sync_service.dart';
import 'core/database_service.dart';
import 'core/providers.dart';
import 'ui/onboarding/model_onboarding.dart';
import 'dart:io';
import 'features/expenses/ui/dashboard_view.dart';
import 'features/cards_loans/ui/cards_loans_view.dart';
import 'features/investments/ui/investments_view.dart';
import 'features/advisor/ui/advisor_view.dart';
import 'ui/settings/settings_view.dart';
import 'ui/settings/widgets/sync_review_helper.dart';
import 'features/expenses/models/transaction_model.dart';
import 'features/parser/services/sms_parser_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OwnFi',
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

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkOnboarding();
      AssetPrecacher.precache(context);
      await _performBackgroundSync();
      if (mounted) {
        _requestPermissionsAndCheckSyncReview();
      }
    });
  }

  Future<void> _requestPermissionsAndCheckSyncReview() async {
    try {
      await Permission.notification.request();
    } catch (_) {}

    const storage = FlutterSecureStorage();
    final review = await storage.read(key: 'settings_interactive_review') ?? 'false';
    if (review != 'true') return;

    final showOnlyValidStr = await storage.read(key: 'settings_show_only_valid_sms_email') ?? 'true';
    final showOnlyValid = showOnlyValidStr == 'true';

    try {
      final dbService = ref.read(databaseServiceProvider);
      final lastTx = await dbService.isar.transactions
          .filter()
          .isDeletedEqualTo(false)
          .sortByTimestampDesc()
          .findFirst();
      final DateTime? since = lastTx?.timestamp;
      if (since == null) return;

      List<Map<String, dynamic>> itemsForReview = [];
      if (Platform.isAndroid) {
        final smsSync = ref.read(smsSyncServiceProvider);
        itemsForReview = await smsSync.fetchNewSmsForReview(since: since);
      }

      final emailItems = await ref
          .read(googleSyncServiceProvider)
          .fetchNewEmailsForReview(dbService, since: since);
      itemsForReview.addAll(emailItems);

      // Merge duplicate transactions across SMS and Email
      itemsForReview = _mergeDuplicateTransactions(itemsForReview);

      if (itemsForReview.isEmpty) return;

      // Sort items by date ascending (oldest first)
      itemsForReview.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
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
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.neonTeal,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unreviewed Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have ${itemsForReview.length} new messages since your last logged transaction. Would you like to review and add them now?',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text(
                            'Bypass',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            showSyncReviewDialog(
                              context,
                              ref,
                              itemsForReview,
                              showOnlyValidSmsEmail: showOnlyValid,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonTeal,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Review Now'),
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
    } catch (e) {
      debugPrint('Startup sync review check failed: $e');
    }
  }

  List<Map<String, dynamic>> _mergeDuplicateTransactions(List<Map<String, dynamic>> items) {
    final parser = SmsParserService();
    final List<Map<String, dynamic>> merged = [];
    final Set<int> mergedIndices = {};

    Map<String, dynamic>? parseGeneric(String body) {
      if (SmsParserService.isOtpOrPromo(body)) return null;
      final res = parser.parseRegexOnly(body);
      if (res != null && res.amount > 0) {
        return {
          'amount': res.amount,
          'transactionType': res.transactionType,
        };
      }
      try {
        final cleanBody = body.toLowerCase();
        final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
        final match = amtRegex.firstMatch(cleanBody);
        if (match == null) return null;
        final amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        if (amount <= 0) return null;

        final isIncome = cleanBody.contains('credited') || cleanBody.contains('received') || cleanBody.contains('deposit');
        final isExpense = cleanBody.contains('spent') ||
            cleanBody.contains('debited') ||
            cleanBody.contains('charged') ||
            cleanBody.contains('sent') ||
            cleanBody.contains('transaction') ||
            cleanBody.contains('txn') ||
            cleanBody.contains('purchase') ||
            cleanBody.contains('payment') ||
            cleanBody.contains('upi');
        if (!isIncome && !isExpense) return null;

        return {
          'amount': amount,
          'transactionType': isIncome ? 'income' : 'expense',
        };
      } catch (_) {
        return null;
      }
    }

    for (int i = 0; i < items.length; i++) {
      if (mergedIndices.contains(i)) continue;

      final itemA = items[i];
      final bodyA = itemA['body'] as String;
      final dateA = itemA['date'] as DateTime;
      final sourceA = itemA['source'] as String;

      final parsedA = parseGeneric(bodyA);
      if (parsedA == null || (parsedA['amount'] as double) <= 0) {
        merged.add(itemA);
        continue;
      }

      final List<int> matches = [];
      for (int j = i + 1; j < items.length; j++) {
        if (mergedIndices.contains(j)) continue;

        final itemB = items[j];
        final bodyB = itemB['body'] as String;
        final dateB = itemB['date'] as DateTime;

        if (bodyA == bodyB) {
          matches.add(j);
          continue;
        }

        final timeDiff = dateA.difference(dateB).abs().inMinutes;
        if (timeDiff > 15) continue;

        final parsedB = parseGeneric(bodyB);
        if (parsedB == null || (parsedB['amount'] as double) <= 0) continue;

        final amtA = parsedA['amount'] as double;
        final amtB = parsedB['amount'] as double;
        final amtDiff = (amtA - amtB).abs();

        final bodyALower = bodyA.toLowerCase();
        final bodyBLower = bodyB.toLowerCase();
        final isCardPayment = bodyALower.contains('cred') ||
            bodyALower.contains('towards') ||
            bodyALower.contains('card payment') ||
            bodyALower.contains('credit card') ||
            bodyBLower.contains('cred') ||
            bodyBLower.contains('towards') ||
            bodyBLower.contains('card payment') ||
            bodyBLower.contains('credit card');

        bool isMatch = false;

        if (isCardPayment) {
          if (amtDiff <= 150.0 && (amtDiff / amtA) < 0.02) {
            isMatch = true;
          }
        } else {
          if (amtDiff <= 0.05) {
            final typeA = parsedA['transactionType'] == 'transfer' ? 'expense' : parsedA['transactionType'];
            final typeB = parsedB['transactionType'] == 'transfer' ? 'expense' : parsedB['transactionType'];
            if (typeA == typeB) {
              isMatch = true;
            }
          }
        }

        if (isMatch) {
          matches.add(j);
        }
      }

      if (matches.isNotEmpty) {
        String smsBody = sourceA == 'sms' ? bodyA : '';
        String emailBody = sourceA == 'email' ? bodyA : '';
        String? mergedSubject = itemA['subject'] as String?;
        bool approvedByRegex = itemA['approvedByRegex'] == true;
        bool isAlreadyRecorded = itemA['isAlreadyRecorded'] == true;
        bool isSkipped = itemA['isSkipped'] == true;

        for (final matchIdx in matches) {
          mergedIndices.add(matchIdx);
          final matchItem = items[matchIdx];
          final matchSrc = matchItem['source'] as String;
          final matchBody = matchItem['body'] as String;
          final matchSubject = matchItem['subject'] as String?;
          if (matchSrc == 'sms') {
            if (smsBody.isEmpty) {
              smsBody = matchBody;
            } else if (!smsBody.contains(matchBody)) {
              smsBody = '$smsBody\n\n$matchBody';
            }
          }
          if (matchSrc == 'email') {
            if (emailBody.isEmpty) {
              emailBody = matchBody;
            } else if (!emailBody.contains(matchBody)) {
              emailBody = '$emailBody\n\n$matchBody';
            }
          }
          if (mergedSubject == null || mergedSubject.isEmpty) {
            mergedSubject = matchSubject;
          }
          if (matchItem['approvedByRegex'] == true) approvedByRegex = true;
          if (matchItem['isAlreadyRecorded'] == true) isAlreadyRecorded = true;
          if (matchItem['isSkipped'] == true) isSkipped = true;
        }

        final finalSource = (smsBody.isNotEmpty && emailBody.isNotEmpty)
            ? 'sms_email'
            : (smsBody.isNotEmpty ? 'sms' : 'email');

        final finalBody = finalSource == 'sms_email'
            ? '📱 SMS:\n$smsBody\n\n📧 EMAIL:\n$emailBody'
            : (smsBody.isNotEmpty ? smsBody : emailBody);

        merged.add({
          'body': finalBody,
          'date': dateA,
          'source': finalSource,
          'approvedByRegex': approvedByRegex,
          'smsBody': smsBody.isNotEmpty ? smsBody : null,
          'emailBody': emailBody.isNotEmpty ? emailBody : null,
          'subject': mergedSubject,
          'isAlreadyRecorded': isAlreadyRecorded,
          'isSkipped': isSkipped,
        });
      } else {
        merged.add(itemA);
      }
    }

    return merged;
  }

  Future<void> _performBackgroundSync() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final syncService = ref.read(googleSyncServiceProvider);
      final restored = await syncService.syncOnStartup(dbService);
      if (restored && mounted) {
        // Reload all providers since database was restored
        ref.read(transactionsProvider.notifier).loadTransactions();
        ref.read(creditCardsProvider.notifier).loadCreditCards();
        ref.read(bankAccountsProvider.notifier).loadBankAccounts();
        ref.read(loansProvider.notifier).loadLoans();
        ref.read(holdingsProvider.notifier).loadHoldings();
      }
    } catch (e) {
      debugPrint('Background startup sync failed: $e');
    }
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

  final List<bool> _loadedScreens = [true, false, false, false, false];

  final List<Widget> _screens = const [
    DashboardView(),
    CardsLoansView(),
    InvestmentsView(),
    AdvisorView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loadedScreens[_currentIndex]) {
      _loadedScreens[_currentIndex] = true;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: List.generate(_screens.length, (index) {
                return _loadedScreens[index] ? _screens[index] : const SizedBox.shrink();
              }),
            ),
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
