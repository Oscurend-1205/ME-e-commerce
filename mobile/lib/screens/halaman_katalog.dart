import 'dart:async';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../enums.dart';
import '../models/hero_banner.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/kartu_produk.dart';
import '../widgets/komponen_header.dart';
import '../widgets/modal_pilih_varian.dart';
import '../widgets/notifikasi_geser.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_keranjang.dart';
import 'halaman_rincian_produk.dart';

class HalamanKatalog extends StatefulWidget {
  final bool modeJelajah;
  final String? storyAwal;
  final void Function(int tabIndeks, String? storyAwal)? onPindahTab;

  const HalamanKatalog({
    super.key,
    this.modeJelajah = false,
    this.storyAwal,
    this.onPindahTab,
  });

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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

  // Hero Banner Slider
  List<HeroBannerModel> _daftarHeroBanner = [];
  int _heroBannerIndeks = 0;
  Timer? _heroBannerTimer;
  final PageController _heroBannerPageController = PageController();

  // Controller Animasi Scroll & Marquee Landing Page
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  bool _tampilkanTombolKeAtas = false;

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

  // Master Stories ME Atelier
  static final List<Map<String, dynamic>> _daftarSemuaStories = [
    {'label': 'Baru Tiba', 'foto': FotoDummy.stories[0], 'kat': null},
    {'label': 'Wanita', 'foto': FotoDummy.stories[1], 'kat': null},
    {'label': 'Pria', 'foto': FotoDummy.stories[2], 'kat': null},
    {'label': 'Aksesori', 'foto': FotoDummy.stories[3], 'kat': 'Aksesori'},
    {'label': 'Lookbook', 'foto': FotoDummy.stories[4], 'kat': null},
    {'label': 'Sale', 'foto': FotoDummy.stories[5], 'kat': null},
  ];

  // 5 Story di Jelajah — ganti dari Pria/Wanita menjadi kategori fungsional
  List<Map<String, dynamic>> get _stories {
    if (widget.modeJelajah) {
      return [
        {
          'label': 'Atasan & Kemeja',
          'foto': '${Konstan.storageUrl}/story-1.jpg',
          'kat': 'Atasan',
        },
        {
          'label': 'Bawahan & Celana',
          'foto': '${Konstan.storageUrl}/story-2.jpg',
          'kat': 'Bawahan',
        },
        {
          'label': 'Outerwear & Jas',
          'foto': '${Konstan.storageUrl}/story-3.jpg',
          'kat': 'Outerwear',
        },
        {
          'label': 'Kulit & Tas',
          'foto': '${Konstan.storageUrl}/story-4.jpg',
          'kat': 'Aksesori',
        },
      ];
    }
    return _daftarSemuaStories;
  }

