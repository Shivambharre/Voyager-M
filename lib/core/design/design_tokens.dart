import 'package:flutter/material.dart';

abstract final class DesignTokens {
  static const Color ink = Color(0xFF1A1A1A);
  static const Color paper = Color(0xFFFDFCF8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellow = Color(0xFFF4FF4D);
  static const Color blue = Color(0xFF4D7BFF);
  static const Color green = Color(0xFF00873E);
  static const Color orange = Color(0xFFFF8C00);
  static const Color red = Color(0xFFD0021B);

  static const Color darkPaper = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkRaised = Color(0xFF252525);
  static const Color darkText = Color(0xFFF7F7F7);
  static const Color darkMuted = Color(0xFFA1A1A1);
  static const Color darkYellow = Color(0xFFFACC15);
  static const Color darkBlue = Color(0xFF3B82F6);

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 48;
  static const double space8 = 64;

  static const double border = 2;
  static const double borderStrong = 3;
  static const double radius = 0;
  static const double radiusPill = 999;
  static const double shadowSmall = 4;
  static const double shadowMedium = 6;
  static const double minTapTarget = 48;
}

extension DesignColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get pageColor => isDarkMode
      ? DesignTokens.darkPaper
      : DesignTokens.paper;

  Color get surfaceColor => isDarkMode
      ? DesignTokens.darkSurface
      : DesignTokens.white;

  Color get raisedColor => isDarkMode
      ? DesignTokens.darkRaised
      : DesignTokens.white;

  Color get inkColor => isDarkMode
      ? DesignTokens.darkText
      : DesignTokens.ink;

  Color get mutedColor => isDarkMode
      ? DesignTokens.darkMuted
      : const Color(0xFF4A4A4A);

  Color get accentColor => isDarkMode
      ? DesignTokens.darkYellow
      : DesignTokens.yellow;

  Color get blueAccentColor => isDarkMode
      ? DesignTokens.darkBlue
      : DesignTokens.blue;

  Color get outlineColor => isDarkMode
      ? const Color(0xFFF7F7F7)
      : DesignTokens.ink;

  Color get dividerColor => isDarkMode
      ? const Color(0xFF454545)
      : DesignTokens.ink;

  Color get hardShadowColor => isDarkMode
      ? const Color(0xFF000000)
      : DesignTokens.ink;
}
