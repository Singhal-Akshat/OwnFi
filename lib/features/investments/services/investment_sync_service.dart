import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../../../core/database_service.dart';
import '../models/holding_model.dart';

class InvestmentSyncService {
  final DatabaseService _dbService;

  // We set a common browser User-Agent to avoid HTTP 403 Forbidden blocks from Yahoo Finance
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  InvestmentSyncService(this._dbService);

  // Sync current prices for all holdings in the database
  Future<int> syncAllPrices() async {
    final holdings = await _dbService.getAllHoldings();
    if (holdings.isEmpty) return 0;

    int updatedCount = 0;
    final isar = _dbService.isar;

    for (final holding in holdings) {
      double? latestPrice;

      try {
        if (holding.assetType == 'stock') {
          latestPrice = await _fetchStockPrice(holding.symbol);
        } else if (holding.assetType == 'mutual_fund') {
          latestPrice = await _fetchMutualFundPrice(holding.symbol);
        }
      } catch (e) {
        print('Error syncing price for ${holding.symbol}: $e');
      }

      if (latestPrice != null && latestPrice > 0) {
        await isar.writeTxn(() async {
          holding.currentPrice = latestPrice!;
          holding.lastUpdated = DateTime.now();
          await isar.holdings.put(holding);
        });
        updatedCount++;
      }
    }

    return updatedCount;
  }

  // Fetch stock price from Yahoo Finance API
  Future<double?> _fetchStockPrice(String symbol) async {
    // Append .NS (NSE) suffix if not present
    final cleanSymbol = symbol.endsWith('.NS') || symbol.endsWith('.BO')
        ? symbol
        : '$symbol.NS';

    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol');
    
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['chart']['result'];
      if (result != null && result.isNotEmpty) {
        final meta = result[0]['meta'];
        final price = meta['regularMarketPrice'];
        if (price != null) {
          return (price as num).toDouble();
        }
      }
    } else {
      print('Yahoo Finance returned status ${response.statusCode} for $cleanSymbol');
    }
    return null;
  }

  // Fetch mutual fund NAV from AMFI API
  Future<double?> _fetchMutualFundPrice(String symbolOrName) async {
    // If the symbol is already a numeric scheme code, use it directly
    int? schemeCode = int.tryParse(symbolOrName);

    if (schemeCode == null) {
      // Otherwise, search for the scheme code by name
      schemeCode = await _findSchemeCode(symbolOrName);
    }

    if (schemeCode == null) {
      print('Could not find AMFI scheme code for mutual fund: $symbolOrName');
      return null;
    }

    // Fetch the latest NAV
    final url = Uri.parse('https://api.mfapi.in/mf/$schemeCode');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final navHistory = data['data'] as List<dynamic>;
      if (navHistory.isNotEmpty) {
        final latestNavStr = navHistory[0]['nav'].toString();
        return double.tryParse(latestNavStr);
      }
    }
    return null;
  }

  // Search for MF scheme code by name
  Future<int?> _findSchemeCode(String name) async {
    // Clean up common suffixes to search better
    var cleanName = name
        .replaceAll(RegExp(r'(Direct|Growth|Growth Option|Option|Fund|Plan|Mutual Fund|Direct Plan)', caseSensitive: false), '')
        .trim();
        
    if (cleanName.length > 30) {
      cleanName = cleanName.substring(0, 30).trim();
    }

    if (cleanName.isEmpty) return null;

    final url = Uri.parse('https://api.mfapi.in/mf/search?q=${Uri.encodeComponent(cleanName)}');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      if (list.isNotEmpty) {
        // Try to find direct growth plan first
        final bestMatch = list.firstWhere(
          (item) {
            final schemeName = item['schemeName'].toString().toLowerCase();
            return schemeName.contains('direct') && schemeName.contains('growth');
          },
          orElse: () => list.first,
        );
        return int.tryParse(bestMatch['schemeCode'].toString());
      }
    }
    return null;
  }
}
