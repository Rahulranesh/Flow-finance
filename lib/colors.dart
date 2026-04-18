import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:system_theme/system_theme.dart';

//import 'package:budget/colors.dart';
//getColor(context, "lightDarkAccent")

Color getColor(BuildContext context, String colorName) {
  return Theme.of(context).extension<AppColors>()?.colors[colorName] ??
      Colors.red;
}

AppColors getAppColors(
    {required Brightness brightness,
    required ThemeData themeData,
    required Color accentColor}) {
  Color lightDarkAccentHeavyLight = brightness == Brightness.light
      ? appStateSettings["accentSystemColor"] == true &&
              appStateSettings["materialYou"] &&
              appStateSettings["batterySaver"] == false
          ? lightenPastel(
              themeData.colorScheme.primary,
              amount: 0.96,
            )
          : appStateSettings["materialYou"]
              ? (appStateSettings["batterySaver"]
                  ? lightenPastel(accentColor, amount: 0.8)
                  : lightenPastel(accentColor, amount: 0.92))
              : (appStateSettings["batterySaver"]
                  ? Color(0xFFF3F3F3)
                  : Color(0xFFFFFFFF))
      : appStateSettings["accentSystemColor"] == true &&
              appStateSettings["materialYou"] &&
              appStateSettings["batterySaver"] == false
          ? darkenPastel(
              themeData.colorScheme.primary,
              amount: 0.85,
            )
          : appStateSettings["materialYou"]
              ? darkenPastel(accentColor, amount: 0.8)
              : Color(0xFF242424);
  return brightness == Brightness.light
      ? AppColors(
          colors: {
            "white": Colors.white,
            "black": Colors.black,
            "textLight": appStateSettings["increaseTextContrast"]
                ? Colors.black.withOpacity(0.7)
                : appStateSettings["materialYou"]
                    ? Colors.black.withOpacity(0.4)
                    : Color(0xFF888888),
            "lightDarkAccent": appStateSettings["materialYou"]
                ? lightenPastel(accentColor, amount: 0.6)
                : Color(0xFFF7F7F7),
            "lightDarkAccentHeavyLight": lightDarkAccentHeavyLight,
            "canvasContainer": const Color(0xFFEBEBEB),
            "lightDarkAccentHeavy": Color(0xFFEBEBEB),
            "shadowColor": const Color(0x655A5A5A),
            "shadowColorLight": const Color(0x2D5A5A5A),
            "unPaidUpcoming": Color(0xFF58A4C2),
            "unPaidOverdue": Color(0xFF6577E0),
            "incomeAmount": Color(0xFF59A849),
            "expenseAmount": Color(0xFFCA5A5A),
            "warningOrange": Color(0xFFCA995A),
            "starYellow": Color(0xFFFFD723),
            "dividerColor": appStateSettings["materialYou"]
                ? Color(0x0F000000)
                : Color(0xFFF0F0F0),
            "standardContainerColor": getPlatform() == PlatformOS.isIOS
                ? themeData.colorScheme.background
                : appStateSettings["materialYou"]
                    ? lightenPastel(
                        themeData.colorScheme.secondaryContainer,
                        amount: 0.3,
                      )
                    : lightDarkAccentHeavyLight,
          },
        )
      : AppColors(
          colors: {
            "white": Colors.black,
            "black": Colors.white,
            "textLight": appStateSettings["increaseTextContrast"]
                ? Colors.white.withOpacity(0.65)
                : appStateSettings["materialYou"]
                    ? Colors.white.withOpacity(0.25)
                    : Color(0xFF494949),
            "lightDarkAccent": appStateSettings["materialYou"]
                ? darkenPastel(accentColor, amount: 0.83)
                : Color(0xFF161616),
            "lightDarkAccentHeavyLight": lightDarkAccentHeavyLight,
            "canvasContainer": const Color(0xFF242424),
            "lightDarkAccentHeavy": const Color(0xFF444444),
            "shadowColor": const Color(0x69BDBDBD),
            "shadowColorLight": appStateSettings["materialYou"]
                ? Colors.transparent
                : Color(0x28747474),
            "unPaidUpcoming": Color(0xFF7DB6CC),
            "unPaidOverdue": Color(0xFF8395FF),
            "incomeAmount": Color(0xFF62CA77),
            "expenseAmount": Color(0xFFDA7272),
            "warningOrange": Color(0xFFDA9C72),
            "starYellow": Colors.yellow,
            "dividerColor": appStateSettings["materialYou"]
                ? Color(0x13FFFFFF)
                : Color(0x6F363636),
            "standardContainerColor": getPlatform() == PlatformOS.isIOS
                ? themeData.colorScheme.background
                : appStateSettings["materialYou"]
                    ? darkenPastel(
                        themeData.colorScheme.secondaryContainer,
                        amount: 0.6,
                      )
                    : lightDarkAccentHeavyLight,
          },
        );
}

