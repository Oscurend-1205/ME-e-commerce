import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../services/layanan_api.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_checkout.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

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
          backgroundColor: Colors.red.shade800,
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
      teksKonfirmasi: 'Hapus',
      warnaKonfirmasi: Colors.red.shade700,
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
          backgroundColor: _hitam,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatKeranjang();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
        title: const Text(
          'KERANJANG BELANJA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: _hitam,
            onRefresh: _muatKeranjang,
            child: _bangunKonten(),
          ),
          if (_sedangMemperbarui)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: _hitam),
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
          pesan: 'Keranjang masih kosong, ayo lihat katalog.',
          saranAksi: 'Mulai Belanja',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(color: _abuGaris, height: 24),
          itemBuilder: (context, index) {
            final item = items[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Gambar Item
                Container(
                  width: 76,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _abuMuda,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(Icons.checkroom, color: _abuSedang, size: 28),
                  ),
                ),
                const SizedBox(width: 14),

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
                                color: _hitam,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: _abuSedang),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _hapusItem(item),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Ukuran dan Warna (Wajib Tampil Sesuai Domain!)
                      Text(
                        'Ukuran: ${item.ukuran}  |  Warna: ${item.warna}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _abuSedang,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Harga Satuan
                      Text(
                        formatRupiah(item.hargaSatuan),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _hitam,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Baris Kuantitas dan Subtotal Item (Dihitung Server)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pengatur Kuantitas
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: _abuGaris),
                              borderRadius: BorderRadius.circular(4),
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
                                      size: 14,
                                      color: item.jumlah > 1 ? _hitam : _abuSedang,
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
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _ubahJumlah(item, item.jumlah + 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.add, size: 14, color: _hitam),
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
                              color: _hitam,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _putih,
        border: const Border(top: BorderSide(color: _abuGaris)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtotal dari Server (Sumber Kebenaran)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBTOTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: _abuSedang,
                  ),
                ),
                Text(
                  formatRupiah(_dataKeranjang!.subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _hitam,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Lanjut ke Checkout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanCheckout(
                        subtotalAwal: _dataKeranjang!.subtotal,
                      ),
                    ),
                  );
                  _muatKeranjang();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hitam,
                  foregroundColor: _putih,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'LANJUT KE CHECKOUT',
                  style: TextStyle(
                    fontSize: 14,
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
  }
}

