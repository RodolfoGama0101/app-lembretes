import 'package:flutter/material.dart';

abstract final class AppColors {
  // Cores de base e azul de ação inspirados no sistema One UI.
  static const blue = Color(0xFF0072DE);
  static const blueBright = Color(0xFF3E91FF);
  static const ink = Color(0xFF1B1B1F);
  static const muted = Color(0xFF65666D);
  static const line = Color(0xFFE7E7EC);
  static const surface = Color(0xFFF6F6FA);
  static const white = Color(0xFFFFFFFF);
  static const paleBlue = Color(0xFFE8F2FF);
  static const danger = Color(0xFFBA3B42);
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101116) : AppColors.surface;
    final surface = dark ? const Color(0xFF202127) : AppColors.white;
    final text = dark ? const Color(0xFFF6F6F8) : AppColors.ink;
    final muted = dark ? const Color(0xFFB6B6C0) : AppColors.muted;
    final accent = dark ? AppColors.blueBright : AppColors.blue;
    final border = dark ? const Color(0xFF35363D) : AppColors.line;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: brightness,
      primary: accent,
      surface: surface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: 38,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.3,
            color: text),
        headlineLarge: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            color: text),
        headlineMedium: TextStyle(
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
            color: text),
        titleLarge: TextStyle(
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: text),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: muted),
        labelLarge:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: accent, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: accent,
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            dark ? const Color(0xFF34343B) : const Color(0xFF303136),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
