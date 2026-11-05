import 'package:flutter/material.dart';

import 'screens/halaman_katalog.dart';
import 'screens/halaman_kelola_produk.dart';
import 'screens/halaman_riwayat_pesanan.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplikasiFashionStore());
}

class AplikasiFashionStore extends StatelessWidget {
  const AplikasiFashionStore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion Store',
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
          border: Border(
            top: BorderSide(color: Color(0xFFDDDDDD), width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _indeksAktif,
          onTap: (index) {
            setState(() {
              _indeksAktif = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF111111),
          unselectedItemColor: const Color(0xFF777777),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'KATALOG',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'PESANAN',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'KELOLA',
            ),
          ],
        ),
      ),
    );
  }
}