// Ensure you specify a shade, otherwise type will be of MaterialColor which can't be compared
// when using in other widgets, such as the Color Picker
extension ColorsDefined on ColorScheme {
  Color get selectableColorRed => Colors.red.shade400;
  Color get selectableColorGreen => Colors.green.shade400;
  Color get selectableColorBlue => Colors.blue.shade400;
  Color get selectableColorPurple => Colors.purple.shade400;
  Color get selectableColorOrange => Colors.orange.shade400;
  Color get selectableColorBlueGrey => Colors.blueGrey.shade400;
  Color get selectableColorYellow => Colors.yellow.shade400;
  Color get selectableColorAqua => Colors.teal.shade400;
  Color get selectableColorInidigo => Colors.indigo.shade500;
  Color get selectableColorGrey => Colors.grey.shade400;
  Color get selectableColorBrown => Colors.brown.shade400;
  Color get selectableColorDeepPurple => Colors.deepPurple.shade400;
  Color get selectableColorDeepOrange => Colors.deepOrange.shade400;
  Color get selectableColorCyan => Colors.cyan.shade400;
}

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.colors,
  });

  final Map<String, Color?> colors;

  @override
  AppColors copyWith({Map<String, Color?>? colors}) {
    return AppColors(
      colors: colors ?? this.colors,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    final Map<String, Color?> lerpColors = {};
    colors.forEach((key, value) {
      lerpColors[key] = Color.lerp(colors[key], other.colors[key], t);
    });

    return AppColors(
      colors: lerpColors,
    );
  }
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

Color lightenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(
    Colors.white.withOpacity(amount),
    color,
  );
}

Color darkenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(
    Colors.black.withOpacity(amount),
    color,
  );
}

Color blend(Color colorToBlend, Color baseColor, {double amount = 0.1}) {
  return Color.alphaBlend(
    baseColor.withOpacity(amount),
    colorToBlend,
  );
}

Color dynamicPastel(
  BuildContext context,
  Color color, {
  double amount = 0.1,
  bool inverse = false,
  double? amountLight,
  double? amountDark,
}) {
  if (amountLight == null) {
    amountLight = amount;
  }
  if (amountDark == null) {
    amountDark = amount;
  }
  if (amountLight > 1) {
    amountLight = 1;
  }
  if (amountDark > 1) {
    amountDark = 1;
  }
  if (amount > 1) {
    amount = 1;
  }
  if (inverse) {
    if (Theme.of(context).brightness == Brightness.light) {
      return darkenPastel(color, amount: amountDark);
    } else {
      return lightenPastel(color, amount: amountLight);
    }
  } else {
    if (Theme.of(context).brightness == Brightness.light) {
      return lightenPastel(color, amount: amountLight);
    } else {
      return darkenPastel(color, amount: amountDark);
    }
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String? hexColor, Color? defaultColor, context) {
    try {
      if (hexColor == null) {
        if (defaultColor == null) {
          return Colors.grey.value;
        } else {
          return defaultColor.value;
        }
      }
      hexColor = hexColor.replaceAll("#", "");
      hexColor = hexColor.replaceAll("0x", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor;
      }
      return int.parse(hexColor, radix: 16);
    } catch (e) {
      return Colors.grey.value;
    }
  }

  HexColor(final String? hexColor, {final Color? defaultColor})
      : super(_getColorFromHex(hexColor, defaultColor, context));
}

