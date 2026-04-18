import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modern typography system using Inter font family
/// Follows 2025 design trends with tight letter-spacing and clear hierarchy
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String fontFamilyFallback = 'Avenir';

  // Display - Large prominent text
  static TextStyle displayLarge({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.5,
        height: 1.1,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        height: 1.2,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.8,
        height: 1.2,
        color: color,
      );

  // Headlines
  static TextStyle headlineLarge({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.8,
        height: 1.2,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.3,
        color: color,
      );

  static TextStyle headlineSmall({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
        color: color,
      );

  // Titles
  static TextStyle titleLarge({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: color,
      );

  // Body
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.normal,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.normal,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.normal,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  // Labels
  static TextStyle labelLarge({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle labelMedium({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle labelSmall({Color? color, FontWeight? fontWeight}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 10,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.4,
        color: color,
      );

  // Special styles for finance app
  static TextStyle amountLarge({Color? color, bool isNegative = false}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
        color: color ??
            (isNegative ? AppColors.expense : AppColors.income),
      );

  static TextStyle amountMedium({Color? color, bool isNegative = false}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: color ??
            (isNegative ? AppColors.expense : AppColors.income),
      );

  static TextStyle amountSmall({Color? color, bool isNegative = false}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: color ??
            (isNegative ? AppColors.expense : AppColors.income),
      );

  static TextStyle currencySymbol({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: color,
      );

  static TextStyle buttonLarge({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle buttonMedium({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle buttonSmall({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.4,
        color: color,
      );

  static TextStyle caption({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
        color: color,
      );

  static TextStyle overline({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const [fontFamilyFallback],
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.4,
        color: color,
      );
}

/// Extension for easy typography access
extension TypographyExtension on BuildContext {
  TextStyle get displayLarge => AppTypography.displayLarge(color: AppColors.textPrimary(this));
  TextStyle get displayMedium => AppTypography.displayMedium(color: AppColors.textPrimary(this));
  TextStyle get displaySmall => AppTypography.displaySmall(color: AppColors.textPrimary(this));
  TextStyle get headlineLarge => AppTypography.headlineLarge(color: AppColors.textPrimary(this));
  TextStyle get headlineMedium => AppTypography.headlineMedium(color: AppColors.textPrimary(this));
  TextStyle get headlineSmall => AppTypography.headlineSmall(color: AppColors.textPrimary(this));
  TextStyle get titleLarge => AppTypography.titleLarge(color: AppColors.textPrimary(this));
  TextStyle get titleMedium => AppTypography.titleMedium(color: AppColors.textPrimary(this));
  TextStyle get titleSmall => AppTypography.titleSmall(color: AppColors.textPrimary(this));
  TextStyle get bodyLarge => AppTypography.bodyLarge(color: AppColors.textPrimary(this));
  TextStyle get bodyMedium => AppTypography.bodyMedium(color: AppColors.textPrimary(this));
  TextStyle get bodySmall => AppTypography.bodySmall(color: AppColors.textSecondary(this));
  TextStyle get labelLarge => AppTypography.labelLarge(color: AppColors.textPrimary(this));
  TextStyle get labelMedium => AppTypography.labelMedium(color: AppColors.textSecondary(this));
  TextStyle get labelSmall => AppTypography.labelSmall(color: AppColors.textTertiary(this));
}
