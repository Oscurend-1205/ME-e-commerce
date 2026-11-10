import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/komponen_header.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Pembayaran Berhasil — konfirmasi pesanan setelah pembayaran
/// diterima. Desain mengikuti cek-pembayaran-berhasil.html.
class HalamanPembayaranBerhasil extends StatefulWidget {
  final int pesananId;

  const HalamanPembayaranBerhasil({super.key, required this.pesananId});

  @override
  State<HalamanPembayaranBerhasil> createState() =>
      _HalamanPembayaranBerhasilState();
}

class _HalamanPembayaranBerhasilState extends State<HalamanPembayaranBerhasil> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  Pesanan? _pesanan;

  @override
  void initState() {
    super.initState();
    _muatPesanan();
  }

  Future<void> _muatPesanan() async {
    setState(() => _keadaan = KeadaanMuat.memuat);

    final respon = await LayananApi.ambilRincianPesanan(widget.pesananId);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      setState(() {
        _pesanan = Pesanan.fromJson(respon.data as Map<String, dynamic>);
        _keadaan = KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  String get _namaDepan {
    final nama = StatePengguna.namaUserNotifier.value.trim();
    if (nama.isEmpty || nama == 'Tamu') return 'Klien';
    return nama.split(' ').first;
  }

  String get _labelStatus {
    switch ((_pesanan?.status ?? '').toLowerCase()) {
      case 'dibayar':
      case 'diproses':
      case 'dikirim':
      case 'selesai':
        return 'LUNAS';
      case 'dibatalkan':
        return 'DIBATALKAN';
      default:
        return 'TERKONFIRMASI';
    }
  }

  String get _estimasiKedatangan {
    final dibuat = _pesanan?.createdAt;
    if (dibuat == null) return '± 3 Hari Kerja';
    try {
      final tanggal = DateTime.parse(dibuat).add(const Duration(days: 3));
      return DateFormat("d MMMM y, HH:mm", 'id_ID').format(tanggal);
    } catch (_) {
      return '± 3 Hari Kerja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            _bangunHeader(),
            Expanded(child: _bangunKonten()),
          ],
        ),
      ),
    );
  }

  // Header: tombol kembali, label "Atelier ME" + judul serif, ikon bantuan
  Widget _bangunHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => NavigasiUniversal.keBeranda(context),
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ATELIER ME',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                  Text(
                    'Konfirmasi Pesanan',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              tooltip: 'Bantuan Concierge',
              icon: const Icon(
                Icons.support_agent_rounded,
                size: 20,
                color: TemaAplikasi.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatPesanan,
        );
      case KeadaanMuat.kosong:
      case KeadaanMuat.berhasil:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              _bangunIkonSukses(),
              const SizedBox(height: 20),
              const Text(
                'KONFIRMASI PEMBAYARAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terima Kasih, $_namaDepan',
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: TemaAplikasi.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Pesanan eksklusif Anda telah terkonfirmasi dan sedang dipersiapkan oleh kurator Atelier ME.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 22),
              _bangunNomorPesanan(),
              const SizedBox(height: 22),
              _bangunRincian(),
              const SizedBox(height: 26),
              _bangunTombolAksi(),
              const SizedBox(height: 30),
              _bangunFooterBrand(),
            ],
          ),
        );
    }
  }

  Widget _bangunIkonSukses() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TemaAplikasi.primary, width: 1.2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_rounded,
        size: 30,
        color: TemaAplikasi.primary,
      ),
    );
  }

  // "Pesanan #ME-XXXXXX • LUNAS" dengan garis bawah
  Widget _bangunNomorPesanan() {
    final p = _pesanan;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PESANAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '#${p?.nomorPesanan ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text('•', style: TextStyle(color: TemaAplikasi.secondary)),
          const SizedBox(width: 10),
          Text(
            _labelStatus,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Kotak rincian: Total, Metode, Estimasi Kedatangan, Tujuan
  Widget _bangunRincian() {
    final p = _pesanan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
          bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          _barisRincian(
            label: 'TOTAL PEMBAYARAN',
            nilai: formatRupiah(p?.total ?? 0),
            serif: true,
          ),
          _barisRincian(
            label: 'METODE',
            nilai: p?.metodePembayaran ?? '-',
          ),
          _barisRincian(
            label: 'ESTIMASI KEDATANGAN',
            nilai: _estimasiKedatangan,
          ),
          _barisRincian(
            label: 'TUJUAN',
            nilai: p?.alamat ?? '-',
            rataKanan: true,
          ),
        ],
      ),
    );
  }

  Widget _barisRincian({
    required String label,
    required String nilai,
    bool serif = false,
    bool rataKanan = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            rataKanan ? CrossAxisAlignment.start : CrossAxisAlignment.baseline,
        textBaseline:
            rataKanan ? null : TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nilai,
              textAlign: rataKanan ? TextAlign.right : TextAlign.left,
              maxLines: rataKanan ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: serif ? 18 : 12,
                fontFamily: serif ? 'PlayfairDisplay' : null,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: TemaAplikasi.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunTombolAksi() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HalamanRincianPesanan(pesananId: widget.pesananId),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LIHAT DETAIL PESANAN'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => NavigasiUniversal.keBeranda(context),
            child: const Text(
              'KEMBALI KE BERANDA',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                color: TemaAplikasi.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunFooterBrand() {
    return const Column(
      children: [
        Text(
          'M E',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
            letterSpacing: 4.0,
            color: TemaAplikasi.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'HAUTE COUTURE & MODERN TAILORING',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 3.0,
            color: TemaAplikasi.mutedGray,
          ),
        ),
      ],
    );
  }
}