String? toHexString(Color? color) {
  if (color == null) {
    return null;
  }
  String valueString = color.value.toRadixString(16);
  return "0x" + valueString;
}

List<Color> selectableColors(context) {
  return [
    Theme.of(context).colorScheme.selectableColorGreen,
    Theme.of(context).colorScheme.selectableColorAqua,
    Theme.of(context).colorScheme.selectableColorCyan,
    Theme.of(context).colorScheme.selectableColorBlue,
    Theme.of(context).colorScheme.selectableColorInidigo,
    Theme.of(context).colorScheme.selectableColorDeepPurple,
    Theme.of(context).colorScheme.selectableColorPurple,
    Theme.of(context).colorScheme.selectableColorRed,
    Theme.of(context).colorScheme.selectableColorOrange,
    Theme.of(context).colorScheme.selectableColorYellow,
    Theme.of(context).colorScheme.selectableColorDeepOrange,
    Theme.of(context).colorScheme.selectableColorBrown,
    Theme.of(context).colorScheme.selectableColorGrey,
    Theme.of(context).colorScheme.selectableColorBlueGrey,
  ];
}

List<Color> selectableAccentColors(context) {
  return [
    Theme.of(context).colorScheme.selectableColorGreen,
    Theme.of(context).colorScheme.selectableColorCyan,
    Theme.of(context).colorScheme.selectableColorBlue,
    Theme.of(context).colorScheme.selectableColorInidigo,
    Theme.of(context).colorScheme.selectableColorDeepPurple,
    Theme.of(context).colorScheme.selectableColorPurple,
    Theme.of(context).colorScheme.selectableColorRed,
    Theme.of(context).colorScheme.selectableColorOrange,
    Theme.of(context).colorScheme.selectableColorYellow,
  ];
}

const ColorFilter greyScale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

Future<String?> getAccentColorSystemString() async {
  if (supportsSystemColor() && appStateSettings["accentSystemColor"] == true) {
    SystemTheme.fallbackColor = Colors.blue;
    await SystemTheme.accentColor.load();
    Color accentColor = SystemTheme.accentColor.accent;
    if (accentColor.toString() == "Color(0xff80cbc4)") {
      // A default cyan color returned from an unsupported accent color Samsung device
      return null;
    }
    print("System color loaded");
    return toHexString(accentColor);
  } else {
    return null;
  }
}

Future<bool> systemColorByDefault() async {
  if (getPlatform() == PlatformOS.isAndroid) {
    if (supportsSystemColor()) {
      int? androidVersion = await getAndroidVersion();
      print("Android version: " + androidVersion.toString());
      if (androidVersion != null && androidVersion >= 12) {
        return true;
      }
    }
    return false;
  }
  return supportsSystemColor();
}

bool supportsSystemColor() {
  return defaultTargetPlatform.supportsAccentColor &&
      kIsWeb != true &&
      getPlatform() != PlatformOS.isIOS;
}

bool isGrayScale(Color color, {int threshold = 10}) {
  int red = color.red;
  int green = color.green;
  int blue = color.blue;

  return (red - green).abs() <= threshold &&
      (red - blue).abs() <= threshold &&
      (green - blue).abs() <= threshold;
}

