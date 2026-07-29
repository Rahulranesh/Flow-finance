import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../blocs/premium_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flow_mascot.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static Color get _gold => AppColors.warning;

  static const _features = [
    _PremiumFeature('Unlimited budgets', CupertinoIcons.chart_pie, 'Create and track as many budgets as you want'),
    _PremiumFeature('AI-powered insights', CupertinoIcons.sparkles, 'Smart financial analysis and suggestions'),
    _PremiumFeature('Bank integration', CupertinoIcons.building_2_fill, 'Connect your real bank accounts'),
    _PremiumFeature('Family mode', CupertinoIcons.person_2, 'Shared budgets with your family'),
    _PremiumFeature('SMS auto-sync', CupertinoIcons.chat_bubble, 'Import bank/UPI transactions from SMS'),
    _PremiumFeature('Export PDF reports', CupertinoIcons.doc_richtext, 'Printable finance reports'),
    _PremiumFeature('Ad-free experience', CupertinoIcons.eye_slash, 'No banners or interstitials'),
    _PremiumFeature('Priority support', CupertinoIcons.star, 'Fast email support'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const FlowMascotAvatar(size: 80, showGlow: true, mood: MascotMood.achieve),
              const SizedBox(height: 20),
              Text(
                'Upgrade to Premium'.tr(),
                style: AppTypography.headlineSmall(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock all features and take control of your finances'.tr(),
                style: AppTypography.bodyMedium(color: AppColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildPricingCard(context, isDark, monthly: true),
              const SizedBox(height: 12),
              _buildPricingCard(context, isDark, monthly: false),
              const SizedBox(height: 28),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.read<PremiumController>().restorePurchases(),
                child: Text(
                  'Restore Purchases'.tr(),
                  style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureList(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, bool isDark, {required bool monthly}) {
    final controller = context.watch<PremiumController>();
    final price = monthly ? '₹99' : '₹899';
    final period = monthly ? 'month'.tr() : 'year'.tr();
    final subtitle = monthly
        ? 'Billed monthly, cancel anytime'.tr()
        : '₹75/month — save 25%'.tr();

    return GestureDetector(
      onTap: () => monthly ? controller.purchaseMonthly() : controller.purchaseYearly(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: monthly
                ? _gold.withOpacity(0.3)
                : _gold.withOpacity(0.5),
            width: monthly ? 1.5 : 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!monthly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BEST VALUE'.tr(),
                            style: AppTypography.labelSmall(color: _gold, fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (!monthly) const SizedBox(width: 8),
                      Text(
                        period,
                        style: AppTypography.bodyLarge(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: AppTypography.headlineSmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '/$period',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                monthly ? CupertinoIcons.money_dollar : CupertinoIcons.star_fill,
                color: _gold,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything included:'.tr(),
            style: AppTypography.bodyLarge(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ..._features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(f.icon, size: 16, color: _gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: AppTypography.bodyMedium(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.subtitle,
                        style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PremiumFeature {
  final String title;
  final IconData icon;
  final String subtitle;
  const _PremiumFeature(this.title, this.icon, this.subtitle);
}
