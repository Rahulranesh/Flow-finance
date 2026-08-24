import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../navigation/main_navigation_screen.dart';

/// Onboarding flow for new users with clean, handcrafted UI cards
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
      title: 'Take Control of\nYour Money',
      subtitle:
          'Smart, private, and automated personal finance tracking designed for everyday financial freedom.',
      features: ['Instant SMS Tracking', 'AI Spending Insights', '100% On-Device Privacy'],
      type: _OnboardingCardType.walletPreview,
    ),
    _OnboardingPage(
      title: 'Automatic SMS\nExpense Tracking',
      subtitle:
          'Never type expenses manually. Bank SMS alerts are automatically parsed and categorized in real-time.',
      features: ['Real-Time SMS Sync', 'Zero Manual Typing', 'Instant Categorization'],
      type: _OnboardingCardType.smsPreview,
    ),
    _OnboardingPage(
      title: 'Smart Category\nBudget Limits',
      subtitle: 'Set flexible spending targets for food, shopping, and bills. Receive instant alerts before overspending.',
      features: ['Category Limits', 'Overspend Alerts', 'Cash Flow Trends'],
      type: _OnboardingCardType.budgetPreview,
    ),
    _OnboardingPage(
      title: 'Achieve Every\nFinancial Goal',
      subtitle:
          'Set custom targets for emergencies, travel, or major purchases and celebrate your milestone progress.',
      features: ['Custom Milestones', 'Visual Progress', 'Family Budgeting'],
      type: _OnboardingCardType.goalsPreview,
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
          // Background gradient header
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            height: size.height * 0.52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),

          // Main layout
          SafeArea(
            child: Column(
              children: [
                // Top header bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Identity
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 36,
                                height: 36,
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
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      // Skip button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Card Illustration PageView
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCardIllustration(_pages[index].type),
                      );
                    },
                  ),
                ),

                // Bottom Content Sheet
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Indicators
                            Row(
                              children: List.generate(_pages.length, (index) {
                                final isActive = _currentPage == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: isActive ? 32 : 8,
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
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              _pages[_currentPage].subtitle.tr(),
                              style: TextStyle(
                                fontSize: 14.5,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Feature Chips
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
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        f.tr(),
                                        style: TextStyle(
                                          fontSize: 12.5,
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

                            // Primary CTA Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
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
                                        fontSize: 16.5,
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

                            const SizedBox(height: 12),
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

  /// Builds a handcrafted native UI card preview for each page
  Widget _buildCardIllustration(_OnboardingCardType type) {
    switch (type) {
      case _OnboardingCardType.walletPreview:
        return _buildWalletPreviewCard();
      case _OnboardingCardType.smsPreview:
        return _buildSmsPreviewCard();
      case _OnboardingCardType.budgetPreview:
        return _buildBudgetPreviewCard();
      case _OnboardingCardType.goalsPreview:
        return _buildGoalsPreviewCard();
    }
  }

  Widget _buildWalletPreviewCard() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 190,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.creditcard_fill, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Flow Wallet',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.arrow_up_right, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text('+12.4%', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
                SizedBox(height: 4),
                Text(
                  '₹1,24,500.00',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('**** **** 4892', style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 2)),
                Text('100% Private', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsPreviewCard() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.chat_bubble_fill, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bank Alert • Just Now',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '₹499.00 debited from A/c XX1234 at Swiggy via UPI',
              style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Parsed: Swiggy • Food & Dining',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetPreviewCard() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.chart_pie_fill, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Food & Dining',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                const Text(
                  '₹8,450 / ₹10,000',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.845,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '84.5% Spent',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₹1,550 Left • On Track',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsPreviewCard() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.flag_fill, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Emergency & Travel Fund',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('78%', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.78,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '₹78,000 saved of ₹1,00,000',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: const [
                    Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('2 Badges', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _OnboardingCardType {
  walletPreview,
  smsPreview,
  budgetPreview,
  goalsPreview,
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final List<String> features;
  final _OnboardingCardType type;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.type,
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

              AppInput(
                controller: _nameController,
                label: 'Your Name'.tr(),
                hint: 'Enter your name'.tr(),
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 28),

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
