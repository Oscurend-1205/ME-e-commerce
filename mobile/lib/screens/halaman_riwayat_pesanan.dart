import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

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
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilRiwayatPesanan();

    if (!mounted) return;

    if (respon.berhasil) {
      final List dataRaw = respon.data is List ? respon.data as List : [];
      final pesananList = dataRaw
          .map((item) => Pesanan.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _daftarPesanan = pesananList;
        _keadaan = pesananList.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
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
        return 'MENUNGGU PEMBAYARAN';
      case 'menunggu_konfirmasi':
        return 'MENUNGGU KONFIRMASI';
      case 'dibayar':
        return 'SUDAH DIBAYAR';
      case 'diproses':
        return 'SEDANG DIPROSES';
      case 'dikirim':
        return 'DALAM PENGIRIMAN';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return status.toUpperCase();
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
          'RIWAYAT PESANAN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: TemaAplikasi.primary,
        onRefresh: _muatRiwayat,
        child: _bangunKonten(),
      ),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.receipt_long_outlined,
          pesan: 'Belum ada riwayat pesanan yang dibuat.',
          saranAksi: 'Mulai Belanja',
          onAksi: _muatRiwayat,
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatRiwayat,
        );
      case KeadaanMuat.berhasil:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: _daftarPesanan.length,
          itemBuilder: (context, index) {
            final p = _daftarPesanan[index];
            final warnaStatus = _warnaStatus(p.status);
            final labelStatus = _labelStatus(p.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceWhite,
                border: Border.all(color: TemaAplikasi.borderGray),
                borderRadius: BorderRadius.circular(2),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanRincianPesanan(pesananId: p.id),
                    ),
                  ).then((_) => _muatRiwayat());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: No Pesanan & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.nomorPesanan,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: TemaAplikasi.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: warnaStatus.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: warnaStatus.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              labelStatus,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: warnaStatus,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: TemaAplikasi.borderGray, height: 1),
                      const SizedBox(height: 12),

                      // Penerima & Kurir
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: TemaAplikasi.secondary),
                          const SizedBox(width: 6),
                          Text(
                            p.namaPenerima,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TemaAplikasi.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.local_shipping_outlined, size: 14, color: TemaAplikasi.secondary),
                          const SizedBox(width: 6),
                          Text(
                            p.namaKurir ?? 'Standar',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Item Ringkasan (jika ada detail)
                      if (p.detail != null && p.detail!.isNotEmpty) ...[
                        Text(
                          '${p.detail!.first.namaProduk} (${p.detail!.first.ukuran}, ${p.detail!.first.warna}) × ${p.detail!.first.jumlah}${p.detail!.length > 1 ? ' dan ${p.detail!.length - 1} produk lainnya' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.secondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Baris Bawah: Total Pembayaran
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL PESANAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          Text(
                            formatRupiah(p.total),
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
              ),
            );
          },
        );
    }
  }
}
