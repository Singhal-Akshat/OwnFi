import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/sync/google_auth_manager.dart';
import 'package:my_personal_tracker/core/providers.dart';

class SmsLookbackDialog extends ConsumerStatefulWidget {
  final int initialValue;
  final String initialUnit;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(int value, String unit, DateTime? startDate, DateTime? endDate) onSave;

  const SmsLookbackDialog({
    super.key,
    required this.initialValue,
    required this.initialUnit,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required int initialValue,
    required String initialUnit,
    required DateTime? initialStartDate,
    required DateTime? initialEndDate,
    required void Function(int value, String unit, DateTime? startDate, DateTime? endDate) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SmsLookbackDialog(
        initialValue: initialValue,
        initialUnit: initialUnit,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<SmsLookbackDialog> createState() => _SmsLookbackDialogState();
}

class _SmsLookbackDialogState extends ConsumerState<SmsLookbackDialog> {
  final _storage = const FlutterSecureStorage();
  late String _selectedUnit;
  late TextEditingController _valueController;
  DateTime? _tempStart;
  DateTime? _tempEnd;
  late bool _useCalendar;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    _valueController = TextEditingController(text: widget.initialValue.toString());
    _tempStart = widget.initialStartDate;
    _tempEnd = widget.initialEndDate;
    _useCalendar = _tempStart != null && _tempEnd != null;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => setState(() => _useCalendar = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useCalendar ? AppColors.neonTeal.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_useCalendar ? AppColors.neonTeal : AppColors.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Relative Window',
                            style: TextStyle(
                              color: !_useCalendar ? Colors.white : AppColors.textSecondary,
                              fontWeight: !_useCalendar ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useCalendar = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useCalendar ? AppColors.neonTeal.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _useCalendar ? AppColors.neonTeal : AppColors.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Calendar Range',
                            style: TextStyle(
                              color: _useCalendar ? Colors.white : AppColors.textSecondary,
                              fontWeight: _useCalendar ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_useCalendar) ...[
                // Unit Selector (Days vs Months)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedUnit = 'days'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedUnit == 'days' ? AppColors.neonTeal.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedUnit == 'days' ? AppColors.neonTeal : AppColors.glassBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Days',
                              style: TextStyle(
                                color: _selectedUnit == 'days' ? Colors.white : AppColors.textSecondary,
                                fontWeight: _selectedUnit == 'days' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedUnit = 'months'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedUnit == 'months' ? AppColors.neonTeal.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedUnit == 'months' ? AppColors.neonTeal : AppColors.glassBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Months',
                              style: TextStyle(
                                color: _selectedUnit == 'months' ? Colors.white : AppColors.textSecondary,
                                fontWeight: _selectedUnit == 'months' ? FontWeight.bold : FontWeight.normal,
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
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _selectedUnit == 'days' ? 'Number of Days' : 'Number of Months',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
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
                        _tempStart != null && _tempEnd != null
                            ? '${_formatDate(_tempStart!)}  ➔  ${_formatDate(_tempEnd!)}'
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
                          backgroundColor: AppColors.neonTeal.withOpacity(0.2),
                          foregroundColor: AppColors.neonTeal,
                          side: const BorderSide(color: AppColors.neonTeal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: _tempStart != null && _tempEnd != null
                                ? DateTimeRange(start: _tempStart!, end: _tempEnd!)
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
                                    style: TextButton.styleFrom(foregroundColor: AppColors.neonTeal),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _tempStart = picked.start;
                              _tempEnd = picked.end;
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
                      if (_useCalendar) {
                        if (_tempStart == null || _tempEnd == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a date range first'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        await _storage.write(
                          key: 'settings_sync_start_date',
                          value: _tempStart!.toIso8601String(),
                        );
                        await _storage.write(
                          key: 'settings_sync_end_date',
                          value: _tempEnd!.toIso8601String(),
                        );
                        await _storage.delete(key: 'settings_sms_lookback_value');
                        await _storage.delete(key: 'settings_sms_lookback_unit');

                        widget.onSave(0, '', _tempStart, _tempEnd);
                      } else {
                        final text = _valueController.text.trim();
                        final val = int.tryParse(text);
                        if (val == null || val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid positive number'),
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
                          value: _selectedUnit,
                        );
                        await _storage.delete(key: 'settings_sync_start_date');
                        await _storage.delete(key: 'settings_sync_end_date');

                        widget.onSave(val, _selectedUnit, null, null);
                      }

                      // Force full scan on next sync
                      await _storage.delete(key: 'last_sms_sync_time');
                      final accounts = await ref.read(googleAuthManagerProvider).getLinkedAccounts();
                      for (var acc in accounts) {
                        await _storage.delete(key: 'last_gmail_sync_time_${acc.email}');
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _useCalendar
                                  ? 'Lookback range set to ${_formatDate(_tempStart!)} - ${_formatDate(_tempEnd!)}.'
                                  : 'Lookback set to ${_valueController.text.trim()} $_selectedUnit. Next sync will perform a full scan.',
                            ),
                            backgroundColor: AppColors.neonEmerald.withOpacity(0.9),
                          ),
                        );
                      }
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
  }
}
