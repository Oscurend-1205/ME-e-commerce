import 'package:flutter/material.dart';

/// Transisi halaman geser horizontal untuk alur checkout.
/// Pengganti MaterialPageRoute agar perpindahan antar langkah terasa
/// seperti satu alur kontinu tanpa animasi platform yang berbeda.
Route<T> ruteGeser<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final masuk = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final keluar = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.25, 0),
      ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic));

      return SlideTransition(
        position: masuk,
        child: SlideTransition(
          position: keluar,
          textDirection: TextDirection.ltr,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
  );
}
