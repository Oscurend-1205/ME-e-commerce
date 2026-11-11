import 'dart:async';
import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

import '../constants.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import 'halaman_konfirmasi_cod.dart';
import 'halaman_pembayaran_berhasil.dart';
import 'midtrans_web_helper.dart';

/// Halaman Pembayaran Utama
///
/// Arsitektur:
/// - Header (Native): Navigasi, Nomor Pesanan, Total Tagihan, Menu Batalkan & Salin Link.
/// - Body (Tengah): Frame Browser / WebView resmi Midtrans Snap
///   (GoPay/QRIS asli, Virtual Account BCA/Mandiri/BNI/BRI asli, Kartu Kredit).
/// - Footer (Native): Tombol Cek Status, Ubah ke COD (dengan alasan), dan Simulasi Lunas.
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
  // Mobile Controller (Android/iOS)
  wf.WebViewController? _mobileController;

  // Windows Controller (Windows Desktop)
  ww.WebviewController? _windowsController;
  bool _windowsInisialisasiSukses = false;
  bool _windowsGagalInisialisasi = false;

  bool _sedangMemuat = true;
  bool _sedangMemeriksa = false;
  bool _sedangMemprosesAksi = false;
  Timer? _pengecekanOtomatisTimer;

  Pesanan? _pesanan;

  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _urlPembayaran {
    if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
      return widget.redirectUrl!;
    }
    if (_pesanan?.redirectUrl != null && _pesanan!.redirectUrl!.isNotEmpty) {
      return _pesanan!.redirectUrl!;
    }
    final token = widget.snapToken.isNotEmpty
        ? widget.snapToken
        : (_pesanan?.snapToken ?? '');
    if (token.isEmpty) {
      return '';
    }
    final isSandbox = Konstan.baseUrl.contains('localhost') ||
        Konstan.baseUrl.contains('127.0.0.1');
    final baseUrl = isSandbox
        ? 'https://app.sandbox.midtrans.com/snap/v4/redirection'
        : 'https://app.midtrans.com/snap/v4/redirection';
    return '$baseUrl/$token';
  }

  int get _nominalTotal => widget.total ?? _pesanan?.total ?? 0;

  @override
  void initState() {
    super.initState();
    _muatRincianPesanan();
    _inisialisasiWebView();
    _mulaiPengecekanBerkala();
  }

  @override
  void dispose() {
    _pengecekanOtomatisTimer?.cancel();
    if (_isWindowsDesktop) {
      _windowsController?.dispose();
    }
    super.dispose();
  }

  void _mulaiPengecekanBerkala() {
    // Polling status otomatis setiap 4 detik untuk responsivitas tinggi
    // saat pembeli membayar via Midtrans Payment Simulator di tab browser lain
    _pengecekanOtomatisTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _periksaStatusTanpaLoading();
    });
  }

  // =========================================================================
  //  INISIALISASI WEBVIEW SESUAI PLATFORM (WINDOWS vs MOBILE)
  // =========================================================================

  Future<void> _inisialisasiWebView() async {
    if (kIsWeb) {
      setState(() => _sedangMemuat = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bukaOverlaySnapWeb();
      });
    } else if (_isWindowsDesktop) {
      await _initWindowsWebView();
    } else if (_isMobile) {
      _initMobileWebView();
    } else {
      setState(() => _sedangMemuat = false);
    }
  }

  void _bukaOverlaySnapWeb() {
    if (!kIsWeb) return;
    final token = widget.snapToken.isNotEmpty
        ? widget.snapToken
        : (_pesanan?.snapToken ?? '');
    if (token.isNotEmpty) {
      triggerMidtransSnapPopup(
        token,
        onSuccess: () => _handlePaymentComplete(),
        onPending: () => _periksaStatusTanpaLoading(),
        onError: () => _periksaStatusTanpaLoading(),
        onClose: () => _periksaStatusTanpaLoading(),
      );
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      final controller = ww.WebviewController();
      await controller.initialize();

      controller.url.listen((url) {
        _periksaUrlRedirect(url);
      });

      controller.loadingState.listen((state) {
        if (!mounted) return;
        if (state == ww.LoadingState.navigationCompleted) {
          setState(() => _sedangMemuat = false);
        } else if (state == ww.LoadingState.loading) {
          setState(() => _sedangMemuat = true);
        }
      });

      final url = _urlPembayaran;
      if (url.isNotEmpty) {
        await controller.loadUrl(url);
      }

      if (mounted) {
        setState(() {
          _windowsController = controller;
          _windowsInisialisasiSukses = true;
          _windowsGagalInisialisasi = false;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      debugPrint('Galat inisialisasi WebView Windows: $e');
      if (mounted) {
        setState(() {
          _windowsInisialisasiSukses = false;
          _windowsGagalInisialisasi = true;
          _sedangMemuat = false;
        });
      }
    }
  }

  void _initMobileWebView() {
    try {
      final controller = wf.WebViewController()
        ..setJavaScriptMode(wf.JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          wf.NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _sedangMemuat = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _sedangMemuat = false);
            },
            onNavigationRequest: (wf.NavigationRequest request) {
              if (_periksaUrlRedirect(request.url)) {
                return wf.NavigationDecision.prevent;
              }
              return wf.NavigationDecision.navigate;
            },
          ),
        );

      final url = _urlPembayaran;
      if (url.isNotEmpty) {
        controller.loadRequest(Uri.parse(url));
      }

      setState(() {
        _mobileController = controller;
        _sedangMemuat = false;
      });
    } catch (_) {
      setState(() => _sedangMemuat = false);
    }
  }

  bool _periksaUrlRedirect(String urlRaw) {
    final url = urlRaw.toLowerCase();
    if (url.contains('payment/callback') ||
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture') ||
        url.contains('order_id=${widget.nomorPesanan.toLowerCase()}')) {
      _handlePaymentComplete();
      return true;
    }
    return false;
  }

  // =========================================================================
  //  MUAT DATA RINCIAN PESANAN DARI API
  // =========================================================================

  Future<void> _muatRincianPesanan() async {
    try {
      final respon = await LayananApi.ambilRincianPesanan(widget.pesananId);
      if (!mounted) return;
      if (respon.berhasil && respon.data != null) {
        final pesananBaru =
            Pesanan.fromJson(respon.data as Map<String, dynamic>);
        setState(() => _pesanan = pesananBaru);

        // Jika URL baru tersedia dan controller belum memuatnya, muat sekarang
        final url = _urlPembayaran;
        if (url.isNotEmpty) {
          if (kIsWeb) {
            _bukaOverlaySnapWeb();
          } else if (_isWindowsDesktop &&
              _windowsController != null &&
              _windowsInisialisasiSukses) {
            _windowsController!.loadUrl(url);
          } else if (_isMobile && _mobileController != null) {
            _mobileController!.loadRequest(Uri.parse(url));
          }
        }
      }
    } catch (_) {}
  }

  // =========================================================================
  //  CEK STATUS & SELESAIKAN PEMBAYARAN
  // =========================================================================

  Future<void> _periksaStatusTanpaLoading() async {
    if (!mounted || _sedangMemeriksa) return;
    try {
      final respon = await LayananApi.cekStatusPembayaran(widget.nomorPesanan);
      if (respon.berhasil && respon.data != null) {
        final data = respon.data as Map<String, dynamic>;
        final statusPesanan = data['status_pesanan'] as String? ?? '';
        if (_adalahStatusSelesaiBayar(statusPesanan)) {
          _handlePaymentComplete();
        }
      }
    } catch (_) {}
  }

  Future<void> _periksaStatusManual() async {
    setState(() => _sedangMemeriksa = true);
    try {
      final respon = await LayananApi.cekStatusPembayaran(widget.nomorPesanan);
      if (!mounted) return;

      if (respon.berhasil && respon.data != null) {
        final data = respon.data as Map<String, dynamic>;
        final statusPesanan = data['status_pesanan'] as String? ?? '';
        if (_adalahStatusSelesaiBayar(statusPesanan)) {
          _handlePaymentComplete();
          return;
        } else {
          _tampilkanSnackBar(
            'Status: ${statusPesanan.toUpperCase()} — Belum ada pembayaran terkonfirmasi dari Midtrans.',
            TemaAplikasi.primary,
          );
        }
      } else {
        _tampilkanSnackBar(
          'Belum ada notifikasi pembayaran dari Midtrans.',
          TemaAplikasi.primary,
        );
      }
    } catch (e) {
      if (mounted) {
        _tampilkanSnackBar('Gagal mengecek status: $e', TemaAplikasi.errorColor);
      }
    } finally {
      if (mounted) setState(() => _sedangMemeriksa = false);
    }
  }

  bool _adalahStatusSelesaiBayar(String status) {
    return ['menunggu_konfirmasi', 'dibayar', 'diproses', 'dikirim', 'selesai']
        .contains(status.toLowerCase());
  }

  Future<void> _handlePaymentComplete() async {
    _pengecekanOtomatisTimer?.cancel();
    try {
      await LayananApi.ubahStatusPesanan(widget.pesananId, 'dibayar');
    } catch (_) {}
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HalamanPembayaranBerhasil(pesananId: widget.pesananId),
      ),
    );
  }

  Future<void> _simulasiBayarDev() async {
    setState(() => _sedangMemeriksa = true);
    try {
      final respon = await LayananApi.ubahStatusPesanan(
        widget.pesananId,
        'dibayar',
      );
      if (mounted) {
        if (respon.berhasil) {
          _tampilkanSnackBar(
            'Simulasi Midtrans berhasil! Status pesanan kini LUNAS (Dibayar).',
            TemaAplikasi.successColor,
          );
        }
        await _handlePaymentComplete();
      }
    } catch (e) {
      if (mounted) {
        _tampilkanSnackBar('Gagal simulasi: $e', TemaAplikasi.errorColor);
      }
    } finally {
      if (mounted) setState(() => _sedangMemeriksa = false);
    }
  }

  // =========================================================================
  //  MODAL UBAH KE COD (DENGAN ALASAN LENGKAP)
  // =========================================================================

  Future<void> _tampilkanDialogUbahMetode() async {
    final total = _nominalTotal;
    if (total > 2500000) {
      _tampilkanSnackBar(
        'COD hanya tersedia untuk pesanan maksimal ${formatRupiah(2500000)}.',
        TemaAplikasi.errorColor,
      );
      return;
    }

    final TextEditingController alasanController = TextEditingController();
    String? alasanTerpilih;

    final daftarAlasan = [
      'Saldo e-wallet / rekening tidak mencukupi',
      'Midtrans mengalami kendala koneksi',
      'Lebih nyaman membayar tunai saat barang tiba',
      'Tidak memiliki metode pembayaran online',
      'Alasan lainnya (tulis di bawah)',
    ];

    final hasil = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: TemaAplikasi.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.swap_horiz,
                            color: TemaAplikasi.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UBAH KE BAYAR DI TEMPAT (COD)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pembayaran tunai kepada kurir',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TemaAplikasi.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                          color: TemaAplikasi.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2DDD8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: TemaAplikasi.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Anda akan membayar sebesar ${formatRupiah(total)} langsung kepada kurir saat barang tiba.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: TemaAplikasi.secondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PILIH ALASAN PENGALIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...daftarAlasan.map((alasan) {
                      final terpilih = alasanTerpilih == alasan;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            setModalState(() => alasanTerpilih = alasan);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: terpilih
                                  ? TemaAplikasi.primary.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: terpilih
                                    ? TemaAplikasi.primary
                                    : TemaAplikasi.borderGray,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  terpilih
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: terpilih
                                      ? TemaAplikasi.primary
                                      : TemaAplikasi.secondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    alasan,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: terpilih
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: terpilih
                                          ? TemaAplikasi.primary
                                          : TemaAplikasi.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (alasanTerpilih != null &&
                        alasanTerpilih!.contains('lainnya')) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: alasanController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Tulis alasan Anda...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.mutedGray,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: TemaAplikasi.borderGray),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: alasanTerpilih == null
                            ? null
                            : () {
                                final alasanFinal =
                                    alasanTerpilih!.contains('lainnya') &&
                                            alasanController.text.isNotEmpty
                                        ? alasanController.text
                                        : alasanTerpilih!;
                                Navigator.pop(ctx, {'alasan': alasanFinal});
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaAplikasi.primary,
                          foregroundColor: TemaAplikasi.onPrimary,
                          disabledBackgroundColor: TemaAplikasi.borderGray,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'KONFIRMASI GANTI KE COD',
                          style: TextStyle(
                            fontSize: 12,
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
          },
        );
      },
    );

    if (hasil == null || !mounted) return;

    setState(() => _sedangMemprosesAksi = true);
    _pengecekanOtomatisTimer?.cancel();

    try {
      final respon = await LayananApi.fallbackCod(
        pesananId: widget.pesananId,
        alasan: hasil['alasan'] ?? 'Pengguna memilih COD dari Midtrans Snap',
      );

      if (!mounted) return;
      setState(() => _sedangMemprosesAksi = false);

      if (respon.berhasil) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanKonfirmasiCod(
              pesananId: widget.pesananId,
              dataPesananAwal: respon.data as Map<String, dynamic>?,
            ),
          ),
        );
      } else {
        _tampilkanSnackBar(respon.message, TemaAplikasi.errorColor);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sedangMemprosesAksi = false);
        _tampilkanSnackBar('Gagal mengganti ke COD: $e', TemaAplikasi.errorColor);
      }
    }
  }

  // =========================================================================
  //  DIALOG BATALKAN PESANAN
  // =========================================================================

  Future<void> _tampilkanDialogBatalkan() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TemaAplikasi.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: TemaAplikasi.errorColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Batalkan Pesanan?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TemaAplikasi.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan Anda akan dibatalkan dan seluruh stok produk pesanan akan dikembalikan ke katalog toko.',
              style: TextStyle(
                fontSize: 13,
                color: TemaAplikasi.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TemaAplikasi.errorColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: TemaAplikasi.errorColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: TemaAplikasi.errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nomor: ${widget.nomorPesanan}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEMBALI',
                style: TextStyle(
                    color: TemaAplikasi.secondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaAplikasi.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: const Text('YA, BATALKAN',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() => _sedangMemprosesAksi = true);
    _pengecekanOtomatisTimer?.cancel();

    try {
      final respon = await LayananApi.ubahStatusPesanan(
        widget.pesananId,
        'dibatalkan',
      );

      if (!mounted) return;
      setState(() => _sedangMemprosesAksi = false);

      if (respon.berhasil) {
        _tampilkanSnackBar(
          'Pesanan ${widget.nomorPesanan} berhasil dibatalkan.',
          TemaAplikasi.successColor,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      } else {
        _tampilkanSnackBar(respon.message, TemaAplikasi.errorColor);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sedangMemprosesAksi = false);
        _tampilkanSnackBar(
          'Gagal membatalkan pesanan: $e',
          TemaAplikasi.errorColor,
        );
      }
    }
  }

  void _konfirmasiTutup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: const Text(
          'Tinggalkan Pembayaran?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        content: const Text(
          'Pesanan Anda tetap tersimpan. Anda dapat menyelesaikan pembayaran kapan saja dari menu Pesanan Saya.',
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

  void _tampilkanSnackBar(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _salinLink() {
    final url = _urlPembayaran;
    if (url.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: url));
      _tampilkanSnackBar('Link Midtrans disalin!', TemaAplikasi.primary);
    }
  }

  void _bukaDiBrowserDefault() {
    final url = _urlPembayaran;
    if (url.isEmpty) return;
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
      _tampilkanSnackBar('Membuka Midtrans di browser...', TemaAplikasi.primary);
    } catch (_) {}
  }

  // =========================================================================
  //  BUILD UTAMA (HEADER + FRAME BROWSER TENGAH + FOOTER)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // 1. HEADER NATIVE
      appBar: _bangunHeaderNative(),
      // 2. FRAME TENGAH (BROWSER / WEBVIEW GATEWAY MIDTRANS)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                _bangunFrameBrowserTengah(),

                // Loading Indicator awal
                if (_sedangMemuat && !_windowsGagalInisialisasi)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF111827),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat Gateway Midtrans...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading overlay untuk aksi modal
                if (_sedangMemprosesAksi)
                  Container(
                    color: Colors.white.withValues(alpha: 0.8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // 3. FOOTER NATIVE (TOMBOL KONTROL)
      bottomNavigationBar: _bangunFooterNative(),
    );
  }

  // =========================================================================
  //  1. HEADER NATIVE FLUTTER
  // =========================================================================

  PreferredSizeWidget _bangunHeaderNative() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Color(0xFF111827)),
        tooltip: 'Tutup Pembayaran',
        onPressed: _konfirmasiTutup,
      ),
      title: Column(
        children: [
          const Text(
            'PEMBAYARAN MIDTRANS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.nomorPesanan} • ${formatRupiah(_nominalTotal)}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: _sedangMemeriksa
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF111827),
                  ),
                )
              : const Icon(Icons.refresh, color: Color(0xFF111827)),
          tooltip: 'Cek Status Pembayaran',
          onPressed: _sedangMemeriksa ? null : _periksaStatusManual,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF111827)),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onSelected: (val) {
            if (val == 'overlay') _bukaOverlaySnapWeb();
            if (val == 'browser') _bukaDiBrowserDefault();
            if (val == 'salin') _salinLink();
            if (val == 'cod') _tampilkanDialogUbahMetode();
            if (val == 'batal') _tampilkanDialogBatalkan();
          },
          itemBuilder: (ctx) => [
            if (kIsWeb)
              const PopupMenuItem(
                value: 'overlay',
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 18, color: TemaAplikasi.primary),
                    SizedBox(width: 8),
                    Text('Buka Overlay Midtrans',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'browser',
              child: Row(
                children: [
                  Icon(Icons.open_in_browser, size: 18, color: TemaAplikasi.primary),
                  SizedBox(width: 8),
                  Text('Buka di Browser Luar', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'salin',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 18, color: TemaAplikasi.primary),
                  SizedBox(width: 8),
                  Text('Salin Tautan Midtrans', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'cod',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18, color: TemaAplikasi.primary),
                  SizedBox(width: 8),
                  Text('Ubah ke COD', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'batal',
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined,
                      size: 18, color: TemaAplikasi.errorColor),
                  SizedBox(width: 8),
                  Text('Batalkan Pesanan',
                      style: TextStyle(fontSize: 13, color: TemaAplikasi.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  //  2. FRAME TENGAH: BROWSER / WEBVIEW RESMI MIDTRANS SNAP
  // =========================================================================

  Widget _bangunFrameBrowserTengah() {
    // A. Web Platform (Chrome / Edge / Firefox)
    if (kIsWeb) {
      final url = _urlPembayaran;
      if (url.isNotEmpty) {
        return Stack(
          children: [
            buildMidtransWebFrame(
              url,
              onLoaded: () {
                if (mounted) setState(() => _sedangMemuat = false);
              },
            ),
            // Tombol buka ulang overlay popup Midtrans resmi
            Positioned(
              top: 10,
              right: 10,
              child: ElevatedButton.icon(
                onPressed: _bukaOverlaySnapWeb,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.layers_outlined, size: 14),
                label: const Text(
                  'BUKA OVERLAY MIDTRANS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return _bangunTampilanEmbeddedFallbackWindows();
    }

    // B. Windows Desktop dengan WebView2 aktif
    if (_isWindowsDesktop) {
      if (_windowsController != null && _windowsInisialisasiSukses) {
        return ww.Webview(
          _windowsController!,
          permissionRequested: (url, permissionKind, isUserInitiated) =>
              Future.value(ww.WebviewPermissionDecision.allow),
        );
      }
      // Jika WebView2 Windows belum terkompilasi / runtime tidak siap:
      // Tampilkan Embedded Browser Card agar Midtrans Simulator tetap dapat diuji
      return _bangunTampilanEmbeddedFallbackWindows();
    }

    // C. Mobile (Android & iOS)
    if (_isMobile) {
      if (_mobileController != null) {
        return wf.WebViewWidget(controller: _mobileController!);
      }
      return const Center(child: CircularProgressIndicator(color: Color(0xFF111827)));
    }

    // Fallback umum
    return _bangunTampilanEmbeddedFallbackWindows();
  }

  /// Tampilan Fallback jika WebView2 native Windows belum siap di runtime
  Widget _bangunTampilanEmbeddedFallbackWindows() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment,
                      color: Color(0xFF111827), size: 26),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MIDTRANS PAYMENT GATEWAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buka antarmuka resmi Midtrans Snap untuk memilih QRIS, BCA/Mandiri/BNI/BRI VA, atau Kartu Kredit agar langsung terdaftar di Midtrans Simulator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 20),

                // Tombol Buka Browser Resmi Midtrans
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _bukaDiBrowserDefault,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text(
                      'BUKA GATEWAY MIDTRANS DI BROWSER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Salin Link
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _salinLink,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text(
                      'SALIN TAUTAN MIDTRANS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Petunjuk Simulator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        size: 16, color: Color(0xFF111827)),
                    SizedBox(width: 8),
                    Text(
                      'CARA PENGUJIAN DI SIMULATOR:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('1. Klik tombol "BUKA GATEWAY MIDTRANS DI BROWSER" di atas.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                Text('2. Pilih saluran pembayaran (misal: Virtual Account BCA atau GoPay QRIS).',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                Text('3. Salin nomor VA yang diberikan Midtrans.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                Text('4. Buka https://simulator.sandbox.midtrans.com/ lalu tempel nomor VA dan bayar.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                Text('5. Aplikasi ME Atelier akan otomatis mendeteksi status LUNAS tanpa perlu reload.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  3. FOOTER NATIVE: TOMBOL KONTROL
  // =========================================================================

  Widget _bangunFooterNative() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cek Status (Otomatis & Manual)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sedangMemeriksa ? null : _periksaStatusManual,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                icon: _sedangMemeriksa
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF111827),
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 16),
                label: const Text(
                  'CEK STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Opsi Ubah ke COD
            if (_nominalTotal <= 2500000) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _sedangMemprosesAksi ? null : _tampilkanDialogUbahMetode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaAplikasi.primary,
                    side: const BorderSide(color: TemaAplikasi.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text(
                    'UBAH KE COD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Simulasi Lunas Dev (Satu Sentuhan)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sedangMemeriksa ? null : _simulasiBayarDev,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text(
                  'SIMULASI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
