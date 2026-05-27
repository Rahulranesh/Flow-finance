import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/currency_formatter.dart';
import '../widgets/mascot_snackbar.dart';
import '../widgets/cupertino_toast.dart';

/// Extension on BuildContext for easy access to theme and media query
extension BuildContextExtension on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);

  /// Get the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get the screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get the device pixel ratio
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Get the safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get the view insets (keyboard height)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if the current theme is dark
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Check if the current theme is light
  bool get isLight => Theme.of(this).brightness == Brightness.light;

  /// Get the navigator
  NavigatorState get navigator => Navigator.of(this);

  /// Get the scaffold messenger (safe — returns null if no Material ancestor)
  ScaffoldMessengerState? get scaffoldMessenger {
    try {
      return ScaffoldMessenger.of(this);
    } catch (_) {
      return null;
    }
  }

  /// Show a premium Cupertino-styled toast with Lottie mascot
  void showSnackBar(SnackBar snackBar) {
    CupertinoToast.show(
      this,
      message: (snackBar.content is Text ? (snackBar.content as Text).data : snackBar.content.toString()) ?? '',
      type: CupertinoToastType.info,
    );
  }

  /// Show a premium mascot Lottie toast notification
  void showMascotSnackBar(
    String message, {
    MascotSnackBarType type = MascotSnackBarType.info,
  }) {
    CupertinoToast.show(
      this,
      message: message,
      type: switch (type) {
        MascotSnackBarType.success => CupertinoToastType.success,
        MascotSnackBarType.error => CupertinoToastType.error,
        MascotSnackBarType.warning => CupertinoToastType.warning,
        MascotSnackBarType.info => CupertinoToastType.info,
      },
    );
  }

  /// Hide snackbar (no-op — CupertinoToast dismisses automatically)
  void hideSnackBar() {}

  /// Show a premium Cupertino-styled notification (alias)
  void showMaterialBanner(MaterialBanner banner) {
    CupertinoToast.show(this, message: 'Notification', type: CupertinoToastType.info);
  }

  /// Hide banner (no-op — CupertinoToast dismisses automatically)
  void hideMaterialBanner() {}

  /// Navigate to a new screen
  Future<T?> push<T>(Widget screen) {
    return Navigator.of(this).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate to a new screen and remove all previous screens
  Future<T?> pushAndRemoveAll<T>(Widget screen) {
    return Navigator.of(this).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Pop the current screen
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Check if can pop
  bool get canPop => Navigator.of(this).canPop();
}

/// Extension on String for common string operations
extension StringExtension on String {
  /// Capitalize the first letter of the string
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize the first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Convert to camelCase
  String get camelCase {
    if (isEmpty) return this;
    final words = split(RegExp(r'[_\s-]+'));
    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.capitalize).join();
  }

  /// Convert to snake_case
  String get snakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp(r'^[\s_-]+'), '');
  }

  /// Truncate the string to a maximum length
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Check if the string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if the string is a valid URL
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(this);
  }

  /// Remove all whitespace from the string
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Convert to currency format
  String toCurrency({String symbol = '\$', int decimalDigits = 2}) {
    final value = double.tryParse(this) ?? 0;
    final resolvedSymbol =
        symbol == r'$' ? CurrencyFormatter.currentCurrency.symbol : symbol;
    return NumberFormat.currency(
      symbol: resolvedSymbol,
      decimalDigits: decimalDigits,
    ).format(value);
  }
}

/// Extension on num for number formatting
extension NumExtension on num {
  /// Format as currency
  String toCurrency({String symbol = '\$', int decimalDigits = 2}) {
    if (symbol == r'$') {
      return CurrencyFormatter.format(
        this,
        decimalDigits: decimalDigits,
      );
    }
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(this);
  }

  /// Format as compact (e.g., 1.2K, 3.4M)
  String toCompact() {
    return NumberFormat.compact().format(this);
  }

  /// Format as percentage
  String toPercent({int decimalDigits = 0}) {
    return NumberFormat.percentPattern().format(this / 100);
  }

  /// Format with commas
  String toFormatted() {
    return NumberFormat('#,###').format(this);
  }

