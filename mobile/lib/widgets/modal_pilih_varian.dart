import 'package:flutter/material.dart';

import '../models/keranjang.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import 'format_rupiah.dart';
import 'foto_dummy.dart';

enum ModeModalVarian { tambah, ubah }

/// Modal Bottom Sheet Editorial ME Atelier untuk pemilihan Ukuran, Warna, dan Jumlah
/// Dapat digunakan untuk Tambah ke Keranjang dari Beranda/Katalog atau Edit di Keranjang
class ModalPilihVarian extends StatefulWidget {
  final Produk? produk;
  final int? produkId;
  final ModeModalVarian mode;
  final Varian? varianAwal;
  final String? ukuranAwal;
  final String? warnaAwal;
  final int jumlahAwal;
  final Future<bool> Function(Varian varian, int jumlah) onKonfirmasi;

  const ModalPilihVarian({
    super.key,
    this.produk,
    this.produkId,
    this.mode = ModeModalVarian.tambah,
    this.varianAwal,
    this.ukuranAwal,
    this.warnaAwal,
    this.jumlahAwal = 1,
    required this.onKonfirmasi,
  }) : assert(produk != null || produkId != null, 'Produk atau produkId harus disediakan');

  /// Helper statis untuk menampilkan modal Tambah ke Keranjang
  static Future<bool?> tampilkanTambah(
    BuildContext context, {
    required Produk produk,
    Varian? varianAwal,
    int jumlahAwal = 1,
    required Future<bool> Function(Varian varian, int jumlah) onKonfirmasi,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalPilihVarian(
        produk: produk,
        mode: ModeModalVarian.tambah,
        varianAwal: varianAwal,
        jumlahAwal: jumlahAwal,
        onKonfirmasi: onKonfirmasi,
      ),
    );
  }

  /// Helper statis untuk menampilkan modal Ubah Varian & Jumlah di Keranjang
  static Future<bool?> tampilkanUbah(
    BuildContext context, {
    required ItemKeranjang item,
    required Future<bool> Function(Varian varian, int jumlah) onKonfirmasi,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalPilihVarian(
        produkId: item.produkId,
        mode: ModeModalVarian.ubah,
        ukuranAwal: item.ukuran,
        warnaAwal: item.warna,
        jumlahAwal: item.jumlah,
        onKonfirmasi: onKonfirmasi,
      ),
    );
  }

  @override
  State<ModalPilihVarian> createState() => _ModalPilihVarianState();
}

class _ModalPilihVarianState extends State<ModalPilihVarian> {
  Produk? _produk;
  bool _memuatProduk = false;
  String? _pesanGalatProduk;

  List<Varian> _daftarVarian = [];
  String? _ukuranTerpilih;
  String? _warnaTerpilih;
  int _jumlah = 1;

  bool _sedangMemproses = false;
  String? _pesanGalatAksi;

  @override
  void initState() {
    super.initState();
    _jumlah = widget.jumlahAwal > 0 ? widget.jumlahAwal : 1;
    _ukuranTerpilih = widget.ukuranAwal ?? widget.varianAwal?.ukuran;
    _warnaTerpilih = widget.warnaAwal ?? widget.varianAwal?.warna;

    if (widget.produk != null) {
      _produk = widget.produk;
      if (_produk!.varian != null && _produk!.varian!.isNotEmpty) {
        _daftarVarian = _produk!.varian!;
        _inisialisasiPilihanAwal();
      } else {
        _ambilRincianProduk(_produk!.id);
      }
    } else if (widget.produkId != null) {
      _ambilRincianProduk(widget.produkId!);
    }
  }

