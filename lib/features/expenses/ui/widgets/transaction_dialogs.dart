import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../../../core/theme.dart';
import '../../../../core/database_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/category_utils.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';
import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/investments/models/holding_model.dart';
import '../../../../ui/settings/widgets/bank_account_card.dart';

class TransactionFormController {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedType = 'expense';
  String selectedCategory = 'Other';
  String selectedAccount = 'Cash';
  String selectedToAccount = 'Cash';

  // Payback details
  bool isPayback = false;
  final paybackContactController = TextEditingController();
  DateTime paybackDate = DateTime.now().add(const Duration(days: 30));
  int? selectedDebtId;

  // Split details
  bool isSplit = false;
  int? selectedSplitLoanId;
  final splitFriendController = TextEditingController();
  final splitAmountController = TextEditingController();

  // Investment details
  bool isCreatingNewInvestment = false;
  String selectedInvestmentName = '';
  final newInvestmentNameController = TextEditingController();
  String newInvestmentAssetType = 'stock';

  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    paybackContactController.dispose();
    newInvestmentNameController.dispose();
    splitFriendController.dispose();
    splitAmountController.dispose();
  }

  void reset({
    double? amount,
    String? description,
    String? type,
    String? category,
    String? account,
    String? toAccount,
  }) {
    amountController.text = amount != null ? amount.toStringAsFixed(0) : '';
    descriptionController.text = description ?? '';
    selectedType = type ?? 'expense';
    selectedCategory = category ?? 'Other';
    selectedAccount = account ?? 'Cash';
    selectedToAccount = toAccount ?? 'Cash';
    isPayback = false;
    paybackContactController.clear();
    paybackDate = DateTime.now().add(const Duration(days: 30));
    selectedDebtId = null;
    isSplit = false;
    selectedSplitLoanId = null;
    splitFriendController.clear();
    splitAmountController.clear();
    isCreatingNewInvestment = false;
    selectedInvestmentName = '';
    newInvestmentNameController.clear();
    newInvestmentAssetType = 'stock';
  }
}

class TransactionFormFields extends ConsumerWidget {
  final TransactionFormController controller;
  final VoidCallback onStateChanged;