ColorScheme getColorScheme(Brightness brightness) {
  if (isGrayScale(
    getSettingConstants(appStateSettings)["accentColor"],
    threshold: 15,
  )) {
    return getGrayScaleColorScheme(brightness);
  }
  if (brightness == Brightness.light) {
    return ColorScheme.fromSeed(
      seedColor: getSettingConstants(appStateSettings)["accentColor"],
      brightness: Brightness.light,
      background: appStateSettings["materialYou"]
          ? lightenPastel(getSettingConstants(appStateSettings)["accentColor"],
              amount: 0.91)
          : Colors.white,
    );
  } else {
    return ColorScheme.fromSeed(
      seedColor: getSettingConstants(appStateSettings)["accentColor"],
      brightness: Brightness.dark,
      background: appStateSettings["forceFullDarkBackground"] == true
          ? Colors.black
          : appStateSettings["materialYou"]
              ? darkenPastel(
                  getSettingConstants(appStateSettings)["accentColor"],
                  amount: 0.92)
              : Colors.black,
    );
  }
}

ColorScheme getGrayScaleColorScheme(Brightness brightness) {
  if (brightness == Brightness.light) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: Colors.blueGrey[700]!,
      onPrimary: Colors.white,
      primaryContainer: Colors.blueGrey[300]!,
      onPrimaryContainer: Colors.black,
      secondary: Colors.blueGrey[800]!,
      onSecondary: Colors.white,
      secondaryContainer: Colors.blueGrey[100]!,
      onSecondaryContainer: Colors.black,
      tertiary: Colors.blueGrey[500]!,
      onTertiary: Colors.white,
      tertiaryContainer: Colors.teal[100],
      onTertiaryContainer: Colors.blueGrey[900]!,
      error: Colors.red[700]!,
      onError: Colors.white,
      errorContainer: Colors.red[100],
      onErrorContainer: Colors.black,
      surface: Colors.grey[200]!,
      onSurface: Colors.black,
      background:
          appStateSettings["materialYou"] ? Colors.blueGrey[50]! : Colors.white,
      onBackground: Colors.black,
      surfaceVariant: Colors.grey[100]!,
      onSurfaceVariant: Colors.black,
      outline: Colors.grey[500]!,
      outlineVariant: Colors.grey[400],
      shadow: Colors.black,
      scrim: Colors.black.withOpacity(0.5),
      inverseSurface: Colors.grey[800],
      onInverseSurface: Colors.white,
      inversePrimary: Colors.blueGrey[300],
      surfaceTint: Colors.blueGrey[700],
    );
  } else {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.blueGrey[200]!,
      onPrimary: Colors.black,
      primaryContainer: Colors.grey[700]!,
      onPrimaryContainer: Colors.white,
      secondary: Colors.grey[500]!,
      onSecondary: Colors.black,
      secondaryContainer: Colors.grey[800]!,
      onSecondaryContainer: Colors.white,
      tertiary: Colors.blueGrey[300],
      onTertiary: Colors.black,
      tertiaryContainer: Colors.blueGrey[700],
      onTertiaryContainer: Colors.blueGrey[200]!,
      error: Colors.red[300]!,
      onError: Colors.black,
      errorContainer: Colors.red[900],
      onErrorContainer: Colors.white,
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
      background: appStateSettings["forceFullDarkBackground"] == true
          ? Colors.black
          : appStateSettings["materialYou"]
              ? Color(0xFF0F0F0F)
              : Colors.black,
      onBackground: Colors.white,
      surfaceVariant: Colors.grey[800]!,
      onSurfaceVariant: Colors.white,
      outline: Colors.grey[600]!,
      outlineVariant: Colors.grey[500],
      shadow: Colors.black,
      scrim: Colors.black.withOpacity(0.7),
      inverseSurface: Colors.grey[100],
      onInverseSurface: Colors.black,
      inversePrimary: Colors.blueGrey[800],
      surfaceTint: Colors.blueGrey[200],
    );
  }
}

