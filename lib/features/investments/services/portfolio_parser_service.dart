import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:isar/isar.dart';
import '../../../core/database_service.dart';
import '../models/holding_model.dart';

class PortfolioParserService {
  final DatabaseService _dbService;

  PortfolioParserService(this._dbService);

  // Parse a CSV or Excel file of Zerodha holdings
  Future<List<Holding>> parseZerodha(Uint8List fileBytes, String fileName) async {
    final isExcel = fileName.endsWith('.xlsx') || fileName.endsWith('.xls');
    if (isExcel) {
      return _parseExcel(fileBytes, 'stock', 'zerodha');
    } else {
      final csvContent = utf8.decode(fileBytes);
      return _parseCsv(csvContent, 'stock', 'zerodha');
    }
  }

  // Parse a CSV or Excel file of Coin holdings
  Future<List<Holding>> parseCoin(Uint8List fileBytes, String fileName) async {
    final isExcel = fileName.endsWith('.xlsx') || fileName.endsWith('.xls');
    if (isExcel) {
      return _parseExcel(fileBytes, 'mutual_fund', 'coin');
    } else {
      final csvContent = utf8.decode(fileBytes);
      return _parseCsv(csvContent, 'mutual_fund', 'coin');
    }
  }

  // Parse Excel sheets
  List<Holding> _parseExcel(Uint8List bytes, String assetType, String broker) {
    final excel = Excel.decodeBytes(bytes);
    final List<Holding> holdings = [];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows == 0) continue;

      // Find headers in the first few rows (usually row 0 or 1)
      List<String> headers = [];
      int headerRowIndex = 0;

      for (int r = 0; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        final rowValues = row.map((cell) => cell?.value?.toString().toLowerCase().trim() ?? '').toList();
        
        // We look for rows containing keyword markers
        if (rowValues.contains('symbol') || 
            rowValues.contains('instrument') || 
            rowValues.contains('scheme name') ||
            rowValues.contains('isin')) {
          headers = row.map((cell) => cell?.value?.toString() ?? '').toList();
          headerRowIndex = r;
          break;
        }
      }

      if (headers.isEmpty) {
        // Fallback to row 0 if no clear headers found
        headers = sheet.rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
        headerRowIndex = 0;
      }

      final symbolIdx = _findHeaderIndex(headers, ['instrument', 'symbol', 'trading symbol', 'scheme name', 'scheme']);
      final qtyIdx = _findHeaderIndex(headers, ['quantity', 'qty', 'units', 'available qty']);
      final avgIdx = _findHeaderIndex(headers, ['buy average', 'buy avg', 'average price', 'avg price', 'buy avg nav', 'average nav']);
      final nameIdx = _findHeaderIndex(headers, ['name', 'company', 'scheme name', 'instrument name']);
      
      if (symbolIdx == -1 || qtyIdx == -1 || avgIdx == -1) {
        continue; // Could not parse columns
      }

