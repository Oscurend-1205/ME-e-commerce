import 'package:flutter/material.dart';

import '../enums.dart';
import '../constants.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/widget_keadaan.dart';

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
        teksKonfirmasi: 'LANJUTKAN',
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
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _muatRincianPesanan();
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
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'RINCIAN PESANAN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
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
          pesan: 'Data pesanan tidak ditemukan.',
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
        final warna = _warnaStatus(pesanan.status);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status Pesanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceBright,
                  border: Border.all(color: TemaAplikasi.borderGray),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    const SizedBox(height: 10),
                    Text(
                      pesanan.nomorPesanan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    if (pesanan.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Waktu: ${pesanan.createdAt}',
                        style: const TextStyle(fontSize: 11, color: TemaAplikasi.mutedGray),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Alamat & Info Pengiriman
              const Text(
                'INFORMASI PENGIRIMAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: TemaAplikasi.borderGray),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.namaPenerima,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pesanan.alamat,
                      style: const TextStyle(
                        fontSize: 13,
                        color: TemaAplikasi.secondary,
                        height: 1.4,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: TemaAplikasi.borderGray),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kurir: ${pesanan.namaKurir}',
                          style: const TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
                        ),
                        Text(
                          'Metode: ${pesanan.metodePembayaran}',
                          style: const TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daftar Item yang Dibeli
              const Text(
                'ITEM PESANAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (pesanan.detail != null && pesanan.detail!.isNotEmpty)
                ...pesanan.detail!.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: TemaAplikasi.borderGray),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 64,
                          decoration: BoxDecoration(
                            color: TemaAplikasi.surfaceContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FotoDummy.bangunGambar(
                            url: item.gambar != null && item.gambar!.isNotEmpty
                                ? '${Konstan.storageUrl}/${item.gambar}'
                                : '${Konstan.storageUrl}/${item.id}.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduk,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Size: ${item.ukuran}  |  ${item.warna}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TemaAplikasi.mutedGray,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.jumlah} × ${formatRupiah(item.hargaSatuan)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TemaAplikasi.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                })
              else
                const Text(
                  'Item pesanan tidak dimuat.',
                  style: TextStyle(color: TemaAplikasi.mutedGray, fontSize: 13),
                ),
              const SizedBox(height: 24),

              // Rincian Pembayaran
              const Text(
                'RINCIAN PEMBAYARAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceBright,
                  border: Border.all(color: TemaAplikasi.borderGray),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal Produk', style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary)),
                        Text(formatRupiah(pesanan.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ongkos Kirim', style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary)),
                        Text(formatRupiah(pesanan.ongkir), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: TemaAplikasi.borderGray),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        Text(
                          formatRupiah(pesanan.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Tindakan Berdasarkan Status
              _bangunAksiStatus(pesanan),
              const SizedBox(height: 20),
            ],
          ),
        );
    }
  }

  Widget _bangunAksiStatus(Pesanan pesanan) {
    if (_sedangMemperbaruiStatus) {
      return const Center(child: CircularProgressIndicator(color: TemaAplikasi.primary));
    }

    final status = pesanan.status.toLowerCase();

    if (status == 'menunggu_pembayaran') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('dibayar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              child: const Text(
                'BAYAR SEKARANG (SIMULASI)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.0),
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
                dialogPesan: 'Apakah Anda yakin ingin membatalkan pesanan ini? Stok varian akan otomatis dikembalikan.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.errorColor,
                side: const BorderSide(color: TemaAplikasi.errorColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'BATALKAN PESANAN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.0),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'dibayar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKSI TOKO / ADMIN:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: TemaAplikasi.secondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('diproses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              child: const Text(
                'PROSES PESANAN (KEMAS BARANG)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
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
                dialogPesan: 'Batalkan pesanan dan kembalikan stok?',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.errorColor,
                side: const BorderSide(color: TemaAplikasi.errorColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'BATALKAN PESANAN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'diproses') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKSI PENGIRIMAN:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: TemaAplikasi.secondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('dikirim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              child: const Text(
                'KIRIM PESANAN KE KURIR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'dikirim') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONFIRMASI PENERIMAAN:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: TemaAplikasi.secondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _ubahStatus('selesai'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              child: const Text(
                'PESANAN DITERIMA (SELESAI)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceBright,
        border: Border.all(color: TemaAplikasi.borderGray),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          status == 'selesai'
              ? 'Pesanan telah selesai. Terima kasih telah berbelanja di ME!'
              : 'Pesanan telah dibatalkan.',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TemaAplikasi.secondary,
          ),
        ),
      ),
    );
  }
}
