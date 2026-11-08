import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/main.dart';
import 'package:fashion_store/screens/halaman_metode_pembayaran.dart';

void main() {
  testWidgets('Aplikasi ME smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AplikasiME());
    expect(find.text('BERANDA'), findsAtLeastNWidgets(1));
    expect(find.text('JELAJAH'), findsOneWidget);
    expect(find.text('PESANAN'), findsOneWidget);
    expect(find.text('AKUN'), findsOneWidget);
  });

  testWidgets('Halaman metode pembayaran menampilkan data pembayaran', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HalamanMetodePembayaran()));

    expect(find.text('METODE PEMBAYARAN'), findsOneWidget);
    expect(find.text('PILIH SALURAN PEMBAYARAN'), findsOneWidget);
    expect(find.text('Virtual Account'), findsOneWidget);
  });
}
