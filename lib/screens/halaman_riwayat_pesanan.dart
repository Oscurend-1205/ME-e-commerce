import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

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
        return Colors.orange.shade800;
      case 'menunggu_konfirmasi':
        return Colors.blue.shade700;
      case 'dibayar':
        return Colors.teal.shade700;
      case 'diproses':
        return Colors.indigo.shade700;
      case 'dikirim':
        return Colors.purple.shade700;
      case 'selesai':
        return Colors.green.shade700;
      case 'dibatalkan':
        return Colors.red.shade700;
      default:
        return _abuSedang;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
        title: const Text(
          'RIWAYAT PESANAN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _hitam,
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
          pesan: 'Anda belum memiliki riwayat pesanan.',
          saranAksi: 'Segarkan Halaman',
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
          padding: const EdgeInsets.all(16),
          itemCount: _daftarPesanan.length,
          itemBuilder: (context, index) {
            final pesanan = _daftarPesanan[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: _putih,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _abuGaris),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanRincianPesanan(pesananId: pesanan.id),
                    ),
                  );
                  _muatRiwayat();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: Nomor Pesanan & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${pesanan.nomorPesanan}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _hitam,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _warnaStatus(pesanan.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _labelStatus(pesanan.status),
                              style: const TextStyle(
                                color: _putih,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Penerima
                      Text(
                        'Penerima: ${pesanan.namaPenerima}',
                        style: const TextStyle(fontSize: 13, color: _abuSedang),
                      ),
                      if (pesanan.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          pesanan.createdAt!,
                          style: const TextStyle(fontSize: 11, color: _abuSedang),
                        ),
                      ],
                      const Divider(height: 20, color: _abuGaris),

                      // Baris Bawah: Total & Arahkan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Belanja',
                                style: TextStyle(fontSize: 11, color: _abuSedang),
                              ),
                              Text(
                                formatRupiah(pesanan.total),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _hitam,
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Text(
                                'Rincian',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _hitam,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: _hitam),
                            ],
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