SystemUiOverlayStyle getSystemUiOverlayStyle(
    AppColors? colors, Brightness brightness) {
  if (brightness == Brightness.light) {
    return SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: kIsWeb ? Colors.black : Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: getBottomNavbarBackgroundColor(
        colorScheme: getColorScheme(brightness),
        brightness: Brightness.light,
        lightDarkAccent: colors?.colors["lightDarkAccent"] ?? Colors.white,
      ),
    );
  } else {
    return SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: kIsWeb ? Colors.black : Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: getBottomNavbarBackgroundColor(
        colorScheme: getColorScheme(brightness),
        brightness: Brightness.dark,
        lightDarkAccent: colors?.colors["lightDarkAccent"] ?? Colors.black,
      ),
    );
  }
}

Color getBottomNavbarBackgroundColor({
  required ColorScheme colorScheme,
  required Brightness brightness,
  required Color lightDarkAccent,
}) {
  if (getPlatform() == PlatformOS.isIOS) {
    return brightness == Brightness.light
        ? lightenPastel(colorScheme.secondaryContainer,
            amount: appStateSettings["materialYou"] ? 0.4 : 0.55)
        : darkenPastel(colorScheme.secondaryContainer,
            amount: appStateSettings["materialYou"] ? 0.4 : 0.55);
  } else if (appStateSettings["materialYou"] == true) {
    if (brightness == Brightness.light) {
      return lightenPastel(
        colorScheme.secondaryContainer,
        amount: 0.4,
      );
    } else {
      return darkenPastel(
        colorScheme.secondaryContainer,
        amount: 0.45,
      );
    }
  } else {
    return lightDarkAccent;
  }
}

Color getCupertinoScaffoldBackgroundColor(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  return Theme.of(context).brightness == Brightness.light
      ? Color.alphaBlend(
          Colors.white.withOpacity(0.82),
          colorScheme.background,
        )
      : Color.alphaBlend(
          const Color(0xFF08111E).withOpacity(0.92),
          colorScheme.background,
        );
}

Color getCupertinoSurfaceColor(
  BuildContext context, {
  double level = 0,
}) {
  final Color base = getCupertinoScaffoldBackgroundColor(context);
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  final double overlayOpacity = isLight
      ? (0.68 + (level * 0.08)).clamp(0.0, 0.95)
      : (0.84 - (level * 0.045)).clamp(0.48, 0.86);
  return Color.alphaBlend(
    (isLight ? const Color(0xFFFDFEFF) : const Color(0xFF172335))
        .withOpacity(overlayOpacity),
    base,
  );
}

LinearGradient getCupertinoSurfaceGradient(
  BuildContext context, {
  double level = 1,
  Color? tint,
}) {
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  final Color baseSurface = getCupertinoSurfaceColor(context, level: level);
  final Color tintColor = tint ?? Theme.of(context).colorScheme.primary;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isLight
        ? [
            Color.alphaBlend(
              Colors.white.withOpacity(0.74),
              baseSurface,
            ),
            Color.alphaBlend(
              tintColor.withOpacity(0.06),
              baseSurface,
            ),
          ]
        : [
            Color.alphaBlend(
              Colors.white.withOpacity(0.04),
              baseSurface,
            ),
            Color.alphaBlend(
              tintColor.withOpacity(0.08),
              baseSurface,
            ),
          ],
  );
}

Color getCupertinoTintedSurfaceColor(
  BuildContext context,
  Color tint, {
  double amount = 0.12,
}) {
  return Color.alphaBlend(
    tint.withOpacity(amount),
    getCupertinoSurfaceColor(context, level: 1),
  );
}

Color getCupertinoBorderColor(
  BuildContext context, {
  double opacity = 1,
}) {
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  final Color borderColor =
      isLight ? const Color(0x1F233246) : const Color(0x29F4F7FB);
  return borderColor.withOpacity(borderColor.opacity * opacity);
}

Color getCupertinoPrimaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF101828)
      : const Color(0xFFF4F7FB);
}