  const TransactionFormFields({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(creditCardsProvider);
    final bankAccountsState = ref.watch(bankAccountsProvider);
    final loansState = ref.watch(loansProvider);
    final holdingsState = ref.watch(holdingsProvider);

    final existingInvestments = holdingsState.valueOrNull ?? [];
    final activeCards = cardsState.valueOrNull ?? [];
    final activeBanks = bankAccountsState.valueOrNull ?? [];
    final activeLoans = loansState.valueOrNull ?? [];

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final List<String> expenseCats = List<String>.from(prefs?.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Payback', 'Other']);
        final List<String> incomeCats = List<String>.from(prefs?.getStringList('categories_income') ?? ['Salary', 'Investment', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other']);
        final List<String> transferCats = List<String>.from(prefs?.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Investment', 'Other']);

        final List<String> currentCats = List<String>.from(controller.selectedType == 'expense'
            ? expenseCats
            : (controller.selectedType == 'income' ? incomeCats : transferCats));

        if (!currentCats.contains(controller.selectedCategory)) {
          if (currentCats.contains('Other')) {
            controller.selectedCategory = 'Other';
          } else if (currentCats.isNotEmpty) {
            controller.selectedCategory = currentCats.first;
          } else {
            controller.selectedCategory = '';
          }
        }

        if (controller.selectedCategory == 'Investment') {
          if (controller.selectedInvestmentName.isEmpty && existingInvestments.isNotEmpty && !controller.isCreatingNewInvestment) {
            controller.selectedInvestmentName = existingInvestments.first.name;
            if (controller.descriptionController.text.isEmpty) {
              controller.descriptionController.text = controller.selectedInvestmentName;
            }
          } else if (existingInvestments.isEmpty) {
            controller.isCreatingNewInvestment = true;
          }
        }

        List<DropdownMenuItem<String>> buildDropdownItems(String valueToVerify) {
          final List<DropdownMenuItem<String>> menu = [
            DropdownMenuItem(
              value: 'Cash',
              child: Row(
                children: [
                  const Icon(Icons.wallet_rounded, color: AppColors.neonEmerald, size: 18),
                  const SizedBox(width: 8),
                  const Text('Cash'),
                ],
              ),
            ),
          ];

          for (final acc in activeBanks) {
            Widget logoWidget = const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 18);
            if (acc.logoAsset.isNotEmpty) {
              logoWidget = SvgPicture.asset('assets/bank_logos/${acc.logoAsset}', width: 18, height: 18);
            }
            menu.add(
              DropdownMenuItem(
                value: 'bank:${acc.id}',
                child: Row(
                  children: [
                    logoWidget,
                    const SizedBox(width: 8),
                    Expanded(child: Text('${acc.bankName} (..${acc.last4})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ),
              ),
            );
          }

          for (final card in activeCards) {
            Widget cardVisual = Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(3),
              ),
            );
            if (card.imageUrl.isNotEmpty) {
              cardVisual = ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 20,
                  height: 14,
                  child: card.imageUrl.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset('assets/credit_card_images/${card.imageUrl}', fit: BoxFit.fill)
                      : Image.asset('assets/credit_card_images/${card.imageUrl}', fit: BoxFit.cover),
                ),
              );
            } else {
              cardVisual = const Icon(Icons.credit_card_rounded, color: Colors.blueAccent, size: 18);
            }

            menu.add(
              DropdownMenuItem(
                value: 'card:${card.id}',
                child: Row(
                  children: [
                    cardVisual,
                    const SizedBox(width: 8),
                    Expanded(child: Text('${card.cardName} (..${card.last4})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ),
              ),
            );
          }

          if (!menu.any((item) => item.value == valueToVerify)) {
            menu.add(
              DropdownMenuItem(
                value: valueToVerify,
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('Unknown Account ($valueToVerify)'),
                  ],
                ),
              ),
            );
          }

          return menu;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Switcher
            DropdownButtonFormField<String>(
              value: controller.selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              dropdownColor: AppColors.obsidianSurface,
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              ],
              onChanged: (val) {
                if (val != null) {
                  controller.selectedType = val;
                  onStateChanged();
                }
              },
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: controller.amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Croma Store',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: controller.selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              dropdownColor: AppColors.obsidianSurface,
              isExpanded: true,
              items: currentCats.map((cat) {
                final icon = CategoryUtils.getCategoryIcon(cat);
                final color = CategoryUtils.getCategoryColor(cat, AppColors.textSecondary);
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(cat),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.selectedCategory = val;
                  if (val == 'Investment') {
                    if (existingInvestments.isNotEmpty) {
                      controller.isCreatingNewInvestment = false;
                      controller.selectedInvestmentName = existingInvestments.first.name;
                      controller.descriptionController.text = controller.selectedInvestmentName;
                    } else {
                      controller.isCreatingNewInvestment = true;
                    }
                  }
                  onStateChanged();
                }
              },
            ),
            const SizedBox(height: 12),

            // Investment fields
            if (controller.selectedCategory == 'Investment') ...[
              DropdownButtonFormField<String>(
                value: controller.isCreatingNewInvestment ? '__new__' : (controller.selectedInvestmentName.isEmpty && existingInvestments.isNotEmpty ? existingInvestments.first.name : controller.selectedInvestmentName),
                decoration: const InputDecoration(
                  labelText: 'Select Investment Account',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: AppColors.obsidianSurface,
                items: [
                  ...existingInvestments.map((h) => DropdownMenuItem(
                        value: h.name,
                        child: Text('${h.name} (${h.assetType.toUpperCase()})'),
                      )),
                  const DropdownMenuItem(
                    value: '__new__',
                    child: Text('+ Create New Investment...', style: TextStyle(color: AppColors.neonTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__new__') {
                    controller.isCreatingNewInvestment = true;
                    controller.selectedInvestmentName = '';
                  } else {
                    controller.isCreatingNewInvestment = false;
                    controller.selectedInvestmentName = val!;
                    controller.descriptionController.text = val;
                  }
                  onStateChanged();
                },
              ),
              if (controller.isCreatingNewInvestment) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller.newInvestmentNameController,
                  decoration: const InputDecoration(
                    labelText: 'New Investment Name',
                    hintText: 'e.g. HDFC Liquid Fund',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    controller.descriptionController.text = val;
                    onStateChanged();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: controller.newInvestmentAssetType,
                  decoration: const InputDecoration(
                    labelText: 'Investment Type',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.obsidianSurface,
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(value: 'mutual_fund', child: Text('Mutual Fund')),
                    DropdownMenuItem(value: 'stable', child: Text('Stable')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      controller.newInvestmentAssetType = val;
                      onStateChanged();
                    }
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Account selectors
            if (controller.selectedType == 'transfer') ...[
              DropdownButtonFormField<String>(
                value: controller.selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'From Account (Source)',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: AppColors.obsidianSurface,
                isExpanded: true,
                items: buildDropdownItems(controller.selectedAccount),
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedAccount = val;
                    onStateChanged();
                  }
                },
              ),
              if (controller.selectedCategory != 'Investment') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: controller.selectedToAccount,
                  decoration: const InputDecoration(
                    labelText: 'To Account (Destination)',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.obsidianSurface,
                  isExpanded: true,
                  items: buildDropdownItems(controller.selectedToAccount),
                  onChanged: (val) {
                    if (val != null) {
                      controller.selectedToAccount = val;
                      onStateChanged();
                    }
                  },
                ),
              ],
            ] else if (controller.selectedCategory != 'Investment') ...[
              DropdownButtonFormField<String>(
                value: controller.selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Account / Card',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: AppColors.obsidianSurface,
                  isExpanded: true,
                  items: buildDropdownItems(controller.selectedAccount),
                  onChanged: (val) {
                    if (val != null) {
                      controller.selectedAccount = val;
                      onStateChanged();
                    }
                  },
                ),
              ],
            const SizedBox(height: 12),

            // Payback Toggle for Income
            if (controller.selectedType == 'income') ...[
              CheckboxListTile(
                title: const Text('Is this a borrowed loan to payback?'),
                subtitle: const Text(
                  '(Creates a debt entry in the ledger)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: controller.isPayback,
                activeColor: AppColors.neonEmerald,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val != null) {
                    controller.isPayback = val;
                    if (val) {
                      controller.paybackContactController.text = controller.descriptionController.text;
                    }
                    onStateChanged();
                  }
                },
              ),
              if (controller.isPayback) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  value: controller.selectedDebtId,
                  decoration: const InputDecoration(
                    labelText: 'Link to existing friend ledger?',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.obsidianSurface,
                  isExpanded: true,
                  items: () {
                    final items = [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Create New Ledger Entry...'),
                      ),
                      ...activeLoans
                          .where((l) => !l.isCompleted)
                          .map((l) => DropdownMenuItem<int?>(
                                value: l.id,
                                child: Text(l.isLent
                                    ? '${l.contactName} (Debt: -₹${l.remainingBalance.toStringAsFixed(0)})'
                                    : '${l.contactName} (Debt: ₹${l.remainingBalance.toStringAsFixed(0)})'),
                              )),
                    ];
                    if (controller.selectedDebtId != null && !items.any((item) => item.value == controller.selectedDebtId)) {
                      try {
                        final l = activeLoans.firstWhere((loan) => loan.id == controller.selectedDebtId);
                        items.add(DropdownMenuItem<int?>(
                          value: l.id,
                          child: Text(l.isLent
                              ? '${l.contactName} (Debt: -₹${l.remainingBalance.toStringAsFixed(0)})'
                              : '${l.contactName} (Debt: ₹${l.remainingBalance.toStringAsFixed(0)})'),
                        ));
                      } catch (_) {}
                    }
                    return items;
                  }(),
                  onChanged: (val) {
                    controller.selectedDebtId = val;
                    if (val != null) {
                      final chosen = activeLoans.firstWhere((l) => l.id == val);
                      controller.paybackContactController.text = chosen.contactName;
                    } else {
                      controller.paybackContactController.clear();
                    }
                    onStateChanged();
                  },
                ),
                if (controller.selectedDebtId == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.paybackContactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact / Lender Name',
                      hintText: 'e.g. Papa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: controller.paybackDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (d != null) {
                      controller.paybackDate = d;
                      onStateChanged();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expected Payback Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd MMMM yyyy').format(controller.paybackDate)),
                  ),
                ),
              ],
            ],

            // Repayment fields for Expense or Transfer
            if (controller.selectedType == 'expense' || controller.selectedType == 'transfer') ...[
              if (activeLoans.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  value: controller.selectedDebtId,
                  decoration: const InputDecoration(
                    labelText: 'Is this repaying a borrowed debt?',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.obsidianSurface,
                  isExpanded: true,
                  hint: const Text('None / Select Debt'),
                  items: () {
                    final items = [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No, regular transaction'),
                      ),
                      ...activeLoans
                          .where((l) => !l.isLent && l.remainingBalance > 0 && !l.isCompleted)
                          .map((l) => DropdownMenuItem<int?>(
                                value: l.id,
                                child: Text('${l.contactName} (Rem: ₹${l.remainingBalance.toStringAsFixed(0)})'),
                              )),
                    ];
                    if (controller.selectedDebtId != null && !items.any((item) => item.value == controller.selectedDebtId)) {
                      try {
                        final l = activeLoans.firstWhere((loan) => loan.id == controller.selectedDebtId);
                        items.add(DropdownMenuItem<int?>(
                          value: l.id,
                          child: Text('${l.contactName} (Rem: ₹${l.remainingBalance.toStringAsFixed(0)})'),
                        ));
                      } catch (_) {}
                    }
                    return items.cast<DropdownMenuItem<int?>>();
                  }(),
                  onChanged: (val) {
                    controller.selectedDebtId = val;
                    onStateChanged();
                  },
                ),
              ],
            ],

            // Split toggle and fields (only for expense type)
            if (controller.selectedType == 'expense') ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text(
                  'Split Expense?',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Split bills with friends/contacts',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: controller.isSplit,
                activeColor: AppColors.neonTeal,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val != null) {
                    controller.isSplit = val;
                    onStateChanged();
                  }
                },
              ),
              if (controller.isSplit) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: controller.selectedSplitLoanId,
                  decoration: const InputDecoration(
                    labelText: 'Link to existing friend ledger?',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.obsidianSurface,
                  isExpanded: true,
                  items: () {
                    final items = [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Create New Ledger Entry...'),
                      ),
                      ...activeLoans
                          .where((l) => !l.isCompleted)
                          .map((l) => DropdownMenuItem<int?>(
                                value: l.id,
                                child: Text(l.isLent
                                    ? '${l.contactName} (Owed: ₹${l.remainingBalance.toStringAsFixed(0)})'
                                    : '${l.contactName} (Owed: -₹${l.remainingBalance.toStringAsFixed(0)})'),
                              )),
                    ];
                    if (controller.selectedSplitLoanId != null && !items.any((item) => item.value == controller.selectedSplitLoanId)) {
                      try {
                        final l = activeLoans.firstWhere((loan) => loan.id == controller.selectedSplitLoanId);
                        items.add(DropdownMenuItem<int?>(
                          value: l.id,
                          child: Text(l.isLent
                              ? '${l.contactName} (Owed: ₹${l.remainingBalance.toStringAsFixed(0)})'
                              : '${l.contactName} (Owed: -₹${l.remainingBalance.toStringAsFixed(0)})'),
                        ));
                      } catch (_) {}
                    }
                    return items;
                  }(),
                  onChanged: (val) {
                    controller.selectedSplitLoanId = val;
                    if (val != null) {
                      final chosen = activeLoans.firstWhere((l) => l.id == val);
                      controller.splitFriendController.text = chosen.contactName;
                    } else {
                      controller.splitFriendController.clear();
                    }
                    onStateChanged();
                  },
                ),
                if (controller.selectedSplitLoanId == null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.splitFriendController,
                    decoration: const InputDecoration(
                      labelText: 'Friend Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: controller.splitAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Owed Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

// Dialog helper to add or edit a transaction
void showTransactionEntryDialog(
  BuildContext context,
  WidgetRef ref, {
  Transaction? existingTransaction,
}) {
  final controller = TransactionFormController();

  if (existingTransaction != null) {
    String account = 'Cash';
    if (existingTransaction.cardId != null) {
      account = 'card:${existingTransaction.cardId}';
    } else {
      account = existingTransaction.accountName ?? 'Cash';
    }

    String toAccount = 'Cash';
    if (existingTransaction.transactionType == 'transfer') {
      if (existingTransaction.cardId != null) {
        if (existingTransaction.cardId!.startsWith('bank:')) {
          toAccount = existingTransaction.cardId!;
        } else {
          toAccount = 'card:${existingTransaction.cardId}';
        }
      }
    }

    controller.reset(
      amount: existingTransaction.amount,
      description: existingTransaction.description,
      type: existingTransaction.transactionType,
      category: existingTransaction.category,
      account: account,
      toAccount: toAccount,
    );

    // Repopulate loan link
    if (existingTransaction.linkedLoanId != null) {
      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
      try {
        final linkedLoan = allLoans.firstWhere((l) => l.id == existingTransaction.linkedLoanId);
        if (existingTransaction.transactionType == 'income') {
          controller.isPayback = true;
          controller.paybackContactController.text = linkedLoan.contactName;
          controller.paybackDate = linkedLoan.paybackDate ?? DateTime.now().add(const Duration(days: 30));
          controller.selectedDebtId = linkedLoan.id;
        } else if (existingTransaction.isSplit) {
          controller.isSplit = true;
          controller.selectedSplitLoanId = linkedLoan.id;
          controller.splitFriendController.text = linkedLoan.contactName;
          controller.splitAmountController.text = existingTransaction.splitDetails.isNotEmpty
              ? existingTransaction.splitDetails.first.amount.toStringAsFixed(0)
              : '';
        } else {
          controller.selectedDebtId = linkedLoan.id;
        }
      } catch (_) {}
    }
  }

  DateTime selectedDateTime = existingTransaction?.timestamp ?? DateTime.now();

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          return Dialog(
            backgroundColor: Colors.transparent,
        child: GlassBlur(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existingTransaction != null ? 'Edit Transaction' : 'New Transaction',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonTeal,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.date_range_rounded, color: Colors.white70),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                                );
                                if (t != null) {
                                  setState(() {
                                    selectedDateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Date: ${DateFormat('dd MMMM yyyy, hh:mm a').format(selectedDateTime)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TransactionFormFields(
                        controller: controller,
                        onStateChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final double amount = double.tryParse(controller.amountController.text) ?? 0.0;
                              final desc = controller.descriptionController.text.trim();
                              final category = controller.selectedCategory;

                              if (amount <= 0 || desc.isEmpty || category.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all required fields')),
                                );
                                return;
                              }

                              // Handle investments saving
                              if (category == 'Investment') {
                                final name = controller.isCreatingNewInvestment ? controller.newInvestmentNameController.text.trim() : controller.selectedInvestmentName;
                                if (name.isNotEmpty) {
                                  final existingInvestments = ref.read(holdingsProvider).valueOrNull ?? [];
                                  Holding? targetHolding;
                                  for (final h in existingInvestments) {
                                    if (h.name.toLowerCase() == name.toLowerCase()) {
                                      targetHolding = h;
                                      break;
                                    }
                                  }
                                  if (targetHolding == null) {
                                    targetHolding = Holding()
                                      ..name = name
                                      ..symbol = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()
                                      ..assetType = controller.newInvestmentAssetType
                                      ..broker = 'manual'
                                      ..quantity = 0.0
                                      ..buyAvgPrice = 0.0
                                      ..currentPrice = 0.0;
                                  }

                                  if (targetHolding.assetType == 'stable') {
                                    targetHolding.quantity += amount;
                                    targetHolding.buyAvgPrice = 1.0;
                                    targetHolding.currentPrice = 1.0;
                                  } else {
                                    final double oldCost = targetHolding.buyAvgPrice * targetHolding.quantity;
                                    final double newCost = oldCost + amount;
                                    targetHolding.quantity += 1.0;
                                    targetHolding.buyAvgPrice = targetHolding.quantity > 0 ? newCost / targetHolding.quantity : 0.0;
                                    if (targetHolding.currentPrice == 0.0) {
                                      targetHolding.currentPrice = targetHolding.buyAvgPrice;
                                    }
                                  }
                                  targetHolding.lastUpdated = DateTime.now();
                                  await ref.read(databaseServiceProvider).saveHolding(targetHolding);
                                  await ref.read(holdingsProvider.notifier).loadHoldings();
                                }
                              }

                              final tx = existingTransaction ?? Transaction();
                              tx.amount = amount;
                              tx.description = desc;
                              tx.category = category;
                              tx.timestamp = selectedDateTime;
                              if (existingTransaction == null) {
                                tx.source = 'manual';
                              }
                              tx.transactionType = controller.selectedType;

                              if (controller.selectedType == 'transfer') {
                                tx.accountName = controller.selectedAccount;
                                if (controller.selectedToAccount.startsWith('card:')) {
                                  tx.cardId = controller.selectedToAccount.substring(5);
                                } else if (controller.selectedToAccount.startsWith('bank:')) {
                                  tx.cardId = controller.selectedToAccount;
                                } else {
                                  tx.cardId = null;
                                }
                              } else {
                                if (controller.selectedAccount.startsWith('card:')) {
                                  tx.cardId = controller.selectedAccount.substring(5);
                                  tx.accountName = 'Credit Card';
                                } else {
                                  tx.cardId = null;
                                  tx.accountName = controller.selectedAccount;
                                }
                              }

                              // Handle Loan updates
                              if (controller.selectedType == 'income' && controller.isPayback) {
                                final contact = controller.paybackContactController.text.trim();
                                if (contact.isNotEmpty) {
                                  final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                  if (controller.selectedDebtId != null) {
                                    try {
                                      final target = allLoans.firstWhere((l) => l.id == controller.selectedDebtId);
                                      if (target.isLent) {
                                        // It was a receivable, borrowing money reduces the receivable
                                        if (amount >= target.remainingBalance) {
                                          final excess = amount - target.remainingBalance;
                                          if (excess > 0) {
                                            target.isLent = false; // Flips to borrowed (debt)
                                            target.remainingBalance = excess;
                                            target.amount = excess;
                                            target.isCompleted = false;
                                          } else {
                                            // Fully paid
                                            target.remainingBalance = 0.0;
                                            target.isCompleted = true;
                                          }
                                        } else {
                                          target.remainingBalance -= amount;
                                        }
                                      } else {
                                        // Already borrowed (debt), borrowing more increases the debt
                                        target.amount += amount;
                                        target.remainingBalance += amount;
                                        target.isCompleted = false;
                                      }
                                      target.paybackDate = controller.paybackDate;
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(target);
                                      tx.linkedLoanId = savedId;
                                    } catch (_) {}
                                  } else {
                                    try {
                                      // Search active loan with this name case-insensitively to combine
                                      final existing = allLoans.firstWhere(
                                        (l) => !l.isCompleted && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                      );
                                      if (existing.isLent) {
                                        if (amount >= existing.remainingBalance) {
                                          final excess = amount - existing.remainingBalance;
                                          if (excess > 0) {
                                            existing.isLent = false;
                                            existing.remainingBalance = excess;
                                            existing.amount = excess;
                                            existing.isCompleted = false;
                                          } else {
                                            existing.remainingBalance = 0.0;
                                            existing.isCompleted = true;
                                          }
                                        } else {
                                          existing.remainingBalance -= amount;
                                        }
                                      } else {
                                        existing.amount += amount;
                                        existing.remainingBalance += amount;
                                        existing.isCompleted = false;
                                      }
                                      existing.paybackDate = controller.paybackDate;
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                      tx.linkedLoanId = savedId;
                                    } catch (_) {
                                      final loan = Loan()
                                        ..contactName = contact
                                        ..isLent = false
                                        ..amount = amount
                                        ..remainingBalance = amount
                                        ..startDate = DateTime.now()
                                        ..paybackDate = controller.paybackDate
                                        ..interestRate = 0.0
                                        ..compoundInterval = 'none'
                                        ..emiAmount = 0.0
                                        ..isCompleted = false;
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                      tx.linkedLoanId = savedId;
                                    }
                                  }
                                }
                              }

                              // Handle Split Expenses
                              if ((controller.selectedType == 'expense' || controller.selectedType == 'transfer') && controller.isSplit) {
                                final friend = controller.splitFriendController.text.trim();
                                final splitAmount = double.tryParse(controller.splitAmountController.text) ?? 0.0;
                                if (splitAmount > 0) {
                                  tx.isSplit = true;
                                  tx.splitDetails = [
                                    TransactionSplitDetail()
                                      ..friendName = friend.isNotEmpty ? friend : 'Friend'
                                      ..amount = splitAmount
                                      ..category = category
                                      ..description = desc
                                  ];

                                  final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                  if (controller.selectedSplitLoanId != null) {
                                    try {
                                      final target = allLoans.firstWhere((l) => l.id == controller.selectedSplitLoanId);
                                      if (!target.isLent) {
                                        // We owed them, lending money reduces our debt
                                        if (splitAmount >= target.remainingBalance) {
                                          final excess = splitAmount - target.remainingBalance;
                                          if (excess > 0) {
                                            target.isLent = true; // Flips to receivable (lent)
                                            target.remainingBalance = excess;
                                            target.amount = excess;
                                            target.isCompleted = false;
                                          } else {
                                            // Fully paid
                                            target.remainingBalance = 0.0;
                                            target.isCompleted = true;
                                          }
                                        } else {
                                          target.remainingBalance -= splitAmount;
                                        }
                                      } else {
                                        // Already lent, lending more increases receivable
                                        target.amount += splitAmount;
                                        target.remainingBalance += splitAmount;
                                        target.isCompleted = false;
                                      }
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(target);
                                      tx.linkedLoanId = savedId;
                                    } catch (_) {}
                                  } else if (friend.isNotEmpty) {
                                    try {
                                      final existing = allLoans.firstWhere(
                                        (l) => !l.isCompleted && l.contactName.trim().toLowerCase() == friend.toLowerCase(),
                                      );
                                      if (!existing.isLent) {
                                        if (splitAmount >= existing.remainingBalance) {
                                          final excess = splitAmount - existing.remainingBalance;
                                          if (excess > 0) {
                                            existing.isLent = true;
                                            existing.remainingBalance = excess;
                                            existing.amount = excess;
                                            existing.isCompleted = false;
                                          } else {
                                            existing.remainingBalance = 0.0;
                                            existing.isCompleted = true;
                                          }
                                        } else {
                                          existing.remainingBalance -= splitAmount;
                                        }
                                      } else {
                                        existing.amount += splitAmount;
                                        existing.remainingBalance += splitAmount;
                                        existing.isCompleted = false;
                                      }
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                      tx.linkedLoanId = savedId;
                                    } catch (_) {
                                      final loan = Loan()
                                        ..contactName = friend
                                        ..isLent = true
                                        ..amount = splitAmount
                                        ..remainingBalance = splitAmount
                                        ..startDate = selectedDateTime
                                        ..interestRate = 0.0
                                        ..compoundInterval = 'none'
                                        ..emiAmount = 0.0
                                        ..isCompleted = false;
                                      final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                      tx.linkedLoanId = savedId;
                                    }
                                  }
                                }
                              }

                              // Handle Loan repayments
                              if ((controller.selectedType == 'expense' || controller.selectedType == 'transfer') && controller.selectedDebtId != null && !controller.isSplit) {
                                final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                try {
                                  final target = allLoans.firstWhere((l) => l.id == controller.selectedDebtId);
                                  if (amount >= target.remainingBalance) {
                                    final overpaid = amount - target.remainingBalance;
                                    if (overpaid > 0) {
                                      // Flip to Lent loan (receivable)
                                      target.isLent = true;
                                      target.remainingBalance = overpaid;
                                      target.amount = overpaid;
                                      target.isCompleted = false;
                                    } else {
                                      // Fully paid
                                      target.remainingBalance = 0.0;
                                      target.isCompleted = true;
                                    }
                                  } else {
                                    // Partially paid
                                    target.remainingBalance -= amount;
                                  }
                                  await ref.read(loansProvider.notifier).addLoan(target);
                                } catch (_) {}
                                tx.linkedLoanId = controller.selectedDebtId;
                              }

                              if (existingTransaction == null) {
                                await ref.read(transactionsProvider.notifier).addTransaction(tx);
                              } else {
                                await ref.read(transactionsProvider.notifier).updateTransaction(tx);
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal),
                            child: Text(existingTransaction != null ? 'Save Changes' : 'Add Transaction', style: const TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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

// Dialog helper to show transaction details, with edit & delete capabilities
void showTransactionDetailDialog(BuildContext context, Transaction tx) {
  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final isIncome = tx.transactionType == 'income';
          final color = CategoryUtils.getCategoryColor(tx.category, AppColors.neonTeal);
          final icon = CategoryUtils.getCategoryIcon(tx.category);

          String displayAccount = tx.accountName ?? 'Cash';
          if (tx.cardId != null && tx.accountName == 'Credit Card') {
            final cardList = ref.read(creditCardsProvider).valueOrNull ?? [];
            try {
              final c = cardList.firstWhere((card) => card.id.toString() == tx.cardId);
              displayAccount = '${c.cardName} (..${c.last4})';
            } catch (_) {
              displayAccount = 'Card ID: ${tx.cardId}';
            }
          } else if (tx.accountName != null && tx.accountName!.startsWith('bank:')) {
            final bankList = ref.read(bankAccountsProvider).valueOrNull ?? [];
            try {
              final bankId = int.tryParse(tx.accountName!.substring(5));
              final b = bankList.firstWhere((acc) => acc.id == bankId);
              displayAccount = '${b.bankName} (..${b.last4})';
            } catch (_) {}
          }

          final loansList = ref.read(loansProvider).valueOrNull ?? [];
          Loan? linkedLoan;
          if (tx.linkedLoanId != null) {
            try {
              linkedLoan = loansList.firstWhere((l) => l.id == tx.linkedLoanId);
            } catch (_) {}
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassBlur(
              borderRadius: 24,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Category Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tx.category,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount Display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? AppColors.neonEmerald : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.transactionType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? AppColors.neonEmerald : AppColors.neonTeal,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // Details Rows
                    _buildDetailRow('Account / Wallet', displayAccount),
                    const SizedBox(height: 10),
                    if (tx.transactionType == 'transfer' && tx.cardId != null) ...[
                      _buildDetailRow('Destination Account', () {
                        if (tx.cardId!.startsWith('bank:')) {
                          final bankList = ref.read(bankAccountsProvider).valueOrNull ?? [];
                          try {
                            final bankId = int.tryParse(tx.cardId!.substring(5));
                            final b = bankList.firstWhere((acc) => acc.id == bankId);
                            return '${b.bankName} (..${b.last4})';
                          } catch (_) {}
                        } else if (tx.cardId!.startsWith('card:')) {
                          final cardList = ref.read(creditCardsProvider).valueOrNull ?? [];
                          try {
                            final cardId = int.tryParse(tx.cardId!.substring(5));
                            final c = cardList.firstWhere((card) => card.id == cardId);
                            return '${c.cardName} (..${c.last4})';
                          } catch (_) {}
                        }
                        return tx.cardId!;
                      }()),
                      const SizedBox(height: 10),
                    ],
                    _buildDetailRow('Date & Time', DateFormat('dd MMMM yyyy, hh:mm a').format(tx.timestamp)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Entry Mode', tx.source?.toUpperCase() ?? 'MANUAL'),
                    if (linkedLoan != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        linkedLoan.isCompleted ? 'Loan Completed' : 'Linked Loan',
                        linkedLoan.contactName,
                      ),
                    ],
                    if (tx.rawMessage != null && tx.rawMessage!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      const Text(
                        'Original Message Context:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            tx.rawMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.obsidianSurface,
                                  title: const Text('Delete Transaction?'),
                                  content: const Text('Are you sure you want to permanently delete this transaction?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await ref.read(transactionsProvider.notifier).removeTransaction(tx.id);
                                        Navigator.pop(context); // pop confirm
                                        Navigator.pop(context); // pop details
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          tooltip: 'Delete Transaction',
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(color: Colors.white70)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // close details dialog
                                showTransactionEntryDialog(context, ref, existingTransaction: tx);
                              },
                              icon: const Icon(Icons.edit_rounded, color: Colors.black, size: 16),
                              label: const Text('Edit', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonTeal),
                            ),
                          ],
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

Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
