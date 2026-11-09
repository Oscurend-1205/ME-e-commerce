import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alamat.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/transisi_geser.dart';
import '../widgets/widget_stepper_checkout.dart';
import 'halaman_pembayaran.dart';
import 'halaman_pembayaran_qris.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Checkout Alur 03 — Metode Pembayaran & Submit
/// Desain mengikuti cek-checkout3.html
/// Seluruh data referensi (keranjang, kurir, metode pembayaran, alamat)
/// sudah dibawa dari langkah sebelumnya sehingga halaman ini
/// langsung tampil tanpa loading.
class HalamanCheckoutAlurTiga extends StatefulWidget {
  final DataKeranjang dataKeranjang;
  final Kurir? kurirTerpilih;
  final Alamat alamatTerpilih;
  final List<MetodePembayaran> daftarMetode;
  final bool kemasHadiah;
  final String kartuUcapan;

  const HalamanCheckoutAlurTiga({
    super.key,
    required this.dataKeranjang,
    this.kurirTerpilih,
    required this.alamatTerpilih,
    required this.daftarMetode,
    this.kemasHadiah = false,
    this.kartuUcapan = '',
  });

  @override
  State<HalamanCheckoutAlurTiga> createState() => _HalamanCheckoutAlurTigaState();
}

class _HalamanCheckoutAlurTigaState extends State<HalamanCheckoutAlurTiga> {
  MetodePembayaran? _metodeTerpilihFinal;

  bool _sedangMemproses = false;
  String? _kunciIdempotenSaatIni;

  @override
  void initState() {
    super.initState();
    _kunciIdempotenSaatIni = const Uuid().v4();
    _metodeTerpilihFinal =
        widget.daftarMetode.isNotEmpty ? widget.daftarMetode.first : null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _ongkir => widget.kurirTerpilih?.tarif ?? 0;
  int get _subtotal => widget.dataKeranjang.subtotal;
  int get _total => _subtotal + _ongkir;

  Future<void> _bayarSekarang() async {
    if (_metodeTerpilihFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu.'),
          backgroundColor: TemaAplikasi.primary,
        ),
      );
      return;
    }

    setState(() {
      _sedangMemproses = true;
    });

    final alamatLengkap = widget.alamatTerpilih.alamat;

    final catatan = [
      if (widget.alamatTerpilih.catatan.isNotEmpty)
        'Catatan alamat: ${widget.alamatTerpilih.catatan}',
      if (widget.kemasHadiah) 'Kemas sebagai hadiah',
      if (widget.kartuUcapan.isNotEmpty)
        'Kartu ucapan: ${widget.kartuUcapan}',
    ].join('\n');

    final respon = await LayananApi.checkout(
      kunciIdempoten: _kunciIdempotenSaatIni!,
      nama: widget.alamatTerpilih.nama,
      alamat: alamatLengkap,
      catatan: catatan.isEmpty ? null : catatan,
      kurirId: widget.kurirTerpilih?.id ?? 0,
      metodePembayaranId: _metodeTerpilihFinal!.id,
    );

    if (!mounted) return;

    setState(() {
      _sedangMemproses = false;
    });

