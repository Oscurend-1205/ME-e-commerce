import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Pembayaran QRIS
/// Mengintegrasikan QR Code resmi Midtrans Core API secara real-time.
class HalamanPembayaranQris extends StatefulWidget {
  final int pesananId;
  final String nomorPesanan;
  final int total;
  final String? qrUrl;
  final String? qrString;
  final String? expiredAt;

  const HalamanPembayaranQris({
    super.key,
    required this.pesananId,
    required this.nomorPesanan,
    required this.total,
    this.qrUrl,
    this.qrString,
    this.expiredAt,
  });

  @override
  State<HalamanPembayaranQris> createState() => _HalamanPembayaranQrisState();
}

class _HalamanPembayaranQrisState extends State<HalamanPembayaranQris> {
  bool _sedangMemproses = false;
  Timer? _timerCekStatus;
  Timer? _timerHitungMundur;
  int _detikSisa = 15 * 60; // Default 15 menit validity QRIS
  String _statusPembayaran = 'menunggu_pembayaran';

  @override
  void initState() {
    super.initState();
    _inisialisasiHitungMundur();
    _mulaiCekStatus();
  }

  void _inisialisasiHitungMundur() {
    if (widget.expiredAt != null && widget.expiredAt!.isNotEmpty) {
      try {
        final exp = DateTime.parse(widget.expiredAt!);
        final sisa = exp.difference(DateTime.now()).inSeconds;
        if (sisa > 0) {
          _detikSisa = sisa;
        }
      } catch (_) {}
    }

    _timerHitungMundur = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_detikSisa > 0) {
        setState(() {
          _detikSisa--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timerCekStatus?.cancel();
    _timerHitungMundur?.cancel();
    super.dispose();
  }

  void _mulaiCekStatus() {
    // Polling status setiap 4 detik untuk responsivitas instan
    _timerCekStatus = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _cekStatusPembayaran(),
    );
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

        if (statusBaru == 'dibayar') {
          _timerCekStatus?.cancel();
          _timerHitungMundur?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran QRIS berhasil diterima!'),
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

  String _formatWaktu(int totalDetik) {
    final menit = (totalDetik ~/ 60).toString().padLeft(2, '0');
    final detik = (totalDetik % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  void _salinStringQr() {
    final str = widget.qrString;
    if (str != null && str.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: str));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('String QRIS berhasil disalin ke clipboard.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _sayaSudahBayar() async {
    setState(() {
      _sedangMemproses = true;
    });

    await _cekStatusPembayaran();

    if (!mounted) return;

    setState(() {
      _sedangMemproses = false;
    });

    if (_statusPembayaran == 'dibayar') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        title: const Text(
          'Konfirmasi Pembayaran QRIS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Sistem sedang memverifikasi transfer QRIS Anda secara otomatis ke Midtrans. Jika Anda baru saja menyelesaikan transaksi di aplikasi perbankan/e-wallet, status akan segera berubah.',
          style: TextStyle(
            color: TemaAplikasi.secondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'TUTUP',
              style: TextStyle(
                color: TemaAplikasi.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cekStatusPembayaran();
            },
            child: const Text(
              'REFRESH STATUS',
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
        centerTitle: true,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Timer Hitung Mundur
          _bangunBannerTimer(),
          const SizedBox(height: 16),

          // Header Info Ringkasan Pesanan
          _bangunInfoPesanan(),
          const SizedBox(height: 20),

          // Wadah QR Code dari Midtrans
          _bangunQrCode(),
          const SizedBox(height: 20),

          // Instruksi Langkah Pembayaran
          _bangunInstruksi(),
          const SizedBox(height: 28),

          // Tombol Konfirmasi "SAYA SUDAH BAYAR"
          _bangunTombolKonfirmasi(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _bangunBannerTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceContainer,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 18, color: TemaAplikasi.primary),
              SizedBox(width: 8),
              Text(
                'BATAS WAKTU PEMBAYARAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          Text(
            _formatWaktu(_detikSisa),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontFeatures: [FontFeature.tabularFigures()],
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunInfoPesanan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL TRANSAKSI',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
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
                style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: TemaAplikasi.borderGray),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
              ),
              Text(
                formatRupiah(widget.total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: TemaAplikasi.borderGray),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Pesanan',
                style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusPembayaran == 'dibayar'
                      ? TemaAplikasi.successColor.withValues(alpha: 0.1)
                      : TemaAplikasi.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _statusPembayaran == 'dibayar' ? 'DIBAYAR' : 'MENUNGGU PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
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
    final hasQrUrl = widget.qrUrl != null && widget.qrUrl!.isNotEmpty;
    final hasQrString = widget.qrString != null && widget.qrString!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        children: [
          // Header Logo QRIS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TemaAplikasi.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'QRIS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: TemaAplikasi.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '• Midtrans Payment Gateway',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tampilan Gambar QR Code dari Midtrans
          Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TemaAplikasi.borderGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: hasQrUrl
                ? Image.network(
                    widget.qrUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TemaAplikasi.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: TemaAplikasi.secondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar QR',
                            style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
                          ),
                        ],
                      );
                    },
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 160,
                        color: TemaAplikasi.primary,
                      ),
                      Text(
                        'QRIS Simulator / Mode Dev',
                        style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
                      ),
                    ],
                  ),
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
            'Buka BCA, Mandiri, GoPay, OVO, ShopeePay, atau aplikasi QRIS apa pun',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasQrString) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salinStringQr,
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.primary,
                side: const BorderSide(color: TemaAplikasi.borderGray),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              icon: const Icon(Icons.copy, size: 14),
              label: const Text(
                'SALIN STRING QRIS',
                style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bangunInstruksi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PANDUAN PEMBAYARAN',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 14),
          _instruksiLangkah(1, 'Buka aplikasi e-wallet atau mobile banking favorit Anda.'),
          const SizedBox(height: 10),
          _instruksiLangkah(2, 'Pilih menu "Bayar" atau "Scan QRIS".'),
          const SizedBox(height: 10),
          _instruksiLangkah(3, 'Arahkan kamera ke QR Code di atas atau upload tangkapan layar.'),
          const SizedBox(height: 10),
          _instruksiLangkah(4, 'Periksa penerima dan pastikan nominal tepat ${formatRupiah(widget.total)}.'),
          const SizedBox(height: 10),
          _instruksiLangkah(5, 'Masukkan PIN transaksi Anda. Halaman ini akan terverifikasi otomatis begitu dana diterima.'),
        ],
      ),
    );
  }

  Widget _instruksiLangkah(int nomor, String teks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: TemaAplikasi.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$nomor',
            style: const TextStyle(
              fontSize: 10,
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
                width: 18,
                height: 18,
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
