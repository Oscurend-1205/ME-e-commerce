import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import 'halaman_pembayaran_berhasil.dart';

/// Halaman pembayaran resmi Midtrans Snap (WebView)
/// Menampilkan antarmuka pembayaran Snap Midtrans (QRIS, VA Bank, Kartu Kredit, GoPay/ShopeePay)
class HalamanPembayaran extends StatefulWidget {
  final int pesananId;
  final String snapToken;
  final String nomorPesanan;
  final String? redirectUrl;
  final int? total;

  const HalamanPembayaran({
    super.key,
    required this.pesananId,
    required this.snapToken,
    required this.nomorPesanan,
    this.redirectUrl,
    this.total,
  });

  @override
  State<HalamanPembayaran> createState() => _HalamanPembayaranState();
}

class _HalamanPembayaranState extends State<HalamanPembayaran> {
  late final WebViewController _controller;
  bool _sedangMemuat = true;
  bool _sedangMemeriksa = false;
  Timer? _pengecekanOtomatisTimer;

  String get _urlPembayaran {
    if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
      return widget.redirectUrl!;
    }
    final isSandbox = Konstan.baseUrl.contains('localhost') ||
        Konstan.baseUrl.contains('127.0.0.1');
    final baseUrl = isSandbox
        ? 'https://app.sandbox.midtrans.com/snap/v4/redirection'
        : 'https://app.midtrans.com/snap/v4/redirection';
    return '$baseUrl/${widget.snapToken}';
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
    _mulaiPengecekanBerkala();
  }

  @override
  void dispose() {
    _pengecekanOtomatisTimer?.cancel();
    super.dispose();
  }

  void _mulaiPengecekanBerkala() {
    // Cek status pembayaran setiap 6 detik secara diam-diam
    _pengecekanOtomatisTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _periksaStatusTanpaLoading();
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _sedangMemuat = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _sedangMemuat = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            // Deteksi callback selesai pembayaran dari Midtrans atau redirect selesai
            if (url.contains('payment/callback') ||
                url.contains('transaction_status=settlement') ||
                url.contains('transaction_status=capture') ||
                url.contains('order_id=${widget.nomorPesanan.toLowerCase()}')) {
              _handlePaymentComplete();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(Uri.parse(_urlPembayaran));
  }

  Future<void> _periksaStatusTanpaLoading() async {
    if (!mounted || _sedangMemeriksa) return;

    try {
      final respon = await LayananApi.cekStatusPembayaran(widget.nomorPesanan);
      if (respon.berhasil && respon.data != null) {
        final data = respon.data as Map<String, dynamic>;
        final statusPesanan = data['status_pesanan'] as String? ?? '';
        if (statusPesanan == 'dibayar' ||
            statusPesanan == 'diproses' ||
            statusPesanan == 'dikirim' ||
            statusPesanan == 'selesai') {
          _handlePaymentComplete();
        }
      }
    } catch (_) {
      // Diam-diam abaikan error polling
    }
  }

  Future<void> _periksaStatusManual() async {
    setState(() => _sedangMemeriksa = true);

    try {
      final respon = await LayananApi.cekStatusPembayaran(widget.nomorPesanan);
      if (!mounted) return;

      if (respon.berhasil && respon.data != null) {
        final data = respon.data as Map<String, dynamic>;
        final statusPesanan = data['status_pesanan'] as String? ?? '';

        if (statusPesanan == 'dibayar' ||
            statusPesanan == 'diproses' ||
            statusPesanan == 'dikirim' ||
            statusPesanan == 'selesai') {
          _handlePaymentComplete();
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status saat ini: ${statusPesanan.toUpperCase()} (Menunggu pembayaran)'),
              backgroundColor: TemaAplikasi.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada pembaruan status pembayaran.'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengecek status: $e'),
            backgroundColor: TemaAplikasi.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMemeriksa = false);
    }
  }

  Future<void> _simulasiBayarDev() async {
    setState(() => _sedangMemeriksa = true);

    try {
      await LayananApi.ubahStatusPesanan(widget.pesananId, 'dibayar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulasi pembayaran berhasil! Status pesanan kini DIBAYAR.'),
            backgroundColor: TemaAplikasi.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _handlePaymentComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simulasi: $e'),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMemeriksa = false);
    }
  }

  void _handlePaymentComplete() {
    _pengecekanOtomatisTimer?.cancel();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HalamanPembayaranBerhasil(pesananId: widget.pesananId),
      ),
    );
  }

  void _salinLinkPembayaran() {
    Clipboard.setData(ClipboardData(text: _urlPembayaran));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link pembayaran Midtrans Snap berhasil disalin ke clipboard.'),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _konfirmasiTutup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: const Text(
          'Keluar dari Pembayaran?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Pesanan Anda telah tersimpan dengan status Menunggu Pembayaran. Anda dapat melanjutkan pembayaran kapan saja melalui menu Riwayat Pesanan.',
          style: TextStyle(
            fontSize: 13,
            color: TemaAplikasi.secondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'LANJUTKAN BAYAR',
              style: TextStyle(
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'KELUAR',
              style: TextStyle(
                color: TemaAplikasi.errorColor,
                fontWeight: FontWeight.w600,
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
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _konfirmasiTutup,
          icon: const Icon(Icons.close),
          tooltip: 'Tutup',
        ),
        title: Column(
          children: [
            const Text(
              'MIDTRANS PAYMENT GATEWAY',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.total != null && widget.total! > 0
                  ? '${widget.nomorPesanan} • ${formatRupiah(widget.total!)}'
                  : widget.nomorPesanan,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
                color: TemaAplikasi.secondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _sedangMemeriksa ? null : _periksaStatusManual,
            icon: _sedangMemeriksa
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TemaAplikasi.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Cek Status Pembayaran',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Pembayaran Aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: TemaAplikasi.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: TemaAplikasi.warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih metode pembayaran di bawah (QRIS, VA, Kartu)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _salinLinkPembayaran,
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 12, color: TemaAplikasi.primary),
                      SizedBox(width: 4),
                      Text(
                        'SALIN LINK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Area WebView Midtrans Snap
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_sedangMemuat)
                  Container(
                    color: TemaAplikasi.surfaceWhite,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TemaAplikasi.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Menghubungkan ke Midtrans...',
                            style: TextStyle(
                              fontSize: 12,
                              color: TemaAplikasi.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bilah Aksi Bawah: Verifikasi & Simulasi Dev
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceWhite,
              border: const Border(
                top: BorderSide(color: TemaAplikasi.borderGray),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sedangMemeriksa ? null : _periksaStatusManual,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TemaAplikasi.primary,
                        side: const BorderSide(color: TemaAplikasi.borderGray),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text(
                        'CEK STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sedangMemeriksa ? null : _simulasiBayarDev,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaAplikasi.primary,
                        foregroundColor: TemaAplikasi.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text(
                        'SIMULASI BAYAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
