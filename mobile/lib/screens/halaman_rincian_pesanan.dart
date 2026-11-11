import 'package:flutter/material.dart';

import '../enums.dart';
import '../constants.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_konfirmasi_cod.dart';
import 'halaman_login.dart';
import 'halaman_pembayaran.dart';

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
    StatePengguna.isLoggedInNotifier.addListener(_onAuthBerubah);
    if (StatePengguna.isLoggedInNotifier.value) {
      _muatRincianPesanan();
    } else {
      _keadaan = KeadaanMuat.kosong;
    }
  }

  void _onAuthBerubah() {
    if (!mounted) return;
    if (StatePengguna.isLoggedInNotifier.value) {
      _muatRincianPesanan();
    } else {
      setState(() {
        _pesanan = null;
        _keadaan = KeadaanMuat.kosong;
      });
    }
  }

  @override
  void dispose() {
    StatePengguna.isLoggedInNotifier.removeListener(_onAuthBerubah);
    super.dispose();
  }

  Future<void> _muatRincianPesanan() async {
    if (!StatePengguna.isLoggedInNotifier.value) {
      setState(() {
        _keadaan = KeadaanMuat.kosong;
      });
      return;
    }

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

      // Jika status masih menunggu pembayaran, cek status ke Midtrans untuk sinkronisasi
      if (p.status.toLowerCase() == 'menunggu_pembayaran' &&
          p.snapToken != null &&
          p.snapToken!.isNotEmpty) {
        _cekStatusPembayaranMidtrans(p.nomorPesanan);
      }
    } else {
      setState(() {
        _keadaan = respon.code == '404'
            ? KeadaanMuat.kosong
            : KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _cekStatusPembayaranMidtrans(String nomorPesanan) async {
    try {
      final respon = await LayananApi.cekStatusPembayaran(nomorPesanan);
      if (respon.berhasil && respon.data != null) {
        final data = respon.data as Map<String, dynamic>;
        final statusPesanan = data['status_pesanan'] as String? ?? '';
        // Jika status sudah berubah, reload rincian pesanan
        if (statusPesanan != 'menunggu_pembayaran' && mounted) {
          _muatRincianPesanan();
        }
      }
    } catch (_) {
      // Abaikan error silent check
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

    final respon = await LayananApi.ubahStatusPesanan(
      widget.pesananId,
      statusBaru,
    );

    if (!mounted) return;

    setState(() {
      _sedangMemperbaruiStatus = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pesanan berhasil diperbarui menjadi "$statusBaru".',
          ),
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

  void _bukaPembayaranMidtrans(Pesanan pesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanPembayaran(
          pesananId: pesanan.id,
          snapToken: pesanan.snapToken ?? '',
          redirectUrl: pesanan.redirectUrl,
          qrUrl: pesanan.qrUrl,
          qrString: pesanan.qrString,
          nomorPesanan: pesanan.nomorPesanan,
          total: pesanan.total,
        ),
      ),
    ).then((_) => _muatRincianPesanan());
  }

  Future<void> _tampilkanDialogUbahMetode(Pesanan pesanan) async {
    final total = pesanan.total;
    if (total > 2500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'COD hanya tersedia untuk pesanan maksimal ${formatRupiah(2500000)}.',
          ),
          backgroundColor: TemaAplikasi.errorColor,
        ),
      );
      return;
    }

    final TextEditingController alasanController = TextEditingController();
    String? alasanTerpilih;

    final daftarAlasan = [
      'Saldo e-wallet / rekening tidak mencukupi',
      'Midtrans mengalami gangguan teknis',
      'Lebih nyaman membayar saat barang tiba',
      'Tidak memiliki metode pembayaran online',
      'Alasan lainnya (tulis di bawah)',
    ];

    final hasil = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaAplikasi.surfaceWhite,
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
                                'UBAH METODE PEMBAYARAN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ganti ke Bayar di Tempat (COD)',
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
                              'Anda akan membayar ${formatRupiah(total)} tunai kepada kurir saat pesanan sampai.',
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
                      'PILIH ALASAN PERUBAHAN',
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
                                  : TemaAplikasi.surfaceWhite,
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
                                Navigator.pop(
                                    ctx, {'alasan': alasanFinal});
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

    setState(() => _sedangMemperbaruiStatus = true);

    try {
      final respon = await LayananApi.fallbackCod(
        pesananId: pesanan.id,
        alasan: hasil['alasan'] ?? 'Pengguna memilih COD dari rincian pesanan',
      );

      if (!mounted) return;
      setState(() => _sedangMemperbaruiStatus = false);

      if (respon.berhasil) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanKonfirmasiCod(
              pesananId: pesanan.id,
              dataPesananAwal: respon.data as Map<String, dynamic>?,
            ),
          ),
        ).then((_) => _muatRincianPesanan());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sedangMemperbaruiStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengganti ke COD: $e'),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
      }
    }
  }

  Color _warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return const Color(0xFFC77700);
      case 'menunggu_verifikasi':
        return const Color(0xFFB5651D);
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
      case 'menunggu_verifikasi':
        return 'MENUNGGU VERIFIKASI COD';
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
    return ValueListenableBuilder<bool>(
      valueListenable: StatePengguna.isLoggedInNotifier,
      builder: (context, isLoggedIn, _) {
        if (isLoggedIn && _pesanan == null && _keadaan != KeadaanMuat.memuat) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                StatePengguna.isLoggedInNotifier.value &&
                _keadaan != KeadaanMuat.memuat) {
              _muatRincianPesanan();
            }
          });
        }

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
      },
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        final belumLogin = !StatePengguna.isLoggedInNotifier.value;
        return WidgetKosong(
          ikon: belumLogin
              ? Icons.lock_outline_rounded
              : Icons.receipt_long_outlined,
          pesan: belumLogin
              ? 'Silakan masuk untuk melihat detail pesanan dan pelacakan.'
              : 'Data pesanan tidak ditemukan.',
          saranAksi: belumLogin ? 'MASUK' : 'Kembali',
          onAksi: belumLogin
              ? () async {
                  final berhasil = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const HalamanLogin()),
                  );
                  if (berhasil == true && mounted) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HalamanRincianPesanan(pesananId: widget.pesananId),
                      ),
                    );
                  }
                }
              : () => Navigator.pop(context),
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: warna.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: warna.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _labelStatus(pesanan.status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: warna,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.mutedGray,
                        ),
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
                    Text(
                      'Kurir: ${pesanan.namaKurir}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Metode: ${pesanan.metodePembayaran}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    if (pesanan.metodePembayaran != null &&
                        (pesanan.metodePembayaran!.toLowerCase().contains('cod') ||
                            pesanan.metodePembayaran!.toLowerCase().contains('tunai'))) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F5),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFFE2DDD8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: TemaAplikasi.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Siapkan uang pas ${formatRupiah(pesanan.total)} saat kurir tiba.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TemaAplikasi.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (pesanan.status == 'menunggu_pembayaran') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceBright,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TemaAplikasi.borderGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _bukaPembayaranMidtrans(pesanan),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text(
                                'BAYAR SEKARANG (MIDTRANS)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TemaAplikasi.primary,
                                foregroundColor: TemaAplikasi.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (pesanan.total <= 2500000) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _tampilkanDialogUbahMetode(pesanan),
                                icon: const Icon(Icons.local_shipping_outlined, size: 15),
                                label: const Text(
                                  'GANTI KE BAYAR DI TEMPAT (COD)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: TemaAplikasi.primary,
                                  side: const BorderSide(color: TemaAplikasi.borderGray),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
                        Flexible(
                          child: Text(
                            formatRupiah(item.subtotal),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: TemaAplikasi.primary,
                            ),
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
                        const Text(
                          'Subtotal Produk',
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        Text(
                          formatRupiah(pesanan.subtotal),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ongkos Kirim',
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        Text(
                          formatRupiah(pesanan.ongkir),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      return const Center(
        child: CircularProgressIndicator(color: TemaAplikasi.primary),
      );
    }

    final status = pesanan.status.toLowerCase();

    // Pesanan menunggu pembayaran online — tombol trigger Midtrans & batalkan
    if (status == 'menunggu_pembayaran') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _bukaPembayaranMidtrans(pesanan),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text(
                'BAYAR SEKARANG (MIDTRANS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _ubahStatus(
                'dibatalkan',
                dialogPesan:
                    'Apakah Anda yakin ingin membatalkan pesanan ini? Stok varian akan otomatis dikembalikan ke katalog.',
              ),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text(
                'BATALKAN PESANAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.errorColor,
                side: const BorderSide(color: TemaAplikasi.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Pesanan COD menunggu verifikasi admin — bisa batalkan sebelum diproses
    if (status == 'menunggu_verifikasi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              border: Border.all(color: const Color(0xFFE2DDD8)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_top,
                  size: 22,
                  color: Color(0xFFB5651D),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MENUNGGU VERIFIKASI ADMIN (COD)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFFB5651D),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pesanan COD Anda sedang ditinjau oleh admin. Anda masih bisa membatalkan sebelum pesanan diproses.',
                        style: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.secondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _ubahStatus(
                'dibatalkan',
                dialogPesan:
                    'Apakah Anda yakin ingin membatalkan pesanan COD ini? Stok varian akan otomatis dikembalikan ke katalog.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.errorColor,
                side: const BorderSide(color: TemaAplikasi.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'BATALKAN PESANAN COD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'menunggu_konfirmasi') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceLight,
          border: Border.all(color: TemaAplikasi.borderGray),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 22,
              color: TemaAplikasi.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MENUNGGU KONFIRMASI PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Pembayaran Anda sedang dalam proses verifikasi sistem/admin Filament.',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'dibayar') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceLight,
          border: Border.all(color: TemaAplikasi.borderGray),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: TemaAplikasi.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PEMBAYARAN DITERIMA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Pesanan Anda sedang menunggu giliran pengemasan eksklusif oleh kurator Atelier ME.',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'diproses') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaAplikasi.surfaceLight,
          border: Border.all(color: TemaAplikasi.borderGray),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.archive_outlined,
              size: 22,
              color: TemaAplikasi.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PESANAN SEDANG DIKEMAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tim atelier sedang mengemas pesanan dengan segel monogram dan segera menyerahkannya ke kurir pengiriman.',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'dikirim') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONFIRMASI PENERIMAAN:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: TemaAplikasi.secondary,
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: const Text(
                'PESANAN DITERIMA (SELESAI)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
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
