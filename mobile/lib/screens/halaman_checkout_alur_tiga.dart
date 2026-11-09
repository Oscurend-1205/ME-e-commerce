import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_checkout_alur_dua.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Checkout Alur 03 — Metode Pembayaran & Submit
/// Desain mengikuti cek-checkout3.html
class HalamanCheckoutAlurTiga extends StatefulWidget {
  final DataKeranjang dataKeranjang;
  final Kurir? kurirTerpilih;
  final AlamatSementara alamatTerpilih;
  final bool kemasHadiah;
  final String kartuUcapan;

  const HalamanCheckoutAlurTiga({
    super.key,
    required this.dataKeranjang,
    this.kurirTerpilih,
    required this.alamatTerpilih,
    this.kemasHadiah = false,
    this.kartuUcapan = '',
  });

  @override
  State<HalamanCheckoutAlurTiga> createState() => _HalamanCheckoutAlurTigaState();
}

class _HalamanCheckoutAlurTigaState extends State<HalamanCheckoutAlurTiga> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  List<MetodePembayaran> _daftarMetode = [];
  MetodePembayaran? _metodeTerpilihFinal;

  bool _sedangMemproses = false;
  String? _kunciIdempotenSaatIni;

  @override
  void initState() {
    super.initState();
    _kunciIdempotenSaatIni = const Uuid().v4();
    _muatData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final responMetode = await LayananApi.ambilMetodePembayaran();

    if (!mounted) return;

    if (!responMetode.berhasil) {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(responMetode.code);
        _pesanGalat = responMetode.message;
      });
      return;
    }

    final metodeRaw = responMetode.data is List
        ? responMetode.data as List
        : [];

    if (metodeRaw.isEmpty) {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = JenisGalat.tidakDiketahui;
        _pesanGalat = 'Data metode pembayaran belum tersedia.';
      });
      return;
    }

    final metodeList = metodeRaw
        .map((m) => MetodePembayaran.fromJson(m as Map<String, dynamic>))
        .toList();

    setState(() {
      _daftarMetode = metodeList;
      _metodeTerpilihFinal = metodeList.first;
      _keadaan = KeadaanMuat.berhasil;
    });
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

    final respon = await LayananApi.checkout(
      kunciIdempoten: _kunciIdempotenSaatIni!,
      nama: widget.alamatTerpilih.nama,
      alamat: alamatLengkap,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan Anda berhasil dibuat.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanRincianPesanan(pesananId: pesananId),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      body: _keadaan == KeadaanMuat.memuat
          ? const WidgetMemuat()
          : _keadaan == KeadaanMuat.galat
          ? WidgetGalat(
              jenisGalat: _jenisGalat,
              pesan: _pesanGalat,
              onCobaLagi: _muatData,
            )
          : _bangunKonten(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil
          ? _bangunBilahBawah()
          : null,
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
              fontSize: 26,
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
          _bangunStepper(),
        ],
      ),
    );
  }

  Widget _bangunStepper() {
    const label = ['01. TAS', '02. KIRIM', '03. BAYAR'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(3, (i) {
          final aktif = i == 2;
          final selesai = i < 2;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i > 0
                            ? (selesai ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh)
                            : Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (aktif || selesai) ? TemaAplikasi.primary : Colors.transparent,
                        border: (aktif || selesai)
                            ? null
                            : Border.all(color: TemaAplikasi.surfaceContainerHigh),
                      ),
                      alignment: Alignment.center,
                      child: selesai
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: TemaAplikasi.onPrimary,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: aktif
                                    ? TemaAplikasi.onPrimary
                                    : TemaAplikasi.mutedGray,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i < 2
                            ? (aktif ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label[i],
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: aktif ? TemaAplikasi.primary : TemaAplikasi.mutedGray,
                    decoration: aktif ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // 2. Countdown Reservation Banner & Security
  Widget _bangunCountdownBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      color: TemaAplikasi.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: TemaAplikasi.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'RESERVASI STOK EKSKLUSIF',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              const Text(
                '14:59',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 15,
                color: TemaAplikasi.secondary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '256-bit SSL Encrypted • Verifikasi Keamanan 3D Secure',
                  style: TextStyle(
                    fontSize: 12,
                    color: TemaAplikasi.secondary,
                  ),
                ),
              ),
            ],
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
          ..._daftarMetode.map((metode) => _bangunKartuMetode(metode)),
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
                        if (metode.id == _daftarMetode.first.id)
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

  // 5. Editorial Gift Packaging Assurance Note
  Widget _bangunCatatanKemasan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      color: TemaAplikasi.surfaceContainerLow,
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard_outlined,
            size: 20,
            color: TemaAplikasi.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'KEMASAN KHAS ATELIER ME',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Setiap busana dikemas dalam kotak bertanda monogram sutra pelindung debu.',
                  style: TextStyle(
                    fontSize: 12,
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
            _ongkir == 0 ? 'Gratis' : formatRupiah(_ongkir),
          ),
          const SizedBox(height: 8),
          _barisRincian('Proteksi & Kemas Hadiah', 'Gratis Privé'),
          const SizedBox(height: 8),
          _barisRincian('Asuransi Pengiriman Penuh', 'Bebas Biaya'),
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
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bangunHeader(),
          _bangunCountdownBanner(),
          _bangunRingkasanPengiriman(),
          const SizedBox(height: 16),
          _bangunMetodePembayaran(),
          const SizedBox(height: 16),
          _bangunCatatanKemasan(),
          _bangunRincianPembayaran(),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
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
