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
import 'halaman_pembayaran_berhasil.dart';
import 'halaman_pembayaran_qris.dart';

/// Halaman Checkout Alur 03 — Metode Pembayaran & Submit.
/// Desain mengikuti cek-checkout3.html.
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

  // Hanya tampilkan Midtrans dan COD.
  List<MetodePembayaran> get _metodeTersedia {
    return widget.daftarMetode.where((metode) {
      final kode = metode.kode.toLowerCase().trim();
      return kode == 'midtrans' ||
          kode == 'cod' ||
          kode == 'cash_on_delivery' ||
          kode == 'cash-on-delivery';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _kunciIdempotenSaatIni = const Uuid().v4();
    _metodeTerpilihFinal =
        _metodeTersedia.isNotEmpty ? _metodeTersedia.first : null;
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

    setState(() => _sedangMemproses = true);

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
    setState(() => _sedangMemproses = false);

    if (respon.berhasil && respon.data != null) {
      final pesananMap = respon.data as Map<String, dynamic>;
      final int pesananId = pesananMap['id'] is int
          ? pesananMap['id'] as int
          : int.tryParse(pesananMap['id'].toString()) ?? 0;

      final kodeMetode = _metodeTerpilihFinal?.kode ?? '';
      final redirectUrl = pesananMap['redirect_url'] as String?;
      final snapToken = pesananMap['snap_token'] as String?;
      final nomorPesanan = pesananMap['nomor_pesanan'] as String? ?? '';
      final total = pesananMap['total'] is int
          ? pesananMap['total'] as int
          : int.tryParse(pesananMap['total'].toString()) ?? 0;

      final qrUrl = pesananMap['qr_url'] as String?;
      final qrString = pesananMap['qr_string'] as String?;
      final bool isCod = kodeMetode == 'cod' ||
          kodeMetode == 'cash_on_delivery' ||
          kodeMetode == 'cash-on-delivery';

      if (kodeMetode == 'midtrans' && snapToken != null && snapToken.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat. Membuka Midtrans...'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPembayaran(
              pesananId: pesananId,
              snapToken: snapToken,
              redirectUrl: redirectUrl,
              qrUrl: qrUrl,
              qrString: qrString,
              nomorPesanan: nomorPesanan,
              total: total,
            ),
          ),
        );
      } else if (kodeMetode == 'midtrans' &&
          ((qrUrl != null && qrUrl.isNotEmpty) ||
              (qrString != null && qrString.isNotEmpty))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat. Silakan scan QRIS.'),
            backgroundColor: TemaAplikasi.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanPembayaranQris(
              pesananId: pesananId,
              nomorPesanan: nomorPesanan,
              total: total,
              qrUrl: qrUrl,
              qrString: qrString,
              expiredAt: pesananMap['expired_at'] as String?,
            ),
          ),
        );
      } else if (isCod) {
        Navigator.pushReplacement(
          context,
          ruteGeser(HalamanPembayaranBerhasil(pesananId: pesananId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Respons pembayaran tidak dikenali. Periksa konfigurasi metode pembayaran di backend.'),
            backgroundColor: TemaAplikasi.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (respon.code == '409') {
        final bool isStokIssue = respon.message.toLowerCase().contains('stok');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: TemaAplikasi.surfaceWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            title: Text(
              isStokIssue ? 'Stok Tidak Mencukupi' : 'Pemberitahuan Transaksi',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: TemaAplikasi.primary,
              ),
            ),
            content: Text(
              respon.message,
              style: const TextStyle(color: TemaAplikasi.secondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
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

  @override
  Widget build(BuildContext context) {
    final tanpaMetode = _metodeTersedia.isEmpty;
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      body: tanpaMetode ? _bangunErrorTanpaMetode() : _bangunKonten(),
      bottomNavigationBar: tanpaMetode ? null : _bangunBilahBawah(),
    );
  }

  // 1. Error State: tidak ada metode pembayaran tersedia
  Widget _bangunErrorTanpaMetode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: TemaAplikasi.secondary),
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
              style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
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

  // 2. Header Bar & Stepper (Langkah 03)
  Widget _bangunHeader() {
    return Container(
      width: double.infinity,
      color: TemaAplikasi.surfaceBright,
      child: SafeArea(
        bottom: false,
        child: Padding(
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
                          Icon(Icons.arrow_back,
                              size: 18, color: TemaAplikasi.secondary),
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
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  // 3. Security & Trust Reassurance
  Widget _bangunJaminanKeamanan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: TemaAplikasi.surfaceWhite,
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: TemaAplikasi.primary),
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

  // 4. Shipping Recap Summary
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
              const Icon(Icons.local_shipping_outlined,
                  size: 16, color: TemaAplikasi.primary),
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
                const Icon(Icons.card_giftcard_outlined,
                    size: 16, color: TemaAplikasi.primary),
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

  // 5. Payment Methods List
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
          ..._metodeTersedia.map((metode) => _bangunKartuMetode(metode)),
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
          color:
              terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
          width: terpilih ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _metodeTerpilihFinal = metode),
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
                    color: terpilih
                        ? TemaAplikasi.primary
                        : TemaAplikasi.surfaceContainerHigh,
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
                        if (_metodeTersedia.isNotEmpty &&
                            metode.id == _metodeTersedia.first.id)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                      metode.kode == 'midtrans'
                          ? 'QRIS, Virtual Account (BCA, Mandiri, BNI, BRI), Kartu Kredit & E-Wallet'
                          : metode.kode.contains('qris')
                              ? 'Scan via GoPay, ShopeePay, BCA, Mandiri, OVO, m-Banking (Midtrans)'
                              : metode.kode.contains('transfer')
                                  ? 'BCA, Mandiri, BNI, Permata, BRI (Verifikasi Otomatis via Midtrans)'
                                  : 'Bayar tunai kepada kurir saat pesanan tiba di alamat Anda',
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

  // 6. Final Breakdown Calculation Table
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
        const SizedBox(height: 80), // Ruang untuk bilah bawah
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
                const Text(
                  'TOTAL PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: TemaAplikasi.secondary,
                  ),
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
