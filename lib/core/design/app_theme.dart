import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.ink;
    final mutedColor = isDark ? DesignTokens.darkMuted : const Color(0xFF4A4A4A);
    final background = isDark ? DesignTokens.darkPaper : DesignTokens.paper;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.white;
    final accent = isDark ? DesignTokens.darkYellow : DesignTokens.yellow;

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: DesignTokens.ink,
        secondary: isDark ? DesignTokens.darkBlue : DesignTokens.blue,
        onSecondary: DesignTokens.white,
        error: isDark ? const Color(0xFFEF4444) : DesignTokens.red,
        onError: DesignTokens.white,
        surface: surface,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: isDark ? const Color(0xFF454545) : DesignTokens.ink,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 56, height: 1.1, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(fontSize: 44, height: 1.1, fontWeight: FontWeight.w800),
        displaySmall: TextStyle(fontSize: 36, height: 1.2, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(fontSize: 32, height: 1.2, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 10, height: 1.3, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: accent,
        foregroundColor: DesignTokens.ink,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: DesignTokens.ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: DesignTokens.ink),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: mutedColor),
        hintStyle: TextStyle(color: mutedColor),
      ),
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
