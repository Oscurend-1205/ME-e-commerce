import 'package:fashion_store/screens/halaman_konfirmasi_cod.dart';
import 'package:fashion_store/services/state_pengguna.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman konfirmasi COD menampilkan nomor pesanan dan instruksi pembayaran tunai', (tester) async {
    StatePengguna.setLoggedIn(
      pelangganId: 1,
      token: 'token-test',
      nama: 'Auril Aditya',
      email: 'auril@toko-me.test',
    );

    final dummyPesanan = {
      'id': 99,
      'nomor_pesanan': 'ORD-COD-TEST-123',
      'status': 'menunggu_verifikasi',
      'subtotal': 350000,
      'ongkir': 15000,
      'total': 365000,
      'nama_penerima': 'Auril Aditya',
      'alamat': 'Jl. Kaliurang KM 5 No. 42, Sleman',
      'nama_kurir': 'JNE Reguler',
      'metode_pembayaran': 'Tunai di Tempat (COD)',
      'is_cod': true,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: HalamanKonfirmasiCod(
          pesananId: 99,
          dataPesananAwal: dummyPesanan,
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    expect(find.text('KONFIRMASI PESANAN COD'), findsOneWidget);
    expect(find.text('PESANAN COD TELAH DITERIMA'), findsOneWidget);
    expect(find.text('RINCIAN TAGIHAN TUNAI (COD)'), findsOneWidget);
    expect(find.text('PANDUAN PEMBAYARAN SAAT BARANG TIBA'), findsOneWidget);
    expect(find.text('LIHAT RIWAYAT PESANAN'), findsOneWidget);
    expect(find.text('KEMBALI KE BERANDA'), findsOneWidget);
    expect(find.text('No. Pesanan: #ORD-COD-TEST-123'), findsOneWidget);
  });
}

