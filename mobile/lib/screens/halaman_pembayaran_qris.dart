import 'dart:async';

import 'package:flutter/material.dart';

import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Pembayaran QRIS
/// Menampilkan QR code dan instruksi pembayaran untuk metode QRIS
class HalamanPembayaranQris extends StatefulWidget {
  final int pesananId;
  final String nomorPesanan;
  final int total;

  const HalamanPembayaranQris({
    super.key,
    required this.pesananId,
    required this.nomorPesanan,
    required this.total,
  });

  @override
  State<HalamanPembayaranQris> createState() => _HalamanPembayaranQrisState();
}

class _HalamanPembayaranQrisState extends State<HalamanPembayaranQris> {
  bool _sedangMemproses = false;
  Timer? _timerCekStatus;
  String _statusPembayaran = 'menunggu_pembayaran';

  @override
  void initState() {
    super.initState();
    _mulaiCekStatus();
  }

  @override
  void dispose() {
    _timerCekStatus?.cancel();
    super.dispose();
  }

  void _mulaiCekStatus() {
    // Cek status setiap 5 detik
    _timerCekStatus = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cekStatusPembayaran(),
    );
    // Cek langsung sekali
    _cekStatusPembayaran();
  }

  Future<void> _cekStatusPembayaran() async {
    final respon = await LayananApi.cekStatusPembayaran(widget.nomorPesanan);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final data = respon.data as Map<String, dynamic>;
      final statusBaru = data['status_pesanan'] as String? ?? '';

      if (statusBaru != _statusPembayaran) {
        setState(() {
          _statusPembayaran = statusBaru;
        });

        // Jika sudah dibayar, hentikan timer dan navigasi
        if (statusBaru == 'dibayar') {
          _timerCekStatus?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil!'),
              backgroundColor: TemaAplikasi.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HalamanRincianPesanan(pesananId: widget.pesananId),
            ),
          );
        }
      }
    }
  }

  void _sayaSudahBayar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Apakah Anda sudah melakukan pembayaran via QRIS?',
          style: TextStyle(
            color: TemaAplikasi.secondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BELUM',
              style: TextStyle(
                color: TemaAplikasi.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _konfirmasiManual();
            },
            child: const Text(
              'SUDAH BAYAR',
              style: TextStyle(
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiManual() async {
    setState(() {
      _sedangMemproses = true;
    });

    // Update status pesanan ke "menunggu_verifikasi" (admin akan verifikasi manual)
    // Untuk sekarang, kita hanya simulasi dengan cek status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pembayaran Anda sedang diverifikasi. Mohon tunggu.'),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _sedangMemproses = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        title: const Text(
          'PEMBAYARAN QRIS',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Tutup',
          ),
        ],
      ),
      body: _bangunKonten(),
    );
  }

  Widget _bangunKonten() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          _bangunInfoPesanan(),
          const SizedBox(height: 24),

          // QR Code
          _bangunQrCode(),
          const SizedBox(height: 24),

          // Instruksi
          _bangunInstruksi(),
          const SizedBox(height: 32),

          // Tombol Konfirmasi
          _bangunTombolKonfirmasi(),
        ],
      ),
    );
  }

  Widget _bangunInfoPesanan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pembayaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nomor Pesanan',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                widget.nomorPesanan,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                formatRupiah(widget.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusPembayaran == 'dibayar'
                      ? TemaAplikasi.successColor.withValues(alpha: 0.1)
                      : TemaAplikasi.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _statusPembayaran == 'dibayar' ? 'Dibayar' : 'Menunggu Pembayaran',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusPembayaran == 'dibayar'
                        ? TemaAplikasi.successColor
                        : TemaAplikasi.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunQrCode() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_2,
            size: 200,
            color: TemaAplikasi.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan QR Code untuk Membayar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan aplikasi e-wallet atau mobile banking yang mendukung QRIS',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _bangunInstruksi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara Pembayaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 12),
          _instruksiLangkah(1, 'Buka aplikasi e-wallet atau mobile banking Anda'),
          const SizedBox(height: 8),
          _instruksiLangkah(2, 'Pilih menu QRIS atau Scan QR'),
          const SizedBox(height: 8),
          _instruksiLangkah(3, 'Scan QR code di atas'),
          const SizedBox(height: 8),
          _instruksiLangkah(4, 'Pastikan nominal pembayaran sesuai: ${formatRupiah(widget.total)}'),
          const SizedBox(height: 8),
          _instruksiLangkah(5, 'Selesaikan pembayaran dan klik "Saya Sudah Bayar"'),
        ],
      ),
    );
  }

  Widget _instruksiLangkah(int nomor, String teks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: TemaAplikasi.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$nomor',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teks,
            style: const TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunTombolKonfirmasi() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sedangMemproses ? null : _sayaSudahBayar,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: TemaAplikasi.primary,
          foregroundColor: TemaAplikasi.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        child: _sedangMemproses
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: TemaAplikasi.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SAYA SUDAH BAYAR',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