Color getCupertinoSecondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF667085)
      : const Color(0xFF9CA8B8);
}

LinearGradient getCupertinoBackgroundGradient(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isLight
        ? [
            Color.alphaBlend(
              colorScheme.primary.withOpacity(0.12),
              const Color(0xFFF9FBFF),
            ),
            Color.alphaBlend(
              colorScheme.tertiary.withOpacity(0.05),
              const Color(0xFFF2F6FB),
            ),
            const Color(0xFFEAF0F8),
          ]
        : [
            Color.alphaBlend(
              colorScheme.primary.withOpacity(0.17),
              const Color(0xFF09111D),
            ),
            Color.alphaBlend(
              colorScheme.tertiary.withOpacity(0.08),
              const Color(0xFF0C1523),
            ),
            const Color(0xFF0F1828),
          ],
  );
}

List<BoxShadow> getCupertinoShadow(
  BuildContext context, {
  double elevation = 1,
}) {
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  return [
    BoxShadow(
      color: (isLight ? const Color(0xFF23344C) : Colors.black)
          .withOpacity(isLight ? 0.09 + elevation * 0.018 : 0.22),
      blurRadius: 24 + elevation * 10,
      spreadRadius: -8,
      offset: Offset(0, 14 + elevation * 3),
    ),
    BoxShadow(
      color: (isLight ? Colors.white : const Color(0xFF3C4F67))
          .withOpacity(isLight ? 0.48 : 0.04),
      blurRadius: 12,
      spreadRadius: -10,
      offset: const Offset(0, -2),
    ),
  ];
}

BoxDecoration getCupertinoCardDecoration(
  BuildContext context, {
  Color? color,
  Gradient? gradient,
  double radius = 24,
  bool addShadow = true,
  bool addBorder = true,
}) {
  return BoxDecoration(
    color:
        gradient == null ? (color ?? getCupertinoSurfaceColor(context)) : null,
    gradient: gradient ?? getCupertinoSurfaceGradient(context, tint: color),
    borderRadius: BorderRadius.circular(radius),
    border: addBorder
        ? Border.all(
            color: getCupertinoBorderColor(context, opacity: 0.9),
            width: 0.8,
          )
        : null,
    boxShadow: addShadow ? getCupertinoShadow(context) : null,
  );
}

// For Android widget hex color code conversion
String colorToHex(Color color) {
  Color opaqueColor = color.withAlpha(255);
  String hexString = opaqueColor.value.toRadixString(16).padLeft(6, '0');
  return "#" + hexString.substring(2);
}

class CustomColorTheme extends StatelessWidget {
  const CustomColorTheme(
      {required this.child, required this.accentColor, super.key});
  final Widget child;
  final Color? accentColor;
  @override
  Widget build(BuildContext context) {
    if (accentColor == null) return child;

    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor!,
      brightness: determineBrightnessTheme(context),
      background: determineBrightnessTheme(context) == Brightness.dark
          ? (appStateSettings["forceFullDarkBackground"] == true
              ? Colors.black
              : appStateSettings["materialYou"]
                  ? darkenPastel(accentColor!, amount: 0.92)
                  : Colors.black)
          : appStateSettings["materialYou"]
              ? lightenPastel(accentColor!, amount: 0.91)
              : Colors.white,
    );
    return Theme(
      data: generateThemeDataWithExtension(
        accentColor: accentColor!,
        brightness: Theme.of(context).brightness,
        themeData: Theme.of(context).copyWith(
          colorScheme: colorScheme,
        ),
      ),
      child: child,
    );
  }
}