  @override
  void initState() {
    super.initState();
    if (widget.modeJelajah) {
      if (widget.storyAwal == 'Semua') {
        // Dipanggil dari tombol "Jelajahi Semua Produk": tampilkan grid
        // semua produk tanpa filter editorial.
        _storyTerpilih = 'Semua';
        _kategoriTerpilih = null;
      } else {
        _storyTerpilih = widget.storyAwal ?? 'Atasan & Kemeja';
        _kategoriTerpilih = 'Atasan';
      }
      _tampilkanPencarian = false;
    } else {
      _storyTerpilih = 'Baru Tiba';
      _kategoriTerpilih = null;
      _tampilkanPencarian = false;
    }

    _scrollController.addListener(_tanganiScroll);
    WidgetsBinding.instance.addObserver(this);
    StatePengguna.versiKatalogNotifier.addListener(_muatData);
    _muatData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _muatHeroBanner();
    }
  }

  @override
  void didUpdateWidget(covariant HalamanKatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modeJelajah &&
        widget.storyAwal != null &&
        widget.storyAwal != _storyTerpilih) {
      if (widget.storyAwal == 'Semua') {
        setState(() {
          _storyTerpilih = 'Semua';
          _kategoriTerpilih = null;
        });
        _muatProduk();
      } else {
        _pilihStoryBerdasarkanLabel(widget.storyAwal!);
      }
    }
  }

  void _tanganiScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    _scrollOffset.value = offset;

    final tampilTombol = offset > 400;
    if (tampilTombol != _tampilkanTombolKeAtas) {
      setState(() {
        _tampilkanTombolKeAtas = tampilTombol;
      });
    }
  }

  @override
  void dispose() {
    _heroBannerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _heroBannerPageController.dispose();
    StatePengguna.versiKatalogNotifier.removeListener(_muatData);
    _scrollController.removeListener(_tanganiScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _cariController.dispose();
    _emailVipController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    await Future.wait([
      _muatProduk(),
      _muatJumlahKeranjang(),
      _muatHeroBanner(),
    ]);
  }

  Future<void> _muatHeroBanner() async {
    final respon = await LayananApi.ambilHeroBanner();
    if (!mounted) return;

    if (respon.berhasil && respon.data is List) {
      final list = (respon.data as List)
          .map((item) => HeroBannerModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        setState(() {
          _daftarHeroBanner = list;
          if (_heroBannerIndeks >= list.length) {
            _heroBannerIndeks = 0;
          }
        });
        if (_heroBannerPageController.hasClients) {
          _heroBannerPageController.jumpToPage(_heroBannerIndeks);
        }
        _aturTimerHeroBanner();
        return;
      }
    }

    if (_daftarHeroBanner.isEmpty) {
      setState(() {
        _daftarHeroBanner = const [
          HeroBannerModel(
            id: 1,
            judul: 'ME MINIMALISM',
            subjudul:
                'Eksplorasi siluet bersih, material linen premium, dan palet monokrom abadi.',
            tag: 'BARU TIBA // DROP 01',
            koleksi: 'ATELIER ÉDITION 2026',
            gambar: 'hero-banner.jpg',
            gambarUrl: '',
            urutan: 1,
          ),
        ];
      });
    }
    _aturTimerHeroBanner();
  }

  void _aturTimerHeroBanner() {
    _heroBannerTimer?.cancel();
    if (!mounted || _daftarHeroBanner.length <= 1) return;
    _heroBannerTimer = Timer(
      const Duration(milliseconds: 4500),
      _geserHeroBanner,
    );
  }

  Future<void> _geserHeroBanner() async {
    if (!mounted) return;
    if (!_heroBannerPageController.hasClients) {
      _aturTimerHeroBanner();
      return;
    }

    final halamanSaatIni =
        _heroBannerPageController.page?.round() ?? _heroBannerIndeks;
    final indeksBerikutnya = (halamanSaatIni + 1) % _daftarHeroBanner.length;

    try {
      await _heroBannerPageController.animateToPage(
        indeksBerikutnya,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    } finally {
      _aturTimerHeroBanner();
    }
  }

  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilProduk(
      kategori:
          (_storyTerpilih == 'Atasan & Kemeja' ||
              _storyTerpilih == 'Bawahan & Celana' ||
              _storyTerpilih == 'Outerwear & Jas' ||
              _storyTerpilih == 'Kulit & Tas')
          ? _kategoriTerpilih
          : null,
      cari: _cariController.text.trim().isEmpty
          ? null
          : _cariController.text.trim(),
    );

    if (!mounted) return;

    if (respon.berhasil) {
      final List dataRaw = respon.data is List ? respon.data as List : [];
      List<Produk> produkList = dataRaw
          .map((item) => Produk.fromJson(item as Map<String, dynamic>))
          .toList();

      // Filter khusus Story: Lookbook atau Sale
      if (_storyTerpilih == 'Sale') {
        produkList = produkList
            .where((p) => p.harga <= 150000 || p.stok < 30)
            .toList();
      }

      setState(() {
        _daftarProduk = produkList;
        _keadaan = produkList.isEmpty
            ? KeadaanMuat.kosong
            : KeadaanMuat.berhasil;
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
      StatePengguna.perbaruiJumlahKeranjang(totalItem);
    }
  }

  void _pilihKategori(String? kategori) {
    setState(() {
      _kategoriTerpilih = (kategori == null || kategori == 'Semua')
          ? null
          : kategori;
      if (_kategoriTerpilih == null) {
        _storyTerpilih = widget.modeJelajah ? 'Atasan & Kemeja' : 'Baru Tiba';
      } else if (_kategoriTerpilih == 'Atasan' ||
          _kategoriTerpilih == 'Bawahan' ||
          _kategoriTerpilih == 'Pakaian') {
        _storyTerpilih = widget.modeJelajah ? 'Atasan & Kemeja' : 'Wanita';
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

  void _pilihStoryBerdasarkanLabel(String label) {
    final story = _daftarSemuaStories.firstWhere(
      (s) => s['label'].toString().toLowerCase() == label.toLowerCase(),
      orElse: () => _daftarSemuaStories[1], // fallback ke Wanita
    );
    _pilihStory(story);
  }

  List<Produk> _dapatkanProdukBaruTiba({int batas = 4}) {
    final hasil = List<Produk>.from(_daftarProduk);
    // Urutkan dari produk paling baru (ID terbesar) dan batasi hanya beberapa produk terbaru untuk Beranda
    hasil.sort((a, b) => b.id.compareTo(a.id));
    if (hasil.length > batas) {
      return hasil.sublist(0, batas);
    }
    return hasil;
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
          StatePengguna.triggerRefreshKatalog();
          await _muatData();
          if (!mounted) return true;
          NotifikasiGeser.tampilkan(
            context,
            pesan:
                '${produk.nama} (${varian.ukuran}, ${varian.warna}) x$jumlah berhasil ditambahkan ke Tas Belanja.',
            durasi: const Duration(milliseconds: 2200),
            labelAksi: 'LIHAT',
            onAksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanKeranjang(),
                ),
              ).then((_) => _muatData());
            },
          );
          return true;
        } else {
          NotifikasiGeser.tampilkan(
            context,
            pesan: respon.message,
            warnaLatar: TemaAplikasi.errorColor,
            durasi: const Duration(milliseconds: 2200),
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
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Di Halaman Jelajah: ADA Story Circle (tanpa 'Baru Tiba')
              // Di Halaman Beranda: TIDAK ADA Story Circle
              if (widget.modeJelajah) _bangunStoryHighlights(),

              // Konten Halaman
              if (widget.modeJelajah)
                _bangunKontenJelajah()
              else
                _bangunKontenLandingPageBeranda(),
            ],
          ),
        ),
      ),
      floatingActionButton: (!widget.modeJelajah && _tampilkanTombolKeAtas)
          ? FloatingActionButton.small(
              backgroundColor: TemaAplikasi.primary,
              foregroundColor: TemaAplikasi.onPrimary,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                );
              },
              tooltip: 'Kembali ke Atas',
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
            )
          : null,
    );
  }

  Widget _bangunKontenLandingPageBeranda() {
    final produkBaruTiba = _dapatkanProdukBaruTiba();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Banner dengan Efek Animasi Scroll Parallax & Overscroll Scale
        ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (context, offset, _) => _bangunHeroBanner(offset),
        ),

        // 2. Animated Continuous Marquee Ribbon
        const _MarqueeRunningText(
          text:
              '✦ BARU TIBA DI ATELIER • EDISI TERBATAS 2026 • READY-TO-WEAR & HAUTE COUTURE • GRATIS PENGIRIMAN EKSPRES • PERSONAL STYLIST CONCIERGE ✦',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE5E2E1),
          ),
          height: 34,
        ),

        // 3. Section Koleksi Baru Tiba
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        'ÉDITION LIMITÉE // MUSIM INI',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Koleksi Baru Tiba',
                        style: TextStyle(
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
                      '${produkBaruTiba.length} ARTIKEL',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.mutedGray,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Potongan esensial modern dan siluet minimalis terkini yang baru saja mendarat di studio.',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        // 4. Grid Produk Koleksi Baru Tiba
        _bangunDaftarProdukKoleksi(produkBaruTiba),

        const SizedBox(height: 14),

        // Tombol Jelajahi Semua Produk untuk Navigasi ke Tab Jelajah
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                widget.onPindahTab?.call(1, 'Semua');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TemaAplikasi.primary, width: 1),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'JELAJAHI SEMUA PRODUK',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: TemaAplikasi.primary,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 5. Kategori Pilihan (Curated Categories 2x2 Grid)
        _bangunKategoriPilihan(),

        // 6. Manifesto Editorial Inset / Campaign Showcase
        _bangunManifestoEditorial(),

        // 7. Curated Editorial Highlight (Asymmetric Banner)
        _bangunCuratedEditorialHighlight(),

        // 8. Pelayanan & Garansi Eksklusif (Trust Badges)
        _bangunPelayananEksklusif(),

        // 9. Newsletter / VIP Club Editorial Sign-up
        _bangunNewsletterVip(),

        const SizedBox(height: 28),
      ],
    );
  }

  Widget _bangunKontenJelajah() {
    if (_tampilkanPencarian && _cariController.text.isNotEmpty) {
      return _bangunHasilPencarian();
    }

    // Navigasi gender dari Beranda tetap membuka katalog khusus Wanita/Pria
    if (_storyTerpilih == 'Wanita') {
      return _bangunKatalogWanita();
    }
    if (_storyTerpilih == 'Pria') {
      return _bangunKatalogPria();
    }

    // Semua kategori fungsional (Atasan & Kemeja, Bawahan & Celana,
    // Outerwear & Jas, Kulit & Tas) memakai daftar produk yang sama;
    // filter kategori sudah diterapkan server-side lewat _kategoriTerpilih.
    return _bangunDaftarProdukKatalog(isPria: false);
  }

  Widget _bangunHasilPencarian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HASIL PENCARIAN // "${_cariController.text}"',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                '${_daftarProduk.length} PRODUK',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
        ),
        _bangunDaftarProdukKoleksi(_daftarProduk),
      ],
    );
  }

  Widget _bangunDaftarProdukKoleksi(List<Produk> items) {
    if (_keadaan == KeadaanMuat.memuat) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: WidgetMemuat(),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: WidgetKosong(
          ikon: Icons.inventory_2_outlined,
          pesan: 'Belum ada produk untuk koleksi ini.',
          saranAksi: 'Lihat Koleksi Terbaru',
          onAksi: () => _pilihStoryBerdasarkanLabel('Wanita'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 20,
          childAspectRatio: 0.51,
        ),
        itemBuilder: (context, index) {
          final produk = items[index];
          return KartuProduk(
            produk: produk,
            isWishlist: _wishlistIds.contains(produk.id),
            onToggleWishlist: () => _toggleWishlist(produk),
            onTambahKeranjang: () => _tambahItemKeKeranjang(produk),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HalamanRincianProduk(produkId: produk.id),
                ),
              ).then((_) => _muatData());
            },
          );
        },
      ),
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

    // Header ala Tokopedia: search bar + ikon notifikasi & keranjang
    return AppBar(
      backgroundColor: TemaAplikasi.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TemaAplikasi.borderGray, width: 0.8),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _tampilkanPencarian = true;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 18,
                  color: TemaAplikasi.secondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cari produk atelier...',
                    style: TextStyle(
                      fontSize: 13,
                      color: TemaAplikasi.mutedGray,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TemaAplikasi.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Cari',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TemaAplikasi.onPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        _TombolNotifikasiHeader(),
        const TombolTasHeader(),
        const AvatarHeaderUser(),
      ],
      bottom: (!widget.modeJelajah)
          ? _HeaderScrollProgress(controller: _scrollController)
          : null,
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
                            cacheWidth: 256,
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
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? TemaAplikasi.primary
                            : TemaAplikasi.secondary,
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
  Widget _bangunHeroBanner(double posisiScroll) {
    final parallaxOffset = (posisiScroll * 0.35).clamp(0.0, 100.0);
    final overscrollScale = posisiScroll < 0
        ? (-posisiScroll / 350.0).clamp(0.0, 0.25)
        : 0.0;
    final textOpacity = (1.0 - (posisiScroll / 300.0)).clamp(0.0, 1.0);

    final jumlahBanner = _daftarHeroBanner.isNotEmpty
        ? _daftarHeroBanner.length
        : 1;
    final indeksAman = _heroBannerIndeks.clamp(0, jumlahBanner - 1);
    final bannerAktif = _daftarHeroBanner.isNotEmpty
        ? _daftarHeroBanner[indeksAman]
        : null;

    final tagText = bannerAktif?.tag.isNotEmpty == true
        ? bannerAktif!.tag
        : 'BARU TIBA // DROP 01';
    final koleksiText = bannerAktif?.koleksi.isNotEmpty == true
        ? bannerAktif!.koleksi
        : 'ATELIER ÉDITION 2026';
    final judulText = bannerAktif?.judul.isNotEmpty == true
        ? bannerAktif!.judul
        : 'ME MINIMALISM';
    final subjudulText = bannerAktif?.subjudul.isNotEmpty == true
        ? bannerAktif!.subjudul
        : 'Eksplorasi siluet bersih, material linen premium, dan palet monokrom abadi.';

    return Container(
      width: double.infinity,
      height: 440,
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(color: TemaAplikasi.primary),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto Editorial ME MINIMALISM dengan Efek Parallax Scroll & Auto-Slide Horizontal
          Transform.translate(
            offset: Offset(0, -parallaxOffset * 0.4),
            child: Transform.scale(
              scale: 1.08 + overscrollScale,
              child: PageView.builder(
                controller: _heroBannerPageController,
                itemCount: jumlahBanner,
                onPageChanged: (index) {
                  if (_heroBannerIndeks == index) return;
                  setState(() {
                    _heroBannerIndeks = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = _daftarHeroBanner.isNotEmpty
                      ? _daftarHeroBanner[index]
                      : null;
                  final url = banner != null && banner.gambarUrl.isNotEmpty
                      ? banner.gambarUrl
                      : FotoDummy.heroBanner;

                  return KeyedSubtree(
                    key: ValueKey<String>(url),
                    child: FotoDummy.bangunGambar(
                      url: url,
                      fit: BoxFit.cover,
                      cacheWidth: 1080,
                    ),
                  );
                },
              ),
            ),
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

          // Teks & Tombol Aksi Hero Banner dengan Animasi Fade saat Scroll
          Opacity(
            opacity: textOpacity,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          tagText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        koleksiText,
                        style: const TextStyle(
                          color: Color(0xFFE5E2E1),
                          fontSize: 10,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    judulText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subjudulText,
                    style: const TextStyle(
                      color: Color(0xFFE5E2E1),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Indikator Titik/Garis Animasi Slide (Jika lebih dari 1 foto)
                  if (jumlahBanner > 1)
                    Row(
                      children: List.generate(jumlahBanner, (i) {
                        final aktif = i == indeksAman;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 6),
                          width: aktif ? 24 : 6,
                          height: 3,
                          decoration: BoxDecoration(
                            color: aktif
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
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
                onTap: () {
                  if (widget.onPindahTab != null) {
                    widget.onPindahTab!(1, 'Wanita');
                  } else {
                    _pilihKategori(null);
                  }
                },
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
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: TemaAplikasi.primary,
                    ),
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
              _bangunKartuKategoriFoto(
                '01 // ESENSIAL',
                'Atasan & Kemeja',
                FotoDummy.katAtasan,
                'Atasan',
                'Wanita',
              ),
              _bangunKartuKategoriFoto(
                '02 // TAILORING',
                'Bawahan & Celana',
                FotoDummy.katBawahan,
                'Bawahan',
                'Pria',
              ),
              _bangunKartuKategoriFoto(
                '03 // SUITING',
                'Outerwear & Jas',
                FotoDummy.katOuterwear,
                'Atasan',
                'Wanita',
              ),
              _bangunKartuKategoriFoto(
                '04 // AKSESORI',
                'Kulit & Tas',
                FotoDummy.katAksesori,
                'Aksesori',
                'Aksesori',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunKartuKategoriFoto(
    String kode,
    String judul,
    String urlFoto,
    String targetKat,
    String targetStory,
  ) {
    return InkWell(
      onTap: () {
        if (widget.onPindahTab != null) {
          widget.onPindahTab!(1, targetStory);
        } else {
          _pilihStoryBerdasarkanLabel(targetStory);
        }
      },
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
              cacheWidth: 720,
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
                cacheWidth: 1080,
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
          _pilihKategori('Atasan');
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
                  cacheWidth: 1080,
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
        border: Border.all(
          color: TemaAplikasi.borderGray.withValues(alpha: 0.7),
        ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaAplikasi.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan alamat email Anda',
                      hintStyle: const TextStyle(
                        color: TemaAplikasi.mutedGray,
                        fontSize: 12,
                      ),
                      fillColor: TemaAplikasi.surfaceContainerLow,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
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
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('coat') ||
              s.contains('mantel') ||
              s.contains('outer') ||
              s.contains('jaket') ||
              s.contains('blazer');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'SUITING & TAILORED') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('suit') ||
              s.contains('setelan') ||
              s.contains('blazer') ||
              s.contains('tailor') ||
              s.contains('celana');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'SILK & DRESSES') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('gaun') ||
              s.contains('dress') ||
              s.contains('sutra') ||
              s.contains('silk') ||
              s.contains('rok');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriWanita == 'KNITWEAR KASMIR') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('rajut') ||
              s.contains('knit') ||
              s.contains('kasmir') ||
              s.contains('sweater') ||
              s.contains('syal');
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
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('blazer') ||
              s.contains('jas') ||
              s.contains('suit') ||
              s.contains('setelan');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'KEMEJA & SHIRTING') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('kemeja') ||
              s.contains('shirt') ||
              s.contains('poplin') ||
              s.contains('atasan');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'MANTEL') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('mantel') ||
              s.contains('coat') ||
              s.contains('outer') ||
              s.contains('jaket');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'KNITWEAR') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('rajut') ||
              s.contains('knit') ||
              s.contains('sweater') ||
              s.contains('kasmir');
        }).toList();
        if (f.isNotEmpty) hasil = f;
      } else if (_subKategoriPria == 'CELANA TAILORED') {
        final f = hasil.where((p) {
          final s = '${p.nama} ${p.deskripsi ?? ''} ${p.kategori}'
              .toLowerCase();
          return s.contains('celana') ||
              s.contains('trouser') ||
              s.contains('pant') ||
              s.contains('pleat');
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                        fontWeight: terpilih
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: terpilih
                            ? TemaAplikasi.primary
                            : TemaAplikasi.secondary,
                      ),
                    ),
                    trailing: terpilih
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: TemaAplikasi.primary,
                          )
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
                    bottom: BorderSide(
                      color: TemaAplikasi.borderGray,
                      width: 0.8,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
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
                horizontal: BorderSide(
                  color: TemaAplikasi.borderGray,
                  width: 0.8,
                ),
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
                      const Icon(
                        Icons.expand_more,
                        size: 16,
                        color: TemaAplikasi.primary,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      color: _modeGrid
                          ? TemaAplikasi.primary
                          : TemaAplikasi.mutedGray,
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
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      color: !_modeGrid
                          ? TemaAplikasi.primary
                          : TemaAplikasi.mutedGray,
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
                    bottom: BorderSide(
                      color: TemaAplikasi.borderGray,
                      width: 0.8,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
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
                horizontal: BorderSide(
                  color: TemaAplikasi.borderGray,
                  width: 0.8,
                ),
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
                      const Icon(
                        Icons.expand_more,
                        size: 16,
                        color: TemaAplikasi.primary,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      color: _modeGrid
                          ? TemaAplikasi.primary
                          : TemaAplikasi.mutedGray,
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
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      color: !_modeGrid
                          ? TemaAplikasi.primary
                          : TemaAplikasi.mutedGray,
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
                return _bangunKartuEditorial(
                  produk,
                  isPria: isPria,
                  isGrid: true,
                );
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
                return _bangunKartuEditorial(
                  produk,
                  isPria: isPria,
                  isGrid: false,
                );
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
        ).then((_) => _muatData());
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
                    cacheWidth: 1080,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
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
                        color: isFav
                            ? TemaAplikasi.errorColor
                            : TemaAplikasi.primary,
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
                  color: isPria
                      ? const Color(0xFF1C1B1B)
                      : const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TemaAplikasi.borderGray,
                    width: 0.5,
                  ),
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

/// Banner Teks Berjalan Animasi Kontinu (Marquee Running Ribbon)
class _MarqueeRunningText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double height;

  const _MarqueeRunningText({
    required this.text,
    required this.style,
    this.height = 36,
  });

  @override
  State<_MarqueeRunningText> createState() => _MarqueeRunningTextState();
}

class _MarqueeRunningTextState extends State<_MarqueeRunningText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 250))
          ..addListener(() {
            if (!mounted) return;
            if (_scrollController.hasClients &&
                _scrollController.position.hasContentDimensions) {
              final max = _scrollController.position.maxScrollExtent;
              if (max.isFinite && max > 0) {
                final target = _animController.value * max;
                if (target.isFinite) {
                  _scrollController.jumpTo(target);
                }
              }
            }
          });
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: TemaAplikasi.primary,
      alignment: Alignment.center,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: 15,
        itemBuilder: (context, index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.text, style: widget.style),
                  const SizedBox(width: 20),
                  const Icon(Icons.circle, size: 4, color: Colors.white54),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Progress bar scroll di header yang hanya me-rebuild dirinya sendiri,
/// sehingga offset scroll tidak memicu rebuild seluruh halaman.
class _HeaderScrollProgress extends StatefulWidget
    implements PreferredSizeWidget {
  const _HeaderScrollProgress({required this.controller});

  final ScrollController controller;

  @override
  Size get preferredSize => const Size.fromHeight(2);

  @override
  State<_HeaderScrollProgress> createState() => _HeaderScrollProgressState();
}

class _HeaderScrollProgressState extends State<_HeaderScrollProgress> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_perbarui);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_perbarui);
    super.dispose();
  }

  void _perbarui() {
    if (!mounted || !widget.controller.hasClients) return;
    final maxScroll = widget.controller.position.maxScrollExtent;
    final progress = maxScroll > 0
        ? (widget.controller.offset / maxScroll).clamp(0.0, 1.0)
        : 0.0;
    if ((progress - _progress).abs() > 0.005) {
      setState(() => _progress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_progress <= 0) return const SizedBox(height: 2);
    return LinearProgressIndicator(
      value: _progress,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(TemaAplikasi.primary),
      minHeight: 2,
    );
  }
}

/// Tombol lonceng notifikasi dengan titik indikator badge kecil.
/// Menggantikan ikon chat pada header ala Tokopedia.
class _TombolNotifikasiHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada notifikasi baru.'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: TemaAplikasi.primary,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: TemaAplikasi.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TemaAplikasi.surfaceWhite,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
