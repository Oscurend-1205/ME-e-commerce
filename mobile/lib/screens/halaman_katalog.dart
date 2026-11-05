import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/kartu_produk.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_keranjang.dart';
import 'halaman_rincian_produk.dart';

class HalamanKatalog extends StatefulWidget {
  const HalamanKatalog({super.key});

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Produk> _daftarProduk = [];

  String? _kategoriTerpilih;
  final TextEditingController _cariController = TextEditingController();
  bool _tampilkanPencarian = false;
  int _jumlahItemKeranjang = 0;

  // Story highlight pills (sesuai cek-beranda.html)
  final List<Map<String, dynamic>> _stories = [
    {'label': 'Semua', 'icon': Icons.auto_awesome_mosaic_outlined, 'kat': null},
    {'label': 'Pakaian', 'icon': Icons.checkroom_outlined, 'kat': 'Pakaian'},
    {'label': 'Aksesori', 'icon': Icons.watch_outlined, 'kat': 'Aksesori'},
    {'label': 'Atasan', 'icon': Icons.dry_cleaning_outlined, 'kat': 'Pakaian'},
    {'label': 'Tas & Kulit', 'icon': Icons.shopping_bag_outlined, 'kat': 'Aksesori'},
  ];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    await Future.wait([
      _muatProduk(),
      _muatJumlahKeranjang(),
    ]);
  }

  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilProduk(
      kategori: _kategoriTerpilih == 'Semua' ? null : _kategoriTerpilih,
      cari: _cariController.text.trim().isEmpty ? null : _cariController.text.trim(),
    );

    if (!mounted) return;

    if (respon.berhasil) {
      final List dataRaw = respon.data is List ? respon.data as List : [];
      final produkList = dataRaw
          .map((item) => Produk.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _daftarProduk = produkList;
        _keadaan = produkList.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _muatJumlahKeranjang() async {
    final respon = await LayananApi.ambilKeranjang();
    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final dataKeranjang = DataKeranjang.fromJson(respon.data as Map<String, dynamic>);
      int totalItem = 0;
      for (final item in dataKeranjang.items) {
        totalItem += item.jumlah;
      }
      setState(() {
        _jumlahItemKeranjang = totalItem;
      });
    }
  }

  void _pilihKategori(String? kategori) {
    setState(() {
      _kategoriTerpilih = (kategori == null || kategori == 'Semua') ? null : kategori;
    });
    _muatProduk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: _bangunHeader(),
      body: RefreshIndicator(
        color: TemaAplikasi.primary,
        onRefresh: _muatData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Story Highlight Circles Row (cek-beranda.html)
              _bangunStoryHighlights(),

              // 2. Full-bleed Hero Editorial Banner (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunHeroBanner(),

              // 3. Kategori Pilihan (Curated Categories 2x2 Grid)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunKategoriPilihan(),

              // 4. Section Header Koleksi Terbaru / Katalog
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kategoriTerpilih != null
                              ? 'KATEGORI // ${_kategoriTerpilih!.toUpperCase()}'
                              : 'EDISI TERBATAS // MUSIM INI',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cariController.text.isNotEmpty
                              ? 'Hasil: "${_cariController.text}"'
                              : (_kategoriTerpilih ?? 'Koleksi Terbaru'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_keadaan == KeadaanMuat.berhasil)
                      Text(
                        '${_daftarProduk.length} ARTIKEL',
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.mutedGray,
                        ),
                      ),
                  ],
                ),
              ),

              // 5. Grid Produk / Status Keadaan
              _bangunKontenProduk(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _bangunHeader() {
    return AppBar(
      backgroundColor: TemaAplikasi.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      title: _tampilkanPencarian
          ? TextField(
              controller: _cariController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: TemaAplikasi.primary),
              decoration: const InputDecoration(
                hintText: 'Cari kemeja, celana, jaket...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: TemaAplikasi.mutedGray, fontSize: 13),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _muatProduk(),
            )
          : Row(
              children: [
                const Text(
                  'ME',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: TemaAplikasi.borderGray),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'STUDIO',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(_tampilkanPencarian ? Icons.close : Icons.search_outlined),
          onPressed: () {
            setState(() {
              if (_tampilkanPencarian) {
                _cariController.clear();
                _tampilkanPencarian = false;
                _muatProduk();
              } else {
                _tampilkanPencarian = true;
              }
            });
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanKeranjang()),
                );
                _muatData();
              },
            ),
            if (_jumlahItemKeranjang > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_jumlahItemKeranjang',
                    style: const TextStyle(
                      color: TemaAplikasi.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _bangunStoryHighlights() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _stories.map((story) {
            final isSelected = (_kategoriTerpilih == null && story['kat'] == null) ||
                _kategoriTerpilih == story['kat'];

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _pilihKategori(story['kat']),
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? TemaAplikasi.primary : TemaAplikasi.borderGray,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? TemaAplikasi.primary : TemaAplikasi.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          story['icon'] as IconData,
                          size: 24,
                          color: isSelected ? TemaAplikasi.onPrimary : TemaAplikasi.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? TemaAplikasi.primary : TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _bangunHeroBanner() {
    return Container(
      width: double.infinity,
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaAplikasi.primary,
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B2B2B),
            Color(0xFF111111),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Pattern Aksen Tekstur
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.checkroom_outlined,
              size: 220,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'KOLEKSI 2026 // ME STUDIO',
                  style: TextStyle(
                    color: Color(0xFFC8C6C5),
                    fontSize: 10,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ME MINIMALISM',
                  style: TextStyle(
                    color: TemaAplikasi.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Eksplorasi siluet bersih, material katun combed & linen, serta palet monokrom abadi.',
                  style: TextStyle(
                    color: Color(0xFFDDDDDD),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pilihKategori('Pakaian'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaAplikasi.onPrimary,
                          foregroundColor: TemaAplikasi.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('PAKAIAN'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pilihKategori('Aksesori'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TemaAplikasi.onPrimary,
                          side: const BorderSide(color: TemaAplikasi.onPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('AKSESORI'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunKategoriPilihan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EKSPLORASI LEMARI',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kategori Pilihan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid Kategori Pilihan (cek-beranda.html)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _bangunKartuKategoriMini('01 // ESENSIAL', 'Atasan & Kaos', Icons.checkroom, 'Pakaian'),
              _bangunKartuKategoriMini('02 // TAILORING', 'Kemeja & Celana', Icons.dry_cleaning, 'Pakaian'),
              _bangunKartuKategoriMini('03 // SUITING', 'Outerwear & Jaket', Icons.layers, 'Pakaian'),
              _bangunKartuKategoriMini('04 // AKSESORI', 'Tas & Dompet', Icons.watch, 'Aksesori'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunKartuKategoriMini(String kode, String judul, IconData ikon, String targetKat) {
    return InkWell(
      onTap: () => _pilihKategori(targetKat),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceWhite,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: TemaAplikasi.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  kode,
                  style: const TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                Icon(ikon, size: 16, color: TemaAplikasi.mutedGray),
              ],
            ),
            Text(
              judul,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TemaAplikasi.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunKontenProduk() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: WidgetMemuat(),
        );
      case KeadaanMuat.kosong:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: WidgetKosong(
            ikon: Icons.inventory_2_outlined,
            pesan: _cariController.text.isNotEmpty
                ? 'Tidak ada produk yang cocok dengan "${_cariController.text}".'
                : 'Belum ada produk untuk kategori ini.',
            saranAksi: 'Tampilkan Semua Produk',
            onAksi: () {
              setState(() {
                _kategoriTerpilih = null;
                _cariController.clear();
                _tampilkanPencarian = false;
              });
              _muatProduk();
            },
          ),
        );
      case KeadaanMuat.galat:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: WidgetGalat(
            jenisGalat: _jenisGalat,
            pesan: _pesanGalat,
            onCobaLagi: _muatProduk,
          ),
        );
      case KeadaanMuat.berhasil:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
            ),
            itemCount: _daftarProduk.length,
            itemBuilder: (context, index) {
              final produk = _daftarProduk[index];
              return KartuProduk(
                produk: produk,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanRincianProduk(produkId: produk.id),
                    ),
                  );
                  _muatData();
                },
              );
            },
          ),
        );
    }
  }
}
