import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { small, medium, large }
enum AppIconButtonSize { small, medium, large }
enum AppIconButtonVariant { standard, filled, outlined }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => Colors.transparent,
      AppButtonVariant.ghost => Colors.transparent,
      AppButtonVariant.danger => AppColors.error,
    };

    final textColor = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      AppButtonVariant.ghost => AppColors.primary,
      AppButtonVariant.danger => Colors.white,
    };

    final border = variant == AppButtonVariant.secondary
        ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)
        : null;

    final padding = switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    };

    final ts = switch (size) {
      AppButtonSize.small => AppTypography.buttonSmall(),
      AppButtonSize.medium => AppTypography.buttonMedium(),
      AppButtonSize.large => AppTypography.buttonLarge(),
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18, height: 18,
            child: CupertinoActivityIndicator(
              radius: 9,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(label, style: ts.copyWith(color: textColor)),
        ],
      ],
    );

    final opacity = (onPressed == null || isLoading) ? 0.5 : 1.0;

    final button = Container(
      width: expanded ? double.infinity : null,
      padding: padding,
      decoration: variant == AppButtonVariant.ghost ? null : BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (onPressed != null && !isLoading) ? onPressed : null,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          child: button,
        ),
      ),
    );
  }
}

/// Flat icon button — clean, no animations/shadows.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final AppIconButtonVariant variant;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppIconButtonSize.medium,
    this.variant = AppIconButtonVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg, hasBorder) = switch (variant) {
      AppIconButtonVariant.standard => (Colors.transparent, isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, false),
      AppIconButtonVariant.filled => (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight, isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, false),
      AppIconButtonVariant.outlined => (Colors.transparent, isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, true),
    };

    final containerSize = switch (size) {
      AppIconButtonSize.small => 32.0,
      AppIconButtonSize.medium => 40.0,
      AppIconButtonSize.large => 52.0,
    };

    final iconSize = switch (size) {
      AppIconButtonSize.small => 16.0,
      AppIconButtonSize.medium => 20.0,
      AppIconButtonSize.large => 26.0,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: hasBorder ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight) : null,
          ),
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
  }
}
