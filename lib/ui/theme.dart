/// Token One UI — satu-satunya tempat hex/ukuran/durasi mentah di lib/ui (docs/design-system.md §10).
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

abstract final class OneUiPalette {
  static const black = Color(0xFF000000);
  static const gray950 = Color(0xFF121212);
  static const gray900 = Color(0xFF1C1C1E);
  static const gray850 = Color(0xFF2C2C2E);
  static const gray800 = Color(0xFF2A2B2E);
  static const gray500 = Color(0xFF6B6F76);
  static const gray400 = Color(0xFFA6A9AF);
  static const gray200 = Color(0xFFE2E4E8);
  static const gray100 = Color(0xFFEEF0F3);
  static const gray50 = Color(0xFFF8F9FA);
  static const ink900 = Color(0xFF111214);
  static const ink50 = Color(0xFFF2F3F5);
  static const blue600 = Color(0xFF0C66E4);
  static const blue500 = Color(0xFF2C74DE);
  static const blue400 = Color(0xFF3E91FF);
  static const blue100 = Color(0xFFDCE9FC);
  static const blue900 = Color(0xFF0F2C55);
}

abstract final class OneUiSpace {
  static const half = 4.0, s1 = 8.0, s1_5 = 12.0, s2 = 16.0, s3 = 24.0,
      s4 = 32.0, s5 = 40.0, s6 = 48.0, s7 = 56.0, s8 = 64.0;
}

abstract final class OneUiRadius {
  static const card = 26.0, edgeCard = 18.0, field = 18.0;
  static const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(card)));
  static const squircle = ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)));
}

abstract final class OneUiMotion {
  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 200);
  static const copied = Duration(milliseconds: 240);
  static const copiedHold = Duration(milliseconds: 1200);
  static const revert = Duration(milliseconds: 300);
  static const chip = Duration(milliseconds: 150);
  static const sheetIn = Duration(milliseconds: 300);
  static const sheetOut = Duration(milliseconds: 200);
  static const reveal = Duration(milliseconds: 180);
  static const standard = Cubic(0.22, 0.25, 0.0, 1.0);
  static const decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
  static const accelerate = Cubic(0.4, 0.0, 1.0, 1.0);
  static const spring = SpringDescription(mass: 1, stiffness: 600, damping: 30);
}

abstract final class OneUiIconSize {
  static const sm = 16.0, md = 20.0, lg = 24.0;
}

/// Warna non-M3: sukses + kategori. Tidak pernah dinamis.
@immutable
class OneUiColors extends ThemeExtension<OneUiColors> {
  const OneUiColors({
    required this.success,
    required this.surfacePressed,
    required this.outlineStrong,
    required this.category,
    required this.categoryContainer,
  });
  final Color success, surfacePressed, outlineStrong;
  final List<Color> category; // index = key DB kategori 0..3
  final List<Color> categoryContainer;

  static const light = OneUiColors(
    success: Color(0xFF1A7F37),
    surfacePressed: OneUiPalette.gray100,
    outlineStrong: Color(0xFF8A8F98),
    category: [Color(0xFF0F7B8A), Color(0xFF7A3FE0), Color(0xFFB54708), Color(0xFF1A7F37)],
    categoryContainer: [Color(0xFFE0F2F4), Color(0xFFEEE6FC), Color(0xFFFCEBDD), Color(0xFFE3F2E7)],
  );
  static const dark = OneUiColors(
    success: Color(0xFF4CC38A),
    surfacePressed: OneUiPalette.gray850,
    outlineStrong: OneUiPalette.gray500,
    category: [Color(0xFF4FD1E0), Color(0xFFB794FF), Color(0xFFF5A524), Color(0xFF4CC38A)],
    categoryContainer: [Color(0xFF0E2A2E), Color(0xFF251A3D), Color(0xFF33240A), Color(0xFF10291A)],
  );

  @override
  OneUiColors copyWith() => this;
  @override
  OneUiColors lerp(OneUiColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

ColorScheme _scheme(Brightness b, ColorScheme? dynamic, bool useDynamic) {
  final light = b == Brightness.light;
  var s = ColorScheme(
    brightness: b,
    primary: light ? OneUiPalette.blue600 : OneUiPalette.blue400,
    onPrimary: light ? Colors.white : OneUiPalette.black,
    primaryContainer: light ? OneUiPalette.blue100 : OneUiPalette.blue900,
    onPrimaryContainer: light ? const Color(0xFF0A3D8F) : const Color(0xFFCFE0FF),
    secondary: light ? OneUiPalette.blue600 : OneUiPalette.blue400,
    onSecondary: light ? Colors.white : OneUiPalette.black,
    error: light ? const Color(0xFFD32F2F) : const Color(0xFFFF6B6B),
    onError: light ? Colors.white : OneUiPalette.black,
    surface: light ? Colors.white : OneUiPalette.gray950,
    onSurface: light ? OneUiPalette.ink900 : OneUiPalette.ink50,
    onSurfaceVariant: light ? OneUiPalette.gray500 : OneUiPalette.gray400,
    surfaceContainerHigh: light ? Colors.white : OneUiPalette.gray900,
    outline: light ? const Color(0xFF8A8F98) : OneUiPalette.gray500,
    outlineVariant: light ? OneUiPalette.gray200 : OneUiPalette.gray800,
    scrim: OneUiPalette.black,
  );
  if (useDynamic && dynamic != null) {
    // Hanya keluarga primary yang ikut wallpaper (design-system §2.4).
    s = s.copyWith(
      primary: dynamic.primary,
      primaryContainer: dynamic.primaryContainer,
      onPrimaryContainer: dynamic.onPrimaryContainer,
    );
  }
  return s;
}

ThemeData buildOneUiTheme(Brightness b, {ColorScheme? dynamic, bool useDynamic = true}) {
  final light = b == Brightness.light;
  final scheme = _scheme(b, dynamic, useDynamic);
  final text = TextTheme(
    displaySmall: const TextStyle(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w700, letterSpacing: -0.4), // headerLarge
    titleLarge: const TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleMedium: const TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
    labelLarge: const TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600),
    labelMedium: const TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelSmall: const TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  // fontFamily sengaja tidak di-set: ikut font sistem One UI (§3.1).

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: light ? OneUiPalette.gray50 : OneUiPalette.black,
    extensions: [light ? OneUiColors.light : OneUiColors.dark],
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: OneUiRadius.cardShape,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: light ? OneUiPalette.gray50 : OneUiPalette.black,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: light ? OneUiPalette.gray100 : OneUiPalette.gray900,
      selectedColor: light ? OneUiPalette.blue600 : OneUiPalette.blue500,
      labelStyle: text.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: OneUiSpace.s1_5),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: light ? OneUiPalette.blue600 : OneUiPalette.blue500,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      elevation: light ? 4 : 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: OneUiRadius.cardShape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(OneUiRadius.card))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? OneUiPalette.gray100 : OneUiPalette.gray900,
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(OneUiRadius.field)),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(OneUiRadius.field)),
          borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(),
    ),
  );
}
