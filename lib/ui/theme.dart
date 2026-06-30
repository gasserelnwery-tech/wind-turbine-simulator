import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4FC3F7),
      secondary: Color(0xFF81C784),
      surface: Color(0xFF161B22),
      error: Color(0xFFEF5350),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFF0D1117),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF4FC3F7),
      inactiveTrackColor: const Color(0xFF30363D),
      thumbColor: const Color(0xFF4FC3F7),
      overlayColor: const Color(0x294FC3F7),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      elevation: 0,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F2F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF388E3C),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFD32F2F),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF1976D2),
      inactiveTrackColor: const Color(0xFFE0E0E0),
      thumbColor: const Color(0xFF1976D2),
      overlayColor: const Color(0x291976D2),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
  );
}