ThemeData generateThemeDataWithExtension(
    {required ThemeData themeData,
    required Brightness brightness,
    required Color accentColor}) {
  AppColors colors = getAppColors(
    accentColor: accentColor,
    brightness: brightness,
    themeData: themeData,
  );

  final bool isLight = brightness == Brightness.light;
  final Color primaryText =
      isLight ? const Color(0xFF0F1728) : const Color(0xFFF5F7FB);
  final Color secondaryText =
      isLight ? const Color(0xFF5B6879) : const Color(0xFF9AA7B8);
  final TextTheme textTheme = themeData.textTheme
      .apply(
        bodyColor: primaryText,
        displayColor: primaryText,
        fontFamily: appStateSettings["font"],
      )
      .copyWith(
        headlineLarge: themeData.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: themeData.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
        ),
        headlineSmall: themeData.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: themeData.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: themeData.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: themeData.textTheme.bodyLarge?.copyWith(
          height: 1.32,
          color: primaryText,
        ),
        bodyMedium: themeData.textTheme.bodyMedium?.copyWith(
          height: 1.3,
          color: secondaryText,
        ),
        labelLarge: themeData.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      );

  return themeData.copyWith(
    extensions: <ThemeExtension<dynamic>>[colors],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: getSystemUiOverlayStyle(colors, brightness),
      backgroundColor: Colors.transparent,
      foregroundColor: primaryText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: primaryText,
      ),
    ),
    cardTheme: CardThemeData(
      color: isLight
          ? Colors.white.withOpacity(0.74)
          : const Color(0xFF132033).withOpacity(0.88),
      shadowColor: themeData.shadowColor.withOpacity(isLight ? 0.12 : 0.36),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isLight ? const Color(0x1E243B53) : const Color(0x24F4F7FB),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight
          ? Colors.white.withOpacity(0.78)
          : const Color(0xFF152235).withOpacity(0.9),
      hintStyle: TextStyle(
        color: secondaryText.withOpacity(0.9),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: isLight ? const Color(0x1F233246) : const Color(0x29F4F7FB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: isLight ? const Color(0x1F233246) : const Color(0x29F4F7FB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: accentColor.withOpacity(0.75),
          width: 1.3,
        ),
      ),
    ),
    chipTheme: themeData.chipTheme.copyWith(
      backgroundColor: isLight
          ? Colors.white.withOpacity(0.78)
          : const Color(0xFF152235).withOpacity(0.9),
      selectedColor: Color.alphaBlend(
        accentColor.withOpacity(isLight ? 0.14 : 0.2),
        isLight ? Colors.white : const Color(0xFF172335),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isLight ? const Color(0x1A243B53) : const Color(0x22F4F7FB),
        ),
      ),
      side: BorderSide(
        color: isLight ? const Color(0x1A243B53) : const Color(0x22F4F7FB),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      height: 72,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        return textTheme.labelMedium?.copyWith(
          color: states.contains(MaterialState.selected)
              ? primaryText
              : secondaryText,
          fontWeight:
              states.contains(MaterialState.selected) ? FontWeight.w700 : null,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isLight
          ? const Color(0xFFF8FBFF).withOpacity(0.96)
          : const Color(0xFF101B2A).withOpacity(0.97),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isLight
          ? const Color(0xFFF8FBFF).withOpacity(0.96)
          : const Color(0xFF101B2A).withOpacity(0.97),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isLight
          ? const Color(0xFF10213A).withOpacity(0.94)
          : const Color(0xFFF5F7FB).withOpacity(0.94),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: isLight ? const Color(0xFFF5F7FB) : const Color(0xFF10213A),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isLight ? const Color(0x12233A53) : const Color(0x12F4F7FB),
      thickness: 1,
    ),
  );
}

