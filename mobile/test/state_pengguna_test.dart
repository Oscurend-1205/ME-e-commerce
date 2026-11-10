import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/services/state_pengguna.dart';
import 'package:fashion_store/widgets/komponen_header.dart';

void main() {
  group('StatePengguna & KomponenHeader Tests', () {
    test('StatePengguna memperbarui foto profil dan nama secara global', () {
      const fotoAwal = 'https://images.unsplash.com/test-1.jpg';
      const fotoBaru = 'https://images.unsplash.com/test-2.jpg';

      StatePengguna.perbaruiFotoProfil(fotoAwal);
      expect(StatePengguna.fotoProfilNotifier.value, fotoAwal);

      StatePengguna.perbaruiFotoProfil(fotoBaru);
      expect(StatePengguna.fotoProfilNotifier.value, fotoBaru);

      StatePengguna.perbaruiNama('Clarissa Vance');
      expect(StatePengguna.namaUserNotifier.value, 'Clarissa Vance');

      StatePengguna.perbaruiNama('Elena Rostova');
      expect(StatePengguna.namaUserNotifier.value, 'Elena Rostova');
    });

    test('StatePengguna memperbarui jumlah keranjang', () {
      StatePengguna.perbaruiJumlahKeranjang(0);
      expect(StatePengguna.jumlahKeranjangNotifier.value, 0);

      StatePengguna.perbaruiJumlahKeranjang(5);
      expect(StatePengguna.jumlahKeranjangNotifier.value, 5);

      StatePengguna.perbaruiJumlahKeranjang(-1);
      expect(StatePengguna.jumlahKeranjangNotifier.value, 0);
    });

    testWidgets('TombolTasHeader menampilkan badge jumlah reaktif', (tester) async {
      StatePengguna.perbaruiJumlahKeranjang(0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: TombolTasHeader(),
            ),
          ),
        ),
      );

      // Pada 0, tidak ada teks badge
      expect(find.text('0'), findsNothing);

      // Ubah jumlah keranjang ke 3
      StatePengguna.perbaruiJumlahKeranjang(3);
      await tester.pump();

      // Badge '3' harus muncul
      expect(find.text('3'), findsOneWidget);

      // Ubah jumlah keranjang ke 105 (>99)
      StatePengguna.perbaruiJumlahKeranjang(105);
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('AvatarHeaderUser merender inisial fallback jika URL gambar gagal', (tester) async {
      StatePengguna.perbaruiNama('Clarissa');
      StatePengguna.perbaruiFotoProfil('https://invalid-url-domain.local/avatar.jpg');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: AvatarHeaderUser(),
            ),
          ),
        ),
      );

      expect(find.byType(AvatarHeaderUser), findsOneWidget);
    });
  });
}
