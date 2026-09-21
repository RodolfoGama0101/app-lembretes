import 'package:flutter/material.dart';

abstract final class AppColors {
  static const blue = Color(0xFF002FA7);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF66676B);
  static const line = Color(0xFFD8D9DD);
  static const surface = Color(0xFFF7F7F8);
  static const white = Color(0xFFFFFFFF);
}

abstract final class AppTheme {
  static ThemeData get light {
    const baseTextTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        height: .9,
        fontWeight: FontWeight.w700,
        letterSpacing: -3,
        color: AppColors.ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -.25,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: .2,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      surface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: baseTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
