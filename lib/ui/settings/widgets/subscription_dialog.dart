import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/expenses/models/subscription_model.dart';

class SubscriptionDialog extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const SubscriptionDialog({super.key, this.subscription});

  static Future<void> show(BuildContext context, {Subscription? subscription}) {
    return showDialog<void>(
      context: context,
      builder: (context) => SubscriptionDialog(subscription: subscription),
    );
  }

  @override
  ConsumerState<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends ConsumerState<SubscriptionDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  String _billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _nameController.text = widget.subscription!.name;
      _amountController.text = widget.subscription!.amount.toStringAsFixed(2);
      _startDate = widget.subscription!.startDate;
      _billingCycle = widget.subscription!.billingCycle;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonTeal,
              onPrimary: Colors.black,
              surface: AppColors.obsidianSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subscription != null;

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
                  isEdit ? 'Edit Subscription' : 'Add Subscription',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track recurring bills, subscriptions, or fixed payments like rent.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Subscription Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Netflix',
                  ),
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Billing Amount (₹)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 199',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // Billing Cycle Dropdown
                DropdownButtonFormField<String>(
                  value: _billingCycle,
                  dropdownColor: AppColors.obsidianSurface,
                  decoration: const InputDecoration(
                    labelText: 'Billing Cycle',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _billingCycle = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Start Date Picker Row
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.02),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Billing Start Date',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_startDate),
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_today_rounded, color: AppColors.neonTeal, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions row
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final amtText = _amountController.text.trim();
                        final amt = double.tryParse(amtText) ?? 0.0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter subscription name.')),
                          );
                          return;
                        }
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid billing amount.')),
                          );
                          return;
                        }

                        final sub = widget.subscription ?? Subscription();
                        sub
                          ..name = name
                          ..amount = amt
                          ..startDate = _startDate
                          ..billingCycle = _billingCycle
                          ..isActive = true;

                        await ref.read(subscriptionsProvider.notifier).addOrUpdateSubscription(sub);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'Subscription "$name" updated.'
                                    : 'Subscription "$name" added successfully.',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Add Subscription'),
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
