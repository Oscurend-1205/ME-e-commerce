import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/foto_dummy.dart';
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
  List<Map<String, dynamic>> get _stories => [
    {
      'label': 'Baru Tiba',
      'foto': FotoDummy.stories[0],
      'kat': null,
    },
    {
      'label': 'Wanita',
      'foto': FotoDummy.stories[1],
      'kat': 'Pakaian',
    },
    {
      'label': 'Pria',
      'foto': FotoDummy.stories[2],
      'kat': 'Pakaian',
    },
    {
      'label': 'Tas & Dompet',
      'foto': FotoDummy.stories[3],
      'kat': 'Aksesori',
    },
    {
      'label': 'Aksesori',
      'foto': FotoDummy.stories[4],
      'kat': 'Aksesori',
    },
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
    if (respon.berhasil && respon.data != null && mounted) {
      final Map<String, dynamic> data = respon.data as Map<String, dynamic>;
      final List items = data['items'] is List ? data['items'] as List : [];
      final totalItem = items.fold<int>(0, (sum, item) {
        final j = item['jumlah'];
        return sum + (j is int ? j : int.tryParse(j.toString()) ?? 1);
      });
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

              // 2. Full-bleed Hero Editorial Banner dengan Foto "ME MINIMALISM"
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunHeroBanner(),

              // 3. Kategori Pilihan (Curated Categories 2x2 Grid dengan Foto)
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

              // 5. Grid Produk / Status Keadaan (Koleksi Terbaru)
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
                      child: ClipOval(
                        child: FotoDummy.bangunGambar(
                          url: story['foto'] as String,
                          fit: BoxFit.cover,
                          fallbackWidget: Container(
                            color: isSelected ? TemaAplikasi.primary : TemaAplikasi.surfaceContainer,
                            child: Icon(
                              Icons.checkroom_outlined,
                              size: 24,
                              color: isSelected ? TemaAplikasi.onPrimary : TemaAplikasi.primary,
                            ),
                          ),
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
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaAplikasi.primary,
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto Dummy Editorial ME MINIMALISM
          FotoDummy.bangunGambar(
            url: FotoDummy.heroBanner,
            fit: BoxFit.cover,
          ),

          // Gradient Monokrom Mewah Sesuai cek-beranda.html
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x66000000),
                  Color(0xEE000000),
                ],
                stops: [0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Teks Editorial ME MINIMALISM
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
                const SizedBox(height: 6),
                const Text(
                  'ME MINIMALISM',
                  style: TextStyle(
                    color: TemaAplikasi.onPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Eksplorasi siluet bersih, material katun combed & linen, serta palet monokrom abadi.',
                  style: TextStyle(
                    color: Color(0xFFEEEEEE),
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

          // 2x2 Grid Kategori Pilihan dengan Foto Editorial (cek-beranda.html)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _bangunKartuKategoriFoto('01 // ESENSIAL', 'Atasan & Kemeja', FotoDummy.katAtasan, 'Pakaian'),
              _bangunKartuKategoriFoto('02 // TAILORING', 'Bawahan & Celana', FotoDummy.katBawahan, 'Pakaian'),
              _bangunKartuKategoriFoto('03 // SUITING', 'Outerwear & Jas', FotoDummy.katOuterwear, 'Pakaian'),
              _bangunKartuKategoriFoto('04 // AKSESORI', 'Kulit & Tas', FotoDummy.katAksesori, 'Aksesori'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunKartuKategoriFoto(String kode, String judul, String urlFoto, String targetKat) {
    return InkWell(
      onTap: () => _pilihKategori(targetKat),
      child: Container(
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceContainer,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: TemaAplikasi.borderGray),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto Kategori Editorial
            FotoDummy.bangunGambar(
              url: urlFoto,
              fit: BoxFit.cover,
            ),

            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x33000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Teks Kategori
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kode,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E2E1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TemaAplikasi.onPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
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
          padding: EdgeInsets.symmetric(vertical: 40),
          child: WidgetMemuat(),
        );

      case KeadaanMuat.kosong:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: WidgetKosong(
            ikon: Icons.search_off_outlined,
            pesan: _cariController.text.isNotEmpty
                ? 'Tidak ada produk yang cocok dengan "${_cariController.text}".'
                : 'Belum ada produk untuk kategori ini.',
            saranAksi: 'Tampilkan Semua Produk',
            onAksi: () {
              _cariController.clear();
              _pilihKategori(null);
            },
          ),
        );

      case KeadaanMuat.galat:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
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
            itemCount: _daftarProduk.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
              childAspectRatio: 0.58, // Rasio 3:4 foto + info teks
            ),
            itemBuilder: (context, index) {
              final produk = _daftarProduk[index];
              return KartuProduk(
                produk: produk,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanRincianProduk(produkId: produk.id),
                    ),
                  ).then((_) => _muatJumlahKeranjang());
                },
              );
            },
          ),
        );
    }
  }
}
