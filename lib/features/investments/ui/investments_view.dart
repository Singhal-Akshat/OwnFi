import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../investments/models/holding_model.dart';

class InvestmentsView extends ConsumerStatefulWidget {
  const InvestmentsView({super.key});

  @override
  ConsumerState<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends ConsumerState<InvestmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdingsState = ref.watch(holdingsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Investments',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.neonTeal,
                      size: 20,
                    ),
                    tooltip: 'Refresh Prices',
                    onPressed: () => _refreshPrices(context),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonEmerald.withOpacity(0.12),
                  foregroundColor: AppColors.neonEmerald,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                icon: const Icon(Icons.file_upload_rounded, size: 16),
                label: const Text('Import CSV', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  _showImportDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.neonEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonEmerald.withOpacity(0.3),
                ),
              ),
              labelColor: AppColors.neonEmerald,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Stocks'),
                Tab(text: 'Mutual Funds'),
                Tab(text: 'Stable'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total valuation banner & Asset Allocation Pie Chart
          holdingsState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.neonTeal),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (holdings) {
              double currentVal = 0.0;
              double buyCost = 0.0;
              double stockVal = 0.0;
              double mfVal = 0.0;
              double stableVal = 0.0;
 
              for (final h in holdings) {
                final val = h.currentPrice * h.quantity;
                currentVal += val;
                buyCost += h.buyAvgPrice * h.quantity;
                if (h.assetType == 'stock') {
                  stockVal += val;
                } else if (h.assetType == 'mutual_fund') {
                  mfVal += val;
                } else if (h.assetType == 'stable') {
                  stableVal += val;
                }
              }
 
              final returnsAmt = currentVal - buyCost;
              final returnsPct = buyCost > 0
                  ? (returnsAmt / buyCost) * 100
                  : 0.0;
              final isNegative = returnsAmt < 0;
 
              final totalVal = stockVal + mfVal + stableVal;
              final double stockPct = totalVal > 0
                  ? (stockVal / totalVal) * 100
                  : 0.0;
              final double mfPct = totalVal > 0
                  ? (mfVal / totalVal) * 100
                  : 0.0;
              final double stablePct = totalVal > 0
                  ? (stableVal / totalVal) * 100
                  : 0.0;

              return Column(
                children: [
                  GlassBlur(
                    borderRadius: 16,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Valuation',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentVal.toIndianRupee(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Returns',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${isNegative ? "" : "+"}${returnsAmt.toIndianRupee()} (${isNegative ? "" : "+"}${returnsPct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNegative
                                      ? Colors.redAccent
                                      : AppColors.neonEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (totalVal > 0) ...[
                    const SizedBox(height: 12),
                    GlassBlur(
                      borderRadius: 16,
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(12),
                        child: Row(  
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    if (stockVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonTeal,
                                        value: stockVal,
                                        title:
                                            '${stockPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    if (mfVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonEmerald,
                                        value: mfVal,
                                        title: '${mfPct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    if (stableVal > 0)
                                      PieChartSectionData(
                                        color: AppColors.neonPink,
                                        value: stableVal,
                                        title: '${stablePct.toStringAsFixed(0)}%',
                                        radius: 28,
                                        titleStyle: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem(
                                    'Stocks',
                                    stockVal.toIndianRupee(),
                                    AppColors.neonTeal,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildLegendItem(
                                    'Mutual Funds',
                                    mfVal.toIndianRupee(),
                                    AppColors.neonEmerald,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildLegendItem(
                                    'Stable',
                                    stableVal.toIndianRupee(),
                                    AppColors.neonPink,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: holdingsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (holdings) {
                final stocks = holdings
                    .where((h) => h.assetType == 'stock')
                    .toList();
                final mutualFunds = holdings
                    .where((h) => h.assetType == 'mutual_fund')
                    .toList();
                final stable = holdings
                    .where((h) => h.assetType == 'stable')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Stocks List
                    stocks.isEmpty
                        ? const Center(
                            child: Text(
                              'No stocks. Click Import to add holdings!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: stocks.length,
                            itemBuilder: (context, index) {
                              final h = stocks[index];
                              final cost = h.buyAvgPrice * h.quantity;
                              final curVal = h.currentPrice * h.quantity;
                              final ret = curVal - cost;
                              final pct = cost > 0 ? (ret / cost) * 100 : 0.0;
                              final isNegative = ret < 0;

                              return _buildHoldingItem(
                                h.symbol,
                                h.name,
                                '${h.quantity.toStringAsFixed(0)} Qty',
                                'Avg: ₹${h.buyAvgPrice.toStringAsFixed(0)}',
                                'Current: ₹${h.currentPrice.toStringAsFixed(0)}',
                                '${isNegative ? "" : "+"}${pct.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                    // Mutual Funds List
                    mutualFunds.isEmpty
                        ? const Center(
                            child: Text(
                              'No mutual funds. Click Import to add holdings!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: mutualFunds.length,
                            itemBuilder: (context, index) {
                              final h = mutualFunds[index];
                              final cost = h.buyAvgPrice * h.quantity;
                              final curVal = h.currentPrice * h.quantity;
                              final ret = curVal - cost;
                              final pct = cost > 0 ? (ret / cost) * 100 : 0.0;
                              final isNegative = ret < 0;

                              return _buildHoldingItem(
                                h.symbol,
                                h.name,
                                '${h.quantity.toStringAsFixed(0)} Units',
                                'Avg NAV: ₹${h.buyAvgPrice.toStringAsFixed(1)}',
                                'Current NAV: ₹${h.currentPrice.toStringAsFixed(1)}',
                                '${isNegative ? "" : "+"}${pct.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                    // Stable List
                    stable.isEmpty
                        ? const Center(
                            child: Text(
                              'No stable assets. Select Investment category to add holdings!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: stable.length,
                            itemBuilder: (context, index) {
                              final h = stable[index];
                              final cost = h.buyAvgPrice * h.quantity;
                              final curVal = h.currentPrice * h.quantity;
                              final ret = curVal - cost;
                              final pct = cost > 0 ? (ret / cost) * 100 : 0.0;
                              final isNegative = ret < 0;

                              return _buildHoldingItem(
                                h.symbol,
                                h.name,
                                '₹${h.quantity.toStringAsFixed(0)} Amount',
                                'Avg Price: ₹${h.buyAvgPrice.toStringAsFixed(1)}',
                                'Current Value: ₹${h.currentPrice.toStringAsFixed(1)}',
                                '${isNegative ? "" : "+"}${pct.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingItem(
    String symbol,
    String name,
    String qty,
    String avg,
    String current,
    String returns,
  ) {
    final isNegative = returns.startsWith('-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        useBlur: false,
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                returns,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? Colors.redAccent : AppColors.neonEmerald,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$qty • $avg',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                current,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
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
                    'Import Portfolio holdings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select your holdings CSV or Excel export from Zerodha Console or Coin:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.neonTeal,
                    ),
                    title: const Text(
                      'Zerodha Holdings (CSV/Excel)',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Upload Console holdings sheet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'zerodha');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.neonEmerald,
                    ),
                    title: const Text(
                      'Coin Mutual Funds (CSV/Excel)',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Upload Coin holdings sheet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndParseFile(context, 'coin');
                    },
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Clear All Holdings',
                      style: TextStyle(fontSize: 14, color: Colors.redAccent),
                    ),
                    subtitle: const Text(
                      'Reset local investments portfolio',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref
                          .read(holdingsProvider.notifier)
                          .clearAllHoldings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All holdings cleared.')),
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
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
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
  }

  Future<void> _pickAndParseFile(BuildContext context, String broker) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes == null) {
        throw Exception('Could not read file bytes.');
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.neonEmerald),
        ),
      );

      final parser = ref.read(portfolioParserServiceProvider);
      List<Holding> holdings;

      if (broker == 'zerodha') {
        holdings = await parser.parseZerodha(fileBytes, file.name);
      } else {
        holdings = await parser.parseCoin(fileBytes, file.name);
      }

      if (!context.mounted) return;
      if (holdings.isEmpty) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid holdings found in the selected file.'),
          ),
        );
        return;
      }

      await parser.importHoldings(holdings);
      await ref.read(holdingsProvider.notifier).loadHoldings();

      if (!context.mounted) return;
      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${holdings.length} holdings successfully!'),
          backgroundColor: AppColors.neonEmerald.withOpacity(0.8),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to import holdings: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _refreshPrices(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBlur(
            borderRadius: 24,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircularProgressIndicator(color: AppColors.neonEmerald),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Fetching latest market prices from Yahoo Finance & AMFI...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final syncService = ref.read(investmentSyncServiceProvider);
      final count = await syncService.syncAllPrices();

      // Reload holdings provider
      await ref.read(holdingsProvider.notifier).loadHoldings();

      if (!context.mounted) return;
      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated $count asset prices!'),
          backgroundColor: AppColors.neonEmerald.withOpacity(0.8),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update prices: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
