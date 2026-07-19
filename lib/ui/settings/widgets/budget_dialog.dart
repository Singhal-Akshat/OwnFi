import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/expenses/models/budget_model.dart';

class BudgetDialog extends ConsumerStatefulWidget {
  const BudgetDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const BudgetDialog(),
    );
  }

  @override
  ConsumerState<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<BudgetDialog> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'All'; // 'All' denotes global budget
  final int _currentYearMonth = DateTime.now().year * 100 + DateTime.now().month;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsProvider);

    final categories = ['All', ...CategoryUtils.availableCategoryColors.keys];

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
                  'Monthly Budgets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set monthly limits overall or for specific spending categories. Alerts trigger when category spending hits 80% or 100%.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Set/Edit Budget form
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.obsidianSurface,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            cat == 'All' ? Icons.all_inclusive_rounded : CategoryUtils.getCategoryIcon(cat),
                            size: 18,
                            color: cat == 'All' ? AppColors.neonTeal : CategoryUtils.getCategoryColor(cat, Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(cat == 'All' ? 'Global Limit' : cat, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Limit Amount (₹)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 5000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final amtText = _amountController.text.trim();
                      final amt = double.tryParse(amtText) ?? 0.0;
                      if (amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid limit amount.')),
                        );
                        return;
                      }

                      final budgets = budgetsState.valueOrNull ?? [];
                      // Find if we already have a budget for this category
                      Budget targetBudget = Budget();
                      for (final b in budgets) {
                        if (b.category == _selectedCategory) {
                          targetBudget = b;
                          break;
                        }
                      }

                      targetBudget
                        ..category = _selectedCategory
                        ..amountLimit = amt
                        ..yearMonth = _currentYearMonth;

                      await ref.read(budgetsProvider.notifier).addOrUpdateBudget(targetBudget);
                      _amountController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Budget limit set for ${_selectedCategory == 'All' ? "Global Limit" : _selectedCategory} to ${amt.toIndianRupee()}',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Limit'),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'CURRENT LIMITS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // List of current budgets
                budgetsState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.neonTeal),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No budgets configured for this month.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: budgets.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder, height: 1),
                        itemBuilder: (context, index) {
                          final b = budgets[index];
                          final isGlobal = b.category == 'All';
                          final color = isGlobal ? AppColors.neonTeal : CategoryUtils.getCategoryColor(b.category, Colors.white);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGlobal ? Icons.all_inclusive_rounded : CategoryUtils.getCategoryIcon(b.category),
                                color: color,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isGlobal ? 'Global Limit' : b.category,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.amountLimit.toIndianRupee(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    ref.read(budgetsProvider.notifier).removeBudget(b.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.textSecondary),
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
