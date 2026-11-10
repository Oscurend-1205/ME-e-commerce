import 'package:flutter/material.dart';

import '../constants.dart';
import '../enums.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/komponen_header.dart';
import '../widgets/modal_pilih_varian.dart';
import '../widgets/widget_keadaan.dart';
import '../widgets/transisi_geser.dart';
import 'halaman_checkout_alur_satu.dart';
import 'halaman_login.dart';
import 'halaman_rincian_produk.dart';

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
  List<Produk> _daftarRekomendasi = [];
  bool _sedangMemperbarui = false;

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
  }

  Future<void> _muatKeranjang() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final hasil = await Future.wait([
      LayananApi.ambilKeranjang(),
      LayananApi.ambilProduk(),
    ]);

    if (!mounted) return;

    final responKeranjang = hasil[0];
    final responProduk = hasil[1];

    if (responKeranjang.berhasil && responKeranjang.data != null) {
      final data = DataKeranjang.fromJson(responKeranjang.data as Map<String, dynamic>);
      final total = data.items.fold<int>(0, (sum, i) => sum + i.jumlah);
      StatePengguna.perbaruiJumlahKeranjang(total);

      List<Produk> rekomendasi = [];
      if (responProduk.berhasil && responProduk.data is List) {
        final cartProductIds = data.items.map((i) => i.produkId).toSet();
        rekomendasi = (responProduk.data as List)
            .map((p) => Produk.fromJson(p as Map<String, dynamic>))
            .where((p) => !cartProductIds.contains(p.id))
            .take(6)
            .toList();
      }

      setState(() {
        _dataKeranjang = data;
        _daftarRekomendasi = rekomendasi;
        _keadaan = data.items.isEmpty
            ? KeadaanMuat.kosong
            : KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(responKeranjang.code);
        _pesanGalat = responKeranjang.message;
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

  /// Ubah varian (ukuran, warna, jumlah) item yang ada di keranjang (CRUD Edit)
  Future<void> _ubahVarianItem(ItemKeranjang item) async {
    await ModalPilihVarian.tampilkanUbah(
      context,
      item: item,
      onKonfirmasi: (varianBaru, jumlahBaru) async {
        final respon = await LayananApi.ubahItemKeranjang(
          item.id,
          varianId: varianBaru.id,
          jumlah: jumlahBaru,
        );

        if (!mounted) return false;

        if (respon.berhasil) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Varian ${item.namaProduk} berhasil diubah ke ${varianBaru.ukuran} - ${varianBaru.warna} (x$jumlahBaru).',
              ),
              duration: const Duration(milliseconds: 1800),
              backgroundColor: TemaAplikasi.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _muatKeranjang();
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

  Future<void> _hapusItem(ItemKeranjang item) async {
    final konfirmasi = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Hapus Item',
      pesan:
          'Apakah Anda yakin ingin menghapus "${item.namaProduk}" (${item.ukuran}, ${item.warna}) dari tas belanja?',
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

  Future<void> _pindahKeWishlist(ItemKeranjang item) async {
    setState(() {
      _sedangMemperbarui = true;
    });

    // 1. Simpan ke wishlist pengguna secara reaktif global
    StatePengguna.tambahWishlist(item.produkId);

    // 2. Hapus item dari keranjang belanja
    final respon = await LayananApi.hapusDariKeranjang(item.id);

    if (!mounted) return;

    setState(() {
      _sedangMemperbarui = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${item.namaProduk} berhasil dipindahkan ke Wishlist.'),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 2000),
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
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _subtotal => _dataKeranjang?.subtotal ?? 0;

  int get _jumlahItem {
    if (_dataKeranjang == null) return 0;
    return _dataKeranjang!.items.fold<int>(0, (sum, i) => sum + i.jumlah);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: _bangunHeaderUtama(),
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
      bottomNavigationBar:
          _keadaan == KeadaanMuat.berhasil &&
              _dataKeranjang != null &&
              _dataKeranjang!.items.isNotEmpty
          ? _bangunStickyBottomBar()
          : null,
    );
  }

  // 1. Header Utama Sesuai cek-keranjangBelanja.html (Bebas Overflow)
  PreferredSizeWidget _bangunHeaderUtama() {
    return AppBar(
      backgroundColor: TemaAplikasi.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          size: 20,
          color: TemaAplikasi.primary,
        ),
        onPressed: () => NavigasiUniversal.kembali(context),
      ),
      centerTitle: true,
      title: const Text(
        'TAS BELANJA',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: TemaAplikasi.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_outlined, size: 20),
          onPressed: () => NavigasiUniversal.kePencarian(context),
        ),
        ValueListenableBuilder<Set<int>>(
          valueListenable: StatePengguna.wishlistNotifier,
          builder: (context, wishlist, _) {
            final hasWishlist = wishlist.isNotEmpty;
            return IconButton(
              icon: Icon(
                hasWishlist ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: hasWishlist ? TemaAplikasi.errorColor : TemaAplikasi.primary,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      hasWishlist
                          ? '${wishlist.length} item tersimpan di Wishlist Anda.'
                          : 'Wishlist Anda masih kosong.',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
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
          saranAksi: 'Lihat Koleksi ME',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.delete_sweep_outlined,
                              size: 16,
                              color: TemaAplikasi.secondary,
                            ),
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

              // Ongkir ditentukan server setelah kurir dipilih saat checkout.
              _bangunNotifikasiBebasOngkir(),

              // Checkout memproses seluruh item di keranjang.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SEMUA ITEM (${items.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.schedule,
                          size: 15,
                          color: TemaAplikasi.secondary,
                        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _bangunKartuItem(items[index]),
              ),

              // Cross-sell Carousel: Sempurnakan Tampilan (cek-keranjangBelanja.html)
              _bangunCrossSellCarousel(),

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
    const int batasBebasOngkir = 1500000;
    final int subtotalSaatIni = _subtotal;
    final int kekurangan = batasBebasOngkir - subtotalSaatIni;
    final double progress = (subtotalSaatIni / batasBebasOngkir).clamp(0.0, 1.0);
    final bool tercapai = kekurangan <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceLight,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: TemaAplikasi.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bebas Ongkir Kilat Atelier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              Text(
                tercapai ? '100%' : '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
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
                ? 'Selamat! Pesanan Anda memenuhi syarat kurir prioritas tanpa biaya.'
                : 'Tambahkan ${formatRupiah(kekurangan)} lagi untuk kualifikasi kurir prioritas tanpa biaya.',
            style: TextStyle(
              fontSize: 11,
              color: tercapai ? TemaAplikasi.primary : TemaAplikasi.secondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.5,
              backgroundColor: TemaAplikasi.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(TemaAplikasi.primary),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Kartu Item Keranjang (cek-keranjangBelanja.html)
  Widget _bangunKartuItem(ItemKeranjang item) {
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

                    // Varian: Warna & Ukuran + Tombol Ubah (CRUD Edit Varian)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _ubahVarianItem(item),
                          borderRadius: BorderRadius.circular(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                        ),
                        InkWell(
                          onTap: () => _ubahVarianItem(item),
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: TemaAplikasi.surfaceLight,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: TemaAplikasi.borderGray, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit_outlined, size: 11, color: TemaAplikasi.primary),
                                SizedBox(width: 3),
                                Text(
                                  'UBAH',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w700,
                                    color: TemaAplikasi.primary,
                                  ),
                                ),
                              ],
                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: TemaAplikasi.secondary,
                      ),
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
    if (_daftarRekomendasi.isEmpty) return const SizedBox.shrink();

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
              children: [
                const Column(
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
                  '${_daftarRekomendasi.length} Pilihan',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Carousel horizontal produk pelengkap nyata dari server
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _daftarRekomendasi.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _bangunKartuUpsell(_daftarRekomendasi[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunKartuUpsell(Produk produk) {
    final gambar = produk.fotoUrl;
    final tag = produk.kategori.isNotEmpty
        ? produk.kategori.toUpperCase()
        : 'PELENGKAP';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          ruteGeser(HalamanRincianProduk(produkId: produk.id)),
        ).then((_) => _muatKeranjang());
      },
      child: Container(
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
                      url: gambar,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
              produk.nama,
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
              formatRupiah(produk.harga),
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
                onPressed: () => _tambahRekomendasiKeKeranjang(produk),
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
      ),
    );
  }

  Future<void> _tambahRekomendasiKeKeranjang(Produk produk) async {
    final detail = await LayananApi.ambilRincianProduk(produk.id);
    if (!mounted) return;

    if (detail.berhasil && detail.data != null) {
      final produkLengkap =
          Produk.fromJson(detail.data as Map<String, dynamic>);
      final varianList = produkLengkap.varian ?? const <Varian>[];

      if (varianList.isEmpty) {
        final respon = await LayananApi.tambahKeKeranjang(
          produkId: produkLengkap.id,
          varianId: 0,
          jumlah: 1,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              respon.berhasil
                  ? '${produk.nama} berhasil ditambahkan ke tas belanja!'
                  : respon.message,
            ),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: respon.berhasil
                ? TemaAplikasi.primary
                : TemaAplikasi.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (respon.berhasil) {
          _muatKeranjang();
        }
        return;
      }

      await ModalPilihVarian.tampilkanTambah(
        context,
        produk: produkLengkap,
        onKonfirmasi: (varian, jumlah) async {
          final respon = await LayananApi.tambahKeKeranjang(
            produkId: produkLengkap.id,
            varianId: varian.id,
            jumlah: jumlah,
          );
          if (!mounted) return false;

          if (respon.berhasil) {
            _muatKeranjang();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${produk.nama} (${varian.ukuran}, ${varian.warna}) x$jumlah berhasil ditambahkan!',
                ),
                duration: const Duration(milliseconds: 1500),
                backgroundColor: TemaAplikasi.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return true;
          }

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(respon.message),
              duration: const Duration(milliseconds: 1500),
              backgroundColor: TemaAplikasi.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        },
      );
    }
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
            label: 'Subtotal ($_jumlahItem item)',
            nilai: formatRupiah(_subtotal),
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
                      'SUBTOTAL DARI SERVER',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ongkir dihitung setelah memilih kurir',
                      style: TextStyle(
                        fontSize: 10,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatRupiah(_subtotal),
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

  Widget _bangunBarisRingkasan({required String label, required String nilai}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
        ),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TemaAplikasi.primary,
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
              Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: TemaAplikasi.secondary,
              ),
              SizedBox(width: 5),
              Text(
                'Keaslian Dijamin 100%',
                style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
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
                style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Sticky Bottom Floating Action Bar untuk Checkout (cek-keranjangBelanja.html)
  Widget _bangunStickyBottomBar() {
    final adaItem = _dataKeranjang?.items.isNotEmpty ?? false;

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
                  'SUBTOTAL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(_subtotal),
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
                onPressed: adaItem
                    ? () {
                        if (!StatePengguna.isLoggedInNotifier.value) {
                          _tampilkanDialogHarusLogin();
                          return;
                        }
                        Navigator.push(
                          context,
                          ruteGeser(const HalamanCheckoutAlurSatu()),
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
                  'CHECKOUT ($_jumlahItem)',
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
          'Silakan masuk atau daftar akun terlebih dahulu untuk melanjutkan checkout.',
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
}
