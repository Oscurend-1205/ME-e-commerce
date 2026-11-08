import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/kartu_produk.dart';
import '../widgets/modal_pilih_varian.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_akun.dart';
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

  // Mode Tampilan: true = 2-Kolom Grid, false = 1-Kolom Lookbook Editorial
  bool _modeGrid = true;
  String _subKategoriWanita = 'SEMUA';
  String _subKategoriPria = 'SEMUA';
  String _urutan = 'KURASI TERBARU';

  final List<String> _chipsWanita = const [
    'SEMUA',
    'OUTERWEAR & COAT',
    'SUITING & TAILORED',
    'SILK & DRESSES',
    'KNITWEAR KASMIR',
  ];

  final List<String> _chipsPria = const [
    'SEMUA',
    'SUITING & BLAZER',
    'KEMEJA & SHIRTING',
    'KNITWEAR',
    'CELANA TAILORED',
  ];

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
      kategori: (_storyTerpilih == 'Wanita' || _storyTerpilih == 'Pria')
          ? null
          : (_kategoriTerpilih == 'Semua' ? null : _kategoriTerpilih),
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
      if (label == 'Wanita') {
        _subKategoriWanita = 'SEMUA';
      } else if (label == 'Pria') {
        _subKategoriPria = 'SEMUA';
      }
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
    // Tampilkan overlay pemilihan ukuran, warna, dan kuantitas sebelum masuk ke keranjang
    await ModalPilihVarian.tampilkanTambah(
      context,
      produk: produk,
      onKonfirmasi: (varian, jumlah) async {
        final respon = await LayananApi.tambahKeKeranjang(
          produkId: produk.id,
          varianId: varian.id,
          jumlah: jumlah,
        );

        if (!mounted) return false;

        if (respon.berhasil) {
          await _muatJumlahKeranjang();
          if (!mounted) return true;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${produk.nama} (${varian.ukuran}, ${varian.warna}) x$jumlah berhasil ditambahkan ke Tas Belanja.',
              ),
              duration: const Duration(milliseconds: 2000),
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
          return true;
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(respon.message),
              duration: const Duration(milliseconds: 2000),
              backgroundColor: TemaAplikasi.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
      },
    );
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
              // 1. Story Highlight Pills (Circular Category Chips) - Tetap ada di semua halaman
              _bangunStoryHighlights(),

              // 2. Konten Halaman Sesuai Kategori / Story yang Dipilih
              if (_storyTerpilih == 'Wanita')
                _bangunKatalogWanita()
              else if (_storyTerpilih == 'Pria')
                _bangunKatalogPria()
              else
                _bangunKontenBerandaUtama(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunKontenBerandaUtama() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  PreferredSizeWidget _bangunHeader() {
    if (_tampilkanPencarian) {
      return AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: TextField(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: () {
              setState(() {
                _cariController.clear();
                _tampilkanPencarian = false;
                _muatProduk();
              });
            },
          ),
        ],
      );
    }

    // Header Beranda PERSIS & SAMA untuk semua halaman/kategori (Tanpa Tombol Back)
    return AppBar(
      backgroundColor: TemaAplikasi.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: const [
          Text(
            'ME',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              fontSize: 22,
              color: TemaAplikasi.primary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'STUDIO',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          Spacer(),
          Text(
            'BERANDA',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          Spacer(),
        ],
      ),
      actions: [
        ..._bangunHeaderActions(),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanAkun()),
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

  List<Widget> _bangunHeaderActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search_outlined, size: 22),
        tooltip: 'Pencarian',
        onPressed: () {
          setState(() {
            _tampilkanPencarian = true;
          });
        },
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, size: 22),
            tooltip: 'Tas Belanja',
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
    ];
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

  // ==========================================
  // KATALOG KHUSUS WANITA & PRIA ATELIER
  // (mobile/penampung-tampilan/cek-katalogWanita.html & cek-katalogPria.html)
  // ==========================================

  List<Produk> _dapatkanProdukTerfilter() {
    List<Produk> hasil = List.from(_daftarProduk);

    if (_storyTerpilih == 'Wanita') {
      if (_subKategoriWanita == 'OUTERWEAR & COAT') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('coat') || s.contains('mantel') || s.contains('outer') || s.contains('jaket') || s.contains('blazer');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'SUITING & TAILORED') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('suit') || s.contains('setelan') || s.contains('blazer') || s.contains('tailor') || s.contains('celana');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'SILK & DRESSES') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('gaun') || s.contains('dress') || s.contains('sutra') || s.contains('silk') || s.contains('rok');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'KNITWEAR KASMIR') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('rajut') || s.contains('knit') || s.contains('kasmir') || s.contains('sweater') || s.contains('syal');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'AKSESORI') {
        final f = hasil.where((p) {
          return p.kategori.toLowerCase() == 'aksesori';
        }).toList();
        if (f.isNotEmpty) hasil = f;
      }
    } else if (_storyTerpilih == 'Pria') {
      if (_subKategoriPria == 'SUITING & BLAZER') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('blazer') || s.contains('jas') || s.contains('suit') || s.contains('setelan');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'KEMEJA & SHIRTING') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('kemeja') || s.contains('shirt') || s.contains('poplin') || s.contains('atasan');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'MANTEL') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('mantel') || s.contains('coat') || s.contains('outer') || s.contains('jaket');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'KNITWEAR') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('rajut') || s.contains('knit') || s.contains('sweater') || s.contains('kasmir');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'CELANA TAILORED') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'.toLowerCase();
          return s.contains('celana') || s.contains('trouser') || s.contains('pant') || s.contains('pleat');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      }
    }

    if (_urutan == 'HARGA: RENDAH KE TINGGI') {
      hasil.sort((a, b) => a.harga.compareTo(b.harga));
    } else if (_urutan == 'HARGA: TINGGI KE RENDAH') {
      hasil.sort((a, b) => b.harga.compareTo(a.harga));
    } else if (_urutan == 'TERPOPULER') {
      hasil.sort((a, b) => b.stok.compareTo(a.stok));
    }

    return hasil;
  }

  void _tampilkanModalSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaAplikasi.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        final opsi = [
          'KURASI TERBARU',
          'HARGA: RENDAH KE TINGGI',
          'HARGA: TINGGI KE RENDAH',
          'TERPOPULER',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'URUTKAN PRODUK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...opsi.map((item) {
                  final terpilih = _urutan == item;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.0,
                        fontWeight: terpilih ? FontWeight.w700 : FontWeight.w400,
                        color: terpilih ? TemaAplikasi.primary : TemaAplikasi.secondary,
                      ),
                    ),
                    trailing: terpilih
                        ? const Icon(Icons.check, size: 18, color: TemaAplikasi.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _urutan = item;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _tampilkanModalFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaAplikasi.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FILTER KURASI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'STATUS PRODUK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _bangunFilterTag('Eksklusif Atelier', true),
                    _bangunFilterTag('Baru Tiba', false),
                    _bangunFilterTag('Wol Murni', false),
                    _bangunFilterTag('Sutra Murni', false),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'PALET WARNA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _bangunFilterTag('Obsidian (Noir)', true),
                    _bangunFilterTag('Blanc Ivoire', false),
                    _bangunFilterTag('Charcoal Gris', false),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Filter kurasi diterapkan.'),
                          duration: Duration(milliseconds: 1500),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaAplikasi.primary,
                      foregroundColor: TemaAplikasi.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'TERAPKAN FILTER (3)',
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
          ),
        );
      },
    );
  }

  Widget _bangunFilterTag(String label, bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: aktif ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: aktif ? TemaAplikasi.onPrimary : TemaAplikasi.secondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ------------------------------------------
  // TAMPILAN KATALOG WANITA (cek-katalogWanita.html)
  // ------------------------------------------
  Widget _bangunKatalogWanita() {
    final produkTerfilter = _dapatkanProdukTerfilter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Metadata & Heading (cek-katalogWanita.html)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ÉDITION 2025 · CURATED',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    Text(
                      '${produkTerfilter.length} PRODUK PILIHAN',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Women’s Atelier',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Siluet dekonstruksi modern, mantel wol kasmir struktural, gaun sutra murni, dan setelan tailored esensial untuk wanita kontemporer.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
        ),

        // 3. Campaign Spotlight Lookbook Card (cek-katalogWanita.html)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FotoDummy.bangunGambar(
                    url: FotoDummy.heroWanita,
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
                          Color(0xEE000000),
                        ],
                        stops: [0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              color: Colors.black.withValues(alpha: 0.75),
                              child: const Text(
                                '• KAMPANYE UTAMA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Text(
                              '02 / 04 SERIES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'L’Élégance Silencieuse',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Eksplorasi drape arsitektural & palet monokrom abadi.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _subKategoriWanita = 'OUTERWEAR & COAT';
                                });
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Menampilkan Seri 02: L’Élégance Silencieuse'),
                                    duration: Duration(milliseconds: 1500),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'JELAJAHI SERI 02',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Horizontal Category Filter Chips (cek-katalogWanita.html)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _chipsWanita.map((chip) {
              final isSelected = _subKategoriWanita == chip;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _subKategoriWanita = chip;
                    });
                  },
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    color: isSelected
                        ? TemaAplikasi.primary
                        : TemaAplikasi.surfaceContainerLow,
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? TemaAplikasi.onPrimary
                            : TemaAplikasi.secondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 5. Quick Controls Bar (cek-katalogWanita.html)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _tampilkanModalFilter,
                  child: Row(
                    children: [
                      const Text(
                        'FILTER',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: TemaAplikasi.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(3)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _tampilkanModalSort,
                  child: Row(
                    children: [
                      const Text(
                        'URUTKAN: ',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      Text(
                        _urutan,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more, size: 16, color: TemaAplikasi.primary),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      color: _modeGrid ? TemaAplikasi.primary : TemaAplikasi.mutedGray,
                      onPressed: () {
                        setState(() {
                          _modeGrid = true;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.splitscreen, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      color: !_modeGrid ? TemaAplikasi.primary : TemaAplikasi.mutedGray,
                      onPressed: () {
                        setState(() {
                          _modeGrid = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 6. Product Listing (2-Column Grid atau 1-Column Lookbook)
        _bangunDaftarProdukKatalog(isPria: false),

        // 7. Filosofi Desain (Quote Box)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            color: TemaAplikasi.surfaceContainerLow,
            child: Column(
              children: const [
                Text(
                  '"Keanggunan bukanlah menarik perhatian, melainkan diingat selamanya."',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: TemaAplikasi.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '— ME PHILOSOPHY',
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ------------------------------------------
  // TAMPILAN KATALOG PRIA (cek-katalogPria.html)
  // ------------------------------------------
  Widget _bangunKatalogPria() {
    final produkTerfilter = _dapatkanProdukTerfilter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Metadata & Heading (cek-katalogPria.html)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ÉDITION 2025 · CURATED',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    Text(
                      '${produkTerfilter.length} PRODUK PILIHAN',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Men’s Atelier',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Siluet tailoring modern, mantel wol struktural, kemeja poplin presisi, dan rajutan kasmir esensial untuk pria.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
        ),

        // 3. Campaign Spotlight Lookbook Card (cek-katalogPria.html)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FotoDummy.bangunGambar(
                    url: FotoDummy.heroPria,
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
                          Color(0xEE000000),
                        ],
                        stops: [0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              color: Colors.black.withValues(alpha: 0.75),
                              child: const Text(
                                '• KAMPANYE UTAMA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Text(
                              '01 / 04 SERIES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'L’Homme Contemporain',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Eksplorasi potongan jas dekonstruksi & palet monokrom abadi.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _subKategoriPria = 'SUITING & BLAZER';
                                });
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Menampilkan Seri 01: L’Homme Contemporain'),
                                    duration: Duration(milliseconds: 1500),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'JELAJAHI SERI 01',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Horizontal Category Filter Chips (cek-katalogPria.html)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _chipsPria.map((chip) {
              final isSelected = _subKategoriPria == chip;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _subKategoriPria = chip;
                    });
                  },
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    color: isSelected
                        ? TemaAplikasi.primary
                        : TemaAplikasi.surfaceContainerLow,
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? TemaAplikasi.onPrimary
                            : TemaAplikasi.secondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 5. Quick Controls Bar (cek-katalogPria.html)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _tampilkanModalFilter,
                  child: Row(
                    children: [
                      const Text(
                        'FILTER',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: TemaAplikasi.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(3)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _tampilkanModalSort,
                  child: Row(
                    children: [
                      const Text(
                        'URUTKAN: ',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      Text(
                        _urutan,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more, size: 16, color: TemaAplikasi.primary),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: _modeGrid ? TemaAplikasi.primary : TemaAplikasi.mutedGray,
                      onPressed: () {
                        setState(() {
                          _modeGrid = true;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.splitscreen, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: !_modeGrid ? TemaAplikasi.primary : TemaAplikasi.mutedGray,
                      onPressed: () {
                        setState(() {
                          _modeGrid = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 6. Product Listing (2-Column Grid atau 1-Column Lookbook)
        _bangunDaftarProdukKatalog(isPria: true),

        // 7. Filosofi Desain (Quote Box)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            color: TemaAplikasi.surfaceContainerLow,
            child: Column(
              children: const [
                Text(
                  '"Kesederhanaan adalah tingkat kecanggihan tertinggi dalam tata busana pria."',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: TemaAplikasi.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '— ME ATELIER HOMME',
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ------------------------------------------
  // LISTING PRODUK & KARTU EDITORIAL KATALOG
  // ------------------------------------------
  Widget _bangunDaftarProdukKatalog({required bool isPria}) {
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
            ikon: Icons.checkroom_outlined,
            pesan: 'Belum ada produk kurasi untuk kategori ini.',
            saranAksi: 'Tampilkan Semua Koleksi',
            onAksi: () {
              setState(() {
                if (isPria) {
                  _subKategoriPria = 'SEMUA';
                } else {
                  _subKategoriWanita = 'SEMUA';
                }
              });
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
        final produkList = _dapatkanProdukTerfilter();

        if (produkList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: WidgetKosong(
              ikon: Icons.search_off_outlined,
              pesan: 'Tidak ada produk yang cocok dengan filter yang dipilih.',
              saranAksi: 'Reset Filter',
              onAksi: () {
                setState(() {
                  if (isPria) {
                    _subKategoriPria = 'SEMUA';
                  } else {
                    _subKategoriWanita = 'SEMUA';
                  }
                });
              },
            ),
          );
        }

        if (_modeGrid) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produkList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 24,
                childAspectRatio: 0.50,
              ),
              itemBuilder: (context, index) {
                final produk = produkList[index];
                return _bangunKartuEditorial(produk, isPria: isPria, isGrid: true);
              },
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produkList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 32),
              itemBuilder: (context, index) {
                final produk = produkList[index];
                return _bangunKartuEditorial(produk, isPria: isPria, isGrid: false);
              },
            ),
          );
        }
    }
  }

  Widget _bangunKartuEditorial(
    Produk produk, {
    required bool isPria,
    required bool isGrid,
  }) {
    final isFav = _wishlistIds.contains(produk.id);
    final foto = FotoDummy.untukProduk(produk);
    final colorName = isPria
        ? (produk.id % 2 == 0 ? 'Noir / Arang' : 'Deep Charcoal')
        : (produk.id % 2 == 0 ? 'Obsidian' : 'Blanc Ivoire');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanRincianProduk(produkId: produk.id),
          ),
        ).then((_) => _muatJumlahKeranjang());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: isGrid ? 3 / 4 : 4 / 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FotoDummy.bangunGambar(
                    url: foto,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    color: Colors.white.withValues(alpha: 0.9),
                    child: Text(
                      isPria ? 'EKSLUSIF ATELIER' : 'EKSKLUSIF ATELIER',
                      style: const TextStyle(
                        color: TemaAplikasi.primary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _toggleWishlist(produk),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav ? TemaAplikasi.errorColor : TemaAplikasi.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPria ? const Color(0xFF1C1B1B) : const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: TemaAplikasi.borderGray, width: 0.5),
                ),
              ),
              if (isPria) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5F5E5E),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(
                colorName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            produk.nama,
            style: TextStyle(
              fontSize: isGrid ? 14 : 17,
              fontWeight: FontWeight.w500,
              color: TemaAplikasi.primary,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            formatRupiah(produk.harga),
            style: TextStyle(
              fontSize: isGrid ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: isGrid ? 34 : 44,
            child: ElevatedButton.icon(
              onPressed: () => _tambahItemKeKeranjang(produk),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPria
                    ? TemaAplikasi.primary
                    : TemaAplikasi.surfaceContainerLow,
                foregroundColor: isPria
                    ? TemaAplikasi.onPrimary
                    : TemaAplikasi.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                isPria ? 'TAS BELANJA' : 'Tas Belanja',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isPria ? Colors.white : TemaAplikasi.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
