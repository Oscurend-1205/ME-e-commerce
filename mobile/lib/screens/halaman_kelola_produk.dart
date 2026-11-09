import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_form_produk.dart';

/// Halaman Kelola Produk — CRUD produk dari dalam aplikasi.
/// Memakai GET/POST/PUT/DELETE /api/produk melalui LayananApi.
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
  int? _idSedangDiproses;

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilProduk();

    if (!mounted) return;

    if (respon.berhasil && respon.data is List) {
      final daftar = (respon.data as List)
          .map((p) => Produk.fromJson(p as Map<String, dynamic>))
          .toList();
      setState(() {
        _daftarProduk = daftar;
        _keadaan = daftar.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _bukaForm({Produk? produk}) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HalamanFormProduk(produk: produk)),
    );

    if (berhasil == true && mounted) {
      _muatProduk();
    }
  }

  Future<void> _hapusProduk(Produk produk) async {
    final konfirmasi = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Hapus Produk',
      pesan:
          'Hapus "${produk.nama}" dari katalog? Tindakan ini tidak dapat dibatalkan.',
      tekstKonfirmasi: 'HAPUS',
      aksiMerah: true,
    );
    if (!konfirmasi || !mounted) return;

    setState(() => _idSedangDiproses = produk.id);

    final respon = await LayananApi.hapusProduk(produk.id);

    if (!mounted) return;
    setState(() => _idSedangDiproses = null);

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${produk.nama}" berhasil dihapus.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatProduk();
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
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'KELOLA PRODUK',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _muatProduk,
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: TemaAplikasi.primary,
        foregroundColor: TemaAplikasi.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'TAMBAH',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      body: _bangunKonten(),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.inventory_2_outlined,
          pesan: 'Belum ada produk di katalog.',
          saranAksi: 'TAMBAH PRODUK',
          onAksi: () => _bukaForm(),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatProduk,
        );
      case KeadaanMuat.berhasil:
        return RefreshIndicator(
          onRefresh: _muatProduk,
          color: TemaAplikasi.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _daftarProduk.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _bangunKartuProduk(_daftarProduk[index]),
          ),
        );
    }
  }

  Widget _bangunKartuProduk(Produk produk) {
    final sedangDiproses = _idSedangDiproses == produk.id;
    final varianList = produk.varian ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(color: TemaAplikasi.borderGray),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRect(
            child: Container(
              width: 64,
              height: 80,
              color: TemaAplikasi.surfaceContainer,
              child: FotoDummy.bangunGambar(
                url: produk.fotoUrl,
                fit: BoxFit.cover,
                cacheWidth: 192,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        produk.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ),
                    if (!produk.tersedia)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: TemaAplikasi.errorColor.withValues(alpha: 0.1),
                        child: const Text(
                          'NONAKTIF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TemaAplikasi.errorColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${produk.kategori}  •  ${formatRupiah(produk.harga)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stok: ${produk.stok}  •  ${varianList.length} varian',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaAplikasi.mutedGray,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _tombolAksi(
                      ikon: Icons.edit_outlined,
                      tooltip: 'Ubah',
                      onTap: sedangDiproses
                          ? null
                          : () => _bukaForm(produk: produk),
                    ),
                    const SizedBox(width: 8),
                    _tombolAksi(
                      ikon: Icons.delete_outline_rounded,
                      tooltip: 'Hapus',
                      warna: TemaAplikasi.errorColor,
                      onTap: sedangDiproses ? null : () => _hapusProduk(produk),
                    ),
                    if (sedangDiproses) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolAksi({
    required IconData ikon,
    required String tooltip,
    required VoidCallback? onTap,
    Color warna = TemaAplikasi.primary,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: TemaAplikasi.borderGray),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(ikon, size: 16, color: warna),
        ),
      ),
    );
  }
}
