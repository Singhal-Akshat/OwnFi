import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/utils/category_utils.dart';
import 'package:my_personal_tracker/core/utils/icon_list.dart';
import 'package:my_personal_tracker/core/utils/transaction_merger.dart';
import 'package:my_personal_tracker/core/database_service.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/sync/drive_backup_service.dart';
import 'package:my_personal_tracker/core/sync/gmail_sync_service.dart';
import 'package:my_personal_tracker/core/sync/google_auth_manager.dart';
import 'package:my_personal_tracker/core/sync/backup_orchestrator.dart';
import 'package:my_personal_tracker/core/animated_gradient_background.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';
import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/investments/models/holding_model.dart';
import 'package:my_personal_tracker/features/parser/services/sms_parser_service.dart';
import 'package:my_personal_tracker/features/parser/services/sms_sync_service.dart';
import 'package:my_personal_tracker/features/parser/services/email_sync_service.dart';
import 'package:my_personal_tracker/features/advisor/services/quant_forecast_service.dart';
import 'package:my_personal_tracker/features/advisor/services/ai_advisor_service.dart';
import 'package:my_personal_tracker/features/advisor/providers/advisor_providers.dart';
import 'widgets/bank_account_card.dart';
import 'widgets/recovery_bin_page.dart';
import 'widgets/bank_account_detail_view.dart';
import 'widgets/api_keys_dialog.dart';
import 'widgets/categories_dialog.dart';
import 'widgets/google_accounts_dialog.dart';
import 'widgets/imap_config_dialog.dart';
import 'widgets/sms_lookback_dialog.dart';
import 'widgets/manage_passwords_dialog.dart';
import 'widgets/huggingface_dialog.dart';
import 'widgets/clear_data_dialog.dart';
import 'widgets/webdav_sync_dialog.dart';
import 'widgets/skipped_messages_log_dialog.dart';
import 'model_download_page.dart';
import '../../features/expenses/ui/widgets/transaction_dialogs.dart';
import 'widgets/sync_review_helper.dart';

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
  bool _showOnlyValidSmsEmail = true;
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
    final showOnlyValid = await _storage.read(key: 'settings_show_only_valid_sms_email') ?? 'true';

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
      _showOnlyValidSmsEmail = showOnlyValid == 'true';
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
                  onTap: () => ManagePasswordsDialog.show(context),
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
                   onTap: () => GoogleAccountsDialog.show(context),
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
                  onTap: () => SmsLookbackDialog.show(
                    context: context,
                    initialValue: _smsLookbackValue,
                    initialUnit: _smsLookbackUnit,
                    initialStartDate: _syncStartDate,
                    initialEndDate: _syncEndDate,
                    onSave: (val, unit, start, end) {
                      setState(() {
                        _smsLookbackValue = val;
                        _smsLookbackUnit = unit;
                        _syncStartDate = start;
                        _syncEndDate = end;
                      });
                    },
                  ),
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
                    'Show Only Valid SMS/Email',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Only review regex-approved messages first during sync',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _showOnlyValidSmsEmail,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) async {
                    setState(() => _showOnlyValidSmsEmail = val);
                    await _storage.write(
                      key: 'settings_show_only_valid_sms_email',
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
                   onTap: () => CategoriesDialog.show(context),
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
                   onTap: () => ApiKeysDialog.show(context),
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
                  onTap: () => HuggingFaceDialog.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Parser Logs
          _buildGroupTitle('Parser Logs'),
          GlassBlur(
            borderRadius: 20,
            child: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.neonTeal),
                    ),
                  );
                }
                final prefs = snapshot.data!;
                final skippedList = prefs.getStringList('regex_skipped_messages') ?? [];
                if (skippedList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No skipped messages logged yet.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Regex Skipped SMS & Email Log',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'View ${skippedList.length} SMS & email alerts that did not match transaction rules',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.obsidianSurface,
                                  title: const Text('Delete Logs', style: TextStyle(color: Colors.white)),
                                  content: const Text('Are you sure you want to delete all parser logs?', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await prefs.remove('regex_skipped_messages');
                                setState(() {});
                              }
                            },
                          ),
                          const Icon(
                            Icons.history_edu_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      onTap: () {
                        SkippedMessagesLogDialog.show(context, skippedList);
                      },
                    ),
                  ],
                );
              },
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
                  onTap: () => ClearDataDialog.show(
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
                      ClearDataDialog.show(context, type: 'loans'),
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
                  onTap: () => ClearDataDialog.show(
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
                      ClearDataDialog.show(context, type: 'all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Version Footer
          const Center(
            child: Text(
              'OwnFi v1.0.0 • 100% Local Encryption',
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

  // Monolithic settings dialogs extracted to widgets/ directory

  // Google Accounts Dialog extracted to widgets/google_accounts_dialog.dart

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

        final emailItems = await ref
            .read(gmailSyncServiceProvider)
            .fetchNewEmailsForReview(ref.read(databaseServiceProvider));
        itemsForReview.addAll(emailItems);

        debugPrint('--- MERGE DEBUG: BEFORE MERGE (${itemsForReview.length} items) ---');
        for (int i = 0; i < itemsForReview.length; i++) {
          final it = itemsForReview[i];
          debugPrint('Item $i: Source=${it['source']}, Date=${it['date']}, Body Length=${(it['body'] as String).length}');
        }

        // Merge duplicate transactions across SMS and Email
        itemsForReview = TransactionMerger.mergeDuplicateTransactions(itemsForReview);

        debugPrint('--- MERGE DEBUG: AFTER MERGE (${itemsForReview.length} items) ---');
        for (int i = 0; i < itemsForReview.length; i++) {
          final it = itemsForReview[i];
          debugPrint('Merged Item $i: Source=${it['source']}, Date=${it['date']}, Body Length=${(it['body'] as String).length}');
        }

        // Sort items by date ascending (oldest first)
        itemsForReview.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        Navigator.pop(context); // Close loading dialog

        if (itemsForReview.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new transactions found to review!'),
            ),
          );
        } else {
          showSyncReviewDialog(context, ref, itemsForReview, showOnlyValidSmsEmail: _showOnlyValidSmsEmail);
        }
      } else {
        int smsCount = 0;
        if (Platform.isAndroid) {
          smsCount = await ref.read(smsSyncServiceProvider).syncSmsInbox();
        }

        int emailCount = 0;
        final parsedTxs = await ref
            .read(gmailSyncServiceProvider)
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

  // API Keys Dialog extracted to widgets/api_keys_dialog.dart

  // Sync config and skipped log dialogs extracted to widgets/
}

