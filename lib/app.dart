import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/lock_screen.dart';
import 'core/animated_gradient_background.dart';
import 'ui/onboarding/model_onboarding.dart';
import 'features/expenses/ui/dashboard_view.dart';
import 'features/cards_loans/ui/cards_loans_view.dart';
import 'features/investments/ui/investments_view.dart';
import 'features/advisor/ui/advisor_view.dart';
import 'ui/settings/settings_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MypersonalTracker',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const AppStartupLockGate(),
    );
  }
}

class AppStartupLockGate extends ConsumerStatefulWidget {
  const AppStartupLockGate({super.key});

  @override
  ConsumerState<AppStartupLockGate> createState() => _AppStartupLockGateState();
}

class _AppStartupLockGateState extends ConsumerState<AppStartupLockGate> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return const MainNavigationShell();
    }
    return LockScreen(
      onAuthenticated: () {
        setState(() {
          _isUnlocked = true;
        });
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenModelOnboarding') ?? false;
    if (!hasSeen) {
      await prefs.setBool('hasSeenModelOnboarding', true);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ModelOnboardingScreen()));
    }
  }

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
      extendBody: true,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: View.of(context).viewInsets.bottom > 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                        _buildNavBarItem(
                          Icons.psychology_rounded,
                          'AI Advisor',
                          3,
                        ),
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
              color: isSelected
                  ? activeColor.withOpacity(0.15)
                  : Colors.transparent,
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
