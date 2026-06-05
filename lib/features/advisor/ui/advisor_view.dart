import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../advisor/providers/advisor_providers.dart';
import '../../advisor/services/ai_advisor_service.dart';
import '../../../../ui/chat/model_selector.dart';
import '../../../../services/model_repository.dart';

class AdvisorView extends ConsumerStatefulWidget {
  const AdvisorView({super.key});

  @override
  ConsumerState<AdvisorView> createState() => _AdvisorViewState();
}

class _AdvisorViewState extends ConsumerState<AdvisorView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _advisorTabController;
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _advisorTabController = TabController(length: 2, vsync: this);
    // Initialize welcome message
    _messages.add({
      'sender': 'AI',
      'text':
          'Hello Akshat! I am your local privacy-first financial advisor. Ask me anything about rebalancing your portfolio, check your emergency fund status, or ask for home/car loan pre-payment guidance!',
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _advisorTabController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'AI Advisor & Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),

          // Selection tab
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _advisorTabController,
              indicator: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonPurple.withOpacity(0.3),
                ),
              ),
              labelColor: AppColors.neonPurple,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Quant Dashboard'),
                Tab(text: 'AI Finance Chat'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: TabBarView(
              controller: _advisorTabController,
              children: [
                // Quant Dashboard
                _buildQuantDashboard(context),

                // AI Finance Chat
                _buildChatInterface(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantDashboard(BuildContext context) {
    final forecastState = ref.watch(quantForecastResultProvider);

    return forecastState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonPurple),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (forecast) {
        double progress = forecast.projectedSpend > 0
            ? (forecast.dailyVelocity * forecast.remainingDays) / 100000.0
            : 0.0;
        if (progress > 1.0) progress = 1.0;
        if (progress < 0.0) progress = 0.0;

        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Forecaster card
            GlassBlur(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline_rounded, color: AppColors.neonTeal),
                        SizedBox(width: 8),
                        Text(
                          'Cash Flow Forecast',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Projected Spend: ${forecast.projectedSpend.toIndianRupee()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on current velocity (${forecast.dailyVelocity.toIndianRupee()}/day) over ${forecast.remainingDays} remaining days + monthly EMIs (${forecast.recurringEmis.toIndianRupee()}) + rent (${forecast.detectedRent.toIndianRupee()}).',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonTeal,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Allocation advice card
            GlassBlur(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          color: AppColors.neonEmerald,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Advisor Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (forecast.rebalanceAmount > 0)
                      _buildRecommendationBullet(
                        'Asset Allocation Rebalancing',
                        'Your current holdings are ${forecast.stocksPercentage.toStringAsFixed(0)}% Stocks and ${forecast.mfsPercentage.toStringAsFixed(0)}% Mutual Funds. Consider shifting ${forecast.rebalanceAmount.toIndianRupee()} to Mutual Funds to align with a balanced 70% direct stocks / 30% mutual funds allocation.',
                      )
                    else
                      _buildRecommendationBullet(
                        'Asset Allocation Healthy',
                        'Your direct stocks (${forecast.stocksPercentage.toStringAsFixed(0)}%) and mutual funds (${forecast.mfsPercentage.toStringAsFixed(0)}%) ratio is healthy. SIP inputs are recommended to grow your portfolio.',
                      ),
                    const SizedBox(height: 8),
                    if (forecast.emergencyFundMonths < 6.0)
                      _buildRecommendationBullet(
                        'Emergency Fund Shortfall',
                        'Your savings of ${forecast.cashAndBank.toIndianRupee()} cover ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of outflow. We recommend building this up to ${forecast.recommendedEmergencyFund.toIndianRupee()} to cover 6 months of basic living needs.',
                      )
                    else
                      _buildRecommendationBullet(
                        'Emergency Fund Secure',
                        'Your savings cover ${forecast.emergencyFundMonths.toStringAsFixed(1)} months of monthly outflow. This is a very secure buffer.',
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationBullet(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.chevron_right,
              color: AppColors.neonEmerald,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 2, bottom: 8),
          child: Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    return Column(
      children: [
        // Active AI Engine Status
        Container(
          margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonPurple.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.neonPurple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Active Engine:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.grey[900]),
                child: ModelSelector(
                  onChanged: () {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),

        // Chat History
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                // Show typing bubble
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                      left: 4,
                      right: 4,
                    ),
                    child: GlassBlur(
                      borderRadius: 16,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Typing advisor recommendations...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final msg = _messages[index];
              final isAI = msg['sender'] == 'AI';
              return Align(
                alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: GlassBlur(
                    borderRadius: 16,
                    cardColor: isAI
                        ? AppColors.glassCard
                        : AppColors.neonPurple.withOpacity(0.1),
                    borderColor: isAI
                        ? AppColors.glassBorder
                        : AppColors.neonPurple.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        msg['text']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Text Input box
        Padding(
          padding: EdgeInsets.only(
            bottom: View.of(context).viewInsets.bottom > 0 ? 12.0 : 90.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: GlassBlur(
                  borderRadius: 16,
                  child: TextField(
                    controller: _chatInputController,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask advisor (e.g. should I pre-pay home loan?)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassBlur(
                borderRadius: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.neonTeal,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'User', 'text': text});
      _isTyping = true;
      _chatInputController.clear();
    });

    try {
      final forecastState = ref.read(quantForecastResultProvider);

      if (forecastState.hasValue) {
        final forecast = forecastState.value!;
        final txs = ref.read(transactionsProvider).value ?? [];
        final cards = ref.read(creditCardsProvider).value ?? [];
        final loans = ref.read(loansProvider).value ?? [];
        final holdings = ref.read(holdingsProvider).value ?? [];

        double totalHoldingsVal = forecast.stocksVal + forecast.mfVal;
        double totalCardOutstanding = 0.0;
        for (final c in cards) {
          totalCardOutstanding += c.balance;
        }
        double totalDebts = 0.0;
        double totalReceivables = 0.0;
        for (final l in loans) {
          if (l.isLent) {
            totalReceivables += l.remainingBalance;
          } else {
            totalDebts += l.remainingBalance;
          }
        }
        double netWorth =
            totalHoldingsVal +
            forecast.cashAndBank +
            totalReceivables -
            totalCardOutstanding -
            totalDebts;

        final advisorService = ref.read(aiAdvisorServiceProvider);

        final sanitizedProfile = advisorService.generateSanitizedProfile(
          transactions: txs,
          cards: cards,
          loans: loans,
          holdings: holdings,
          netWorth: netWorth,
          cashAndBank: forecast.cashAndBank,
          forecast: forecast,
        );

        final reply = await advisorService.queryAdvisor(
          userQuery: text,
          sanitizedProfile: sanitizedProfile,
          forecast: forecast,
        );

        setState(() {
          _messages.add({'sender': 'AI', 'text': reply});
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'AI',
            'text':
                'I am still loading your financial profile. Please wait a moment.',
          });
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text':
              'Sorry, I encountered an error while processing your request: $e',
        });
        _isTyping = false;
      });
    }
  }
}
