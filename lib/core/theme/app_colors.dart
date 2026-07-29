import 'package:flutter/material.dart';

/// Accent color enum representing selectable theme accent color combos
enum AppAccentColor {
  greenGold('Green & Gold', Color(0xFF10B981), Color(0xFFD4AF37), Color(0xFF047857)),
  gold('Gold Classic', Color(0xFFB8860B), Color(0xFFD4AF37), Color(0xFF8A6500)),
  blue('Blue Shades', Color(0xFF2563EB), Color(0xFF60A5FA), Color(0xFF1D4ED8));

  final String label;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  const AppAccentColor(this.label, this.primary, this.primaryLight, this.primaryDark);
}

/// Modern palette with selectable accent colors for a clean finance UI.
class AppColors {
  AppColors._();

  static AppAccentColor _accent = AppAccentColor.gold;

  static void setAccent(AppAccentColor accent) {
    _accent = accent;
  }

  static AppAccentColor get currentAccent => _accent;

  // Dynamic Primary Accent
  static Color get primary => _accent.primary;
  static Color get primaryLight => _accent.primaryLight;
  static Color get primaryLighter => _accent.primaryLight.withOpacity(0.3);
  static Color get primaryDark => _accent.primaryDark;
  static Color get primaryDarker => _accent.primaryDark;

  // Secondary - Cool Slate Grey
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryLight = Color(0xFFCBD5E1);
  static const Color secondaryLighter = Color(0xFFF1F5F9);
  static const Color secondaryDark = Color(0xFF334155);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFA7F3D0);
  static const Color successDark = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFDE68A);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoDark = Color(0xFF1D4ED8);

  // Light Theme Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  // Dark Theme Backgrounds
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color surfaceElevatedDark = Color(0xFF1E293B);

  // Light Theme Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  // Dark Theme Text
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static Color get borderFocused => primary;

  // Snackbar
  static const Color snackbarBackgroundLight = Color(0xFF0F172A);
  static const Color snackbarTextLight = Color(0xFFFFFFFF);
  static const Color snackbarBackgroundDark = Color(0xFF1E293B);
  static const Color snackbarTextDark = Color(0xFFF8FAFC);

  // Navigation Bar
  static const Color navBarBackgroundLight = Color(0xFFFFFFFF);
  static const Color navBarBorderLight = Color(0xFFE2E8F0);
  static const Color navBarBackgroundDark = Color(0xFF1E293B);
  static const Color navBarBorderDark = Color(0xFF334155);

  // Primary background for action bars
  static const Color actionBarBackgroundLight = Color(0xFFFFFFFF);
  static const Color actionBarBorderLight = Color(0xFFE2E8F0);
  static const Color actionBarBackgroundDark = Color(0xFF1E293B);
  static const Color actionBarBorderDark = Color(0xFF334155);

  // Income/Expense (Finance specific)
  static const Color income = Color(0xFF10B981);
  static const Color incomeLight = Color(0xFFA7F3D0);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFCA5A5);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
  ];

  /// Get color based on brightness
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? backgroundLight
        : backgroundDark;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceVariantLight
        : surfaceVariantDark;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }

  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textTertiaryLight
        : textTertiaryDark;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? borderLight
        : borderDark;
  }

  /// Helper method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

/// Extension for easy color access in widgets
extension ColorExtension on BuildContext {
  Color get backgroundColor => AppColors.background(this);
  Color get surfaceColor => AppColors.surface(this);
  Color get surfaceVariantColor => AppColors.surfaceVariant(this);
  Color get textPrimaryColor => AppColors.textPrimary(this);
  Color get textSecondaryColor => AppColors.textSecondary(this);
  Color get textTertiaryColor => AppColors.textTertiary(this);
  Color get borderColor => AppColors.border(this);
}
