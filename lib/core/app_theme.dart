import 'package:flutter/material.dart';

class AppPalette {
  static const forest = Color(0xFF3558D4);
  static const deepForest = Color(0xFF152B70);
  static const ink = Color(0xFF18243B);
  static const canvas = Color(0xFFF5F6FA);
  static const mint = Color(0xFFBFEFE5);
  static const lime = Color(0xFFFFE0A3);
  static const amber = Color(0xFFF5B74F);
  static const coral = Color(0xFFFF735E);
  static const teal = Color(0xFF1C9E93);
  static const violet = Color(0xFF7965D8);
  static const darkCanvas = Color(0xFF101827);
  static const darkSurface = Color(0xFF1C2940);
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.forest,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF9FB4FF) : AppPalette.forest,
    onPrimary: dark ? AppPalette.ink : Colors.white,
    secondary: AppPalette.coral,
    surface: dark ? AppPalette.darkSurface : Colors.white,
    onSurface: dark ? const Color(0xFFF3F5FF) : AppPalette.ink,
    surfaceContainerLowest: dark ? AppPalette.darkCanvas : AppPalette.canvas,
    onSurfaceVariant: dark ? const Color(0xFFB4C0D5) : const Color(0xFF68748A),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
          ? AppPalette.forest.withValues(alpha: 0.48)
          : AppPalette.forest.withValues(alpha: 0.12),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
