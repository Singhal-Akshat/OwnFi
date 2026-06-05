import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/animated_gradient_background.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/database_service.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';

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
