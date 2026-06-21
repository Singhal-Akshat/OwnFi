import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/providers.dart';

class WebDavSyncDialog extends ConsumerStatefulWidget {
  const WebDavSyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const WebDavSyncDialog(),
    );
  }

  @override
  ConsumerState<WebDavSyncDialog> createState() => _WebDavSyncDialogState();
}

class _WebDavSyncDialogState extends ConsumerState<WebDavSyncDialog> {
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://');
  final _userController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate config
    ref.read(syncServiceProvider).getSyncConfig().then((config) {
      if (mounted) {
        setState(() {
          _passwordController.text = config['masterPassword'] ?? '';
          _urlController.text = config['webdavUrl'] ?? 'https://';
          _userController.text = config['webdavUser'] ?? '';
          _tokenController.text = config['webdavPassword'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Master Encryption Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'WebDAV Server URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: 'WebDAV Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
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
                        final pw = _passwordController.text.trim();
                        final url = _urlController.text.trim();
                        final user = _userController.text.trim();
                        final token = _tokenController.text.trim();

                        if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill master password, URL and username'),
                            ),
                          );
                          return;
                        }

                        await ref.read(syncServiceProvider).saveSyncConfig(
                              masterPassword: pw,
                              webdavUrl: url,
                              webdavUser: user,
                              webdavPassword: token,
                            );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sync configuration saved locally'),
                            ),
                          );
                        }
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
                          final pw = _passwordController.text.trim();
                          final url = _urlController.text.trim();
                          final user = _userController.text.trim();

                          if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please configure and save settings first'),
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
                            await ref.read(syncServiceProvider).uploadBackup();
                            if (context.mounted) {
                              Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AES-256 encrypted database backup uploaded successfully!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Backup failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
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
                          final pw = _passwordController.text.trim();
                          final url = _urlController.text.trim();
                          final user = _userController.text.trim();

                          if (pw.isEmpty || url.isEmpty || user.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please configure and save settings first'),
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
                            await ref.read(syncServiceProvider).restoreBackup();

                            // Reload all providers
                            await ref.read(transactionsProvider.notifier).loadTransactions();
                            await ref.read(creditCardsProvider.notifier).loadCreditCards();
                            await ref.read(bankAccountsProvider.notifier).loadBankAccounts();
                            await ref.read(loansProvider.notifier).loadLoans();
                            await ref.read(holdingsProvider.notifier).loadHoldings();

                            if (context.mounted) {
                              Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Encrypted backup successfully restored and database re-initialized!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Restore failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
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
  }
}
