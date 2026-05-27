import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/theme.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/sms_sync_screen.dart';
import '../../presentation/screens/settings/google_pay_sync_screen.dart';
import '../../presentation/screens/goals/goals_screen.dart';

/// Quick settings button with menu
class QuickSettingsButton extends StatelessWidget {
  const QuickSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.settings_suggest,
        color: AppColors.textPrimary(context),
      ),
      tooltip: 'Quick Settings'.tr(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'sms_sync':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmsSyncScreen()),
            );
            break;
          case 'google_pay':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const GooglePaySyncScreen()),
            );
            break;
          case 'goals':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GoalsScreen()),
            );
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'sms_sync',
          child: Row(
            children: [
              Icon(Icons.sms, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Flexible(child: Text('SMS Sync'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'google_pay',
          child: Row(
            children: [
              Icon(Icons.payment, size: 20, color: AppColors.secondary),
              const SizedBox(width: 12),
              Flexible(child: Text('Google Pay Sync'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'goals',
          child: Row(
            children: [
              Icon(Icons.flag, size: 20, color: AppColors.success),
              const SizedBox(width: 12),
              Flexible(child: Text('Goals'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings,
                  size: 20, color: AppColors.textSecondary(context)),
              const SizedBox(width: 12),
              Flexible(child: Text('All Settings'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quick settings guide banner
class QuickSettingsGuideBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const QuickSettingsGuideBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
