import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/database_service.dart';
import '../../../core/providers.dart';
import '../../../core/google_sync_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_utils.dart';
import '../../expenses/models/transaction_model.dart';
import '../../cards_loans/models/card_loan_models.dart';
import '../../investments/models/holding_model.dart';
import '../../../../ui/settings/widgets/bank_account_card.dart';
import 'widgets/transaction_dialogs.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsState = ref.watch(transactionsProvider);
    final cardsState = ref.watch(creditCardsProvider);
    final loansState = ref.watch(loansProvider);
    final holdingsState = ref.watch(holdingsProvider);

    // Dynamic Net Worth Calculation using Riverpod Providers
    final totalHoldingsVal = ref.watch(totalHoldingsValueProvider);
    final totalCardOutstanding = ref.watch(totalCardOutstandingProvider);
    final totalDebts = ref.watch(totalDebtsProvider);
    final totalReceivables = ref.watch(totalReceivablesProvider);
    final cashAndBank = ref.watch(cashAndBankProvider);
    final netWorth = ref.watch(netWorthProvider);

    final bankAccountsState = ref.watch(bankAccountsProvider);

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
                        showTransactionEntryDialog(context, ref);
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
                      isLoading: txsState.isLoading ||
                          cardsState.isLoading ||
                          loansState.isLoading ||
                          holdingsState.isLoading,
                    ),

                    // Card 2+: Bank Accounts
                    ...accounts.map((account) {
                      return _buildBankAccountCard(
                        context,
                        ref,
                        account,
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
                          useBlur: false,
                          child: ListTile(
                            onTap: () => showTransactionDetailDialog(context, tx),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: CategoryUtils.getCategoryColor(tx.category, iconColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CategoryUtils.getCategoryIcon(tx.category),
                                    color: CategoryUtils.getCategoryColor(tx.category, iconColor),
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
                                                    placeholderBuilder: (context) => Container(
                                                      color: Colors.white10,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/credit_card_images/${card.imageUrl}',
                                                    fit: BoxFit.cover,
                                                    frameBuilder: (context, child, frame, wasSync) {
                                                      if (wasSync) return child;
                                                      return frame == null
                                                          ? Container(color: Colors.white10)
                                                          : child;
                                                    },
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
                                          placeholderBuilder: (context) => const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              color: AppColors.neonTeal,
                                            ),
                                          ),
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
                              String accountDisplayName;
                              if (tx.category == 'Investment') {
                                accountDisplayName = tx.description;
                              } else if (tx.cardId != null) {
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
                              } else {
                                accountDisplayName = 'Cash';
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
                                          if (tx.source == 'sms_email') const Text('📱✉️ SMS & Email', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
    double receivables, {
    required bool isLoading,
  }) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.neonTeal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: isLoading
                    ? const SizedBox(
                        height: 38,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: AppColors.neonTeal,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        netWorth.toIndianRupee(),
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
                      totalHoldingsVal.toIndianRupee(),
                      AppColors.neonEmerald,
                    ),
                  ),
                  Expanded(
                    child: _buildAssetMini(
                      'Cash/Bank',
                      cashAndBank.toIndianRupee(),
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
                      (-liabilities).toIndianRupee(),
                      Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildAssetMini(
                      'Receivables',
                      receivables.toIndianRupee(),
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
  ) {
    return BankAccountCard(
      account: account,
      ref: ref,
      formatCurrency: (val) => val.toIndianRupee(),
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
}
