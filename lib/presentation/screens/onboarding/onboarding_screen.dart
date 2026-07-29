import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../navigation/main_navigation_screen.dart';

/// Onboarding flow for new users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Welcome to\nFlow Finance',
      subtitle:
          'Your smart personal finance companion for a brighter financial future.',
      icon: CupertinoIcons.creditcard_fill,
      features: ['Track every rupee', 'Smart AI insights', 'Beautiful reports'],
    ),
    _OnboardingPage(
      title: 'Track Your\nExpenses',
      subtitle:
          'Log transactions in seconds. SMS sync and Google Pay import make it effortless.',
      icon: CupertinoIcons.doc_checkmark_fill,
      features: ['Auto SMS import', 'Google Pay sync', 'Smart categories'],
    ),
    _OnboardingPage(
      title: 'Set Smart\nBudgets',
      subtitle: 'Create monthly budgets and get alerts before you overspend.',
      icon: CupertinoIcons.chart_pie_fill,
      features: ['Monthly limits', 'Overspend alerts', 'Category budgets'],
    ),
    _OnboardingPage(
      title: 'Reach Your\nGoals',
      subtitle:
          'Set savings goals and watch your progress with beautiful visualizations.',
      icon: CupertinoIcons.chart_bar_fill,
      features: ['Savings goals', 'Progress tracking', 'Family sharing'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _fadeController.forward();
      });
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('seen_onboarding', true);
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Unified gradient background for all slides (top half)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            height: size.height * 0.55,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Flow Finance',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // Skip
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration area
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _fadeController.forward(from: 0);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildIllustration(_pages[index]);
                    },
                  ),
                ),

                // Bottom content card
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page indicators
                            Row(
                              children: List.generate(_pages.length, (index) {
                                final isActive = _currentPage == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: isActive ? 28 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? primaryColor
                                        : primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 20),

                            // Title
                            Text(
                              _pages[_currentPage].title.tr(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              _pages[_currentPage].subtitle.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Feature chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _pages[_currentPage].features.map((f) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        f.tr(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const Spacer(),

                            // Next button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage == _pages.length - 1
                                          ? 'Get Started'.tr()
                                          : 'Next'.tr(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.arrow_right,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(_OnboardingPage page) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: child,
        ),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> features;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.features,
  });
}

/// Initial setup screen after onboarding
class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _nameController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR');
  String _selectedCurrency = 'INR';

  final List<_Currency> _currencies = const [
    _Currency('INR', '₹', 'Indian Rupee'),
    _Currency('USD', '\$', 'US Dollar'),
    _Currency('EUR', '€', 'Euro'),
    _Currency('GBP', '£', 'British Pound'),
    _Currency('JPY', '¥', 'Japanese Yen'),
    _Currency('AUD', 'A\$', 'Australian Dollar'),
    _Currency('CAD', 'C\$', 'Canadian Dollar'),
    _Currency('SGD', 'S\$', 'Singapore Dollar'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _completeSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8860B), Color(0xFFE7B416)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Let\'s set you up'.tr(),
                style: AppTypography.headlineLarge(),
              ),

              const SizedBox(height: 8),

              Text(
                'We just need a few details to get started.'.tr(),
                style: AppTypography.bodyLarge(
                  color: AppColors.textSecondary(context),
                ),
              ),

              const SizedBox(height: 32),

              // Name input
              AppInput(
                controller: _nameController,
                label: 'Your Name'.tr(),
                hint: 'Enter your name'.tr(),
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 28),

              // Currency selector
              Text(
                'Currency'.tr(),
                style: AppTypography.labelLarge(),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currencies.map((currency) {
                  final isSelected = currency.code == _selectedCurrency;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency.code;
                      });
                    },
                    child: AnimatedContainer(
                      duration: AppAnimations.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency.symbol,
                            style: AppTypography.titleMedium(
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.code,
                            style: AppTypography.bodyMedium(
                              fontWeight: isSelected ? FontWeight.w600 : null,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Complete button
              AppButton.primary(
                label: 'Complete Setup'.tr(),
                onPressed: _completeSetup,
                expanded: true,
                size: AppButtonSize.large,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Currency {
  final String code;
  final String symbol;
  final String name;

  const _Currency(this.code, this.symbol, this.name);
}
