import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/features/expenses/models/transaction_model.dart';
import 'package:my_personal_tracker/features/expenses/services/export_service.dart';

void main() {
  group('Export Service Mappings & Formatting Tests', () {
    test('CSV generation correctly handles descriptions with commas', () {
      final txs = [
        Transaction()
          ..id = 1
          ..description = 'Netflix, Inc. Premium'
          ..category = 'Entertainment'
          ..transactionType = 'expense'
          ..amount = 649.0
          ..timestamp = DateTime(2026, 7, 10)
          ..source = 'manual',
        Transaction()
          ..id = 2
          ..description = 'Simple purchase'
          ..category = 'Food'
          ..transactionType = 'expense'
          ..amount = 150.0
          ..timestamp = DateTime(2026, 7, 11)
          ..source = 'sms',
      ];

      final csv = ExportService.generateCsv(txs);
      final lines = csv.split('\n');

      // Header line checks
      expect(lines[0].trim(), 'ID,Date,Description,Type,Category,Amount,Source');

      // Escaped quote description check
      expect(lines[1].trim(), '1,2026-07-10,"Netflix, Inc. Premium",expense,Entertainment,649.0,manual');

      // Standard row check
      expect(lines[2].trim(), '2,2026-07-11,"Simple purchase",expense,Food,150.0,sms');
    });

    test('Excel spreadsheet generation produces valid byte outputs', () {
      final txs = [
        Transaction()
          ..id = 5
          ..description = 'Salary Credit'
          ..category = 'Salary'
          ..transactionType = 'income'
          ..amount = 75000.0
          ..timestamp = DateTime(2026, 7, 1)
          ..source = 'imap',
      ];

      final excelBytes = ExportService.generateExcel(txs);

      expect(excelBytes, isNotNull);
      expect(excelBytes!.isNotEmpty, isTrue);
    });

    test('PDF summary report compilation produces valid byte outputs', () {
      final txs = [
        Transaction()
          ..id = 10
          ..description = 'Dining Out'
          ..category = 'Food'
          ..transactionType = 'expense'
          ..amount = 1200.0
          ..timestamp = DateTime(2026, 7, 5)
          ..source = 'manual',
      ];

      final pdfBytes = ExportService.generatePdfReport(
        transactions: txs,
        totalIncome: 0.0,
        totalExpense: 1200.0,
        categoryDistribution: {'Food': 1200.0},
        dateRangeTitle: 'July 2026',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
