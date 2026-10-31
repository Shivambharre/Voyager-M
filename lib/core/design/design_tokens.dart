import 'package:flutter/material.dart';

abstract final class DesignTokens {
  static const Color parchment = Color(0xFFE8DDC7);
  static const Color sandstone = Color(0xFFB49B78);
  static const Color pompeianRed = Color(0xFF6C3028);
  static const Color romanOlive = Color(0xFF263B35);
  static const Color antiqueGold = Color(0xFFA8894E);
  static const Color charcoalUmber = Color(0xFF292724);
  static const Color marbleGrey = Color(0xFFD6D0C3);
  static const Color frescoBlue = Color(0xFF8796A0);
  static const Color lightSurface = Color(0xFFF2EBE0);
  static const Color darkBackground = Color(0xFF292724);
  static const Color darkSurface = Color(0xFF36332F);
  static const Color darkRaised = Color(0xFF1A1917);
  static const Color darkMuted = Color(0xFFB49B78);
  static const Color darkOutline = Color(0xFF5C5852);
  static const Color darkDivider = Color(0xFF3D3A36);
  static const Color darkError = Color(0xFFFF453A);

  static const String editorialFont = 'Cormorant Garamond';
  static const String bodyFont = 'Inter';

  static const Color ink = charcoalUmber;
  static const Color paper = parchment;
  static const Color white = lightSurface;
  static const Color yellow = antiqueGold;
  static const Color blue = frescoBlue;
  static const Color green = romanOlive;
  static const Color orange = sandstone;
  static const Color red = pompeianRed;

  static const Color darkPaper = darkBackground;
  static const Color darkText = parchment;
  static const Color darkYellow = antiqueGold;
  static const Color darkBlue = frescoBlue;

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 48;
  static const double space8 = 64;

  static const double border = 1;
  static const double borderStrong = 1.5;
  static const double radius = 12;
  static const double radiusPill = 999;
  static const double shadowSmall = 2;
  static const double shadowMedium = 8;
  static const double minTapTarget = 48;
}

extension DesignColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get pageColor => isDarkMode
      ? DesignTokens.darkPaper
      : DesignTokens.paper;

  Color get surfaceColor => isDarkMode
      ? DesignTokens.darkSurface
      : DesignTokens.lightSurface;

  Color get raisedColor => isDarkMode
      ? DesignTokens.darkRaised
      : DesignTokens.marbleGrey;

  Color get inkColor => isDarkMode
      ? DesignTokens.darkText
      : DesignTokens.ink;

  Color get mutedColor => isDarkMode
      ? DesignTokens.darkMuted
      : const Color(0xFF5C5852);

  Color get accentColor => isDarkMode
      ? DesignTokens.darkYellow
      : DesignTokens.yellow;

  Color get blueAccentColor => isDarkMode
      ? DesignTokens.darkBlue
      : DesignTokens.blue;

  Color get outlineColor => isDarkMode
      ? DesignTokens.darkOutline
      : DesignTokens.sandstone;

  Color get dividerColor => isDarkMode
      ? DesignTokens.darkDivider
      : DesignTokens.marbleGrey;

  Color get hardShadowColor => isDarkMode
      ? const Color(0xFF000000)
      : DesignTokens.ink;
}
