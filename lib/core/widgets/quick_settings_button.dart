import 'package:flutter/cupertino.dart';
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
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: Text('Quick Settings'.tr()),
            actions: [
              CupertinoActionSheetAction(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.chat_bubble_2_fill, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Flexible(child: Text('SMS Sync'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SmsSyncScreen()));
                },
              ),
              CupertinoActionSheetAction(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.creditcard, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Flexible(child: Text('Google Pay Sync'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GooglePaySyncScreen()));
                },
              ),
              CupertinoActionSheetAction(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.flag, size: 20, color: AppColors.success),
                    const SizedBox(width: 12),
                    Flexible(child: Text('Goals'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
                },
              ),
              CupertinoActionSheetAction(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.settings, size: 20, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 12),
                    Flexible(child: Text('All Settings'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              child: Text('Cancel'.tr()),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      },
      child: Icon(
        CupertinoIcons.settings,
        color: AppColors.textPrimary(context),
      ),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
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
              icon: const Icon(CupertinoIcons.xmark, size: 20),
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
