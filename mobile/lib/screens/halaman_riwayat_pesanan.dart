import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Riwayat Pesanan — daftar pesanan dari GET /api/pesanan
/// diurutkan dari yang terbaru, menuju rincian pesanan saat diketuk.
class HalamanRiwayatPesanan extends StatefulWidget {
  const HalamanRiwayatPesanan({super.key});

  @override
  State<HalamanRiwayatPesanan> createState() => _HalamanRiwayatPesananState();
}

class _HalamanRiwayatPesananState extends State<HalamanRiwayatPesanan> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Pesanan> _daftarPesanan = [];

  @override
  void initState() {
    super.initState();
    _muatPesanan();
  }

  Future<void> _muatPesanan() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilRiwayatPesanan();

    if (!mounted) return;

    if (respon.berhasil && respon.data is List) {
      final daftar = (respon.data as List)
          .map((p) => Pesanan.fromJson(p as Map<String, dynamic>))
          .toList();
      setState(() {
        _daftarPesanan = daftar;
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

  Color _warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return const Color(0xFFC77700);
      case 'menunggu_konfirmasi':
        return const Color(0xFF1E6091);
      case 'dibayar':
        return const Color(0xFF184E77);
      case 'diproses':
        return const Color(0xFF168AAD);
      case 'dikirim':
        return const Color(0xFF52B69A);
      case 'selesai':
        return const Color(0xFF2D6A4F);
      case 'dibatalkan':
        return TemaAplikasi.errorColor;
      default:
        return TemaAplikasi.secondary;
    }
  }

  String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'MENUNGGU BAYAR';
      case 'menunggu_konfirmasi':
        return 'KONFIRMASI';
      case 'dibayar':
        return 'DIBAYAR';
      case 'diproses':
        return 'DIPROSES';
      case 'dikirim':
        return 'DIKIRIM';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return status.toUpperCase();
    }
  }

  void _bukaRincian(Pesanan pesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanRincianPesanan(pesananId: pesanan.id),
      ),
    ).then((_) => _muatPesanan());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'RIWAYAT PESANAN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
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
          ikon: Icons.receipt_long_outlined,
          pesan: 'Belum ada pesanan. Yuk, mulai belanja koleksi ME!',
          saranAksi: 'LIHAT KATALOG',
          onAksi: () => Navigator.maybePop(context),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatPesanan,
        );
      case KeadaanMuat.berhasil:
        return RefreshIndicator(
          onRefresh: _muatPesanan,
          color: TemaAplikasi.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: _daftarPesanan.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _bangunKartuPesanan(_daftarPesanan[index]),
          ),
        );
    }
  }

  Widget _bangunKartuPesanan(Pesanan pesanan) {
    final warna = _warnaStatus(pesanan.status);
    final jumlahItem =
        pesanan.detail?.fold<int>(0, (t, d) => t + d.jumlah) ?? 0;

    return InkWell(
      onTap: () => _bukaRincian(pesanan),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceWhite,
          border: Border.all(color: TemaAplikasi.borderGray),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pesanan.nomorPesanan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: warna.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _labelStatus(pesanan.status),
                    style: TextStyle(
                      color: warna,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: TemaAplikasi.mutedGray,
                ),
                const SizedBox(width: 6),
                Text(
                  '$jumlahItem item',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const Spacer(),
                if (pesanan.createdAt != null)
                  Text(
                    pesanan.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.mutedGray,
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: TemaAplikasi.borderGray, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                Text(
                  formatRupiah(pesanan.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
