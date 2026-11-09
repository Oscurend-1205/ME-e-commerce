import 'package:fashion_store/screens/halaman_buku_alamat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman buku alamat menampilkan judul dan tombol tambah', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HalamanBukuAlamat(),
      ),
    );

    expect(find.text('BUKU ALAMAT'), findsOneWidget);
    expect(find.text('TAMBAH ALAMAT BARU'), findsOneWidget);
  });
}
