import 'package:flutter/material.dart';

import '../constants.dart';
import '../enums.dart';
import '../models/keranjang.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_checkout.dart';

class HalamanKeranjang extends StatefulWidget {
  const HalamanKeranjang({super.key});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  DataKeranjang? _dataKeranjang;
  bool _sedangMemperbarui = false;

  // State Pilihan Item (Checkbox per item & Pilih Semua)
  final Set<int> _itemTerpilihIds = {};

  // State Voucher Promo
  final TextEditingController _voucherController = TextEditingController(text: 'MEVIP-150');
  bool _voucherDiterapkan = true;
  final int _potonganVoucher = 150000;

  // Ambang batas Bebas Ongkir Kilat Atelier (Rp 1.500.000)
  static const int _ambangBebasOngkir = 1500000;

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _muatKeranjang() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilKeranjang();

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final data = DataKeranjang.fromJson(respon.data as Map<String, dynamic>);
      setState(() {
        _dataKeranjang = data;
        _keadaan = data.items.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
        // Default: semua item otomatis terpilih saat pertama dimuat
        _itemTerpilihIds.clear();
        for (final item in data.items) {
          _itemTerpilihIds.add(item.id);
        }
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _ubahJumlah(ItemKeranjang item, int jumlahBaru) async {
    if (jumlahBaru < 1) return;

    setState(() {
      _sedangMemperbarui = true;
    });

    final respon = await LayananApi.ubahJumlahKeranjang(item.id, jumlahBaru);

    if (!mounted) return;

    setState(() {
      _sedangMemperbarui = false;
    });

    if (respon.berhasil) {
      _muatKeranjang();
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

  Future<void> _hapusItem(ItemKeranjang item) async {
    final konfirmasi = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Hapus Item',
      pesan: 'Apakah Anda yakin ingin menghapus "${item.namaProduk}" (${item.ukuran}, ${item.warna}) dari tas belanja?',
      teksKonfirmasi: 'HAPUS',
      warnaKonfirmasi: TemaAplikasi.errorColor,
    );

    if (!konfirmasi || !mounted) return;

    setState(() {
      _sedangMemperbarui = true;
    });

    final respon = await LayananApi.hapusDariKeranjang(item.id);

    if (!mounted) return;

    setState(() {
      _sedangMemperbarui = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item berhasil dihapus dari tas belanja.'),
          duration: Duration(milliseconds: 1500),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatKeranjang();
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

  Future<void> _kosongkanKeranjang() async {
    if (_dataKeranjang == null || _dataKeranjang!.items.isEmpty) return;

    final konfirmasi = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Kosongkan Tas Belanja',
      pesan: 'Apakah Anda yakin ingin menghapus semua item dari tas belanja?',
      teksKonfirmasi: 'KOSONGKAN',
      warnaKonfirmasi: TemaAplikasi.errorColor,
    );

    if (!konfirmasi || !mounted) return;

    setState(() {
      _sedangMemperbarui = true;
    });

    for (final item in _dataKeranjang!.items) {
      await LayananApi.hapusDariKeranjang(item.id);
    }

    if (!mounted) return;

    setState(() {
      _sedangMemperbarui = false;
    });

    _muatKeranjang();
  }

  void _pindahKeWishlist(ItemKeranjang item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.namaProduk} dipindahkan ke Wishlist.')),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _terapkanVoucher() {
    final kode = _voucherController.text.trim();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (kode.isEmpty) {
      setState(() {
        _voucherDiterapkan = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher dibatalkan.'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _voucherDiterapkan = true;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode promo MEVIP-150 berhasil diterapkan! Potongan Rp 150.000.'),
        duration: Duration(milliseconds: 1500),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Perhitungan Subtotal dan Diskon
  int get _subtotalTerpilih {
    if (_dataKeranjang == null) return 0;
    return _dataKeranjang!.items
        .where((i) => _itemTerpilihIds.contains(i.id))
        .fold<int>(0, (sum, i) => sum + i.subtotalItem);
  }

  int get _jumlahItemTerpilih {
    if (_dataKeranjang == null) return 0;
    return _dataKeranjang!.items
        .where((i) => _itemTerpilihIds.contains(i.id))
        .fold<int>(0, (sum, i) => sum + i.jumlah);
  }

  int get _diskonAktif {
    if (!_voucherDiterapkan || _subtotalTerpilih == 0) return 0;
    return _subtotalTerpilih > _potonganVoucher ? _potonganVoucher : _subtotalTerpilih;
  }

  int get _totalEstimasi {
    final total = _subtotalTerpilih - _diskonAktif;
    return total > 0 ? total : 0;
  }

  double get _persentaseBebasOngkir {
    if (_subtotalTerpilih >= _ambangBebasOngkir) return 1.0;
    return (_subtotalTerpilih / _ambangBebasOngkir).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final totalSemuaItem = _dataKeranjang?.items.length ?? 0;

    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: _bangunHeaderUtama(totalSemuaItem),
      body: Stack(
        children: [
          RefreshIndicator(
            color: TemaAplikasi.primary,
            onRefresh: _muatKeranjang,
            child: _bangunKonten(),
          ),
          if (_sedangMemperbarui)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: TemaAplikasi.primary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil &&
              _dataKeranjang != null &&
              _dataKeranjang!.items.isNotEmpty
          ? _bangunStickyBottomBar()
          : null,
    );
  }

  // 1. Header Utama Sesuai cek-keranjangBelanja.html
  PreferredSizeWidget _bangunHeaderUtama(int totalItem) {
    return AppBar(
      backgroundColor: TemaAplikasi.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 22, color: TemaAplikasi.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text(
            'ME',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'STUDIO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: TemaAplikasi.secondary,
            ),
          ),
          const Spacer(),
          const Text(
            'TAS BELANJA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: TemaAplikasi.primary,
            ),
          ),
          const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_outlined, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Membuka koleksi Wishlist ME Studio.'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag, size: 22),
              onPressed: () {},
            ),
            if (totalItem > 0)
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
                    '$totalItem',
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
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.shopping_bag_outlined,
          pesan: 'Tas belanja Anda masih kosong.',
          saranAksi: 'Lihat Koleksi Terbaru ME',
          onAksi: () => Navigator.pop(context),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatKeranjang,
        );
      case KeadaanMuat.berhasil:
        final items = _dataKeranjang!.items;
        final semuaTerpilih = items.isNotEmpty && _itemTerpilihIds.length == items.length;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub-Bar: Judul Halaman + Tombol Kosongkan (cek-keranjangBelanja.html)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Tas Belanja',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${items.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _kosongkanKeranjang,
                      borderRadius: BorderRadius.circular(2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: const [
                            Icon(Icons.delete_sweep_outlined, size: 16, color: TemaAplikasi.secondary),
                            SizedBox(width: 4),
                            Text(
                              'KOSONGKAN',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indikator Bebas Ongkir Kilat Atelier (cek-keranjangBelanja.html)
              _bangunNotifikasiBebasOngkir(),

              // Batch Controls (Pilih Semua & Kirim Hari Ini) (cek-keranjangBelanja.html)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (semuaTerpilih) {
                            _itemTerpilihIds.clear();
                          } else {
                            _itemTerpilihIds.clear();
                            for (final item in items) {
                              _itemTerpilihIds.add(item.id);
                            }
                          }
                        });
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: semuaTerpilih,
                              activeColor: TemaAplikasi.primary,
                              checkColor: Colors.white,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    for (final item in items) {
                                      _itemTerpilihIds.add(item.id);
                                    }
                                  } else {
                                    _itemTerpilihIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PILIH SEMUA (${items.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: TemaAplikasi.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.schedule, size: 15, color: TemaAplikasi.secondary),
                        SizedBox(width: 4),
                        Text(
                          'Kirim Hari Ini',
                          style: TextStyle(
                            fontSize: 11,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Daftar Item Keranjang (cek-keranjangBelanja.html)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _bangunKartuItem(items[index]),
              ),

              // Cross-sell Carousel: Sempurnakan Tampilan (cek-keranjangBelanja.html)
              _bangunCrossSellCarousel(),

              // Voucher & Kode Promosi (cek-keranjangBelanja.html)
              _bangunVoucherInput(),

              // Ringkasan Pesanan (cek-keranjangBelanja.html)
              _bangunRingkasanPesanan(),

              // Jaminan Keaslian & Retur (cek-keranjangBelanja.html)
              _bangunJaminanAtelier(),

              const SizedBox(height: 20),
            ],
          ),
        );
    }
  }

  // 2. Indikator Bebas Ongkir Kilat Atelier
  Widget _bangunNotifikasiBebasOngkir() {
    final kekurangan = _ambangBebasOngkir - _subtotalTerpilih;
    final tercapai = _persentaseBebasOngkir >= 1.0;
    final persenTeks = '${(_persentaseBebasOngkir * 100).toInt()}%';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceLight,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_shipping_outlined, size: 18, color: TemaAplikasi.primary),
                  SizedBox(width: 8),
                  Text(
                    'Bebas Ongkir Kilat Atelier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              Text(
                persenTeks,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tercapai
                ? 'Kualifikasi kurir prioritas tanpa biaya telah terpenuhi.'
                : 'Tambahkan ${formatRupiah(kekurangan)} lagi untuk kualifikasi kurir prioritas tanpa biaya.',
            style: const TextStyle(
              fontSize: 11.5,
              color: TemaAplikasi.secondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: _persentaseBebasOngkir,
              backgroundColor: TemaAplikasi.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(TemaAplikasi.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Kartu Item Keranjang (cek-keranjangBelanja.html)
  Widget _bangunKartuItem(ItemKeranjang item) {
    final isTerpilih = _itemTerpilihIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Item
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: isTerpilih,
                    activeColor: TemaAplikasi.primary,
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _itemTerpilihIds.add(item.id);
                        } else {
                          _itemTerpilihIds.remove(item.id);
                        }
                      });
                    },
                  ),
                ),
              ),