  /// Check if the number is between two values
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// Clamp the number to a range
  num clamp(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

/// Extension on DateTime for date formatting
extension DateTimeExtension on DateTime {
  /// Format as relative time (e.g., "2 hours ago")
  String toRelative() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '{} years ago'.tr(args: [(difference.inDays / 365).floor().toString()]);
    } else if (difference.inDays > 30) {
      return '{} months ago'.tr(args: [(difference.inDays / 30).floor().toString()]);
    } else if (difference.inDays > 0) {
      return '{} days ago'.tr(args: [difference.inDays.toString()]);
    } else if (difference.inHours > 0) {
      return '{} hours ago'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inMinutes > 0) {
      return '{} minutes ago'.tr(args: [difference.inMinutes.toString()]);
    } else {
      return 'Just now'.tr();
    }
  }

  /// Format as short date (e.g., "Jan 15")
  String toShortDate() {
    return DateFormat('MMM d').format(this);
  }

  /// Format as long date (e.g., "January 15, 2025")
  String toLongDate() {
    return DateFormat('MMMM d, y').format(this);
  }

  /// Format as time (e.g., "2:30 PM")
  String toTime() {
    return DateFormat('h:mm a').format(this);
  }

  /// Format as date and time
  String toDateTime() {
    return DateFormat('MMM d, y • h:mm a').format(this);
  }

  /// Check if the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if the date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if the date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get the start of the day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get the end of the day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Get the start of the week
  DateTime get startOfWeek {
    final weekday = this.weekday;
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Get the end of the week
  DateTime get endOfWeek {
    final weekday = this.weekday;
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Get the start of the month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Get the end of the month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}

/// Extension on List for common list operations
extension ListExtension<T> on List<T> {
  /// Get the first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get the last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Get element at index or null if out of bounds
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Split the list into chunks of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Remove duplicates based on a key
  List<T> distinctBy<K>(K Function(T) keySelector) {
    final seen = <K>{};
    return where((item) {
      final key = keySelector(item);
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Sort by a key
  List<T> sortedBy<K extends Comparable<K>>(K Function(T) keySelector) {
    return [...this]..sort((a, b) => keySelector(a).compareTo(keySelector(b)));
  }

  /// Sort by a key in descending order
  List<T> sortedByDescending<K extends Comparable<K>>(
    K Function(T) keySelector,
  ) {
    return [...this]..sort((a, b) => keySelector(b).compareTo(keySelector(a)));
  }
}

/// Extension on Widget for common widget operations
extension WidgetExtension on Widget {
  /// Add padding to the widget
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }

  /// Add symmetric padding
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }

  /// Add all-side padding
  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }

  /// Center the widget
  Widget get center => Center(child: this);

  /// Expand the widget
  Widget get expand => Expanded(child: this);

  /// Make the widget flexible
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  /// Add a tap gesture
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: this);
  }

  /// Wrap in a Card
  Widget card({
    Color? color,
    double elevation = 1,
    ShapeBorder? shape,
  }) {
    return Card(
      color: color,
      elevation: elevation,
      shape: shape,
      child: this,
    );
  }

  /// Add opacity
  Widget opacity(double value) {
    return Opacity(opacity: value, child: this);
  }

  /// Add visibility
  Widget visible(bool visible, {Widget? replacement}) {
    return Visibility(
      visible: visible,
      replacement: replacement ?? const SizedBox.shrink(),
      child: this,
    );
  }

  /// Add hero animation
  Widget hero(String tag) {
    return Hero(tag: tag, child: this);
  }
}

/// Extension on Color for color operations
extension ColorExtension on Color {
  /// Darken the color by a percentage
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return hslDark.toColor();
  }

  /// Lighten the color by a percentage
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Blend with another color
  Color blend(Color other, double amount) {
    return Color.lerp(this, other, amount)!;
  }

  /// Get the hex string representation
  String get hexString {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Get color with opacity (compatible with Flutter 3.27+)
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    return Color.from(
      alpha: alpha ?? a,
      red: red ?? r,
      green: green ?? g,
      blue: blue ?? b,
    );
  }

  /// Get color with opacity value (0.0 to 1.0)
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
}