ThemeData getLightTheme() {
  Brightness brightness = Brightness.light;
  ThemeData themeData = ThemeData(
    // pageTransitionsTheme: PageTransitionsTheme(builders: {
    //   // the page route animation is set in pushRoute() - functions.dart
    //   TargetPlatform.android: appStateSettings["iOSNavigation"]
    //       ? CupertinoPageTransitionsBuilder()
    //       : ZoomPageTransitionsBuilder(),
    //   TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    // }),
    fontFamily: appStateSettings["font"],
    fontFamilyFallback: ['Inter'],
    colorScheme: getColorScheme(brightness),
    scaffoldBackgroundColor: const Color(0xFFF2F5FA),
    canvasColor: const Color(0xFFF2F5FA),
    cardColor: Colors.white.withOpacity(0.8),
    useMaterial3: true,
    applyElevationOverlayColor: false,
    typography: Typography.material2014(),
    dividerColor: const Color(0x1A243B53),
    shadowColor: const Color(0x1A23344C),
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: getColorScheme(brightness).primary,
      scaffoldBackgroundColor: const Color(0xFFF2F5FA),
      barBackgroundColor: Colors.white.withOpacity(0.82),
      textTheme: CupertinoTextThemeData(
        textStyle: const TextStyle(
          color: Color(0xFF101828),
          fontFamily: 'Avenir',
        ),
        navTitleTextStyle: const TextStyle(
          color: Color(0xFF101828),
          fontFamily: 'Avenir',
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        navLargeTitleTextStyle: const TextStyle(
          color: Color(0xFF101828),
          fontFamily: 'Avenir',
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
      ),
    ),
    splashColor: getPlatform() == PlatformOS.isIOS
        ? Colors.transparent
        : appStateSettings["materialYou"]
            ? darkenPastel(
                    lightenPastel(
                        getSettingConstants(appStateSettings)["accentColor"],
                        amount: 0.8),
                    amount: 0.2)
                .withOpacity(0.5)
            : null,
  );
  return generateThemeDataWithExtension(
    themeData: themeData,
    brightness: brightness,
    accentColor: getSettingConstants(appStateSettings)["accentColor"],
  );
}

ThemeData getDarkTheme() {
  Brightness brightness = Brightness.dark;
  ThemeData themeData = ThemeData(
    // pageTransitionsTheme: PageTransitionsTheme(builders: {
    //   // the page route animation is set in pushRoute() - functions.dart
    //   TargetPlatform.android: appStateSettings["iOSNavigation"]
    //       ? CupertinoPageTransitionsBuilder()
    //       : ZoomPageTransitionsBuilder(),
    //   TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    // }),
    fontFamily: appStateSettings["font"],
    fontFamilyFallback: ['Inter'],
    colorScheme: getColorScheme(brightness),
    scaffoldBackgroundColor: const Color(0xFF0B1422),
    canvasColor: const Color(0xFF0B1422),
    cardColor: const Color(0xFF152133),
    useMaterial3: true,
    typography: Typography.material2014(),
    dividerColor: const Color(0x26F4F7FB),
    shadowColor: Colors.black.withOpacity(0.45),
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: getColorScheme(brightness).primary,
      scaffoldBackgroundColor: const Color(0xFF0B1422),
      barBackgroundColor: const Color(0xFF142033).withOpacity(0.84),
      textTheme: CupertinoTextThemeData(
        textStyle: const TextStyle(
          color: Color(0xFFF4F7FB),
          fontFamily: 'Avenir',
        ),
        navTitleTextStyle: const TextStyle(
          color: Color(0xFFF4F7FB),
          fontFamily: 'Avenir',
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        navLargeTitleTextStyle: const TextStyle(
          color: Color(0xFFF4F7FB),
          fontFamily: 'Avenir',
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
      ),
    ),
    splashColor: getPlatform() == PlatformOS.isIOS
        ? Colors.transparent
        : appStateSettings["materialYou"]
            ? darkenPastel(
                    lightenPastel(
                        getSettingConstants(appStateSettings)["accentColor"],
                        amount: 0.86),
                    amount: 0.1)
                .withOpacity(0.2)
            : null,
  );
  return generateThemeDataWithExtension(
    themeData: themeData,
    brightness: brightness,
    accentColor: getSettingConstants(appStateSettings)["accentColor"],
  );
}
