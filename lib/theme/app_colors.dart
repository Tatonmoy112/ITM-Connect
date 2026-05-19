import 'package:flutter/material.dart';

/// Centralized color constants for the ITM Connect brand.
/// Blue (#185a9d) + Green (#43cea2) represent the ITM department identity.
class ITMColors {
  ITMColors._();

  // ─── Brand Gradient ───
  static const Color gradientStart = Color(0xFF185a9d); // ITM Blue
  static const Color gradientEnd = Color(0xFF43cea2);   // ITM Green

  static const LinearGradient brandGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─── Light Theme Colors ───
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE8EDF2);
  static const Color lightTextPrimary = Color(0xFF1A2138);
  static const Color lightTextSecondary = Color(0xFF5A6577);
  static const Color lightTextTertiary = Color(0xFF8E99A8);
  static const Color lightDivider = Color(0xFFE8EDF2);
  static const Color lightNavBar = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFFFFFFFF);
  static const Color lightInputFill = Color(0xFFF5F7FA);
  static const Color lightInputBorder = Color(0xFFDDE2E8);
  static const Color lightShimmer = Color(0xFFE8EDF2);

  // ─── Dark Theme Colors ───
  static const Color darkBackground = Color(0xFF0A1628);
  static const Color darkSurface = Color(0xFF111D2E);
  static const Color darkCard = Color(0xFF152238);
  static const Color darkCardBorder = Color(0xFF1E3050);
  static const Color darkTextPrimary = Color(0xFFE8EDF2);
  static const Color darkTextSecondary = Color(0xFFA0ADBF);
  static const Color darkTextTertiary = Color(0xFF6B7A8D);
  static const Color darkDivider = Color(0xFF1E3050);
  static const Color darkNavBar = Color(0xFF0E1A2B);
  static const Color darkAppBar = Color(0xFF0E1A2B);
  static const Color darkInputFill = Color(0xFF152238);
  static const Color darkInputBorder = Color(0xFF1E3050);
  static const Color darkShimmer = Color(0xFF1E3050);

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Accent / Utility ───
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentCyan = Color(0xFF06B6D4);

  // ─── Nav Item Colors ───
  static const Color navUnselectedLight = Color(0xFF9CA3AF);
  static const Color navUnselectedDark = Color(0xFF6B7A8D);
}