              // Foto Item Rasio 3:4 dari Backend Storage
              Container(
                width: 82,
                height: 110,
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
                clipBehavior: Clip.antiAlias,
                child: FotoDummy.bangunGambar(
                  url: item.gambar != null && item.gambar!.isNotEmpty
                      ? '${Konstan.storageUrl}/${item.gambar}'
                      : '${Konstan.storageUrl}/${item.produkId}.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Info & Aksi Item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label Koleksi & Tombol Hapus (delete_outline)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ATELIER ME · FW24',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        InkWell(
                          onTap: () => _hapusItem(item),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Nama Produk
                    Text(
                      item.namaProduk,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: TemaAplikasi.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Varian: Warna & Ukuran
                    Row(
                      children: [
                        Text(
                          item.warna,
                          style: const TextStyle(
                            fontSize: 11,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: TemaAplikasi.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Size ${item.ukuran}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Baris Harga & Pengatur Kuantitas (Stepper)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatRupiah(item.hargaSatuan),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),

                        // Stepper Kuantitas Kompak Sesuai cek-keranjangBelanja.html
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: TemaAplikasi.surfaceLight,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: TemaAplikasi.borderGray),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: item.jumlah > 1
                                    ? () => _ubahJumlah(item, item.jumlah - 1)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  child: Icon(
                                    Icons.remove,
                                    size: 13,
                                    color: item.jumlah > 1
                                        ? TemaAplikasi.primary
                                        : TemaAplikasi.mutedGray,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${item.jumlah}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TemaAplikasi.primary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _ubahJumlah(item, item.jumlah + 1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  child: const Icon(
                                    Icons.add,
                                    size: 13,
                                    color: TemaAplikasi.primary,
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
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub-Aksi: Pindah ke Wishlist (cek-keranjangBelanja.html)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _pindahKeWishlist(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.favorite_border, size: 14, color: TemaAplikasi.secondary),
                      SizedBox(width: 4),
                      Text(
                        'PINDAH KE WISHLIST',
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Cross-sell Carousel: Sempurnakan Tampilan (cek-keranjangBelanja.html)
  Widget _bangunCrossSellCarousel() {
    return Container(
      width: double.infinity,
      color: TemaAplikasi.surfaceLight,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEMPURNAKAN TAMPILAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lengkapi Koleksi Anda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '2 Pilihan',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Carousel horizontal dua produk pelengkap
          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _bangunKartuUpsell(
                  nama: 'Silk Neck Scarf',
                  harga: 320000,
                  tag: 'PELENGKAP',
                  fotoUrl: FotoDummy.upsell1,
                  produkId: 12,
                ),
                const SizedBox(width: 12),
                _bangunKartuUpsell(
                  nama: 'Wide-Leg Trousers',
                  harga: 890000,
                  tag: 'SET PASANGAN',
                  fotoUrl: FotoDummy.upsell2,
                  produkId: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunKartuUpsell({
    required String nama,
    required int harga,
    required String tag,
    required String fotoUrl,
    required int produkId,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FotoDummy.bangunGambar(
                    url: fotoUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: TemaAplikasi.primary,
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: TemaAplikasi.onPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            formatRupiah(harga),
            style: const TextStyle(
              fontSize: 11.5,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: () async {
                final responDetail = await LayananApi.ambilRincianProduk(produkId);
                int? varianId;
                if (responDetail.berhasil && responDetail.data != null) {
                  final p = responDetail.data as Map<String, dynamic>;
                  final listVarian = p['varians'] as List?;
                  if (listVarian != null && listVarian.isNotEmpty) {
                    varianId = listVarian.first['id'] as int?;
                  }
                }
                if (varianId != null) {
                  await LayananApi.tambahKeKeranjang(
                    produkId: produkId,
                    varianId: varianId,
                    jumlah: 1,
                  );
                  _muatKeranjang();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$nama berhasil ditambahkan ke tas belanja!'),
                      duration: const Duration(milliseconds: 1500),
                      backgroundColor: TemaAplikasi.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add, size: 13),
              label: const Text(
                'TAMBAH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Voucher & Privilege Code Input (cek-keranjangBelanja.html)
  Widget _bangunVoucherInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'KODE PROMO / HAK ISTIMEWA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: TemaAplikasi.primary),
                  SizedBox(width: 4),
                  Text(
                    'ME Club Terpasang',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _voucherController,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: TemaAplikasi.primary,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'MASUKKAN KODE...',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: TemaAplikasi.mutedGray,
                      ),
                      fillColor: TemaAplikasi.surfaceLight,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _voucherDiterapkan
                          ? const Icon(Icons.check_circle, size: 16, color: TemaAplikasi.primary)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _terapkanVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaAplikasi.primary,
                    foregroundColor: TemaAplikasi.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'TERAPKAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_voucherDiterapkan) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Diskon keanggotaan ME VIP senilai Rp 150.000 berhasil digunakan.',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 6. Ringkasan Pesanan (cek-keranjangBelanja.html)
  Widget _bangunRingkasanPesanan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN PESANAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 12),
          _bangunBarisRingkasan(
            label: 'Total Barang ($_jumlahItemTerpilih item)',
            nilai: formatRupiah(_subtotalTerpilih),
          ),
          const SizedBox(height: 8),
          _bangunBarisRingkasan(
            label: 'ME Club Privilege Benefit',
            nilai: _diskonAktif > 0 ? '-${formatRupiah(_diskonAktif)}' : 'Rp 0',
            isDiskon: _diskonAktif > 0,
          ),
          const SizedBox(height: 8),
          _bangunBarisRingkasan(
            label: 'Estimasi Pajak Pertambahan Nilai (PPN 11%)',
            nilai: 'Termasuk',
          ),
          const SizedBox(height: 8),
          _bangunBarisRingkasan(
            label: 'Pengiriman Ekspres Terpilih',
            nilai: 'GRATIS',
            isBebasOngkir: true,
          ),
          const SizedBox(height: 12),
          const Divider(color: TemaAplikasi.borderGray),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TOTAL ESTIMASI',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sudah termasuk potongan membership',
                      style: TextStyle(
                        fontSize: 10,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatRupiah(_totalEstimasi),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunBarisRingkasan({
    required String label,
    required String nilai,
    bool isDiskon = false,
    bool isBebasOngkir = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TemaAplikasi.secondary,
          ),
        ),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBebasOngkir || isDiskon ? FontWeight.w600 : FontWeight.w500,
            color: isDiskon
                ? TemaAplikasi.primary
                : (isBebasOngkir ? TemaAplikasi.primary : TemaAplikasi.primary),
          ),
        ),
      ],
    );
  }

  // 7. Jaminan Keaslian & Retur (cek-keranjangBelanja.html)
  Widget _bangunJaminanAtelier() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user_outlined, size: 15, color: TemaAplikasi.secondary),
              SizedBox(width: 5),
              Text(
                'Keaslian Dijamin 100%',
                style: TextStyle(
                  fontSize: 11,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: TemaAplikasi.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Row(
            children: const [
              Icon(Icons.sync_alt, size: 15, color: TemaAplikasi.secondary),
              SizedBox(width: 5),
              Text(
                'Pengembalian 14 Hari',
                style: TextStyle(
                  fontSize: 11,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Sticky Bottom Floating Action Bar untuk Checkout (cek-keranjangBelanja.html)
  Widget _bangunStickyBottomBar() {
    final adaItemTerpilih = _itemTerpilihIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: const Border(top: BorderSide(color: TemaAplikasi.borderGray)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(_totalEstimasi),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: adaItemTerpilih
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HalamanCheckout(
                              subtotalAwal: _totalEstimasi,
                            ),
                          ),
                        ).then((_) => _muatKeranjang());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplikasi.primary,
                  foregroundColor: TemaAplikasi.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: Text(
                  'CHECKOUT ($_jumlahItemTerpilih)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                label: const Icon(Icons.arrow_forward, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
