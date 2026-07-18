import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/database_service.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/sync/google_auth_manager.dart';
import 'package:my_personal_tracker/core/sync/drive_backup_service.dart';

class GoogleAccountsDialog extends ConsumerStatefulWidget {
  const GoogleAccountsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const GoogleAccountsDialog(),
    );
  }

  @override
  ConsumerState<GoogleAccountsDialog> createState() => _GoogleAccountsDialogState();
}

class _GoogleAccountsDialogState extends ConsumerState<GoogleAccountsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassBlur(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<List<LinkedGoogleAccount>>(
            future: ref.read(googleAuthManagerProvider).getLinkedAccounts(),
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? [];
              final primary = accounts.firstWhere(
                (e) => e.isPrimary,
                orElse: () => LinkedGoogleAccount(email: 'Not Linked', isPrimary: true),
              );
              final secondaries = accounts.where((e) => !e.isPrimary).toList();

              return Column(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      .read(googleAuthManagerProvider)
                                      .authenticateAccount(true);
                                  if (acc != null && mounted) {
                                    setState(() {});
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Google Sign-In failed: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
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
                                    .read(driveBackupServiceProvider)
                                    .backupToCloud(
                                      ref.read(databaseServiceProvider),
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.sync_rounded,
                                color: AppColors.neonTeal,
                              ),
                              onPressed: () async {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Checking cloud backup status...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                                try {
                                  final restored = await ref
                                      .read(driveBackupServiceProvider)
                                      .syncOnStartup(
                                        ref.read(databaseServiceProvider),
                                      );
                                  if (restored) {
                                    ref.read(transactionsProvider.notifier).loadTransactions();
                                    ref.read(creditCardsProvider.notifier).loadCreditCards();
                                    ref.read(bankAccountsProvider.notifier).loadBankAccounts();
                                    ref.read(loansProvider.notifier).loadLoans();
                                    ref.read(holdingsProvider.notifier).loadHoldings();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Sync completed. Newer data restored from Google Drive.'),
                                          backgroundColor: AppColors.neonEmerald,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Your database is already in sync with Google Drive.'),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sync failed: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
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
                                    .read(driveBackupServiceProvider)
                                    .restoreFromCloud(
                                      ref.read(databaseServiceProvider),
                                    );
                                if (error == null) {
                                  ref.read(transactionsProvider.notifier).loadTransactions();
                                  ref.read(creditCardsProvider.notifier).loadCreditCards();
                                  ref.read(bankAccountsProvider.notifier).loadBankAccounts();
                                  ref.read(loansProvider.notifier).loadLoans();
                                  ref.read(holdingsProvider.notifier).loadHoldings();
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(googleAuthManagerProvider)
                                    .removeAccount(primary.email);
                                if (mounted) {
                                  setState(() {});
                                }
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
                                .read(googleAuthManagerProvider)
                                .authenticateAccount(false);
                            if (acc != null && mounted) {
                              setState(() {});
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Google Sign-In failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
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
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        await ref
                                            .read(googleAuthManagerProvider)
                                            .removeAccount(sec.email);
                                        if (mounted) {
                                          setState(() {});
                                        }
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.neonTeal),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