    if (respon.berhasil && respon.data != null) {
      final pesananMap = respon.data as Map<String, dynamic>;
      final int pesananId = pesananMap['id'] is int
          ? pesananMap['id'] as int
          : int.tryParse(pesananMap['id'].toString()) ?? 0;

      // Cek apakah metode pembayaran adalah QRIS
      final kodeMetode = _metodeTerpilihFinal?.kode ?? '';
      final snapToken = pesananMap['snap_token'] as String?;
      final nomorPesanan = pesananMap['nomor_pesanan'] as String? ?? '';

      if (kodeMetode == 'qris') {
        // Navigasi ke halaman QRIS
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat. Silakan scan QRIS untuk pembayaran.'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPembayaranQris(
              pesananId: pesananId,
              nomorPesanan: nomorPesanan,
              total: pesananMap['total'] ?? 0,
            ),
          ),
        );
      } else if (snapToken != null && snapToken.isNotEmpty) {
        // Navigasi ke halaman pembayaran Midtrans
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat. Silakan selesaikan pembayaran.'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPembayaran(
              pesananId: pesananId,
              snapToken: snapToken,
              nomorPesanan: nomorPesanan,
            ),
          ),
        );
      } else {
        // Fallback: jika tidak ada snap_token, tampilkan opsi manual
        _tampilkanOpsiPembayaranManual(pesananId, pesananMap);
      }
    } else {
      // 409 Conflict: Stok Habis saat Checkout Atomic
      if (respon.code == '409') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: TemaAplikasi.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            title: const Text(
              'Stok Tidak Mencukupi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: TemaAplikasi.primary,
              ),
            ),
            content: Text(
              respon.message,
              style: const TextStyle(
                color: TemaAplikasi.secondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'MENGERTI',
                  style: TextStyle(
                    color: TemaAplikasi.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (respon.code == '422') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  }

  void _tampilkanOpsiPembayaranManual(int pesananId, Map<String, dynamic> pesananMap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        title: const Text(
          'Pembayaran Manual',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: TemaAplikasi.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment gateway tidak tersedia. Pilih opsi pembayaran manual:',
              style: TextStyle(
                color: TemaAplikasi.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nomor Pesanan:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pesananMap['nomor_pesanan'] ?? '',
              style: const TextStyle(
                color: TemaAplikasi.secondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Total Pembayaran:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(pesananMap['total'] ?? 0),
              style: const TextStyle(
                color: TemaAplikasi.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Langsung ke rincian pesanan (mode simulasi)
              Navigator.pushReplacement(
                context,
                ruteGeser(HalamanRincianPesanan(pesananId: pesananId)),
              );
            },
            child: const Text(
              'BAYAR MANUAL (TEST)',
              style: TextStyle(
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BATAL',
              style: TextStyle(
                color: TemaAplikasi.secondary,
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
    final tanpaMetode = widget.daftarMetode.isEmpty;

    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      body: tanpaMetode ? _bangunErrorTanpaMetode() : _bangunKonten(),
      bottomNavigationBar: tanpaMetode ? null : _bangunBilahBawah(),
    );
  }

  Widget _bangunErrorTanpaMetode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: TemaAplikasi.secondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Metode pembayaran belum tersedia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kembali ke langkah sebelumnya dan coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: TemaAplikasi.secondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'KEMBALI',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Header Bar & Stepper (Langkah 03)
  Widget _bangunHeader() {
    return Container(
      width: double.infinity,
      color: TemaAplikasi.surfaceBright,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(2),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: TemaAplikasi.secondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Kembali ke Pengiriman',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'LANGKAH 03 / 03',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
              color: TemaAplikasi.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pilih kanal pembayaran terenkripsi untuk merampungkan pesanan Anda',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const WidgetStepperCheckout(langkahAktif: 3),
        ],
      ),
    );
  }

  // 2. Security & Trust Reassurance
  Widget _bangunJaminanKeamanan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: TemaAplikasi.surfaceWhite,
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: TemaAplikasi.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enkripsi SSL 256-Bit • Transaksi Terverifikasi & Terlindungi',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
                color: TemaAplikasi.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Shipping Recap Summary
  Widget _bangunRingkasanPengiriman() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      color: TemaAplikasi.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TUJUAN PENGIRIMAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.alamatTerpilih.nama} (${widget.alamatTerpilih.label})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.alamatTerpilih.alamat,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: TemaAplikasi.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.kurirTerpilih?.nama ?? 'Kurir'} • ${widget.kurirTerpilih?.tarif == 0 ? 'Gratis' : formatRupiah(widget.kurirTerpilih?.tarif ?? 0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.kemasHadiah) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard_outlined,
                  size: 16,
                  color: TemaAplikasi.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.kartuUcapan.isNotEmpty
                        ? 'Kemas Sebagai Hadiah (Dengan Kartu Ucapan)'
                        : 'Kemas Sebagai Hadiah (ME Signature Box)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. Payment Methods List
  Widget _bangunMetodePembayaran() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'PILIH SALURAN PEMBAYARAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                'Terverifikasi Otomatis',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.daftarMetode.map((metode) => _bangunKartuMetode(metode)),
        ],
      ),
    );
  }

  Widget _bangunKartuMetode(MetodePembayaran metode) {
    final terpilih = _metodeTerpilihFinal?.id == metode.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(
          color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
          width: terpilih ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _metodeTerpilihFinal = metode;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
                    width: 2,
                  ),
                ),
                child: terpilih
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            metode.nama,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: TemaAplikasi.primary,
                            ),
                          ),
                        ),
                        if (metode.id == widget.daftarMetode.first.id)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            color: TemaAplikasi.surfaceContainer,
                            child: const Text(
                              'Rekomendasi',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metode.kode.contains('transfer')
                          ? 'BCA, Mandiri, BNI, Permata, BRI (Verifikasi Instan)'
                          : 'Tersedia cicilan 0% hingga 12 bulan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Final Breakdown Calculation Table
  Widget _bangunRincianPembayaran() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      color: TemaAplikasi.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINCIAN PEMBAYARAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 10),
          _barisRincian('Subtotal Produk', formatRupiah(_subtotal)),
          const SizedBox(height: 8),
          _barisRincian(
            'Pengiriman ${widget.kurirTerpilih?.nama ?? 'Kurir'}',
            _ongkir == 0 ? 'Bebas Biaya' : formatRupiah(_ongkir),
          ),
          if (widget.kemasHadiah) ...[
            const SizedBox(height: 8),
            _barisRincian('Kemas Hadiah & Pita ME', 'Bebas Biaya'),
          ],
          const SizedBox(height: 8),
          _barisRincian('Pajak PPN 11%', 'Sudah Termasuk'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: TemaAplikasi.surfaceContainerHigh, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TAGIHAN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sudah termasuk PPN 11%',
                    style: TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.mutedGray,
                    ),
                  ),
                ],
              ),
              Text(
                formatRupiah(_total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                  color: TemaAplikasi.primary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barisRincian(String label, String nilai) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TemaAplikasi.secondary,
          ),
        ),
        Text(
          nilai,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TemaAplikasi.primary,
          ),
        ),
      ],
    );
  }

  Widget _bangunKonten() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _bangunHeader(),
        _bangunJaminanKeamanan(),
        _bangunRingkasanPengiriman(),
        const SizedBox(height: 8),
        _bangunMetodePembayaran(),
        const SizedBox(height: 8),
        _bangunRincianPembayaran(),
        const SizedBox(height: 80), // Space for bottom bar
      ],
    );
  }

  // 7. Sticky Bottom Action Area
  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: TemaAplikasi.surfaceContainerHigh),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatRupiah(_total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: TemaAplikasi.primary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sedangMemproses ? null : _bayarSekarang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplikasi.primary,
                  foregroundColor: TemaAplikasi.onPrimary,
                  elevation: 0,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BAYAR SEKARANG',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dengan menekan Bayar Sekarang, Anda menyetujui Ketentuan Layanan & Kebijakan Privasi ME Atelier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: TemaAplikasi.secondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
