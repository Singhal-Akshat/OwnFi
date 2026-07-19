import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/budget_model.dart';

class InsightsView extends ConsumerStatefulWidget {
  const InsightsView({super.key});

  @override
  ConsumerState<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends ConsumerState<InsightsView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _activeChartIndex = 0; // 0 = Category Distribution, 1 = Cash Flow
  String _selectedType = 'expense'; // 'expense', 'income', 'transfer'

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Selector Card
        _buildMonthSelector(),
        const SizedBox(height: 16),

        // Sub-Tab Switcher (Category Allocation vs Cash Flow)
        _buildChartSubTabs(),
        const SizedBox(height: 20),

        // Active Chart Section
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _activeChartIndex == 0
                ? _buildCategoryDistributionSection()
                : _buildCashFlowSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return GlassBlur(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.neonTeal, size: 28),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
            ),
            Text(
              '${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: isCurrentMonth ? AppColors.textMuted : AppColors.neonTeal,
                size: 28,
              ),
              onPressed: isCurrentMonth
                  ? null
                  : () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSubTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeChartIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeChartIndex == 0
                      ? AppColors.neonTeal.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Category Allocation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _activeChartIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _activeChartIndex == 0 ? AppColors.neonTeal : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeChartIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeChartIndex == 1
                      ? AppColors.neonTeal.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cash Flow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _activeChartIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _activeChartIndex == 1 ? AppColors.neonTeal : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionSection() {
    final distribution = ref.watch(monthlyCategoryDistributionProvider(
      month: _selectedMonth,
      type: _selectedType,
    ));

    final selectedYearMonth = _selectedMonth.year * 100 + _selectedMonth.month;
    final budgetsAsync = ref.watch(monthlyBudgetsProvider(selectedYearMonth));

    double totalAmount = 0.0;
    distribution.forEach((key, val) => totalAmount += val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction Type Pill Filters
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypePill('expense', 'Expenses'),
            const SizedBox(width: 8),
            _buildTypePill('income', 'Income'),
            const SizedBox(width: 8),
            _buildTypePill('transfer', 'Transfers'),
          ],
        ),
        const SizedBox(height: 20),

        if (distribution.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: GlassBlur(
              borderRadius: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.textMuted.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recorded ${_selectedType}s',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'There is no transaction data for this month.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Pie Chart and Legend Box
          GlassBlur(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Net sum header
                  Text(
                    'TOTAL ${_selectedType.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalAmount.toIndianRupee(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Global Budget Progress Bar
                  if (_selectedType == 'expense') ...[
                    budgetsAsync.maybeWhen(
                      data: (budgets) {
                        Budget? globalBudget;
                        for (final b in budgets) {
                          if (b.category == 'All') {
                            globalBudget = b;
                            break;
                          }
                        }
                        if (globalBudget == null) return const SizedBox.shrink();

                        final double ratio = globalBudget.amountLimit > 0 
                            ? totalAmount / globalBudget.amountLimit 
                            : 0.0;
                        final double progressVal = ratio.clamp(0.0, 1.0);
                        final color = ratio >= 1.0
                            ? Colors.redAccent
                            : (ratio >= 0.8 ? Colors.orangeAccent : AppColors.neonTeal);

                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progressVal,
                                  minHeight: 6,
                                  backgroundColor: AppColors.glassBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Global Budget Spent: ${(ratio * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ratio >= 1.0
                                          ? Colors.redAccent
                                          : (ratio >= 0.8 ? Colors.orangeAccent : AppColors.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    'Limit: ${globalBudget.amountLimit.toIndianRupee()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Chart Row
                  SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sections: distribution.entries.map((entry) {
                          final categoryColor = CategoryUtils.getCategoryColor(entry.key, AppColors.neonTeal);
                          final pct = totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0.0;
                          return PieChartSectionData(
                            color: categoryColor,
                            value: entry.value,
                            title: pct > 8 ? '${pct.toStringAsFixed(0)}%' : '',
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Legends List
                  const Divider(color: AppColors.glassBorder, height: 1),
                  const SizedBox(height: 12),
                  () {
                    final budgets = budgetsAsync.valueOrNull ?? [];
                    final categoriesWithData = <String>{
                      ...distribution.keys,
                      ...budgets.map((b) => b.category).where((cat) => cat != 'All'),
                    }.toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoriesWithData.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final categoryName = categoriesWithData[index];
                        final spendingVal = distribution[categoryName] ?? 0.0;
                        final categoryColor = CategoryUtils.getCategoryColor(categoryName, AppColors.neonTeal);
                        final pct = totalAmount > 0 ? (spendingVal / totalAmount) * 100 : 0.0;

                        // Find if this category has a budget limit configured
                        Budget? catBudget;
                        for (final b in budgets) {
                          if (b.category == categoryName) {
                            catBudget = b;
                            break;
                          }
                        }

                        final ratio = catBudget != null && catBudget.amountLimit > 0
                            ? spendingVal / catBudget.amountLimit
                            : 0.0;
                        final progressVal = ratio.clamp(0.0, 1.0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  CategoryUtils.getCategoryIcon(categoryName),
                                  size: 14,
                                  color: categoryColor.withOpacity(0.8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    categoryName,
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(1)}% (${spendingVal.toIndianRupee()})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (catBudget != null && _selectedType == 'expense') ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progressVal,
                                        minHeight: 4,
                                        backgroundColor: AppColors.glassBorder,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          ratio >= 1.0
                                              ? Colors.redAccent
                                              : (ratio >= 0.8 ? Colors.orangeAccent : categoryColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(ratio * 100).toStringAsFixed(0)}% of ${catBudget.amountLimit.toIndianRupee()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: ratio >= 1.0
                                          ? Colors.redAccent
                                          : (ratio >= 0.8 ? Colors.orangeAccent : AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  }(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCashFlowSection() {
    final cashFlow = ref.watch(monthlyCashFlowProvider(_selectedMonth));
    final income = cashFlow['income'] ?? 0.0;
    final expense = cashFlow['expense'] ?? 0.0;
    final netSavings = income - expense;

    if (income == 0 && expense == 0) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: GlassBlur(
              borderRadius: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.textMuted.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Cash Flow Recorded',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'There is no income or expense data for this month.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final double maxVal = income > expense ? income : expense;
    final double scaleMax = maxVal == 0 ? 1000 : maxVal * 1.15;

    return Column(
      children: [
        // Cash Flow Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildCashFlowSummaryCard(
                'Income',
                income.toIndianRupee(),
                AppColors.neonEmerald,
                Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCashFlowSummaryCard(
                'Expense',
                expense.toIndianRupee(),
                Colors.redAccent,
                Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Net Savings Summary
        GlassBlur(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Savings',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${netSavings >= 0 ? "+" : ""}${netSavings.toIndianRupee()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: netSavings >= 0 ? AppColors.neonEmerald : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Double Bar Chart
        GlassBlur(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Income vs Expense Breakdown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      maxY: scaleMax,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value == 0) {
                                return const SideTitleWidget(
                                  axisSide: AxisSide.bottom,
                                  child: Text('Cash Flow', style: TextStyle(color: Colors.white, fontSize: 12)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          groupVertically: false,
                          barRods: [
                            BarChartRodData(
                              toY: income,
                              color: AppColors.neonEmerald,
                              width: 28,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: scaleMax,
                                color: Colors.white.withOpacity(0.02),
                              ),
                            ),
                            BarChartRodData(toY: 0, width: 20, color: Colors.transparent), // spacer
                            BarChartRodData(
                              toY: expense,
                              color: Colors.redAccent,
                              width: 28,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: scaleMax,
                                color: Colors.white.withOpacity(0.02),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendDot(AppColors.neonEmerald, 'Income'),
                    const SizedBox(width: 24),
                    _buildLegendDot(Colors.redAccent, 'Expense'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSummaryCard(String label, String value, Color color, IconData icon) {
    return GlassBlur(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTypePill(String type, String label) {
    final isSelected = _selectedType == type;
    final activeColor = _selectedType == 'expense'
        ? Colors.redAccent
        : (_selectedType == 'income' ? AppColors.neonEmerald : AppColors.neonTeal);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.5) : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
