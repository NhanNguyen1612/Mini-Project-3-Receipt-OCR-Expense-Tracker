import 'package:flutter/material.dart';

class AppPalette {
  static const forest = Color(0xFF0D5C4D);
  static const deepForest = Color(0xFF073F36);
  static const mint = Color(0xFFB8E8D3);
  static const lime = Color(0xFFE6F4B8);
  static const ink = Color(0xFF17302B);
  static const canvas = Color(0xFFF5F7F3);
  static const amber = Color(0xFFE6A75D);
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.forest,
    brightness: brightness,
  ).copyWith(
    primary: dark ? AppPalette.mint : AppPalette.forest,
    onPrimary: dark ? AppPalette.deepForest : Colors.white,
    surface: dark ? const Color(0xFF152320) : Colors.white,
    onSurface: dark ? const Color(0xFFEAF2ED) : AppPalette.ink,
    surfaceContainerLowest: dark ? const Color(0xFF101B19) : AppPalette.canvas,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: dark
          ? AppPalette.forest.withValues(alpha: 0.55)
          : AppPalette.mint.withValues(alpha: 0.7),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
