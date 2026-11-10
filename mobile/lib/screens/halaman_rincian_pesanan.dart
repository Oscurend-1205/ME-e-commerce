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
import 'halaman_login.dart';
import 'halaman_pembayaran.dart';
import 'halaman_pembayaran_qris.dart';

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

    if (status == 'menunggu_pembayaran') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (pesanan.snapToken != null &&
                    pesanan.snapToken!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanPembayaran(
                        pesananId: pesanan.id,
                        snapToken: pesanan.snapToken!,
                        redirectUrl: pesanan.redirectUrl,
                        qrUrl: pesanan.qrUrl,
                        qrString: pesanan.qrString,
                        nomorPesanan: pesanan.nomorPesanan,
                        total: pesanan.total,
                      ),
                    ),
                  ).then((_) => _muatRincianPesanan());
                } else if (pesanan.metodePembayaran?.toLowerCase().contains(
                      'qris',
                    ) ==
                    true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanPembayaranQris(
                        pesananId: pesanan.id,
                        nomorPesanan: pesanan.nomorPesanan,
                        total: pesanan.total,
                        qrUrl: pesanan.qrUrl,
                        qrString: pesanan.qrString,
                      ),
                    ),
                  ).then((_) => _muatRincianPesanan());
                } else {
                  _ubahStatus('menunggu_konfirmasi');
                }
              },
              icon: const Icon(Icons.payment, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              label: const Text(
                'BAYAR SEKARANG (MIDTRANS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
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
                dialogPesan:
                    'Apakah Anda yakin ingin membatalkan pesanan ini? Stok varian akan otomatis dikembalikan.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.errorColor,
                side: const BorderSide(color: TemaAplikasi.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'BATALKAN PESANAN',
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
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _ubahStatus('dibayar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TemaAplikasi.primary,
            foregroundColor: TemaAplikasi.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            elevation: 0,
          ),
          child: const Text(
            'KONFIRMASI PEMBAYARAN (ADMIN)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
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
