import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_form_produk.dart';

class HalamanKelolaProduk extends StatefulWidget {
  const HalamanKelolaProduk({super.key});

  @override
  State<HalamanKelolaProduk> createState() => _HalamanKelolaProdukState();
}

class _HalamanKelolaProdukState extends State<HalamanKelolaProduk> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Produk> _daftarProduk = [];
  bool _sedangMenghapus = false;

  @override
  void initState() {
    super.initState();
    _muatDaftarProduk();
  }

  Future<void> _muatDaftarProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilProduk();

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

  Future<void> _hapusProduk(Produk produk) async {
    final konfirmasi = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Hapus Produk',
      pesan: 'Apakah Anda yakin ingin menghapus "${produk.nama}"? Produk yang terkait dengan pesanan aktif tidak dapat dihapus.',
      teksKonfirmasi: 'Hapus',
      warnaKonfirmasi: TemaAplikasi.errorColor,
    );

    if (!konfirmasi || !mounted) return;

    setState(() {
      _sedangMenghapus = true;
    });

    final respon = await LayananApi.hapusProduk(produk.id);

    if (!mounted) return;

    setState(() {
      _sedangMenghapus = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${produk.nama}" berhasil dihapus.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatDaftarProduk();
    } else {
      // 409 bila produk terpakai pada pesanan aktif
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: TemaAplikasi.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        title: const Row(
          children: [
            Text(
              'KELOLA PRODUK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Produk Baru',
            onPressed: () async {
              final hasil = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanFormProduk(),
                ),
              );
              if (hasil == true) {
                _muatDaftarProduk();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: TemaAplikasi.primary,
            onRefresh: _muatDaftarProduk,
            child: _bangunKonten(),
          ),
          if (_sedangMenghapus)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(color: TemaAplikasi.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TemaAplikasi.primary,
        foregroundColor: TemaAplikasi.onPrimary,
        elevation: 2,
        onPressed: () async {
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HalamanFormProduk(),
            ),
          );
          if (hasil == true) {
            _muatDaftarProduk();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.inventory_2_outlined,
          pesan: 'Belum ada produk di database toko.',
          saranAksi: 'Tambah Produk Pertama',
          onAksi: () async {
            final hasil = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HalamanFormProduk(),
              ),
            );
            if (hasil == true) {
              _muatDaftarProduk();
            }
          },
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatDaftarProduk,
        );
      case KeadaanMuat.berhasil:
        return ListView.separated(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
          itemCount: _daftarProduk.length,
          separatorBuilder: (context, index) => const Divider(color: TemaAplikasi.borderGray, height: 16),
          itemBuilder: (context, index) {
            final produk = _daftarProduk[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TemaAplikasi.borderGray),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder Icon Produk
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TemaAplikasi.surfaceContainer,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      produk.kategori.toLowerCase() == 'aksesori'
                          ? Icons.watch_outlined
                          : Icons.checkroom_outlined,
                      color: TemaAplikasi.mutedGray,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Detail Produk
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: TemaAplikasi.surfaceContainer,
                              child: Text(
                                produk.kategori.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: TemaAplikasi.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              produk.merek,
                              style: const TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          produk.nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(produk.harga),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Stok Total: ${produk.stok}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: produk.stok > 0 ? Colors.green.shade800 : TemaAplikasi.errorColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Bahan: ${produk.bahan}',
                              style: const TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Aksi Ubah & Hapus
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: TemaAplikasi.primary),
                        onPressed: () async {
                          final hasil = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HalamanFormProduk(produk: produk),
                            ),
                          );
                          if (hasil == true) {
                            _muatDaftarProduk();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: TemaAplikasi.errorColor),
                        onPressed: () => _hapusProduk(produk),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}
