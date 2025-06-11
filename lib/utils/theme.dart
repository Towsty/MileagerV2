import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryLight = Color(0xFF7C6A46); // Earthy brown
  static const Color _accentLight = Color(0xFF94A684); // Sage green
  static const Color _backgroundLight = Color(0xFFF5F5F5);

  static const Color _primaryDark = Color(0xFF94A684); // Sage green
  static const Color _accentDark = Color(0xFF7C6A46); // Earthy brown
  static const Color _backgroundDark = Color(0xFF121212);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _accentLight,
        background: _backgroundLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentLight,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _accentDark,
        background: _backgroundDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
