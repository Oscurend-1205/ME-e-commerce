import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

class HalamanRincianPesanan extends StatefulWidget {
  final int pesananId;

  const HalamanRincianPesanan({super.key, required this.pesananId});

  @override
  State<HalamanRincianPesanan> createState() => _HalamanRincianPesananState();
}

class _HalamanRincianPesananState extends State<HalamanRincianPesanan> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  Pesanan? _pesanan;
  bool _sedangMemperbaruiStatus = false;

  @override
  void initState() {
    super.initState();
    _muatRincianPesanan();
  }

  Future<void> _muatRincianPesanan() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilRincianPesanan(widget.pesananId);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final p = Pesanan.fromJson(respon.data as Map<String, dynamic>);
      setState(() {
        _pesanan = p;
        _keadaan = KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = respon.code == '404' ? KeadaanMuat.kosong : KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _ubahStatus(String statusBaru, {String? dialogPesan}) async {
    if (dialogPesan != null) {
      final konfirmasi = await tampilkanDialogKonfirmasi(
        context,
        judul: 'Konfirmasi Perubahan Status',
        pesan: dialogPesan,
        teksKonfirmasi: 'Lanjutkan',
      );
      if (!konfirmasi || !mounted) return;
    }

    setState(() {
      _sedangMemperbaruiStatus = true;
    });

    final respon = await LayananApi.ubahStatusPesanan(widget.pesananId, statusBaru);

    if (!mounted) return;

    setState(() {
      _sedangMemperbaruiStatus = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan berhasil diperbarui menjadi "$statusBaru".'),
          backgroundColor: _hitam,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatRincianPesanan();
    } else {
      // Menampilkan galat 409 jika perpindahan status tidak sah sesuai tabel PRD
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        return 'SEDANG DIPROSES';
      case 'dikirim':
        return 'SEDANG DIKIRIM';
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
        title: Text(
          _pesanan != null ? 'PESANAN #${_pesanan!.nomorPesanan}' : 'RINCIAN PESANAN',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _hitam,
        onRefresh: _muatRincianPesanan,
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
          pesan: 'Pesanan tidak ditemukan.',
          saranAksi: 'Kembali',
          onAksi: () => Navigator.pop(context),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatRincianPesanan,
        );
      case KeadaanMuat.berhasil:
        final pesanan = _pesanan!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Status Pesanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _abuMuda,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STATUS PESANAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: _abuSedang,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _warnaStatus(pesanan.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _labelStatus(pesanan.status),
                            style: const TextStyle(
                              color: _putih,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nomor: ${pesanan.nomorPesanan}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _hitam,
                      ),
                    ),
                    if (pesanan.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Waktu Pemesanan: ${pesanan.createdAt}',
                        style: const TextStyle(fontSize: 12, color: _abuSedang),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informasi Pengiriman & Penerima
              const Text(
                'ALAMAT PENGIRIMAN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: _hitam,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _abuGaris),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.namaPenerima,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _hitam,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pesanan.alamat,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _abuSedang,
                        height: 1.4,
                      ),
                    ),
                    if (pesanan.namaKurir != null) ...[
                      const Divider(height: 16, color: _abuGaris),
                      Text(
                        'Kurir: ${pesanan.namaKurir}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (pesanan.metodePembayaran != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Metode: ${pesanan.metodePembayaran}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daftar Item yang Dibeli (Detail Pesanan Snapshot)
              const Text(
                'ITEM PESANAN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: _hitam,
                ),
              ),
              const SizedBox(height: 8),
              if (pesanan.detail != null && pesanan.detail!.isNotEmpty)
                ...pesanan.detail!.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _abuGaris),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _abuMuda,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.checkroom, color: _abuSedang, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduk,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _hitam,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ukuran: ${item.ukuran}  |  Warna: ${item.warna}',
                                style: const TextStyle(fontSize: 11, color: _abuSedang),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.jumlah} x ${formatRupiah(item.hargaSatuan)}',
                                style: const TextStyle(fontSize: 12, color: _abuSedang),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _hitam,
                          ),
                        ),
                      ],
                    ),
                  );
                })
              else
                const Text(
                  'Item pesanan tidak dimuat.',
                  style: TextStyle(color: _abuSedang, fontSize: 13),
                ),
              const SizedBox(height: 20),

              // Rincian Pembayaran dari Server
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _abuMuda,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal Produk', style: TextStyle(fontSize: 13, color: _abuSedang)),
                        Text(formatRupiah(pesanan.subtotal), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ongkos Kirim', style: TextStyle(fontSize: 13, color: _abuSedang)),
                        Text(formatRupiah(pesanan.ongkir), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Divider(height: 20, color: _abuGaris),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(
                          formatRupiah(pesanan.total),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _hitam),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Tindakan Berdasarkan Status (Simulasi Alur Sistem Terdistribusi)
              _bangunAksiStatus(pesanan),
              const SizedBox(height: 20),
            ],
          ),
        );
    }
  }

  Widget _bangunAksiStatus(Pesanan pesanan) {
    if (_sedangMemperbaruiStatus) {
      return const Center(child: CircularProgressIndicator(color: _hitam));
    }

    final status = pesanan.status.toLowerCase();

    if (status == 'menunggu_pembayaran') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('menunggu_konfirmasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hitam,
                foregroundColor: _putih,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text(
                'BAYAR SEKARANG (SIMULASI)',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _ubahStatus(
                'dibatalkan',
                dialogPesan: 'Apakah Anda yakin ingin membatalkan pesanan ini? Stok varian akan dikembalikan.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('BATALKAN PESANAN'),
            ),
          ),
        ],
      );
    }

    if (status == 'menunggu_konfirmasi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Simulasi Toko (Admin):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _abuSedang),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('dibayar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: _putih,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('KONFIRMASI PEMBAYARAN (ADMIN)'),
            ),
          ),
        ],
      );
    }

    if (status == 'dibayar') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _ubahStatus('diproses'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: _putih,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('PROSES PESANAN (ADMIN)'),
        ),
      );
    }

    if (status == 'diproses') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _ubahStatus('dikirim'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: _putih,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('KIRIM PESANAN (ADMIN)'),
        ),
      );
    }

    if (status == 'dikirim') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _ubahStatus('selesai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: _putih,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('TERIMA & SELESAIKAN PESANAN'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

