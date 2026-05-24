import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Modern scaffold with consistent styling and navigation
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.body,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = false,
  });

  final String? title;
  final Widget? body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null
          ? AppBar(
              title: Text(
                title!,
                style: AppTypography.headlineSmall(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              centerTitle: centerTitle,
              backgroundColor: extendBodyBehindAppBar
                  ? Colors.transparent
                  : (isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: leading ??
                  (showBackButton && Navigator.canPop(context)
                      ? AppIconButton(
                          icon: Icons.arrow_back,
                          onPressed:
                              onBackPressed ?? () => Navigator.pop(context),
                          variant: AppIconButtonVariant.filled,
                        )
                      : null),
              actions: actions,
            )
          : null,
      body: body == null
          ? null
          : Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -40,
                  child: IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(isDark ? 0.08 : 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppAnimations.medium,
                  switchInCurve: AppAnimations.easeOutCubic,
                  switchOutCurve: AppAnimations.easeInOut,
                  child: body!,
                ),
              ],
            ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Scaffold with custom scroll view and slivers
class AppScrollScaffold extends StatelessWidget {
  const AppScrollScaffold({
    super.key,
    this.title,
    this.slivers,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = false,
    this.pinnedHeader = true,
  });

  final String? title;
  final List<Widget>? slivers;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final bool pinnedHeader;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      body: CustomScrollView(
        slivers: [
          if (title != null)
            SliverAppBar(
              title: Text(
                title!,
                style: AppTypography.headlineSmall(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              centerTitle: centerTitle,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(isDark ? 0.08 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: pinnedHeader,
              leading: leading ??
                  (showBackButton && Navigator.canPop(context)
                      ? AppIconButton(
                          icon: Icons.arrow_back,
                          onPressed:
                              onBackPressed ?? () => Navigator.pop(context),
                          variant: AppIconButtonVariant.filled,
                        )
                      : null),
              actions: actions,
            ),
          ...?slivers,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Bottom navigation bar with modern styling
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _NavItem(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Floating action button with animation
class AppFAB extends StatelessWidget {
  const AppFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

/// Section header for scroll views
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLarge(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          if (action != null)
            action!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
