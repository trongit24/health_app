import 'package:flutter/material.dart';

/// Design System for SoulFlow: Zen-Minimalism, soft and calming.
class SoulFlowTheme {
  static const Color primarySage = Color(0xFF4B6B5E);
  static const Color backgroundCream = Color(0xFFFFFBF1);
  static const Color textCharcoal = Color(0xFF2C2C2C);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color accentCoral = Color(0xFFE9967A);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color accentGlow = Color(0xFFE2ECE9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primarySage,
      scaffoldBackgroundColor: backgroundCream,
      colorScheme: const ColorScheme.light(
        primary: primarySage,
        secondary: accentCoral,
        surface: backgroundCream,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCharcoal,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shadowColor: primarySage.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textCharcoal,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textCharcoal,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textCharcoal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 14,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
      ),
    );
  }

  static const Color primarySageDark = Color(0xFF8AA69B);
  static const Color backgroundDark = Color(0xFF121816);
  static const Color surfaceCardDark = Color(0xFF1E2623);
  static const Color textLight = Color(0xFFE2ECE9);
  static const Color textMutedDark = Color(0xFF9EAEA8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primarySageDark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primarySageDark,
        secondary: accentCoral,
        surface: backgroundDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textLight,
      ),
      cardTheme: CardThemeData(
        color: surfaceCardDark,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 14,
          color: textMutedDark,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'sans-serif'],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
    );
  }
}
