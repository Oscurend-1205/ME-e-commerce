import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/kartu_produk.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_kelola_produk.dart';
import 'halaman_keranjang.dart';
import 'halaman_rincian_produk.dart';

class HalamanKatalog extends StatefulWidget {
  final bool modeJelajah;

  const HalamanKatalog({super.key, this.modeJelajah = false});

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Produk> _daftarProduk = [];

  String? _kategoriTerpilih;
  String _storyTerpilih = 'Baru Tiba';
  final TextEditingController _cariController = TextEditingController();
  final TextEditingController _emailVipController = TextEditingController();
  final Set<int> _wishlistIds = {};
  bool _tampilkanPencarian = false;
  int _jumlahItemKeranjang = 0;

  // 6 Story highlight pills sesuai mobile/penampung-tampilan/cek-beranda.html
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
          'label': 'Aksesori',
          'foto': FotoDummy.stories[3],
          'kat': 'Aksesori',
        },
        {
          'label': 'Lookbook',
          'foto': FotoDummy.stories[4],
          'kat': null,
        },
        {
          'label': 'Sale',
          'foto': FotoDummy.stories[5],
          'kat': null,
        },
      ];

  @override
  void initState() {
    super.initState();
    if (widget.modeJelajah) {
      _tampilkanPencarian = true;
    }
    _muatData();
  }

  @override
  void dispose() {
    _cariController.dispose();
    _emailVipController.dispose();
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
      List<Produk> produkList = dataRaw
          .map((item) => Produk.fromJson(item as Map<String, dynamic>))
          .toList();

      // Filter khusus Story: Lookbook atau Sale
      if (_storyTerpilih == 'Sale') {
        produkList = produkList.where((p) => p.harga <= 150000 || p.stok < 30).toList();
      }

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
      if (_kategoriTerpilih == null) {
        _storyTerpilih = 'Baru Tiba';
      } else if (_kategoriTerpilih == 'Pakaian') {
        _storyTerpilih = 'Wanita';
      } else if (_kategoriTerpilih == 'Aksesori') {
        _storyTerpilih = 'Aksesori';
      }
    });
    _muatProduk();
  }

  void _pilihStory(Map<String, dynamic> story) {
    final label = story['label'] as String;
    final kat = story['kat'] as String?;
    setState(() {
      _storyTerpilih = label;
      _kategoriTerpilih = (kat == null || kat == 'Semua') ? null : kat;
    });
    _muatProduk();
  }

  void _toggleWishlist(Produk produk) {
    setState(() {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (_wishlistIds.contains(produk.id)) {
        _wishlistIds.remove(produk.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${produk.nama} dihapus dari Wishlist'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _wishlistIds.add(produk.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('${produk.nama} ditambahkan ke Wishlist')),
              ],
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _tambahItemKeKeranjang(Produk produk) async {
    // Ambil ID varian pertama yang tersedia atau null
    int? varianId;
    if (produk.varian != null && produk.varian!.isNotEmpty) {
      final varianTersedia = produk.varian!.firstWhere(
        (v) => v.stok > 0,
        orElse: () => produk.varian!.first,
      );
      varianId = varianTersedia.id;
    } else {
      // Ambil rincian produk untuk mendapatkan varian ID jika belum termuat
      final detail = await LayananApi.ambilRincianProduk(produk.id);
      if (detail.berhasil && detail.data != null) {
        final p = Produk.fromJson(detail.data as Map<String, dynamic>);
        if (p.varian != null && p.varian!.isNotEmpty) {
          final v = p.varian!.firstWhere(
            (x) => x.stok > 0,
            orElse: () => p.varian!.first,
          );
          varianId = v.id;
        }
      }
    }

    if (varianId == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanRincianProduk(produkId: produk.id),
        ),
      ).then((_) => _muatJumlahKeranjang());
      return;
    }

    final respon = await LayananApi.tambahKeKeranjang(
      produkId: produk.id,
      varianId: varianId,
      jumlah: 1,
    );

    if (!mounted) return;

    if (respon.berhasil) {
      await _muatJumlahKeranjang();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produk.nama} berhasil ditambahkan ke Tas Belanja.'),
          duration: const Duration(milliseconds: 1500),
          action: SnackBarAction(
            label: 'LIHAT',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanKeranjang()),
              ).then((_) => _muatJumlahKeranjang());
            },
          ),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _daftarVipNewsletter() {
    final email = _emailVipController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan alamat email yang valid.'),
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _emailVipController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terima kasih telah bergabung dengan ME Privé.'),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              // 1. Story Highlight Pills (cek-beranda.html)
              _bangunStoryHighlights(),

              // 2. Full-bleed Mobile Hero Editorial Banner (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunHeroBanner(),

              // 3. Kategori Pilihan (Curated Categories 2x2 Grid) (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunKategoriPilihan(),

              // 4. Section Header Koleksi Terbaru / Katalog (cek-beranda.html)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
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
                        const SizedBox(height: 3),
                        Text(
                          _cariController.text.isNotEmpty
                              ? 'Hasil: "${_cariController.text}"'
                              : (_kategoriTerpilih ?? 'Koleksi Terbaru'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
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

              // 5. Grid Produk / Status Keadaan (cek-beranda.html)
              _bangunKontenProduk(),

              // 6. Manifesto Editorial Inset / Campaign Showcase (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunManifestoEditorial(),

              // 7. Curated Editorial Highlight (Asymmetric Banner) (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunCuratedEditorialHighlight(),

              // 8. Pelayanan & Garansi Eksklusif (Trust Badges) (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunPelayananEksklusif(),

              // 9. Newsletter / VIP Club Editorial Sign-up (cek-beranda.html)
              if (_kategoriTerpilih == null && !_tampilkanPencarian)
                _bangunNewsletterVip(),

              const SizedBox(height: 24),
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
      elevation: 0,
      title: _tampilkanPencarian
          ? TextField(
              controller: _cariController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: TemaAplikasi.primary),
              decoration: const InputDecoration(
                hintText: 'Cari kemeja, celana, tas, aksesori...',
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
                // Brand Logo ME (Playfair Display)
                const Text(
                  'ME',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    fontSize: 22,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'STUDIO',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'BERANDA',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const Spacer(),
              ],
            ),
      actions: [
        // Tombol Cari
        IconButton(
          icon: Icon(_tampilkanPencarian ? Icons.close : Icons.search_outlined, size: 22),
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

        // Tombol Shopping Bag dengan Badge Kuantitas
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanKeranjang()),
                );
                _muatJumlahKeranjang();
              },
            ),
            if (_jumlahItemKeranjang > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_jumlahItemKeranjang',
                    style: const TextStyle(
                      color: TemaAplikasi.onPrimary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        // Profile Avatar (cek-beranda.html)
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanKelolaProduk()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TemaAplikasi.borderGray),
              ),
              clipBehavior: Clip.antiAlias,
              child: FotoDummy.bangunGambar(
                url: FotoDummy.avatar,
                fit: BoxFit.cover,
                fallbackWidget: Container(
                  color: TemaAplikasi.primary,
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Story / Category Highlight Pills (Horizontal Scroll)
  Widget _bangunStoryHighlights() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _stories.map((story) {
            final isSelected = _storyTerpilih == story['label'];

            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: InkWell(
                onTap: () => _pilihStory(story),
                borderRadius: BorderRadius.circular(36),
                child: Column(
                  children: [
                    // Lingkaran Foto dengan Indikator Aktif Bergradasi Sesuai cek-beranda.html
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  TemaAplikasi.primary,
                                  TemaAplikasi.secondary,
                                  Color(0xFFE5E2E1),
                                ],
                              )
                            : null,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: const Color(0xFFE2E2E2),
                                width: 1.5,
                              ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: TemaAplikasi.surfaceWhite,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: FotoDummy.bangunGambar(
                            url: story['foto'] as String,
                            fit: BoxFit.cover,
                            fallbackWidget: Container(
                              color: isSelected
                                  ? TemaAplikasi.primary
                                  : TemaAplikasi.surfaceContainer,
                              child: Icon(
                                Icons.checkroom_outlined,
                                size: 24,
                                color: isSelected
                                    ? TemaAplikasi.onPrimary
                                    : TemaAplikasi.primary,
                              ),
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

  // 2. Full-bleed Mobile Hero Editorial Banner (cek-beranda.html)
  Widget _bangunHeroBanner() {
    return Container(
      width: double.infinity,
      height: 420,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TemaAplikasi.primary,
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto Editorial ME MINIMALISM
          FotoDummy.bangunGambar(
            url: FotoDummy.heroBanner,
            fit: BoxFit.cover,
          ),

          // Gradient Overlay Dramatis Sesuai cek-beranda.html
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x4D000000),
                  Color(0xEE000000),
                ],
                stops: [0.25, 0.55, 1.0],
              ),
            ),
          ),

          // Teks & Tombol Aksi Hero Banner
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'KOLEKSI 2025 // ME STUDIO',
                  style: TextStyle(
                    color: Color(0xFFE5E2E1),
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ME MINIMALISM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Eksplorasi siluet bersih, material linen premium, dan palet monokrom abadi.',
                  style: TextStyle(
                    color: Color(0xFFE5E2E1),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Tombol Wanita Sesuai cek-beranda.html
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            _pilihStory(_stories[1]); // Wanita
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: TemaAplikasi.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: const Text(
                            'WANITA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Pria Sesuai cek-beranda.html
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            _pilihStory(_stories[2]); // Pria
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.4),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: const Text(
                            'PRIA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
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

  // 3. Kategori Pilihan (Curated Categories 2x2 Grid) (cek-beranda.html)
  Widget _bangunKategoriPilihan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'EKSPLORASI LEMARI',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kategori Pilihan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _pilihKategori(null),
                child: Row(
                  children: const [
                    Text(
                      'LIHAT SEMUA',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: TemaAplikasi.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid Kategori Pilihan dengan Foto Editorial (cek-beranda.html)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75, // Aspek rasio 3:4 sesuai cek-beranda.html
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
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FotoDummy.bangunGambar(
              url: urlFoto,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x22000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.4, 0.7, 1.0],
                ),
              ),
            ),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5E2E1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  // 4 & 5. Grid Produk / Status Keadaan (cek-beranda.html)
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
              childAspectRatio: 0.51, // Pas untuk foto 3:4 + title + price + tombol Tas Belanja
            ),
            itemBuilder: (context, index) {
              final produk = _daftarProduk[index];
              return KartuProduk(
                produk: produk,
                isWishlist: _wishlistIds.contains(produk.id),
                onToggleWishlist: () => _toggleWishlist(produk),
                onTambahKeranjang: () => _tambahItemKeKeranjang(produk),
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

  // 6. Manifesto Editorial Inset / Campaign Showcase (cek-beranda.html)
  Widget _bangunManifestoEditorial() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      color: const Color(0xFF1C1B1B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANIFESTO DESAIN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF868381),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'THE MONOCHROME CAPSULE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '"Kesederhanaan adalah wujud kemewahan tertinggi. Setiap jahitan dirancang untuk ketahanan gaya lintas dekade."',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFFE2E2E2),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Foto Showcase 16:9 Sesuai cek-beranda.html
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FotoDummy.bangunGambar(
                url: FotoDummy.manifesto,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'EDISI KOLEKTOR',
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC8C6C5),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Vol. 04 / Autumn-Winter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _pilihStory(_stories[4]); // Lookbook
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TemaAplikasi.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Text(
                    'JELAJAHI LOOKBOOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  label: const Icon(Icons.arrow_forward, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Curated Editorial Highlight (Asymmetric Banner) (cek-beranda.html)
  Widget _bangunCuratedEditorialHighlight() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _pilihKategori('Pakaian');
        },
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FotoDummy.bangunGambar(
                  url: FotoDummy.siluetBaru,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x33000000),
                        Color(0xCC000000),
                      ],
                      stops: [0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SILUET BARU',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE5E2E1),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Garis Arsitektural',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Potongan tegas yang merayakan proporsi tubuh kontemporer.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEEEEEE),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 8. Pelayanan & Garansi Eksklusif (Trust Badges) (cek-beranda.html)
  Widget _bangunPelayananEksklusif() {
    return Container(
      width: double.infinity,
      color: TemaAplikasi.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          const Text(
            'STANDAR ME STUDIO',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Pelayanan Eksklusif',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 18),
          _bangunItemPelayanan(
            ikon: Icons.local_shipping_outlined,
            judul: 'Gratis Ongkir Seluruh Indonesia',
            deskripsi: 'Pengiriman ekspres tanpa minimum pembelian',
          ),
          const SizedBox(height: 10),
          _bangunItemPelayanan(
            ikon: Icons.sync_alt,
            judul: 'Pengembalian 14 Hari Tanpa Syarat',
            deskripsi: 'Penukaran ukuran atau pengembalian dana mudah',
          ),
          const SizedBox(height: 10),
          _bangunItemPelayanan(
            ikon: Icons.verified_outlined,
            judul: '100% Autentik & Dijamin',
            deskripsi: 'Dibuat dengan kurasi material standar couture',
          ),
        ],
      ),
    );
  }

  Widget _bangunItemPelayanan({
    required IconData ikon,
    required String judul,
    required String deskripsi,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceContainer,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(ikon, size: 20, color: TemaAplikasi.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deskripsi,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. Newsletter / VIP Club Editorial Sign-up (cek-beranda.html)
  Widget _bangunNewsletterVip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'ME PRIVÉ',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dapatkan Akses Pratinjau Eksklusif',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadilah yang pertama mengakses rilis terbatas dan lookbook privat setiap musim.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _emailVipController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 12, color: TemaAplikasi.primary),
                    decoration: InputDecoration(
                      hintText: 'Masukkan alamat email Anda',
                      hintStyle: const TextStyle(color: TemaAplikasi.mutedGray, fontSize: 12),
                      fillColor: TemaAplikasi.surfaceContainerLow,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _daftarVipNewsletter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaAplikasi.primary,
                    foregroundColor: TemaAplikasi.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text(
                    'DAFTAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'PRIVASI ANDA TERJAMIN SEPENUHNYA',
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.5,
              color: TemaAplikasi.mutedGray,
            ),
          ),
        ],
      ),
    );
  }
}
