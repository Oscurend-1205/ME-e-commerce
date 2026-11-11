import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_riwayat_pesanan.dart';

/// Halaman konfirmasi resmi pesanan dengan metode Cash on Delivery (COD) / Tunai di Tempat.
/// Responsif untuk mobile dan desktop (ME Atelier aesthetic).
class HalamanKonfirmasiCod extends StatefulWidget {
  final int pesananId;
  final Map<String, dynamic>? dataPesananAwal;

  const HalamanKonfirmasiCod({
    super.key,
    required this.pesananId,
    this.dataPesananAwal,
  });

  @override
  State<HalamanKonfirmasiCod> createState() => _HalamanKonfirmasiCodState();
}

class _HalamanKonfirmasiCodState extends State<HalamanKonfirmasiCod> {
  Pesanan? _pesanan;
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  @override
  void initState() {
    super.initState();
    _muatDataPesanan();
  }

  Future<void> _muatDataPesanan() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _pesanGalat = '';
    });

    final respon = await LayananApi.ambilRincianPesanan(widget.pesananId);
    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      setState(() {
        _pesanan = Pesanan.fromJson(respon.data as Map<String, dynamic>);
        _keadaan = KeadaanMuat.berhasil;
      });
    } else if (widget.dataPesananAwal != null) {
      setState(() {
        _pesanan = Pesanan.fromJson(widget.dataPesananAwal!);
        _keadaan = KeadaanMuat.berhasil;
      });
    } else if (respon.code == '404') {
      setState(() => _keadaan = KeadaanMuat.kosong);
    } else {
      setState(() {
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
        _keadaan = KeadaanMuat.galat;
      });
    }
  }

  void _salinNomorPesanan(String nomor) {
    Clipboard.setData(ClipboardData(text: nomor));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor pesanan berhasil disalin!'),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        title: const Text(
          'KONFIRMASI PESANAN COD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: TemaAplikasi.primary,
          ),
        ),
        backgroundColor: TemaAplikasi.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: TemaAplikasi.primary),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'Tutup',
          ),
        ],
      ),
      body: switch (_keadaan) {
        KeadaanMuat.memuat => const WidgetMemuat(),
        KeadaanMuat.kosong => WidgetKosong(
          ikon: Icons.receipt_long_outlined,
          pesan: 'Pesanan tidak ditemukan.',
          saranAksi: 'KEMBALI',
          onAksi: () => Navigator.pop(context),
        ),
        KeadaanMuat.galat => WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatDataPesanan,
        ),
        KeadaanMuat.berhasil => _bangunKontenUtama(),
      },
    );
  }

  Widget _bangunKontenUtama() {
    final p = _pesanan!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner Konfirmasi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: TemaAplikasi.borderGray),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: TemaAplikasi.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: TemaAplikasi.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PESANAN COD TELAH DITERIMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pesanan Anda menggunakan metode Cash on Delivery (Tunai di Tempat) dan saat ini sedang menunggu verifikasi atelier.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: TemaAplikasi.secondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _salinNomorPesanan(p.nomorPesanan),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceWhite,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: TemaAplikasi.borderGray),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No. Pesanan: #${p.nomorPesanan}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.copy,
                              size: 14,
                              color: TemaAplikasi.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Kartu Rincian Tagihan Tunai
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: TemaAplikasi.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: TemaAplikasi.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'RINCIAN TAGIHAN TUNAI (COD)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal Produk',
                          style: TextStyle(
                            color: TemaAplikasi.secondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          formatRupiah(p.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ongkos Kirim (${p.namaKurir ?? "Kurir"})',
                          style: const TextStyle(
                            color: TemaAplikasi.secondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          formatRupiah(p.ongkir),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: TemaAplikasi.borderGray,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL HARUS DIBAYAR KE KURIR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        Text(
                          formatRupiah(p.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Kartu Instruksi Pembayaran Tunai di Tempat (COD)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2DDD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: TemaAplikasi.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PANDUAN PEMBAYARAN SAAT BARANG TIBA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _bangunPoinInstruksi(
                      nomor: '1',
                      judul: 'Siapkan Uang Tunai Pas',
                      deskripsi:
                          'Siapkan uang tunai pas sebesar ${formatRupiah(p.total)} agar proses serah terima barang berlangsung cepat dan lancar.',
                    ),
                    const SizedBox(height: 10),
                    _bangunPoinInstruksi(
                      nomor: '2',
                      judul: 'Pastikan Nomor Telepon Aktif',
                      deskripsi:
                          'Kurir pengantaran akan menghubungi nomor telepon penerima sebelum menuju ke alamat pengiriman.',
                    ),
                    const SizedBox(height: 10),
                    _bangunPoinInstruksi(
                      nomor: '3',
                      judul: 'Periksa Segel Kemasan Atelier',
                      deskripsi:
                          'Periksa keutuhan paket dan label resi pengiriman sebelum menyerahkan uang pembayaran kepada kurir.',
                    ),
                    const SizedBox(height: 10),
                    _bangunPoinInstruksi(
                      nomor: '4',
                      judul: 'Simpan Bukti Pembayaran',
                      deskripsi:
                          'Mintalah bukti tanda terima resmi dari kurir setelah pembayaran tunai dilakukan.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Kartu Tujuan Pengiriman
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: TemaAplikasi.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: TemaAplikasi.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TUJUAN PENGIRIMAN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.namaPenerima.isNotEmpty ? p.namaPenerima : 'Penerima',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.alamat.isNotEmpty ? p.alamat : '-',
                      style: const TextStyle(
                        color: TemaAplikasi.secondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 5. Tombol Aksi Bawah
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TemaAplikasi.primary,
                        side: const BorderSide(color: TemaAplikasi.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'KEMBALI KE BERANDA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HalamanRiwayatPesanan(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaAplikasi.primary,
                        foregroundColor: TemaAplikasi.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'LIHAT RIWAYAT PESANAN',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunPoinInstruksi({
    required String nomor,
    required String judul,
    required String deskripsi,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: TemaAplikasi.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            nomor,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deskripsi,
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
