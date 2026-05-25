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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Welcome to Flow Finance',
      subtitle:
          'Your personal finance companion for a brighter financial future.',
      icon: Icons.account_balance_wallet,
      color: AppColors.primary,
    ),
    _OnboardingPage(
      title: 'Track Your Expenses',
      subtitle:
          'Easily record and categorize your daily transactions in seconds.',
      icon: Icons.receipt_long,
      color: AppColors.secondary,
    ),
    _OnboardingPage(
      title: 'Set Budgets',
      subtitle:
          'Create monthly budgets and get alerts when you\'re close to limits.',
      icon: Icons.pie_chart,
      color: AppColors.warning,
    ),
    _OnboardingPage(
      title: 'Visualize Progress',
      subtitle:
          'Beautiful charts and insights to help you understand your spending.',
      icon: Icons.trending_up,
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.normal,
        curve: AppAnimations.easeInOut,
      );
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'Skip'.tr(),
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        return AnimatedContainer(
                          duration: AppAnimations.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.border(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Next/Get Started button
                    AppButton.primary(
                      label: _currentPage == _pages.length - 1
                          ? 'Get Started'.tr()
                          : 'Next'.tr(),
                      onPressed: _nextPage,
                      expanded: true,
                      size: AppButtonSize.large,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: AppAnimations.slower,
            curve: AppAnimations.springLight,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.color.withOpacity(0.2),
                    page.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withOpacity(0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Icon(
                    page.icon,
                    size: 86,
                    color: page.color,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title.tr(),
            style: AppTypography.headlineMedium(),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle.tr(),
            style: AppTypography.bodyLarge(
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

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

              const SizedBox(height: 40),

              // Name input
              AppInput(
                controller: _nameController,
                label: 'Your Name'.tr(),
                hint: 'Enter your name'.tr(),
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 24),

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
