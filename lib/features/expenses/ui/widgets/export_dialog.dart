import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../models/transaction_model.dart';
import '../../services/export_service.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  String _dateRange = 'current_month'; // current_month, last_3_months, all_time
  String _format = 'csv'; // csv, excel, pdf
  bool _isProcessing = false;

  List<Transaction> _filterTransactions(List<Transaction> allTxs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_dateRange == 'current_month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return allTxs.where((tx) => tx.timestamp.isAfter(startOfMonth) || tx.timestamp.isAtSameMomentAs(startOfMonth)).toList();
    } else if (_dateRange == 'last_3_months') {
      final threeMonthsAgo = today.subtract(const Duration(days: 90));
      return allTxs.where((tx) => tx.timestamp.isAfter(threeMonthsAgo) || tx.timestamp.isAtSameMomentAs(threeMonthsAgo)).toList();
    }
    return allTxs;
  }

  @override
  Widget build(BuildContext context) {
    final txsState = ref.watch(transactionsProvider);

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
                'Export Reports',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Export your financial statements or download category spending reports offline.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Date Range Dropdown
              DropdownButtonFormField<String>(
                value: _dateRange,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  labelText: 'Select Date Range',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'current_month', child: Text('Current Month')),
                  DropdownMenuItem(value: 'last_3_months', child: Text('Last 3 Months')),
                  DropdownMenuItem(value: 'all_time', child: Text('All Time')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _dateRange = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Format Dropdown
              DropdownButtonFormField<String>(
                value: _format,
                dropdownColor: AppColors.obsidianSurface,
                decoration: const InputDecoration(
                  labelText: 'Export Format',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'csv', child: Text('CSV (Comma Separated)')),
                  DropdownMenuItem(value: 'excel', child: Text('Excel Spreadsheet (.xlsx)')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF Summary Report')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _format = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
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
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            final txs = txsState.valueOrNull ?? [];
                            if (txs.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No transactions to export.')),
                              );
                              return;
                            }

                            setState(() {
                              _isProcessing = true;
                            });

                            try {
                              final filtered = _filterTransactions(txs);
                              final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

                              List<int> bytes = [];
                              String defaultName = '';

                              if (_format == 'csv') {
                                final csvData = ExportService.generateCsv(filtered);
                                bytes = utf8.encode(csvData);
                                defaultName = 'ownfi_transactions_$dateStr.csv';
                              } else if (_format == 'excel') {
                                final excelData = ExportService.generateExcel(filtered);
                                if (excelData == null) {
                                  throw Exception('Excel compilation failed.');
                                }
                                bytes = excelData;
                                defaultName = 'ownfi_transactions_$dateStr.xlsx';
                              } else if (_format == 'pdf') {
                                // Calculate summary stats
                                double incomeSum = 0;
                                double expenseSum = 0;
                                final Map<String, double> categorySum = {};

                                for (final tx in filtered) {
                                  if (tx.isDeleted) continue;
                                  if (tx.transactionType == 'income') {
                                    incomeSum += tx.amount;
                                  } else if (tx.transactionType == 'expense') {
                                    expenseSum += tx.amount;
                                    categorySum[tx.category] = (categorySum[tx.category] ?? 0) + tx.amount;
                                  }
                                }

                                final rangeTitle = _dateRange == 'current_month'
                                    ? 'Current Month'
                                    : (_dateRange == 'last_3_months' ? 'Last 3 Months' : 'All Time');

                                bytes = ExportService.generatePdfReport(
                                  transactions: filtered,
                                  totalIncome: incomeSum,
                                  totalExpense: expenseSum,
                                  categoryDistribution: categorySum,
                                  dateRangeTitle: rangeTitle,
                                );
                                defaultName = 'ownfi_financial_summary_$dateStr.pdf';
                              }

                              final success = await ExportService.saveExportedFile(
                                bytes: bytes,
                                defaultFileName: defaultName,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Report exported successfully!'
                                          : 'Export cancelled.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Export failed: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            }
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text('Export Now'),
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
