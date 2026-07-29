import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../presentation/blocs/premium_controller.dart';
import '../../presentation/screens/settings/paywall_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final Feature feature;

  const PremiumGate({
    super.key,
    required this.child,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumController>().isPremium;
    if (isPremium) return child;

    return Stack(
      children: [
        child,
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  Icon(CupertinoIcons.lock_fill, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Premium Feature'.tr(),
                      style: AppTypography.titleMedium(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature.description.tr(),
                      style: AppTypography.bodySmall(color: AppColors.textSecondary(context)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton(
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      child: Text(
                        'Unlock Premium'.tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Feature {
  final String id;
  final String description;
  const Feature(this.id, this.description);
}
