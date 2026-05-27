import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';
import '../theme/app_animations.dart';

/// Unified button component with multiple variants
/// Supports primary, secondary, ghost, and icon button types
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.expanded = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.expanded = false,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool isLoading;
  final bool isDisabled;
  final bool expanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { small, medium, large }
enum IconPosition { left, right }

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.buttonPress,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: _buildButton(isDark),
      ),
    );
  }

  Widget _buildButton(bool isDark) {
    final config = _getButtonConfig(isDark);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null && widget.iconPosition == IconPosition.left) ...[
          _buildIcon(config.foregroundColor),
          SizedBox(width: _getIconSpacing()),
        ],
        if (widget.isLoading)
          SizedBox(
            width: _getLoadingSize(),
            height: _getLoadingSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(config.foregroundColor),
            ),
          )
        else
          Flexible(
            child: Text(
              widget.label,
              style: _getTextStyle().copyWith(color: config.foregroundColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (widget.icon != null && widget.iconPosition == IconPosition.right) ...[
          SizedBox(width: _getIconSpacing()),
          _buildIcon(config.foregroundColor),
        ],
      ],
    );

    Widget button = Container(
      width: widget.expanded ? double.infinity : null,
      padding: _getPadding(),
      decoration: BoxDecoration(
        gradient: config.gradient,
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: config.border,
        boxShadow: config.shadow,
      ),
      child: buttonContent,
    );

    if (widget.isDisabled || widget.isLoading) {
      return Opacity(
        opacity: 0.5,
        child: button,
      );
    }

    return GestureDetector(
      onTap: widget.onPressed,
      child: button,
    );
  }

  Widget _buildIcon(Color color) {
    return Icon(
      widget.icon,
      size: _getIconSize(),
      color: color,
    );
  }

  _ButtonConfig _getButtonConfig(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonConfig(
          backgroundColor: null,
          foregroundColor: Colors.white,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          border: null,
          shadow: AppShadows.md,
        );
      case AppButtonVariant.secondary:
        return _ButtonConfig(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          gradient: null,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          shadow: AppShadows.xs,
        );
      case AppButtonVariant.ghost:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          gradient: null,
          border: null,
          shadow: AppShadows.none,
        );
      case AppButtonVariant.danger:
        return _ButtonConfig(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          gradient: null,
          border: null,
          shadow: AppShadows.md,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 8;
      case AppButtonSize.medium:
        return 12;
      case AppButtonSize.large:
        return 16;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall();
      case AppButtonSize.medium:
        return AppTypography.buttonMedium();
      case AppButtonSize.large:
        return AppTypography.buttonLarge();
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 6;
      case AppButtonSize.medium:
        return 8;
      case AppButtonSize.large:
        return 10;
    }
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 22;
    }
  }
}

class _ButtonConfig {
  final Color? backgroundColor;
  final Color foregroundColor;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow> shadow;

  _ButtonConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.gradient,
    required this.border,
    required this.shadow,
  });
}

/// Icon button component
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppIconButtonSize.medium,
    this.variant = AppIconButtonVariant.standard,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final AppIconButtonVariant variant;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

enum AppIconButtonSize { small, medium, large }
enum AppIconButtonVariant { standard, filled, outlined }

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.buttonPress,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig(isDark);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: _getContainerSize(),
          height: _getContainerSize(),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            border: config.border,
            boxShadow: config.shadow,
          ),
          child: Icon(
            widget.icon,
            size: _getIconSize(),
            color: config.iconColor,
          ),
        ),
      ),
    );
  }

  _IconButtonConfig _getConfig(bool isDark) {
    switch (widget.variant) {
      case AppIconButtonVariant.standard:
        return _IconButtonConfig(
          backgroundColor: Colors.transparent,
          iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          border: null,
          shadow: AppShadows.none,
        );
      case AppIconButtonVariant.filled:
        return _IconButtonConfig(
          backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          border: null,
          shadow: AppShadows.xs,
        );
      case AppIconButtonVariant.outlined:
        return _IconButtonConfig(
          backgroundColor: Colors.transparent,
          iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          shadow: AppShadows.none,
        );
    }
  }

  double _getContainerSize() {
    switch (widget.size) {
      case AppIconButtonSize.small:
        return 32;
      case AppIconButtonSize.medium:
        return 44;
      case AppIconButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppIconButtonSize.small:
        return 16;
      case AppIconButtonSize.medium:
        return 22;
      case AppIconButtonSize.large:
        return 28;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case AppIconButtonSize.small:
        return 8;
      case AppIconButtonSize.medium:
        return 12;
      case AppIconButtonSize.large:
        return 16;
    }
  }
}

class _IconButtonConfig {
  final Color backgroundColor;
  final Color iconColor;
  final Border? border;
  final List<BoxShadow> shadow;

  _IconButtonConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.border,
    required this.shadow,
  });
}
