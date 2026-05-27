import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

class HomeFloatingMascot extends StatefulWidget {
  const HomeFloatingMascot({super.key});

  @override
  State<HomeFloatingMascot> createState() => _HomeFloatingMascotState();
}

class _HomeFloatingMascotState extends State<HomeFloatingMascot> {
  bool _isVisible = true;

  void _hideMascot() {
    setState(() {
      _isVisible = false;
    });
  }

  void _showFeatureAssistant() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AppFeatureAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      bottom: 16,
      child: GestureDetector(
        onTap: _showFeatureAssistant,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,

              ),
              child: const FlowMascotAvatar(size: 110),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: _hideMascot,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    shape: BoxShape.circle,

                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppFeatureAssistantSheet extends StatelessWidget {
  const AppFeatureAssistantSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 120,
            height: 120,
            child: const FlowMascotAvatar(size: 120),
          ),
          const SizedBox(height: 16),
          Text(
            'Flow Finance Features'.tr(),
            style: AppTypography.headlineSmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Here is everything I can help you with!'.tr(),
            style: AppTypography.bodyMedium(color: AppColors.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FeatureTile(
                    icon: CupertinoIcons.sparkles,
                    iconColor: AppColors.primary,
                    title: 'AI Insights',
                    subtitle: 'Get smart financial analysis and suggestions',
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.chart_pie,
                    iconColor: AppColors.secondary,
                    title: 'Budgets & Goals',
                    subtitle: 'Track your spending limits and savings',
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    iconColor: AppColors.success,
                    title: 'SMS & Google Pay Sync',
                    subtitle: 'Automatically import transactions',
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.person_3_fill,
                    iconColor: AppColors.warning,
                    title: 'Family Mode',
                    subtitle: 'Share budgets and track expenses together',
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.repeat,
                    iconColor: AppColors.income,
                    title: 'Recurring Bills',
                    subtitle: 'Manage your subscriptions automatically',
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.building_2_fill,
                    iconColor: AppColors.info,
                    title: 'Bank Integration',
                    subtitle: 'Connect your real bank accounts securely',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            label: 'Got it!'.tr(),
            onPressed: () => Navigator.pop(context),
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr(),
                  style: AppTypography.bodyLarge(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.tr(),
                  style: AppTypography.bodySmall(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
