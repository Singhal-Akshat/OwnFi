import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/database_service.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/google_sync_service.dart';

class ClearDataDialog extends ConsumerStatefulWidget {
  final String type;

  const ClearDataDialog({
    super.key,
    this.type = 'all',
  });

  static Future<void> show(BuildContext context, {String type = 'all'}) {
    return showDialog<void>(
      context: context,
      builder: (context) => ClearDataDialog(type: type),
    );
  }

  @override
  ConsumerState<ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends ConsumerState<ClearDataDialog> {
  final _storage = const FlutterSecureStorage();
  final _textController = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
      debugPrint('Biometrics failed: $e');
    }

    // Fallback to PIN dialog
    final storedPin = await _storage.read(key: 'settings_backup_pin') ?? '1234';
    final pinController = TextEditingController();

    if (!context.mounted) return false;

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
                                content: Text('Incorrect PIN. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    String title = 'Erase All Data';
    String warning =
        'This will permanently delete all transactions, credit cards, active loans, and portfolios from this device. This operation cannot be undone.';
    if (widget.type == 'transactions') {
      title = 'Clear All Transactions';
      warning =
          'This will permanently delete all transaction history from this device. Your cards and bank accounts will remain intact.';
    } else if (widget.type == 'loans') {
      title = 'Clear All Debts & Loans';
      warning =
          'This will permanently delete all active loans and debtor/creditor ledgers. Your cards and bank accounts will remain intact.';
    } else if (widget.type == 'sync_history') {
      title = 'Reset Sync History';
      warning =
          'This will clear all records of skipped/ignored messages and delete the last sync timestamps for all accounts. The next sync will perform a complete scan from the beginning.';
    }

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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                controller: _textController,
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
                    _canDelete = val == 'CLEAR';
                  });
                },
              ),
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
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canDelete ? Colors.redAccent : Colors.redAccent.withOpacity(0.2),
                      foregroundColor: _canDelete ? Colors.white : Colors.white.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: !_canDelete
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context); // Close confirm dialog

                            // Trigger security authentication layer
                            final authenticated = await _authenticateUserForClear(context);
                            if (authenticated) {
                              // Clear DB based on type
                              if (widget.type == 'sync_history') {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('skipped_sms_messages');
                                await prefs.remove('regex_skipped_messages');

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
                              } else if (widget.type == 'transactions') {
                                await ref.read(databaseServiceProvider).clearAllTransactions();
                                await _storage.delete(key: 'last_sms_sync_time');
                                await _storage.delete(key: 'last_email_sync_time');
                                ref.read(transactionsProvider.notifier).loadTransactions();
                                ref.read(creditCardsProvider.notifier).loadCreditCards();
                                ref.read(bankAccountsProvider.notifier).loadBankAccounts();
                              } else if (widget.type == 'loans') {
                                await ref.read(databaseServiceProvider).clearAllLoans();
                                ref.read(loansProvider.notifier).loadLoans();
                              } else {
                                await ref.read(databaseServiceProvider).clearAllData();
                                await _storage.delete(key: 'last_sms_sync_time');
                                await _storage.delete(key: 'last_email_sync_time');
                                ref.read(transactionsProvider.notifier).loadTransactions();
                                ref.read(creditCardsProvider.notifier).loadCreditCards();
                                ref.read(bankAccountsProvider.notifier).loadBankAccounts();
                                ref.read(loansProvider.notifier).loadLoans();
                                ref.read(holdingsProvider.notifier).loadHoldings();
                              }

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Selected data successfully cleared from the database.'),
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
  }
}