  Future<void> _ambilRincianProduk(int produkId) async {
    setState(() {
      _memuatProduk = true;
      _pesanGalatProduk = null;
    });

    final respon = await LayananApi.ambilRincianProduk(produkId);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final p = Produk.fromJson(respon.data as Map<String, dynamic>);
      setState(() {
        _produk = p;
        _daftarVarian = p.varian ?? [];
        _memuatProduk = false;
        _inisialisasiPilihanAwal();
      });
    } else {
      setState(() {
        _memuatProduk = false;
        _pesanGalatProduk = respon.message.isNotEmpty
            ? respon.message
            : 'Gagal memuat varian produk.';
      });
    }
  }

  void _inisialisasiPilihanAwal() {
    if (_daftarVarian.isEmpty) return;

    // Jika sudah ada ukuran dan warna awal, pastikan valid
    if (_ukuranTerpilih != null && _warnaTerpilih != null) {
      final ada = _daftarVarian.any(
        (v) => v.ukuran == _ukuranTerpilih && v.warna == _warnaTerpilih,
      );
      if (ada) return;
    }

    // Jika belum dipilih, coba pilih varian pertama yang stok > 0
    final varianTersedia = _daftarVarian.firstWhere(
      (v) => v.stok > 0,
      orElse: () => _daftarVarian.first,
    );

    setState(() {
      _ukuranTerpilih = varianTersedia.ukuran;
      _warnaTerpilih = varianTersedia.warna;
    });
  }

  List<String> get _daftarUkuran {
    final setUkuran = <String>{};
    for (final v in _daftarVarian) {
      setUkuran.add(v.ukuran);
    }
    return setUkuran.toList();
  }

  List<String> get _daftarWarna {
    final setWarna = <String>{};
    final sumber = _ukuranTerpilih != null
        ? _daftarVarian.where((v) => v.ukuran == _ukuranTerpilih)
        : _daftarVarian;
    for (final v in sumber) {
      setWarna.add(v.warna);
    }
    return setWarna.toList();
  }

  bool _ukuranHabis(String ukuran) {
    return _daftarVarian
        .where((v) => v.ukuran == ukuran)
        .every((v) => v.stok == 0);
  }

  bool _warnaHabis(String warna) {
    final sumber = _ukuranTerpilih != null
        ? _daftarVarian.where(
            (v) => v.ukuran == _ukuranTerpilih && v.warna == warna,
          )
        : _daftarVarian.where((v) => v.warna == warna);
    if (sumber.isEmpty) return true;
    return sumber.every((v) => v.stok == 0);
  }

  Varian? get _varianCocok {
    if (_ukuranTerpilih == null || _warnaTerpilih == null) return null;
    try {
      return _daftarVarian.firstWhere(
        (v) => v.ukuran == _ukuranTerpilih && v.warna == _warnaTerpilih,
      );
    } catch (_) {
      return null;
    }
  }

  void _pilihUkuran(String ukuran) {
    setState(() {
      _ukuranTerpilih = ukuran;
      _pesanGalatAksi = null;
      // Jika warna sebelumnya tidak tersedia di ukuran baru, pilih warna pertama yang tersedia
      if (_warnaTerpilih != null) {
        final cocok = _daftarVarian.any(
          (v) => v.ukuran == ukuran && v.warna == _warnaTerpilih,
        );
        if (!cocok) {
          final opsiWarna = _daftarVarian
              .where((v) => v.ukuran == ukuran)
              .map((v) => v.warna)
              .toList();
          _warnaTerpilih = opsiWarna.isNotEmpty ? opsiWarna.first : null;
        }
      } else {
        final opsiWarna = _daftarVarian
            .where((v) => v.ukuran == ukuran)
            .map((v) => v.warna)
            .toList();
        _warnaTerpilih = opsiWarna.isNotEmpty ? opsiWarna.first : null;
      }

      // Pastikan kuantitas tidak melebihi stok varian baru
      final v = _varianCocok;
      if (v != null && v.stok > 0 && _jumlah > v.stok) {
        _jumlah = v.stok;
      }
    });
  }

  void _pilihWarna(String warna) {
    setState(() {
      _warnaTerpilih = warna;
      _pesanGalatAksi = null;
      final v = _varianCocok;
      if (v != null && v.stok > 0 && _jumlah > v.stok) {
        _jumlah = v.stok;
      }
    });
  }

  void _tambahJumlah() {
    final v = _varianCocok;
    final maxStok = v != null ? v.stok : 99;
    if (_jumlah < maxStok) {
      setState(() {
        _jumlah++;
        _pesanGalatAksi = null;
      });
    }
  }

  void _kurangJumlah() {
    if (_jumlah > 1) {
      setState(() {
        _jumlah--;
        _pesanGalatAksi = null;
      });
    }
  }

  Future<void> _kirimAksi() async {
    final v = _varianCocok;
    if (v == null) {
      setState(() {
        _pesanGalatAksi = 'Silakan pilih ukuran dan warna terlebih dahulu.';
      });
      return;
    }

    if (v.stok <= 0) {
      setState(() {
        _pesanGalatAksi = 'Stok untuk ukuran $v.ukuran warna $v.warna sedang habis.';
      });
      return;
    }

    if (_jumlah > v.stok) {
      setState(() {
        _pesanGalatAksi = 'Jumlah diminta ($_jumlah) melebihi stok tersedia (${v.stok}).';
      });
      return;
    }

    setState(() {
      _sedangMemproses = true;
      _pesanGalatAksi = null;
    });

    final berhasil = await widget.onKonfirmasi(v, _jumlah);

    if (!mounted) return;

    setState(() {
      _sedangMemproses = false;
    });

    if (berhasil) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produk = _produk;
    final varian = _varianCocok;
    final stokTersedia = varian != null && varian.stok > 0;
    final totalHarga = produk != null ? produk.harga * _jumlah : 0;

    return Container(
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: TemaAplikasi.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Modal: Judul & Tombol Tutup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.mode == ModeModalVarian.ubah
                        ? 'UBAH VARIAN ITEM'
                        : 'PILIH VARIAN PRODUK',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    color: TemaAplikasi.primary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.8, color: TemaAplikasi.borderGray),

            // Content Body
            if (_memuatProduk)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ),
              )
            else if (_pesanGalatProduk != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 36, color: TemaAplikasi.errorColor),
                      const SizedBox(height: 10),
                      Text(
                        _pesanGalatProduk!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, color: TemaAplikasi.secondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          if (widget.produk != null) {
                            _ambilRincianProduk(widget.produk!.id);
                          } else if (widget.produkId != null) {
                            _ambilRincianProduk(widget.produkId!);
                          }
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (produk != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ringkasan Produk Header (Thumbnail + Merek + Nama + Harga)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 68,
                            height: 88,
                            decoration: BoxDecoration(
                              color: TemaAplikasi.surfaceContainer,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: TemaAplikasi.borderGray, width: 0.6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FotoDummy.bangunGambar(
                              url: produk.fotoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produk.merek.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: TemaAplikasi.secondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  produk.nama,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TemaAplikasi.primary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatRupiah(produk.harga),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: TemaAplikasi.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.8, color: TemaAplikasi.borderGray),
                      const SizedBox(height: 16),

                      // 1. Pemilih Ukuran
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'UKURAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          if (_ukuranTerpilih != null)
                            Text(
                              'Terpilih: $_ukuranTerpilih',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _daftarUkuran.map((ukuran) {
                          final dipilih = _ukuranTerpilih == ukuran;
                          final habis = _ukuranHabis(ukuran);

                          return InkWell(
                            onTap: habis ? null : () => _pilihUkuran(ukuran),
                            borderRadius: BorderRadius.circular(2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: habis
                                    ? TemaAplikasi.surfaceContainerLow
                                    : (dipilih ? TemaAplikasi.primary : TemaAplikasi.surfaceWhite),
                                border: Border.all(
                                  color: habis
                                      ? TemaAplikasi.borderGray
                                      : (dipilih ? TemaAplikasi.primary : TemaAplikasi.borderGray),
                                  width: dipilih ? 1.2 : 0.8,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                ukuran,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
                                  decoration: habis ? TextDecoration.lineThrough : null,
                                  color: habis
                                      ? TemaAplikasi.mutedGray
                                      : (dipilih ? TemaAplikasi.onPrimary : TemaAplikasi.primary),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 2. Pemilih Warna
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'WARNA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          if (_warnaTerpilih != null)
                            Text(
                              _warnaTerpilih!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _daftarWarna.map((warna) {
                          final dipilih = _warnaTerpilih == warna;
                          final habis = _warnaHabis(warna);

                          return InkWell(
                            onTap: habis ? null : () => _pilihWarna(warna),
                            borderRadius: BorderRadius.circular(2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: habis
                                    ? TemaAplikasi.surfaceContainerLow
                                    : (dipilih ? TemaAplikasi.primary : TemaAplikasi.surfaceWhite),
                                border: Border.all(
                                  color: habis
                                      ? TemaAplikasi.borderGray
                                      : (dipilih ? TemaAplikasi.primary : TemaAplikasi.borderGray),
                                  width: dipilih ? 1.2 : 0.8,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: habis
                                          ? TemaAplikasi.mutedGray
                                          : (dipilih ? TemaAplikasi.onPrimary : TemaAplikasi.primary),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    warna,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
                                      decoration: habis ? TextDecoration.lineThrough : null,
                                      color: habis
                                          ? TemaAplikasi.mutedGray
                                          : (dipilih ? TemaAplikasi.onPrimary : TemaAplikasi.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 3. Status Stok & Kuantitas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status Stok
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STATUS STOK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: TemaAplikasi.secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (varian != null)
                                Row(
                                  children: [
                                    Icon(
                                      stokTersedia ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      size: 14,
                                      color: stokTersedia ? Colors.green.shade700 : TemaAplikasi.errorColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      stokTersedia
                                          ? 'Tersedia: ${varian.stok} unit'
                                          : 'Stok varian ini habis',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: stokTersedia ? Colors.green.shade800 : TemaAplikasi.errorColor,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Text(
                                  'Pilih ukuran & warna',
                                  style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
                                ),
                            ],
                          ),

                          // Pengatur Kuantitas (Stepper)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'KUANTITAS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: TemaAplikasi.secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: TemaAplikasi.surfaceLight,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: TemaAplikasi.borderGray),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: stokTersedia && _jumlah > 1 ? _kurangJumlah : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Icon(
                                          Icons.remove,
                                          size: 15,
                                          color: stokTersedia && _jumlah > 1
                                              ? TemaAplikasi.primary
                                              : TemaAplikasi.mutedGray,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$_jumlah',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: stokTersedia
                                              ? TemaAplikasi.primary
                                              : TemaAplikasi.mutedGray,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: stokTersedia && _jumlah < varian.stok
                                          ? _tambahJumlah
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Icon(
                                          Icons.add,
                                          size: 15,
                                          color: stokTersedia && _jumlah < varian.stok
                                              ? TemaAplikasi.primary
                                              : TemaAplikasi.mutedGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Pesan Galat Aksi (jika ada)
                      if (_pesanGalatAksi != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: TemaAplikasi.errorColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: TemaAplikasi.errorColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: TemaAplikasi.errorColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pesanGalatAksi!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: TemaAplikasi.errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

            // Tombol Aksi Bawah Sticky
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: TemaAplikasi.surfaceWhite,
                border: Border(
                  top: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: (!stokTersedia || _sedangMemproses || _memuatProduk)
                      ? null
                      : _kirimAksi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaAplikasi.primary,
                    foregroundColor: TemaAplikasi.onPrimary,
                    disabledBackgroundColor: TemaAplikasi.surfaceContainer,
                    disabledForegroundColor: TemaAplikasi.mutedGray,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: _sedangMemproses
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.mode == ModeModalVarian.ubah
                                  ? Icons.check
                                  : Icons.shopping_bag_outlined,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              !stokTersedia
                                  ? (varian != null && varian.stok == 0
                                      ? 'STOK VARIAN HABIS'
                                      : 'PILIH UKURAN & WARNA')
                                  : (widget.mode == ModeModalVarian.ubah
                                      ? 'SIMPAN PERUBAHAN VARIAN'
                                      : 'TAMBAH KE TAS BELANJA • ${formatRupiah(totalHarga)}'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
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
