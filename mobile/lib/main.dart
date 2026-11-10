import 'package:flutter/material.dart';

import 'screens/halaman_akun.dart';
import 'screens/halaman_katalog.dart';
import 'screens/halaman_riwayat_pesanan.dart';
import 'services/state_pengguna.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pulihkan sesi login tersimpan agar keranjang & pesanan tetap utuh
  // setelah aplikasi ditutup dan dibuka kembali.
  await StatePengguna.muatSesiTersimpan();
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
  String? _storyAwalJelajah;

  @override
  void initState() {
    super.initState();
    StatePengguna.sinkronkanKeranjang();
  }

  void _pindahKeTab(int indeks, [String? story]) {
    setState(() {
      _indeksAktif = indeks;
      if (story != null) {
        _storyAwalJelajah = story;
      }
    });
  }

  List<Widget> get _daftarHalaman => [
    HalamanKatalog(
      onPindahTab: _pindahKeTab,
    ),
    HalamanKatalog(
      modeJelajah: true,
      storyAwal: _storyAwalJelajah,
      onPindahTab: _pindahKeTab,
    ),
    const HalamanRiwayatPesanan(),
    const HalamanAkun(),
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
            top: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _bangunItemTab(
                  indeks: 0,
                  ikonAktif: Icons.home,
                  ikonTidakAktif: Icons.home_outlined,
                  label: 'BERANDA',
                ),
                _bangunItemTab(
                  indeks: 1,
                  ikonAktif: Icons.explore,
                  ikonTidakAktif: Icons.explore_outlined,
                  label: 'JELAJAH',
                ),
                _bangunItemTab(
                  indeks: 2,
                  ikonAktif: Icons.receipt_long,
                  ikonTidakAktif: Icons.receipt_long_outlined,
                  label: 'PESANAN',
                ),
                _bangunItemTab(
                  indeks: 3,
                  ikonAktif: Icons.person,
                  ikonTidakAktif: Icons.person_outline,
                  label: 'AKUN',
                  pakaiAvatar: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bangunItemTab({
    required int indeks,
    required IconData ikonAktif,
    required IconData ikonTidakAktif,
    required String label,
    bool pakaiAvatar = false,
  }) {
    final isAktif = _indeksAktif == indeks;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _indeksAktif = indeks;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 64,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Ikon atau Micro Avatar (Sesuai State 2A & 2B di cek-navbar.html)
              if (pakaiAvatar && isAktif)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TemaAplikasi.primary, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ValueListenableBuilder<String>(
                    valueListenable: StatePengguna.fotoProfilNotifier,
                    builder: (context, foto, _) {
                      return Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: TemaAplikasi.primary,
                          child: Center(
                            child: Text(
                              StatePengguna.namaUserNotifier.value.isNotEmpty
                                  ? StatePengguna.namaUserNotifier.value[0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                color: TemaAplikasi.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Icon(
                  isAktif ? ikonAktif : ikonTidakAktif,
                  size: 22,
                  color: isAktif
                      ? TemaAplikasi.primary
                      : TemaAplikasi.mutedGray,
                ),
              const SizedBox(height: 3),
              // Label (font-label-sm uppercase tracking-widest)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: isAktif ? FontWeight.w700 : FontWeight.w500,
                  color: isAktif
                      ? TemaAplikasi.primary
                      : TemaAplikasi.mutedGray,
                ),
              ),
              const SizedBox(height: 2),
              // Titik Indikator 2x6px Aktif (Sesuai State 2A di cek-navbar.html)
              Container(
                width: 6,
                height: 2,
                decoration: BoxDecoration(
                  color: isAktif ? TemaAplikasi.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
