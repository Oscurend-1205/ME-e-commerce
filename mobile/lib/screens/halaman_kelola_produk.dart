import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_form_produk.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

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
      warnaKonfirmasi: Colors.red.shade700,
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
          backgroundColor: _hitam,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatDaftarProduk();
    } else {
      // 409 bila produk terpakai pada pesanan aktif
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
          'KELOLA PRODUK (ADMIN)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
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
            color: _hitam,
            onRefresh: _muatDaftarProduk,
            child: _bangunKonten(),
          ),
          if (_sedangMenghapus)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: CircularProgressIndicator(color: _hitam),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _hitam,
        foregroundColor: _putih,
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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
          itemCount: _daftarProduk.length,
          separatorBuilder: (context, index) => const Divider(color: _abuGaris, height: 16),
          itemBuilder: (context, index) {
            final produk = _daftarProduk[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder Icon Produk
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _abuMuda,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      produk.kategori.toLowerCase() == 'aksesori'
                          ? Icons.watch_outlined
                          : Icons.checkroom_outlined,
                      color: _abuSedang,
                      size: 26,
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
                              decoration: BoxDecoration(
                                color: _abuMuda,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                produk.kategori.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _abuSedang,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              produk.merek,
                              style: const TextStyle(fontSize: 11, color: _abuSedang),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          produk.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _hitam,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(produk.harga),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _hitam,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Total Stok: ${produk.stok}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: produk.stok > 0 ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Bahan: ${produk.bahan}',
                              style: const TextStyle(fontSize: 12, color: _abuSedang),
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
                        icon: const Icon(Icons.edit_outlined, size: 20, color: _hitam),
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
                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
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

