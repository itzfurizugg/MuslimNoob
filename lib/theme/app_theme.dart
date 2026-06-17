import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F0E8);
  static const Color lightPrimary = Color(0xFF1A6B6B);
  static const Color lightSecondary = Color(0xFF0D4A4A);
  static const Color lightSurface = Colors.white;

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF243642);
  static const Color darkCard = Color(0xFF2E4F4F);
  static const Color darkPrimary = Color(0xFF1A6B6B);
  static const Color darkTextPrimary = Color(0xFFE2F1E7);

  static ThemeData get lightTheme {
    final base = GoogleFonts.dmSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onSurface: lightSecondary,
      ),
      textTheme: _buildTextTheme(base),
    );
  }

  static ThemeData get darkTheme {
    final base = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkTextPrimary,
        secondary: darkCard,
        surface: darkCard,
        onSurface: darkTextPrimary,
      ),
      textTheme: _buildTextTheme(base, isDark: true),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, {bool isDark = false}) {
    final textColor = isDark ? darkTextPrimary : lightSecondary;
    return base.copyWith(
      displayLarge: GoogleFonts.poppins(textStyle: base.displayLarge?.copyWith(color: textColor)),
      displayMedium: GoogleFonts.poppins(textStyle: base.displayMedium?.copyWith(color: textColor)),
      displaySmall: GoogleFonts.poppins(textStyle: base.displaySmall?.copyWith(color: textColor)),
      headlineLarge: GoogleFonts.poppins(textStyle: base.headlineLarge?.copyWith(color: textColor)),
      headlineMedium: GoogleFonts.poppins(textStyle: base.headlineMedium?.copyWith(color: textColor)),
      headlineSmall: GoogleFonts.poppins(textStyle: base.headlineSmall?.copyWith(color: textColor)),
      titleLarge: GoogleFonts.poppins(textStyle: base.titleLarge?.copyWith(color: textColor)),
      titleMedium: GoogleFonts.poppins(textStyle: base.titleMedium?.copyWith(color: textColor)),
      bodyLarge: base.bodyLarge?.copyWith(color: textColor),
      bodyMedium: base.bodyMedium?.copyWith(color: textColor),
      bodySmall: base.bodySmall?.copyWith(color: textColor),
    );
  }
}
