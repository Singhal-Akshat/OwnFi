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
import 'package:my_personal_tracker/core/database_service.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/google_sync_service.dart';
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
                        'Regex Skipped SMS Log',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'View ${skippedList.length} messages that did not match transaction rules',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(
                        Icons.history_edu_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        _showSkippedMessagesLogDialog(context, skippedList);
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
    IconData selectedIconData = Icons.category_rounded;
    Color selectedColor = AppColors.neonTeal;
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
                              ? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Other']
                              : (currentType == 'income'
                                  ? ['Salary', 'Investment', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other']
                                  : ['Internal transfer', 'Credit card payment', 'Investment', 'Other']);
                          final cats = prefs.getStringList(key) ?? defaultCats;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: cats.length,
                                  itemBuilder: (context, index) {
                                    final cat = cats[index];
                                    final icon = CategoryUtils.getCategoryIcon(cat);
                                    final color = CategoryUtils.getCategoryColor(cat, Colors.white70);
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 18),
                                      ),
                                      title: Text(cat, style: const TextStyle(fontSize: 14)),
                                      trailing: cat.toLowerCase() == 'other' || cat.toLowerCase() == 'others'
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                              onPressed: () async {
                                                final updated = List<String>.from(cats)..removeAt(index);
                                                await prefs.setStringList(key, updated);
                                                
                                                // Clean up custom icon and color mappings
                                                final iconMap = prefs.getStringList('custom_category_icons') ?? [];
                                                iconMap.removeWhere((item) => item.startsWith('$cat:'));
                                                await prefs.setStringList('custom_category_icons', iconMap);

                                                final colorMap = prefs.getStringList('custom_category_colors') ?? [];
                                                colorMap.removeWhere((item) => item.startsWith('$cat:'));
                                                await prefs.setStringList('custom_category_colors', colorMap);

                                                // Reload memory cache
                                                await CategoryUtils.loadCustomCategories();
                                                
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
                                        
                                        // Save custom icon mapping (we store codePoint as string)
                                        final iconMap = prefs.getStringList('custom_category_icons') ?? [];
                                        iconMap.add('$newCat:${selectedIconData.codePoint}');
                                        await prefs.setStringList('custom_category_icons', iconMap);
                                        
                                        // Save custom color mapping
                                        final colorMap = prefs.getStringList('custom_category_colors') ?? [];
                                        final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';
                                        colorMap.add('$newCat:$colorHex');
                                        await prefs.setStringList('custom_category_colors', colorMap);

                                        // Reload memory cache
                                        await CategoryUtils.loadCustomCategories();

                                        newCategoryController.clear();
                                        selectedIconData = Icons.category_rounded;
                                        selectedColor = AppColors.neonTeal;
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Select Icon & Color:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  GestureDetector(
                                    onTap: () {
                                      _showIconPickerDialog(context, (icon, color) {
                                        setState(() {
                                          selectedIconData = icon;
                                          selectedColor = color;
                                        });
                                      });
                                    },
                                    child: const Text(
                                      'More Icons ➔',
                                      style: TextStyle(fontSize: 12, color: AppColors.neonTeal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 44,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    // Current selection preview
                                    GestureDetector(
                                      onTap: () {
                                        _showIconPickerDialog(context, (icon, color) {
                                          setState(() {
                                            selectedIconData = icon;
                                            selectedColor = color;
                                          });
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: selectedColor.withOpacity(0.25),
                                          border: Border.all(color: selectedColor, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(selectedIconData, color: selectedColor, size: 18),
                                      ),
                                    ),
                                    ...CategoryUtils.availableCategoryIcons.entries.map((e) {
                                      final isSelected = selectedIconData == e.value;
                                      final iconColor = CategoryUtils.availableCategoryColors[e.key] ?? Colors.white;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIconData = e.value;
                                            selectedColor = iconColor;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? iconColor.withOpacity(0.15) : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected ? iconColor : Colors.white10,
                                              width: 1.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(e.value, color: isSelected ? iconColor : Colors.white70, size: 18),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
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

  void _showIconPickerDialog(BuildContext context, void Function(IconData, Color) onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedCategory = CategoryUtils.iconLibrary.keys.first;
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setState) {
            final filteredIcons = <IconData>[];
            if (searchQuery.isNotEmpty) {
              IconList.allIcons.forEach((name, icon) {
                if (name.contains(searchQuery)) {
                  filteredIcons.add(icon);
                }
              });
            } else {
              filteredIcons.addAll(CategoryUtils.iconLibrary[selectedCategory] ?? []);
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Icon Library',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      // Search field
                      TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search icons (e.g. food, bill, bank)...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val.toLowerCase().trim();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Category Tabs selector (only show when not searching)
                      if (searchQuery.isEmpty) ...[
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: CategoryUtils.iconLibrary.keys.map((catName) {
                              final isSelected = selectedCategory == catName;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(catName, style: const TextStyle(fontSize: 11)),
                                  selected: isSelected,
                                  selectedColor: AppColors.neonPurple.withOpacity(0.2),
                                  checkmarkColor: AppColors.neonPurple,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.neonPurple : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        selectedCategory = catName;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Icons Grid
                      Container(
                        width: double.maxFinite,
                        height: 200,
                        child: filteredIcons.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching icons found',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              )
                            : GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filteredIcons.length,
                                itemBuilder: (context, index) {
                                  final icon = filteredIcons[index];
                                  return InkWell(
                                    onTap: () {
                                      final color = Colors.primaries[icon.codePoint % Colors.primaries.length];
                                      onSelected(icon, color);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Icon(icon, color: Colors.white, size: 22),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
          showSyncReviewDialog(context, ref, itemsForReview, showOnlyValidSmsEmail: _showOnlyValidSmsEmail);
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

  void _showSkippedMessagesLogDialog(BuildContext context, List<String> skippedList) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Regex Skipped Messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonTeal,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scrollable list of SMS alerts that were automatically skipped by the regex parser.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: skippedList.length,
                      itemBuilder: (context, index) {
                        try {
                          final item = jsonDecode(skippedList[index]);
                          final body = item['body'] ?? '';
                          final dateStr = item['date'] ?? '';
                          final sender = item['sender'] ?? 'Unknown';
                          final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                          return InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              showSyncReviewDialog(
                                context,
                                ref,
                                [
                                  {
                                    'body': body,
                                    'date': date,
                                    'source': 'sms',
                                    'approvedByRegex': true,
                                  }
                                ],
                                showOnlyValidSmsEmail: true,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            sender.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.playlist_add_check_rounded,
                                            size: 14,
                                            color: AppColors.neonTeal,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        DateFormat('dd MMM, hh:mm a').format(date),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      },
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

