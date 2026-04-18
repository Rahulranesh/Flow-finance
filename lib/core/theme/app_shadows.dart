import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modern shadow system with soft, diffused shadows
/// Creates depth without harsh edges - perfect for 2025 UI design
class AppShadows {
  AppShadows._();

  /// No shadow - flat design
  static const List<BoxShadow> none = [];

  /// Extra small shadow - subtle elevation
  static List<BoxShadow> get xs => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.04),
          blurRadius: 2,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Small shadow - cards at rest
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.05),
          blurRadius: 4,
          spreadRadius: -1,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium shadow - elevated cards, buttons
  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.06),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// Large shadow - modals, floating elements
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 16,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  /// Extra large shadow - dialogs, bottom sheets
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 24,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
      ];

  /// 2XL shadow - full screen overlays
  static List<BoxShadow> get xxl => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.12),
          blurRadius: 32,
          spreadRadius: -8,
          offset: const Offset(0, 16),
        ),
      ];

  /// Inner shadow for inset effect
  static List<BoxShadow> get inner => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.06),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Colored shadow with primary color
  static List<BoxShadow> colored({double opacity = 0.15}) => [
        BoxShadow(
          color: AppColors.primary.withOpacity(opacity),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  /// Success colored shadow
  static List<BoxShadow> success({double opacity = 0.2}) => [
        BoxShadow(
          color: AppColors.success.withOpacity(opacity),
          blurRadius: 16,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];

  /// Error colored shadow
  static List<BoxShadow> error({double opacity = 0.2}) => [
        BoxShadow(
          color: AppColors.error.withOpacity(opacity),
          blurRadius: 16,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];

  /// Glassmorphism shadow - for modern glass effects
  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.white.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, -5),
        ),
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 30,
          spreadRadius: -10,
          offset: const Offset(0, 10),
        ),
      ];

  /// Neumorphism light shadow
  static List<BoxShadow> get neumorphismLight => [
        BoxShadow(
          color: Colors.white.withOpacity(0.8),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(-4, -4),
        ),
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(4, 4),
        ),
      ];

  /// Neumorphism dark shadow
  static List<BoxShadow> get neumorphismDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(4, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(-4, -4),
        ),
      ];
}

/// Box decoration presets for common card styles
class AppDecorations {
  AppDecorations._();

  /// Flat card - no elevation
  static BoxDecoration flat(BuildContext context) => BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      );

  /// Elevated card - small shadow
  static BoxDecoration elevated(BuildContext context) => BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      );

  /// Highlighted card - medium shadow with border
  static BoxDecoration highlighted(BuildContext context) => BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppShadows.md,
      );

  /// Premium card - large shadow with gradient border
  static BoxDecoration premium(BuildContext context) => BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface(context),
            AppColors.surfaceVariant(context),
          ],
        ),
        boxShadow: AppShadows.lg,
      );

  /// Glass card - for modern glassmorphism effect
  static BoxDecoration glass(BuildContext context) => BoxDecoration(
        color: AppColors.surface(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppShadows.glass,
      );

  /// Input field decoration
  static BoxDecoration input(BuildContext context, {bool isFocused = false}) =>
      BoxDecoration(
        color: AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.primary : AppColors.border(context),
          width: isFocused ? 2 : 1,
        ),
      );

  /// Button decoration - primary
  static BoxDecoration buttonPrimary({bool isPressed = false}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPressed ? AppShadows.xs : AppShadows.md,
      );

  /// Button decoration - secondary
  static BoxDecoration buttonSecondary(BuildContext context,
          {bool isPressed = false}) =>
      BoxDecoration(
        color: AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: isPressed ? AppShadows.none : AppShadows.xs,
      );

  /// Chip decoration
  static BoxDecoration chip(BuildContext context, {bool isSelected = false}) =>
      BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border(context),
          width: 1,
        ),
      );

  /// Avatar decoration
  static BoxDecoration avatar({double radius = 40}) => BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
      );

  /// Circular progress indicator background
  static BoxDecoration progressBackground(BuildContext context) =>
      BoxDecoration(
        color: AppColors.surfaceVariant(context),
        shape: BoxShape.circle,
      );
}
