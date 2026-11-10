import 'package:fashion_store/screens/halaman_riwayat_pesanan.dart';
import 'package:fashion_store/services/state_pengguna.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman riwayat pesanan menolak akses saat user belum login', (tester) async {
    StatePengguna.setLoggedOut();

    await tester.pumpWidget(
      const MaterialApp(
        home: HalamanRiwayatPesanan(),
      ),
    );

    expect(
      find.text('Silakan masuk untuk melihat riwayat pesanan dan status pengiriman Anda.'),
      findsOneWidget,
    );
    expect(find.text('MASUK'), findsOneWidget);
  });
}
