import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema Aplikasi ME — Terinspirasi dari editorial minimalis fashion ZARA & cek-beranda.html
class TemaAplikasi {
  // Palet Warna dari cek-beranda.html & DESIGN.md
  static const Color primary = Color(0xFF000000);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceLight = Color(0xFFF7F7F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color borderGray = Color(0xFFE5E5E5);
  static const Color secondary = Color(0xFF5E5E5E);
  static const Color mutedGray = Color(0xFF767676);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFBA1A1A);

  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceBright,
      primaryColor: primary,
      textTheme: GoogleFonts.playfairDisplayTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        surface: surfaceBright,
        onSurface: primary,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: secondary, fontSize: 13),
        hintStyle: const TextStyle(color: mutedGray, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 0.8,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
      ),
    );
  }
}
