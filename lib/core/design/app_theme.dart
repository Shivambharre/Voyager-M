import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? DesignTokens.darkText : DesignTokens.ink;
    final mutedColor = isDark
        ? DesignTokens.darkMuted
        : const Color(0xFF5C5852);
    final background = isDark ? DesignTokens.darkPaper : DesignTokens.paper;
    final surface = isDark ? DesignTokens.darkSurface : DesignTokens.white;
    final accent = isDark ? DesignTokens.darkYellow : DesignTokens.yellow;
    final primary = isDark ? DesignTokens.darkYellow : DesignTokens.pompeianRed;
    final secondary = isDark ? DesignTokens.parchment : DesignTokens.romanOlive;

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: DesignTokens.bodyFont,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: isDark ? DesignTokens.ink : DesignTokens.white,
        secondary: secondary,
        onSecondary: isDark ? DesignTokens.ink : DesignTokens.white,
        tertiary: accent,
        onTertiary: DesignTokens.ink,
        error: isDark ? DesignTokens.darkError : DesignTokens.red,
        onError: DesignTokens.white,
        surface: surface,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: isDark ? DesignTokens.darkDivider : DesignTokens.marbleGrey,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 58,
          height: 1.1,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        displayMedium: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 46,
          height: 1.1,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        displaySmall: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 38,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        headlineLarge: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 34,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        headlineMedium: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        headlineSmall: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        titleLarge: TextStyle(
          fontFamily: DesignTokens.editorialFont,
          fontSize: 23,
          height: 1.3,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.55),
        bodyMedium: TextStyle(fontSize: 14, height: 1.55),
        bodySmall: TextStyle(fontSize: 12, height: 1.45),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
      ).apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontFamily: DesignTokens.editorialFont,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation.weight(600)],
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: mutedColor),
        hintStyle: TextStyle(color: mutedColor),
        filled: true,
        fillColor: isDark ? DesignTokens.darkRaised : DesignTokens.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.darkOutline : DesignTokens.sandstone,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.darkOutline : DesignTokens.sandstone,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius),
          side: BorderSide(
            color: isDark ? DesignTokens.darkOutline : DesignTokens.sandstone,
          ),
        ),
      ),
    );
  }
}
