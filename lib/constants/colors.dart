// New Color Scheme Implementation
// Dark Mode (Default) and Light Mode Color Constants

import 'package:flutter/material.dart';

/// New Color Scheme Constants
class AppColors {
  // Dark Mode Colors (Default)
  static const Color darkBackground =
      Color(0xFF0F172A); // Deep slate - Main screen background
  static const Color darkSurface =
      Color(0xFF1E293B); // Elevated slate - Cards, panels
  static const Color darkPrimary =
      Color(0xFF14B8A6); // Bright teal - Buttons, brand elements
  static const Color darkSecondary =
      Color(0xFF94A3B8); // Light slate gray - Secondary text, borders
  static const Color darkTextPrimary =
      Color(0xFFF1F5F9); // Off-white - Main text
  static const Color darkTextSecondary =
      Color(0xFFCBD5E1); // Muted gray - Descriptions, labels
  static const Color darkSuccess =
      Color(0xFF22C55E); // Lighter green - Safe status
  static const Color darkAlert = Color(0xFFEF4444); // Red - Warnings

  // Light Mode Colors
  static const Color lightBackground =
      Color(0xFFF8FAFC); // Light gray - Main screen background
  static const Color lightSurface = Color(0xFFFFFFFF); // White - Cards, panels
  static const Color lightPrimary =
      Color(0xFF0D9488); // Teal - Buttons, brand elements
  static const Color lightSecondary =
      Color(0xFF475569); // Slate gray - Secondary text, borders
  static const Color lightTextPrimary =
      Color(0xFF0F172A); // Deep slate - Main text
  static const Color lightTextSecondary =
      Color(0xFF475569); // Slate gray - Descriptions, labels
  static const Color lightSuccess =
      Color(0xFF10B981); // Lighter green - Safe status
  static const Color lightAlert = Color(0xFFDC2626); // Darker red - Warnings

  // Legacy color mappings for easy migration
  static const Color legacyBlue = Color(0xFF3B82F6); // Old blue
  static const Color legacyGreen = Color(0xFF10B981); // Old green
}

/// Dark Theme Configuration
ThemeData getDarkTheme() {
  return ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary, // Bright teal
      secondary: AppColors.darkSecondary, // Light slate gray
      tertiary: AppColors.darkSuccess, // Success
      error: AppColors.darkAlert, // Red
      surface: AppColors.darkSurface, // Elevated slate
      background: AppColors.darkBackground, // Deep slate
      onPrimary: AppColors.darkTextPrimary, // Off-white
      onSecondary: AppColors.darkTextPrimary, // Off-white
      onTertiary: AppColors.darkTextPrimary, // Off-white
      onError: AppColors.darkTextPrimary, // Off-white
      onSurface: AppColors.darkTextPrimary, // Off-white
      onBackground: AppColors.darkTextPrimary, // Off-white
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: AppColors.darkSurface.withOpacity(0.8),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
        textStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
    ),
  );
}

/// Light Theme Configuration
ThemeData getLightTheme() {
  return ThemeData(
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary, // Teal - Buttons, brand
      secondary: AppColors.lightSecondary, // Slate gray - Secondary/borders
      tertiary: AppColors.lightSuccess, // Success
      error: AppColors.lightAlert, // Darker red - Warnings
      surface: AppColors.lightSurface, // White - Cards, panels
      background: AppColors.lightBackground, // Light gray
      onPrimary: AppColors.lightSurface, // Text on primary (white)
      onSecondary: AppColors.lightSurface, // Text on secondary (white)
      onTertiary: AppColors.lightSurface, // Text on success (white)
      onError: AppColors.lightSurface, // Text on error (white)
      onSurface: AppColors.lightTextPrimary, // Main text
      onBackground: AppColors.lightTextPrimary, // Main text
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
        textStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
    ),
  );
}
