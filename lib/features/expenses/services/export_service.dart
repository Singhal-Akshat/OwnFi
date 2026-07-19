import 'dart:io';
import 'dart:ui';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction_model.dart';

class ExportService {
  /// Generate a CSV formatted string from transaction list
  static String generateCsv(List<Transaction> transactions) {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Date,Description,Type,Category,Amount,Source');
    for (final tx in transactions) {
      final id = tx.id;
      final date = tx.timestamp.toIso8601String().substring(0, 10);
      final desc = tx.description.replaceAll('"', '""');
      final type = tx.transactionType;
      final cat = tx.category;
      final amt = tx.amount;
      final src = tx.source;
      buffer.writeln('$id,$date,"$desc",$type,$cat,$amt,$src');
    }
    return buffer.toString();
  }

  /// Generate a styled Excel sheet using excel library
  static List<int>? generateExcel(List<Transaction> transactions) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Headers
    sheet.appendRow([
      TextCellValue('Transaction ID'),
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Amount (₹)'),
      TextCellValue('Source'),
    ]);

    // Data rows
    for (final tx in transactions) {
      sheet.appendRow([
        IntCellValue(tx.id),
        TextCellValue(tx.timestamp.toIso8601String().substring(0, 10)),
        TextCellValue(tx.description),
        TextCellValue(tx.transactionType),
        TextCellValue(tx.category),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.source),
      ]);
    }

    return excel.save();
  }

  /// Generate a summary PDF with cash flow tables and transaction grid
  static List<int> generatePdfReport({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryDistribution,
    required String dateRangeTitle,
  }) {
    // Create a new PDF document
    final document = PdfDocument();
    final page = document.pages.add();

    // Draw Report Header Title
    page.graphics.drawString(
      'OwnFi Financial Summary Report',
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 0, 500, 30),
    );

    page.graphics.drawString(
      'Period: $dateRangeTitle',
      PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.italic),
      bounds: const Rect.fromLTWH(0, 32, 500, 20),
    );

    // Draw Summary Segment
    page.graphics.drawString(
      'CASH FLOW STATS',
      PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 70, 500, 20),
    );

    page.graphics.drawString(
      'Total Income: Rs. ${totalIncome.toStringAsFixed(2)}\n'
      'Total Expenses: Rs. ${totalExpense.toStringAsFixed(2)}\n'
      'Net Savings: Rs. ${(totalIncome - totalExpense).toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 11),
      bounds: const Rect.fromLTWH(0, 95, 500, 55),
    );

    // Draw Category summary
    page.graphics.drawString(
      'CATEGORY BREAKDOWN',
      PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 165, 500, 20),
    );

    double currentY = 190;
    if (categoryDistribution.isEmpty) {
      page.graphics.drawString(
        'No category expenses tracked in this period.',
        PdfStandardFont(PdfFontFamily.helvetica, 11),
        bounds: Rect.fromLTWH(0, currentY, 500, 18),
      );
      currentY += 20;
    } else {
      categoryDistribution.forEach((cat, amt) {
        page.graphics.drawString(
          '$cat: Rs. ${amt.toStringAsFixed(2)}',
          PdfStandardFont(PdfFontFamily.helvetica, 11),
          bounds: Rect.fromLTWH(0, currentY, 500, 18),
        );
        currentY += 20;
      });
    }

    // Recent Transactions Grid Title
    page.graphics.drawString(
      'RECENT TRANSACTIONS',
      PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, currentY + 15, 500, 20),
    );
    currentY += 40;

    // Build PDF table grid
    final grid = PdfGrid();
    grid.columns.add(count: 5);
    grid.headers.add(1);

    final headerRow = grid.headers[0];
    headerRow.cells[0].value = 'Date';
    headerRow.cells[1].value = 'Description';
    headerRow.cells[2].value = 'Type';
    headerRow.cells[3].value = 'Category';
    headerRow.cells[4].value = 'Amount';

    // Highlight headers
    for (int i = 0; i < headerRow.cells.count; i++) {
      headerRow.cells[i].style.backgroundBrush = PdfSolidBrush(PdfColor(0, 128, 128)); // Teal
      headerRow.cells[i].style.textBrush = PdfBrushes.white;
    }

    // Limit to top 20 rows to avoid overlapping or spilling across pages simply
    final list = transactions.take(20).toList();
    for (final tx in list) {
      final row = grid.rows.add();
      row.cells[0].value = tx.timestamp.toIso8601String().substring(0, 10);
      row.cells[1].value = tx.description;
      row.cells[2].value = tx.transactionType;
      row.cells[3].value = tx.category;
      row.cells[4].value = 'Rs. ${tx.amount.toStringAsFixed(2)}';
    }

    grid.draw(page: page, bounds: Rect.fromLTWH(0, currentY, 500, 0));

    final bytes = document.saveSync();
    document.dispose();
    return bytes;
  }

  /// Launch save dialog and write raw bytes to disk
  static Future<bool> saveExportedFile({
    required List<int> bytes,
    required String defaultFileName,
  }) async {
    try {
      final String? selectedPath = await fp.FilePicker.saveFile(
        dialogTitle: 'Select destination folder to save the report:',
        fileName: defaultFileName,
      );

      if (selectedPath != null) {
        final file = File(selectedPath);
        await file.writeAsBytes(bytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
