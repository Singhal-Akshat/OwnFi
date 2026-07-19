import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../features/cards_loans/models/card_loan_models.dart';

class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeType = ref.watch(transactionTypeFilterProvider);
    final activeCategory = ref.watch(transactionCategoryFilterProvider);
    final activeAccount = ref.watch(transactionAccountFilterProvider);
    final activeSort = ref.watch(transactionSortProvider);
    final activeMonth = ref.watch(transactionMonthFilterProvider);

    final bankAccounts = ref.watch(bankAccountsProvider).valueOrNull ?? [];
    final creditCards = ref.watch(creditCardsProvider).valueOrNull ?? [];

    final categories = CategoryUtils.availableCategoryColors.keys.toList();

    final List<MapEntry<DateTime?, String>> monthOptions = [
      const MapEntry(null, 'All Time'),
    ];

    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final mDate = DateTime(now.year, now.month - i);
      final monthName = _getMonthName(mDate.month);
      monthOptions.add(MapEntry(mDate, '$monthName ${mDate.year}'));
    }

    return GlassBlur(
      borderRadius: 24,
      blurX: 30,
      blurY: 30,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.obsidianSurface.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters & Sorting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(transactionTypeFilterProvider.notifier).state = null;
                      ref.read(transactionCategoryFilterProvider.notifier).state = null;
                      ref.read(transactionAccountFilterProvider.notifier).state = null;
                      ref.read(transactionSortProvider.notifier).state = 'date_desc';
                      ref.read(transactionSearchQueryProvider.notifier).state = '';
                      final currentNow = DateTime.now();
                      ref.read(transactionMonthFilterProvider.notifier).state = DateTime(currentNow.year, currentNow.month);
                    },
                    child: const Text(
                      'Reset All',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort By Section
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: activeSort,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'date_desc', child: Text('Date: Newest First')),
                  DropdownMenuItem(value: 'date_asc', child: Text('Date: Oldest First')),
                  DropdownMenuItem(value: 'amount_desc', child: Text('Amount: High to Low')),
                  DropdownMenuItem(value: 'amount_asc', child: Text('Amount: Low to High')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(transactionSortProvider.notifier).state = val;
                  }
                },
              ),
              const SizedBox(height: 20),

              // Month Section
              const Text(
                'MONTH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<DateTime?>(
                value: activeMonth != null ? DateTime(activeMonth.year, activeMonth.month) : null,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: monthOptions.map((entry) {
                  return DropdownMenuItem<DateTime?>(
                    value: entry.key != null ? DateTime(entry.key!.year, entry.key!.month) : null,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  ref.read(transactionMonthFilterProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 20),

              // Transaction Type Section
              const Text(
                'TRANSACTION TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTypeChip(ref, null, 'All', activeType),
                  const SizedBox(width: 8),
                  _buildTypeChip(ref, 'expense', 'Expense', activeType),
                  const SizedBox(width: 8),
                  _buildTypeChip(ref, 'income', 'Income', activeType),
                  const SizedBox(width: 8),
                  _buildTypeChip(ref, 'transfer', 'Transfer', activeType),
                ],
              ),
              const SizedBox(height: 20),

              // Category Section
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: activeCategory,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            CategoryUtils.getCategoryIcon(cat),
                            size: 16,
                            color: CategoryUtils.getCategoryColor(cat, Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(transactionCategoryFilterProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 20),

              // Card / Account Section
              const Text(
                'CARD / ACCOUNT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: activeAccount,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Cards & Accounts')),
                  ...bankAccounts.map((acc) {
                    return DropdownMenuItem(
                      value: 'bank:${acc.id}',
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.neonTeal),
                          const SizedBox(width: 8),
                          Text(acc.bankName),
                        ],
                      ),
                    );
                  }),
                  ...creditCards.map((card) {
                    return DropdownMenuItem(
                      value: card.id.toString(),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card_rounded, size: 16, color: AppColors.neonPink),
                          const SizedBox(width: 8),
                          Text(card.cardName),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(transactionAccountFilterProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 30),

              // Close / Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonTeal,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply & Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(WidgetRef ref, String? value, String label, String? activeValue) {
    final isSelected = value == activeValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.neonTeal,
      backgroundColor: Colors.white.withOpacity(0.05),
      onSelected: (selected) {
        if (selected) {
          ref.read(transactionTypeFilterProvider.notifier).state = value;
        }
      },
    );
  }
}
