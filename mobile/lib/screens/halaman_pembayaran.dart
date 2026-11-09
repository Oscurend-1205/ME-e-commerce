import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../theme.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman pembayaran Midtrans (WebView)
/// Menampilkan Snap payment page Midtrans untuk transaksi
class HalamanPembayaran extends StatefulWidget {
  final int pesananId;
  final String snapToken;
  final String nomorPesanan;

  const HalamanPembayaran({
    super.key,
    required this.pesananId,
    required this.snapToken,
    required this.nomorPesanan,
  });

  @override
  State<HalamanPembayaran> createState() => _HalamanPembayaranState();
}

class _HalamanPembayaranState extends State<HalamanPembayaran> {
  late final WebViewController _controller;
  bool _sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _sedangMemuat = true);
          },
          onPageFinished: (String url) {
            setState(() => _sedangMemuat = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Deteksi callback selesai pembayaran dari Midtrans
            if (url.contains('payment/callback') || url.contains('order_id=')) {
              _handlePaymentComplete();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // URL Snap Midtrans dengan token
    // Format: https://app.sandbox.midtrans.com/snap/v2/embed/{token} untuk sandbox
    // atau https://app.midtrans.com/snap/v2/embed/{token} untuk production
    final isSandbox = Konstan.baseUrl.contains('localhost') || Konstan.baseUrl.contains('127.0.0.1');
    final baseSnapUrl = isSandbox
        ? 'https://app.sandbox.midtrans.com/snap/v2/embed'
        : 'https://app.midtrans.com/snap/v2/embed';

    _controller.loadRequest(Uri.parse('$baseSnapUrl/${widget.snapToken}'));
  }

  void _handlePaymentComplete() {
    // Navigasi ke halaman rincian pesanan setelah pembayaran selesai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanRincianPesanan(pesananId: widget.pesananId),
      ),
    );
  }

  void _tutup() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        title: const Text(
          'PEMBAYARAN',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _tutup,
            icon: const Icon(Icons.close),
            tooltip: 'Tutup',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_sedangMemuat)
            Container(
              color: TemaAplikasi.surfaceWhite,
              child: const Center(
                child: CircularProgressIndicator(
                  color: TemaAplikasi.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
