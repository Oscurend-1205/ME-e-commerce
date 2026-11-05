import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
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

  @override
  void initState() {
    super.initState();
    _muatKeranjang();
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
      // Tampilkan galat 409 (stok varian kurang), 422, dll
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
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
      pesan: 'Apakah Anda yakin ingin menghapus "${item.namaProduk}" (${item.ukuran}, ${item.warna}) dari keranjang?',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item berhasil dihapus dari keranjang.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatKeranjang();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
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
        title: const Text(
          'KERANJANG BELANJA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
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
          ikon: Icons.shopping_bag_outlined,
          pesan: 'Keranjang belanja Anda masih kosong.',
          saranAksi: 'Lihat Katalog ME',
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
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(
            color: TemaAplikasi.borderGray,
            height: 32,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Gambar Item (Editorial 3:4)
                Container(
                  width: 76,
                  height: 100,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: TemaAplikasi.borderGray),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      color: TemaAplikasi.mutedGray,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Detail Item
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: Nama Produk + Tombol Hapus
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.namaProduk,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: TemaAplikasi.secondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _hapusItem(item),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Ukuran dan Warna (Domain Fashion Wajib Tampil)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TemaAplikasi.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'SIZE: ${item.ukuran}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: TemaAplikasi.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: TemaAplikasi.borderGray),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              item.warna.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: TemaAplikasi.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Harga Satuan
                      Text(
                        formatRupiah(item.hargaSatuan),
                        style: const TextStyle(
                          fontSize: 12,
                          color: TemaAplikasi.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Baris Kuantitas dan Subtotal Item (Dihitung Server)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pengatur Kuantitas Sleek
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: TemaAplikasi.borderGray),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: item.jumlah > 1
                                      ? () => _ubahJumlah(item, item.jumlah - 1)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '${item.jumlah}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TemaAplikasi.primary,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _ubahJumlah(item, item.jumlah + 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(
                                      Icons.add,
                                      size: 13,
                                      color: TemaAplikasi.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtotal Item dari Server
                          Text(
                            formatRupiah(item.subtotalItem),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TemaAplikasi.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(top: BorderSide(color: TemaAplikasi.borderGray)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL SUBTOAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_dataKeranjang!.items.fold<int>(0, (sum, i) => sum + i.jumlah)} item terpilih',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TemaAplikasi.mutedGray,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatRupiah(_dataKeranjang!.subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanCheckout(
                        subtotalAwal: _dataKeranjang!.subtotal,
                      ),
                    ),
                  ).then((_) => _muatKeranjang());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplikasi.primary,
                  foregroundColor: TemaAplikasi.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'LANJUT KE CHECKOUT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
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
