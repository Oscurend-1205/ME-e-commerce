import 'package:flutter/material.dart';

import 'screens/halaman_katalog.dart';
import 'screens/halaman_kelola_produk.dart';
import 'screens/halaman_riwayat_pesanan.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplikasiME());
}

class AplikasiME extends StatelessWidget {
  const AplikasiME({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ME',
      theme: TemaAplikasi.tema,
      debugShowCheckedModeBanner: false,
      home: const HalamanUtamaNavigasi(),
    );
  }
}

class HalamanUtamaNavigasi extends StatefulWidget {
  const HalamanUtamaNavigasi({super.key});

  @override
  State<HalamanUtamaNavigasi> createState() => _HalamanUtamaNavigasiState();
}

class _HalamanUtamaNavigasiState extends State<HalamanUtamaNavigasi> {
  int _indeksAktif = 0;

  final List<Widget> _daftarHalaman = const [
    HalamanKatalog(),
    HalamanRiwayatPesanan(),
    HalamanKelolaProduk(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indeksAktif,
        children: _daftarHalaman,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: TemaAplikasi.surfaceWhite,
          border: Border(
            top: BorderSide(color: TemaAplikasi.borderGray, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _indeksAktif,
          onTap: (index) {
            setState(() {
              _indeksAktif = index;
            });
          },
          backgroundColor: TemaAplikasi.surfaceWhite,
          selectedItemColor: TemaAplikasi.primary,
          unselectedItemColor: TemaAplikasi.mutedGray,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined, size: 22),
              activeIcon: Icon(Icons.storefront, size: 22),
              label: 'KATALOG',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: 22),
              activeIcon: Icon(Icons.receipt_long, size: 22),
              label: 'PESANAN',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: 22),
              activeIcon: Icon(Icons.inventory_2, size: 22),
              label: 'KELOLA',
            ),
          ],
        ),
      ),
    );
  }
}
