import 'package:fashion_store/screens/halaman_bukti_transaksi.dart';
import 'package:fashion_store/services/state_pengguna.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman bukti transaksi menampilkan judul utama dan daftar dokumen', (tester) async {
    StatePengguna.setLoggedIn(
      pelangganId: 1,
      token: 'token-test',
      nama: 'Tester',
      email: 'tester@example.com',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HalamanBuktiTransaksi(),
      ),
    );

    expect(find.text('BUKTI TRANSAKSI'), findsOneWidget);
    expect(find.text('DOKUMEN TERKAIT'), findsOneWidget);
    expect(find.text('UNDUH SEMUA DOKUMEN'), findsOneWidget);
  });
}
