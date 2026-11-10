import 'dart:async';
import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import 'halaman_pembayaran_berhasil.dart';

/// Halaman pembayaran resmi Midtrans Snap
/// Mendukung WebView terintegrasi (Android/iOS) dan Fallback Desktop Browser (Windows/macOS/Linux/Web)
class HalamanPembayaran extends StatefulWidget {
  final int pesananId;
  final String snapToken;
  final String nomorPesanan;
  final String? redirectUrl;
  final String? qrUrl;
  final String? qrString;
  final int? total;

  const HalamanPembayaran({
    super.key,
    required this.pesananId,
    required this.snapToken,
    required this.nomorPesanan,
    this.redirectUrl,
    this.qrUrl,
    this.qrString,
    this.total,
  });

  @override
  State<HalamanPembayaran> createState() => _HalamanPembayaranState();
}

class _HalamanPembayaranState extends State<HalamanPembayaran> {
  WebViewController? _controller;
  bool _isWebViewSupported = false;
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
    _cekDukunganDanInisialisasi();
    _mulaiPengecekanBerkala();
  }

  void _cekDukunganDanInisialisasi() {
    // webview_flutter hanya didukung secara bawaan di Android dan iOS
    // Pada Windows Desktop / Web / Linux, WebViewPlatform.instance bernilai null
    bool didukung = false;
    try {
      didukung = WebViewPlatform.instance != null;
    } catch (_) {
      didukung = false;
    }

    if (didukung) {
      _isWebViewSupported = true;
      _initWebView();
    } else {
      _isWebViewSupported = false;
      _sedangMemuat = false;
      // Di platform desktop, otomatis buka URL pembayaran di browser default
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bukaDiBrowserDefault(tampilkanPesan: false);
      });
    }
  }

  @override
  void dispose() {
    _pengecekanOtomatisTimer?.cancel();
    super.dispose();
  }

  void _mulaiPengecekanBerkala() {
    // Polling status pembayaran setiap 5 detik secara otomatis
    _pengecekanOtomatisTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _periksaStatusTanpaLoading();
    });
  }

  void _initWebView() {
    try {
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

              // Deteksi redirect penyelesaian transaksi Midtrans
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

      _controller!.loadRequest(Uri.parse(_urlPembayaran));
    } catch (_) {
      setState(() {
        _isWebViewSupported = false;
        _sedangMemuat = false;
      });
    }
  }

  void _bukaDiBrowserDefault({bool tampilkanPesan = true}) {
    final url = _urlPembayaran;
    try {
      if (!kIsWeb) {
        if (Platform.isWindows) {
          Process.run('cmd', ['/c', 'start', '', url]);
        } else if (Platform.isMacOS) {
          Process.run('open', [url]);
        } else if (Platform.isLinux) {
          Process.run('xdg-open', [url]);
        }
      }

      if (tampilkanPesan && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membuka halaman Midtrans Snap di browser Anda...'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka browser: $e. Silakan gunakan tombol salin link.'),
            backgroundColor: TemaAplikasi.primary,
          ),
        );
      }
    }
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
      // Abaikan error polling latar belakang
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
              content: Text('Status terkini: ${statusPesanan.toUpperCase()} (Menunggu pembayaran Midtrans)'),
              backgroundColor: TemaAplikasi.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada pembaruan status dari Midtrans.'),
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
            content: Text('Simulasi berhasil! Status pesanan otomatis diubah menjadi DIBAYAR.'),
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
        content: Text('Link pembayaran Midtrans Snap disalin ke clipboard!'),
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
          'Tinggalkan Pembayaran?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Pesanan Anda tetap tersimpan. Anda dapat menyelesaikan pembayaran kapan saja dari menu Riwayat Pesanan.',
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
      backgroundColor: TemaAplikasi.surfaceBright,
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
      body: _isWebViewSupported ? _bangunTampilanWebView() : _bangunTampilanDesktopFallback(),
      bottomNavigationBar: _bangunBilahBawah(),
    );
  }

  /// Tampilan WebView untuk platform mobile (Android / iOS)
  Widget _bangunTampilanWebView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: TemaAplikasi.surfaceContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: TemaAplikasi.primary),
                  SizedBox(width: 6),
                  Text(
                    'Pilih metode pembayaran resmi di bawah',
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
        Expanded(
          child: Stack(
            children: [
              if (_controller != null) WebViewWidget(controller: _controller!),
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
                          'Memuat Midtrans Snap...',
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
      ],
    );
  }

  /// Tampilan Fallback Khusus Platform Desktop (Windows / macOS / Web / Linux)
  Widget _bangunTampilanDesktopFallback() {
    final effectiveQrUrl = widget.qrUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Pembayaran Midtrans Snap
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: TemaAplikasi.borderGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: TemaAplikasi.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PORTAL PEMBAYARAN MIDTRANS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih saluran pembayaran Anda (GoPay/QRIS, Virtual Account, Kartu Kredit) melalui antarmuka resmi Midtrans.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rincian Transaksi
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainer,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nomor Pesanan', style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary)),
                              Text(widget.nomorPesanan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Divider(height: 16, color: TemaAplikasi.borderGray),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Tagihan', style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary)),
                              Text(
                                widget.total != null ? formatRupiah(widget.total!) : '-',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Buka di Browser Default (Chrome / Edge)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _bukaDiBrowserDefault(tampilkanPesan: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaAplikasi.primary,
                          foregroundColor: TemaAplikasi.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text(
                          'BUKA PEMBAYARAN MIDTRANS DI BROWSER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Salin Link
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _salinLinkPembayaran,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TemaAplikasi.primary,
                          side: const BorderSide(color: TemaAplikasi.borderGray),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text(
                          'SALIN LINK PEMBAYARAN MIDTRANS',
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

              // Jika tersedia QRIS URL resmi Midtrans, tampilkan standee card agar bisa di-scan dari HP
              if (effectiveQrUrl != null && effectiveQrUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: TemaAplikasi.borderGray),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ATAU SCAN LANGSUNG DARI PONSEL ANDA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Buka GoPay, BCA, Mandiri, ShopeePay, atau m-Banking Anda',
                        style: TextStyle(fontSize: 10, color: TemaAplikasi.secondary),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          effectiveQrUrl,
                          width: 260,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 260,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Bilah Aksi Bawah: Verifikasi & Simulasi Dev
  Widget _bangunBilahBawah() {
    return Container(
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
    );
  }
}
