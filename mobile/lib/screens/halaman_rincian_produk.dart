import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/komponen_header.dart';
import '../widgets/pemilih_varian.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_keranjang.dart';
import 'halaman_login.dart';

class HalamanRincianProduk extends StatefulWidget {
  final int produkId;

  const HalamanRincianProduk({super.key, required this.produkId});

  @override
  State<HalamanRincianProduk> createState() => _HalamanRincianProdukState();
}

class _HalamanRincianProdukState extends State<HalamanRincianProduk> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  Produk? _produk;
  Varian? _varianTerpilih;
  int _jumlah = 1;
  bool _sedangMenambahkan = false;

  @override
  void initState() {
    super.initState();
    _muatRincianProduk();
  }

  Future<void> _muatRincianProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _varianTerpilih = null;
      _jumlah = 1;
    });

    final respon = await LayananApi.ambilRincianProduk(widget.produkId);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final p = Produk.fromJson(respon.data as Map<String, dynamic>);
      setState(() {
        _produk = p;
        _keadaan = KeadaanMuat.berhasil;

        // Auto pilih varian pertama yang ada stoknya jika tersedia
        if (p.varian != null && p.varian!.isNotEmpty) {
          final varianTersedia = p.varian!.where((v) => v.stok > 0);
          if (varianTersedia.isNotEmpty) {
            _varianTerpilih = varianTersedia.first;
          } else {
            _varianTerpilih = p.varian!.first;
          }
        }
      });
    } else {
      setState(() {
        _keadaan = respon.code == '404'
            ? KeadaanMuat.kosong
            : KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _tambahKeKeranjang() async {
    // Gate autentikasi: guest harus login dulu sebelum belanja
    if (!StatePengguna.isLoggedInNotifier.value) {
      await _tampilkanDialogHarusLogin();
      return;
    }

    if (_produk == null || _varianTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih varian ukuran dan warna terlebih dahulu.',
          ),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_varianTerpilih!.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Varian yang dipilih sedang habis.'),
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _sedangMenambahkan = true;
    });

    final respon = await LayananApi.tambahKeKeranjang(
      produkId: _produk!.id,
      varianId: _varianTerpilih!.id,
      jumlah: _jumlah,
    );

    if (!mounted) return;

    setState(() {
      _sedangMenambahkan = false;
    });

    if (respon.berhasil) {
      StatePengguna.sinkronkanKeranjang();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text(
  '${_produk!.nama} (${_varianTerpilih!.ukuran}, ${_varianTerpilih!.warna}) masuk ke keranjang.',
),
duration: const Duration(milliseconds: 1500),

          action: SnackBarAction(
            label: 'LIHAT',
            textColor: TemaAplikasi.surfaceWhite,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanKeranjang(),
                ),
              );
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

  Future<void> _tampilkanDialogHarusLogin() async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'Masuk Diperlukan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Silakan masuk atau daftar akun terlebih dahulu untuk menambahkan produk ke keranjang.',
          style: TextStyle(fontSize: 13, color: TemaAplikasi.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: TemaAplikasi.secondary,
            ),
            child: const Text('NANTI'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaAplikasi.primary,
              foregroundColor: TemaAplikasi.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: const Text('MASUK'),
          ),
        ],
      ),
    );

    if (lanjut == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HalamanLogin()),
      );
    }
  }

  void _kurangiJumlah() {
    if (_jumlah > 1) {
      setState(() {
        _jumlah--;
      });
    }
  }

  void _tambahJumlah() {
    final maxStok = _varianTerpilih?.stok ?? _produk?.stok ?? 99;
    if (_jumlah < maxStok) {
      setState(() {
        _jumlah++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jumlah maksimal sesuai stok varian ($maxStok).'),
          duration: const Duration(seconds: 1),
          backgroundColor: TemaAplikasi.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigasiUniversal.kembali(context),
        ),
        title: Text(
          _produk?.nama.toUpperCase() ?? 'RINCIAN PRODUK',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          TombolTasHeader(),
        ],
      ),
      body: _bangunKonten(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil && _produk != null
          ? _bangunBilahBawah()
          : null,
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.search_off_outlined,
          pesan: 'Produk tidak ditemukan atau telah dihapus.',
          saranAksi: 'Kembali ke Katalog',
          onAksi: () => Navigator.pop(context),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatRincianProduk,
        );
      case KeadaanMuat.berhasil:
        final produk = _produk!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image 3:4 Aspect Ratio (Editorial ZARA style dengan Foto Dummy)
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: TemaAplikasi.borderGray),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FotoDummy.bangunGambar(
                        url: FotoDummy.untukProduk(produk),
                        fit: BoxFit.cover,
                        fallbackWidget: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                produk.kategori.toLowerCase() == 'aksesori'
                                    ? Icons.watch_outlined
                                    : Icons.checkroom_outlined,
                                size: 80,
                                color: TemaAplikasi.mutedGray,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                produk.merek.toUpperCase(),
                                style: const TextStyle(
                                  color: TemaAplikasi.secondary,
                                  letterSpacing: 3.0,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: TemaAplikasi.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            produk.kategori.toUpperCase(),
                            style: const TextStyle(
                              color: TemaAplikasi.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          color: Colors.black.withValues(alpha: 0.5),
                          child: const Text(
                            'ME STUDIO / 2026',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Merek & Kategori Baris Halus
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    produk.merek.toUpperCase(),
                    style: const TextStyle(
                      color: TemaAplikasi.secondary,
                      letterSpacing: 2.0,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!produk.tersedia)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'TIDAK AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Nama Produk
              Text(
                produk.nama,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: TemaAplikasi.primary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),

              // Harga
              Text(
                formatRupiah(produk.harga),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 20),

              const Divider(color: TemaAplikasi.borderGray),
              const SizedBox(height: 16),

              // Atribut Khas Domain: Bahan & Spesifikasi
              Row(
                children: [
                  const Text(
                    'BAHAN',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    produk.bahan.isNotEmpty ? produk.bahan : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: TemaAplikasi.secondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deskripsi (nullable safe)
              if (produk.deskripsi != null && produk.deskripsi!.isNotEmpty) ...[
                const Text(
                  'DESKRIPSI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  produk.deskripsi!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TemaAplikasi.secondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Divider(color: TemaAplikasi.borderGray),
              const SizedBox(height: 20),

              // Pemilih Varian (Ukuran & Warna)
              if (produk.varian != null && produk.varian!.isNotEmpty) ...[
                PemilihVarian(
                  daftarVarian: produk.varian!,
                  varianTerpilih: _varianTerpilih,
                  onPilih: (varian) {
                    setState(() {
                      _varianTerpilih = varian;
                      _jumlah = 1; // reset kuantitas ke 1
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Pengatur Kuantitas
              const Text(
                'KUANTITAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: TemaAplikasi.borderGray),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: _kurangiJumlah,
                          splashRadius: 20,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_jumlah',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: TemaAplikasi.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: _tambahJumlah,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_varianTerpilih != null)
                    Text(
                      'Sisa stok: ${_varianTerpilih!.stok}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _varianTerpilih!.stok <= 3
                            ? TemaAplikasi.errorColor
                            : TemaAplikasi.secondary,
                        fontWeight: _varianTerpilih!.stok <= 3
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
    }
  }

  Widget _bangunBilahBawah() {
    final bool bisaBeli =
        _produk!.tersedia &&
        _varianTerpilih != null &&
        _varianTerpilih!.stok > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(top: BorderSide(color: TemaAplikasi.borderGray)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_sedangMenambahkan || !bisaBeli)
                ? null
                : _tambahKeKeranjang,
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaAplikasi.primary,
              disabledBackgroundColor: TemaAplikasi.surfaceContainerHigh,
              foregroundColor: TemaAplikasi.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              elevation: 0,
            ),
            child: _sedangMenambahkan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: TemaAplikasi.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    !bisaBeli ? 'VARIAN INI HABIS' : 'TAMBAH KE KERANJANG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: !bisaBeli
                          ? TemaAplikasi.mutedGray
                          : TemaAplikasi.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