      for (int r = headerRowIndex + 1; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        if (row.length <= symbolIdx || row.length <= qtyIdx || row.length <= avgIdx) continue;

        final symbolVal = row[symbolIdx]?.value?.toString().trim();
        final qtyVal = row[qtyIdx]?.value?.toString().trim();
        final avgVal = row[avgIdx]?.value?.toString().trim();
        
        if (symbolVal == null || symbolVal.isEmpty || qtyVal == null || avgVal == null) continue;

        // Skip summary or footer rows
        final qty = double.tryParse(qtyVal.replaceAll(',', ''));
        final avgPrice = double.tryParse(avgVal.replaceAll(',', ''));

        if (qty == null || qty <= 0 || avgPrice == null || avgPrice <= 0) continue;

        String name = symbolVal;
        if (nameIdx != -1 && nameIdx < row.length) {
          final n = row[nameIdx]?.value?.toString().trim();
          if (n != null && n.isNotEmpty) name = n;
        }

        holdings.add(
          Holding()
            ..symbol = symbolVal.toUpperCase()
            ..name = name
            ..quantity = qty
            ..buyAvgPrice = avgPrice
            ..currentPrice = avgPrice // Default current price to buy average until live query
            ..assetType = assetType
            ..broker = broker
            ..lastUpdated = DateTime.now(),
        );
      }
    }

    return holdings;
  }

  // Parse CSV text content
  List<Holding> _parseCsv(String csvContent, String assetType, String broker) {
    final lines = csvContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return [];

    List<String> headers = [];
    int headerRowIndex = 0;

    // Find headers row
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseCsvLine(line);
      final fieldsLower = fields.map((f) => f.toLowerCase()).toList();

      if (fieldsLower.contains('symbol') || 
          fieldsLower.contains('instrument') || 
          fieldsLower.contains('scheme name') ||
          fieldsLower.contains('isin')) {
        headers = fields;
        headerRowIndex = i;
        break;
      }
    }

    if (headers.isEmpty) {
      headers = _parseCsvLine(lines[0]);
      headerRowIndex = 0;
    }

    final symbolIdx = _findHeaderIndex(headers, ['instrument', 'symbol', 'trading symbol', 'scheme name', 'scheme']);
    final qtyIdx = _findHeaderIndex(headers, ['quantity', 'qty', 'units', 'available qty']);
    final avgIdx = _findHeaderIndex(headers, ['buy average', 'buy avg', 'average price', 'avg price', 'buy avg nav', 'average nav']);
    final nameIdx = _findHeaderIndex(headers, ['name', 'company', 'scheme name', 'instrument name']);

    if (symbolIdx == -1 || qtyIdx == -1 || avgIdx == -1) {
      return []; // Could not parse columns
    }

    final List<Holding> holdings = [];

    for (int i = headerRowIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final row = _parseCsvLine(line);
      if (row.length <= symbolIdx || row.length <= qtyIdx || row.length <= avgIdx) continue;

      final symbolVal = row[symbolIdx].trim();
      final qtyVal = row[qtyIdx].trim();
      final avgVal = row[avgIdx].trim();

      if (symbolVal.isEmpty) continue;

      final qty = double.tryParse(qtyVal.replaceAll(',', ''));
      final avgPrice = double.tryParse(avgVal.replaceAll(',', ''));

      if (qty == null || qty <= 0 || avgPrice == null || avgPrice <= 0) continue;

      String name = symbolVal;
      if (nameIdx != -1 && nameIdx < row.length) {
        final n = row[nameIdx].trim();
        if (n.isNotEmpty) name = n;
      }

      holdings.add(
        Holding()
          ..symbol = symbolVal.toUpperCase()
          ..name = name
          ..quantity = qty
          ..buyAvgPrice = avgPrice
          ..currentPrice = avgPrice // Fallback
          ..assetType = assetType
          ..broker = broker
          ..lastUpdated = DateTime.now(),
      );
    }

    return holdings;
  }

  // Standard CSV line parser that respects quotes
  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString().trim());
    return fields;
  }

  int _findHeaderIndex(List<String> headers, List<String> aliases) {
    for (final alias in aliases) {
      final index = headers.indexWhere((h) => h.toLowerCase().trim() == alias.toLowerCase());
      if (index != -1) return index;
    }
    return -1;
  }

  // Save/Upsert imported holdings into local database
  Future<void> importHoldings(List<Holding> importedHoldings) async {
    final isar = _dbService.isar;
    await isar.writeTxn(() async {
      for (final imported in importedHoldings) {
        // Check if holding already exists in Isar
        final existing = await isar.holdings
            .filter()
            .symbolEqualTo(imported.symbol)
            .assetTypeEqualTo(imported.assetType)
            .findFirst();

        if (existing != null) {
          // Update quantity, buy average, last updated
          existing.quantity = imported.quantity;
          existing.buyAvgPrice = imported.buyAvgPrice;
          existing.name = imported.name;
          existing.lastUpdated = DateTime.now();
          // Keep the existing current price if it was updated by API previously
          if (existing.currentPrice == 0.0) {
            existing.currentPrice = imported.currentPrice;
          }
          await isar.holdings.put(existing);
        } else {
          await isar.holdings.put(imported);
        }
      }
    });
  }
}
