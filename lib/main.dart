import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MypersonalTracker',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardView(),
    CardsLoansView(),
    InvestmentsView(),
    AdvisorView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: GlassBlur(
            borderRadius: 24,
            blurX: 20,
            blurY: 20,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavBarItem(Icons.dashboard_rounded, 'Home', 0),
                  _buildNavBarItem(Icons.credit_card_rounded, 'Cards', 1),
                  _buildNavBarItem(Icons.show_chart_rounded, 'Invest', 2),
                  _buildNavBarItem(Icons.psychology_rounded, 'AI Advisor', 3),
                  _buildNavBarItem(Icons.settings_rounded, 'Settings', 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.neonTeal;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STUNNING BACKGROUND RADIAL GRADIENTS ORBS ANIMATOR
// ---------------------------------------------------------------------------
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.midnightBg,
          ),
          child: Stack(
            children: [
              // Purple Orb (top left to center right)
              Positioned(
                top: -100 + (val * 200),
                left: -100 + (val * 150),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonPurple.withOpacity(0.2),
                        AppColors.neonPurple.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Teal Orb (bottom right to center left)
              Positioned(
                bottom: -150 + (val * 250),
                right: -100 + (val * 200),
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonTeal.withOpacity(0.18),
                        AppColors.neonTeal.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Pink Orb (middle-bottom animation)
              Positioned(
                top: 300 + (val * 100),
                right: 200 - (val * 300),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonPink.withOpacity(0.12),
                        AppColors.neonPink.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 1: HOME DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'MypersonalTracker',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              GlassBlur(
                borderRadius: 14,
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.neonTeal),
                  onPressed: () {
                    // Quick Expense Dialog
                    _showAddExpenseDialog(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Glass Net Worth Card
          GlassBlur(
            borderRadius: 20,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET WORTH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹12,45,820',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAssetMini('Investments', '₹9,80,000', AppColors.neonEmerald),
                      _buildAssetMini('Cash & Bank', '₹3,25,820', AppColors.neonTeal),
                      _buildAssetMini('Outstanding', '-₹60,000', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Title
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Transactions List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTransactionItem('Netflix Subscription', 'recurring', '-₹649', 'Entertainment', 'May 28', AppColors.neonPurple),
                _buildTransactionItem('Zerodha Dividend', 'income', '+₹1,200', 'Investment', 'May 27', AppColors.neonEmerald),
                _buildTransactionItem('Amazon Purchase', 'expense', '-₹15,000', 'Electronics', 'May 25', AppColors.neonTeal),
                _buildTransactionItem('HDFC Card Bill Pay', 'transfer', '-₹24,500', 'Card Payment', 'May 20', AppColors.neonPink),
                _buildTransactionItem('Dine-out Split with Joy', 'split', '+₹1,850', 'Food', 'May 18', Colors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetMini(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
      String title, String type, String amount, String category, String date, Color iconColor) {
    final isNegative = amount.startsWith('-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            '$category • $date',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.white : AppColors.neonEmerald,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
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
                    'Quick Manual Log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Amount (INR)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Description (e.g. Croma purchase)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Category (Food, Shopping, Bills)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          // Simulate adding
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense logged successfully (Mocked)')),
                          );
                        },
                        child: const Text('Log Expense'),
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
}

// ---------------------------------------------------------------------------
// VIEW 2: CARDS & LOANS VIEW
// ---------------------------------------------------------------------------
class CardsLoansView extends StatelessWidget {
  const CardsLoansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cards & Debts',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Cards horizontal scroll list
          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCreditCardItem('HDFC Regalia', '1234', '₹1,45,000 / ₹5,00,000', '15th', '05th June', AppColors.tealBlueGradient),
                _buildCreditCardItem('ICICI Amazon Pay', '5678', '₹24,500 / ₹3,00,000', '20th', '10th June', AppColors.purplePinkGradient),
                _buildAddCardButton(context),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Loans section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Loans & Ledgers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: AppColors.neonTeal),
                label: const Text('Add Loan', style: TextStyle(color: AppColors.neonTeal, fontSize: 13)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Loans items list
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildLoanItem('Home Loan (SBI)', 'Borrowed', '₹45,00,000', 'EMI: ₹38,200 (8.5%)', Colors.redAccent),
                _buildLoanItem('Joy (Split settlement)', 'Lent (Receivable)', '₹3,500', 'Friendly Loan (0%)', AppColors.neonEmerald),
                _buildLoanItem('Car Loan (HDFC)', 'Borrowed', '₹8,50,000', 'EMI: ₹18,400 (9.2%)', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardItem(
      String cardName, String last4, String spendText, String billDay, String dueText, List<Color> colors) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: GlassBlur(
        borderRadius: 20,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors[0].withOpacity(0.12), colors[1].withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '•••• •••• •••• $last4',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Icon(Icons.contactless, color: AppColors.textSecondary, size: 24),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SPENT / LIMIT', style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(spendText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCardFooter('Statement Day', '$billDay of month'),
                  _buildCardFooter('Due Date', dueText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFooter(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonTeal)),
      ],
    );
  }

  Widget _buildAddCardButton(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {},
        child: GlassBlur(
          borderRadius: 20,
          borderColor: AppColors.glassBorder.withOpacity(0.05),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_card_rounded, color: AppColors.neonTeal, size: 36),
                SizedBox(height: 8),
                Text('Add Card', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanItem(String title, String type, String principal, String emiInfo, Color typeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          subtitle: Text(emiInfo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
              ),
              const SizedBox(height: 4),
              Text(
                principal,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 3: INVESTMENTS VIEW (Zerodha & Coin holdings)
// ---------------------------------------------------------------------------
class InvestmentsView extends StatefulWidget {
  const InvestmentsView({super.key});

  @override
  State<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends State<InvestmentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Investments',
                style: Theme.of(context).textTheme.headlineMedium,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zerodha/Coin holding file picker opened (Mocked)')),
                  );
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
                border: Border.all(color: AppColors.neonEmerald.withOpacity(0.3)),
              ),
              labelColor: AppColors.neonEmerald,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Stocks (Zerodha)'),
                Tab(text: 'Mutual Funds (Coin)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total valuation banner
          GlassBlur(
            borderRadius: 16,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Valuation', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('₹9,80,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Returns', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('+₹1,24,000 (+14.5%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.neonEmerald)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Stocks
                ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHoldingItem('TCS', 'TATA Consultancy Services', '25 Qty', 'Avg: ₹3,820', 'Current: ₹4,150', '+8.6%'),
                    _buildHoldingItem('RELIANCE', 'Reliance Industries Ltd.', '50 Qty', 'Avg: ₹2,450', 'Current: ₹2,920', '+19.1%'),
                    _buildHoldingItem('INFY', 'Infosys Ltd.', '30 Qty', 'Avg: ₹1,610', 'Current: ₹1,480', '-8.1%'),
                  ],
                ),
                // MFs
                ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHoldingItem('Parag Parikh Flexi Cap', 'Direct Growth Mutual Fund', '1240 Units', 'Avg NAV: ₹62.4', 'Current NAV: ₹78.9', '+26.4%'),
                    _buildHoldingItem('Nippon India Small Cap', 'Direct Growth Mutual Fund', '820 Units', 'Avg NAV: ₹110.2', 'Current NAV: ₹132.5', '+20.2%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingItem(
      String symbol, String name, String qty, String avg, String current, String returns) {
    final isNegative = returns.startsWith('-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(symbol, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
              Text('$qty • $avg', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(current, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VIEW 4: AI FINANCIAL ADVISOR (Quant Engine + LLM Chat)
// ---------------------------------------------------------------------------
class AdvisorView extends StatefulWidget {
  const AdvisorView({super.key});

  @override
  State<AdvisorView> createState() => _AdvisorViewState();
}

class _AdvisorViewState extends State<AdvisorView> with SingleTickerProviderStateMixin {
  late TabController _advisorTabController;
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'AI',
      'text': 'Hello Akshat! I am your local privacy-first financial advisor. Based on your current profile: Net Worth is ₹12.45L, Credit outstanding is ₹60k, and you have EMIs totaling ₹56,600. How can I help you invest or manage debt today?'
    }
  ];

  @override
  void initState() {
    super.initState();
    _advisorTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _advisorTabController.dispose();
    _chatInputController.dispose();
    super.dispose();
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
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
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
                    Text('Cash Flow Forecast (June 2026)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Projected Spend: ₹1,20,500',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Based on current velocity (spending ₹2,300/day) + recurring HDFC regalia EMI (₹38.2k) + rent (₹25k).',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
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
                    Icon(Icons.pie_chart_outline_rounded, color: AppColors.neonEmerald),
                    SizedBox(width: 8),
                    Text('Rebalancing Recommendations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecommendationBullet(
                  'Asset Allocation mismatch',
                  'Your current holdings are 80% Stocks and 20% Mutual Funds. Standard aggressive recommendation is 70% Equity / 30% Debt/Hybrid. Consider shifting ₹50k to index funds.',
                ),
                const SizedBox(height: 8),
                _buildRecommendationBullet(
                  'Emergency Fund status',
                  'Emergency fund (₹3.25L in Bank) currently covers 2.7 months of EMIs + basic spends. We recommend building this up to ₹6.0L to cover 6 months.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationBullet(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.chevron_right, color: AppColors.neonEmerald, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 2, bottom: 8),
          child: Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    return Column(
      children: [
        // Chat History
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isAI = msg['sender'] == 'AI';
              return Align(
                alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: GlassBlur(
                    borderRadius: 16,
                    cardColor: isAI ? AppColors.glassCard : AppColors.neonPurple.withOpacity(0.1),
                    borderColor: isAI ? AppColors.glassBorder : AppColors.neonPurple.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        msg['text']!,
                        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Text Input box
        Row(
          children: [
            Expanded(
              child: GlassBlur(
                borderRadius: 16,
                child: TextField(
                  controller: _chatInputController,
                  decoration: const InputDecoration(
                    hintText: 'Ask advisor (e.g. should I pre-pay home loan?)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GlassBlur(
              borderRadius: 16,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.neonTeal),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'User', 'text': text});
      _chatInputController.clear();
    });

    // Mock response trigger
    Timer(const Duration(milliseconds: 1000), () {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': 'Analyzing your request locally... As a quantitative engine fallback, I advise reviewing your SBI home loan interest rate (8.5%). Pre-paying the principal saves long-term compounding interest if you don\'t expect your stock holdings to beat a net 10% annual return.'
        });
      });
    });
  }
}

// ---------------------------------------------------------------------------
// VIEW 5: SETTINGS SCREEN
// ---------------------------------------------------------------------------
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _biometricsEnabled = true;
  bool _localLLMEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Security Group
          _buildGroupTitle('Security & Privacy'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Authentication', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Lock app using Fingerprint / FaceID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _biometricsEnabled,
                  activeColor: AppColors.neonTeal,
                  onChanged: (val) => setState(() => _biometricsEnabled = val),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Manage PDF Passwords', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Add decryption keys for CC Statements', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Integrations Group
          _buildGroupTitle('Integrations & Fetching'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Configure Gmail IMAP', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Store email fetch credentials locally', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Google Drive Sync Setup', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Configure client OAuth credentials', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.cloud_queue_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Config Group
          _buildGroupTitle('AI Model Configuration'),
          GlassBlur(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable On-Device LLM', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Run Gemma-2B locally (needs 1.5GB file download)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _localLLMEnabled,
                  activeColor: AppColors.neonPurple,
                  onChanged: (val) => setState(() => _localLLMEnabled = val),
                ),
                const Divider(height: 1, color: AppColors.glassBorder),
                ListTile(
                  title: const Text('Cloud AI API Keys', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Configure personal Gemini or OpenAI keys', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.api_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Version Footer
          const Center(
            child: Text(
              'MypersonalTracker v1.0.0 • 100% Local Encryption',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
