import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Core Colors ---
  static const Color _primaryBlue = Color(0xFF007AFF);
  static const Color _accentOrange = Color(0xFFFF9500);

  // --- Light Theme Colors ---
  static const Color _lightBackground = Color(0xFFF6F7F9);
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextMain = Color(0xFF1D1D1F);
  static const Color _lightTextSecondary = Color(0xFF6E6E73);
  static const Color _lightBorder = Color(0xFFE5E5E5);

  // --- Dark Theme Colors ---
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkSurface = Color(0xFF1C1C1E);
  static const Color _darkTextMain = Color(0xFFF5F5F7);
  static const Color _darkTextSecondary = Color(0xFF8A8A8E);
  static const Color _darkBorder = Color(0xFF38383A);

  // --- Base Text Theme using Poppins ---
  static final TextTheme _baseTextTheme = GoogleFonts.poppinsTextTheme();

  // --- Helper for consistent InputBorders ---
  static OutlineInputBorder _buildInputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  // --- Light Theme Definition ---
  static ThemeData get lightTheme {
    final textTheme = _baseTextTheme.apply(
      bodyColor: _lightTextMain,
      displayColor: _lightTextMain,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryBlue,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _primaryBlue,
        onPrimary: Colors.white,
        secondary: _accentOrange,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        background: _lightBackground,
        onBackground: _lightTextMain,
        surface: _lightSurface,
        onSurface: _lightTextMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: _lightTextSecondary),
        border: _buildInputBorder(_lightBorder),
        enabledBorder: _buildInputBorder(_lightBorder),
        focusedBorder: _buildInputBorder(_primaryBlue).copyWith(borderSide: const BorderSide(color: _primaryBlue, width: 2)),
        errorBorder: _buildInputBorder(Colors.redAccent),
        focusedErrorBorder: _buildInputBorder(Colors.redAccent).copyWith(borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        color: _lightSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _lightTextMain),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: _lightTextMain),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _lightTextSecondary,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.bodySmall,
        elevation: 0,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Dark Theme Definition ---
  static ThemeData get darkTheme {
    final textTheme = _baseTextTheme.apply(
      bodyColor: _darkTextMain,
      displayColor: _darkTextMain,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryBlue,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _primaryBlue,
        onPrimary: Colors.white,
        secondary: _accentOrange,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        background: _darkBackground,
        onBackground: _darkTextMain,
        surface: _darkSurface,
        onSurface: _darkTextMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: _darkTextSecondary),
        border: _buildInputBorder(_darkBorder),
        enabledBorder: _buildInputBorder(_darkBorder),
        focusedBorder: _buildInputBorder(_primaryBlue).copyWith(borderSide: const BorderSide(color: _primaryBlue, width: 2)),
        errorBorder: _buildInputBorder(Colors.redAccent),
        focusedErrorBorder: _buildInputBorder(Colors.redAccent).copyWith(borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        color: _darkSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _darkTextMain),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: _darkTextMain),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _darkTextSecondary,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.bodySmall,
        elevation: 0,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
