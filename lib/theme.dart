import 'package:flutter/material.dart';

class TemaAplikasi {
  // === Palet Warna ===
  static const Color _hitam = Color(0xFF111111);
  static const Color _putih = Color(0xFFFFFFFF);
  static const Color _abuMuda = Color(0xFFF3F3F3);
  static const Color _abuSedang = Color(0xFF777777);
  static const Color _abuGaris = Color(0xFFDDDDDD);

  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _putih,
      primaryColor: _hitam,
      colorScheme: const ColorScheme.light(
        primary: _hitam,
        onPrimary: _putih,
        secondary: _hitam,
        onSecondary: _putih,
        surface: _abuMuda,
        onSurface: _hitam,
        error: Color(0xFFB00020),
        onError: _putih,
        outline: _abuGaris,
      ),
      dividerColor: _abuGaris,
      dividerTheme: const DividerThemeData(
        color: _abuGaris,
        thickness: 1,
        space: 0,
      ),

      // === AppBar ===
      appBarTheme: const AppBarTheme(
        backgroundColor: _putih,
        foregroundColor: _hitam,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _hitam,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: _hitam),
      ),

      // === ElevatedButton ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _hitam,
          foregroundColor: _putih,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      // === OutlinedButton ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _hitam,
          side: const BorderSide(color: _hitam, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // === TextButton ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _hitam,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // === Card ===
      cardTheme: CardThemeData(
        color: _abuMuda,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.zero,
      ),

      // === Input Decoration ===
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _abuGaris),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _abuGaris),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _hitam, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
        hintStyle: const TextStyle(color: _abuSedang, fontSize: 14),
        labelStyle: const TextStyle(color: _abuSedang, fontSize: 14),
      ),

      // === Chip ===
      chipTheme: ChipThemeData(
        backgroundColor: _putih,
        selectedColor: _hitam,
        disabledColor: _abuMuda,
        labelStyle: const TextStyle(color: _hitam, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: _putih, fontSize: 13),
        side: const BorderSide(color: _abuGaris),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),

      // === Bottom Navigation Bar ===
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _putih,
        selectedItemColor: _hitam,
        unselectedItemColor: _abuSedang,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // === SnackBar ===
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        contentTextStyle: const TextStyle(color: _putih, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // === Icon ===
      iconTheme: const IconThemeData(
        color: _hitam,
        size: 24,
      ),

      // === Typography ===
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: _hitam, fontWeight: FontWeight.w300, letterSpacing: -1.5),
        displayMedium: TextStyle(color: _hitam, fontWeight: FontWeight.w300, letterSpacing: -0.5),
        displaySmall: TextStyle(color: _hitam, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(color: _hitam, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        headlineMedium: TextStyle(color: _hitam, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(color: _hitam, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(color: _hitam, fontWeight: FontWeight.w600, letterSpacing: 0.15),
        titleMedium: TextStyle(color: _hitam, fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleSmall: TextStyle(color: _hitam, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyLarge: TextStyle(color: _hitam, fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyMedium: TextStyle(color: _hitam, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: TextStyle(color: _abuSedang, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        labelLarge: TextStyle(color: _hitam, fontWeight: FontWeight.w600, letterSpacing: 1.0),
        labelMedium: TextStyle(color: _hitam, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: TextStyle(color: _abuSedang, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),

      // === ListTile ===
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        dense: false,
      ),

      // === ProgressIndicator ===
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _hitam,
      ),
    );
  }
}
