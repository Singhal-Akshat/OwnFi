import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/animated_gradient_background.dart';
import '../../../cards_loans/models/card_loan_models.dart';

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
