import 'package:flutter/material.dart';

import '../constants.dart';
import '../enums.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/transisi_geser.dart';
import '../widgets/widget_keadaan.dart';
import '../widgets/widget_stepper_checkout.dart';
import 'halaman_checkout_alur_dua.dart';

/// Halaman Checkout Alur 01 — Review pesanan sesuai cek-checkout1.html
/// Menampilkan ringkasan item, alamat (placeholder), kurir & pembayaran
/// terpilih, voucher, dan ringkasan tagihan sebelum lanjut ke langkah 02.
class HalamanCheckoutAlurSatu extends StatefulWidget {
  final List<int> selectedItemIds;

  const HalamanCheckoutAlurSatu({
    super.key,
    required this.selectedItemIds,
  });

  @override
  State<HalamanCheckoutAlurSatu> createState() => _HalamanCheckoutAlurSatuState();
}

class _HalamanCheckoutAlurSatuState extends State<HalamanCheckoutAlurSatu> {
  final TextEditingController _kodePromoController = TextEditingController();

  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  DataKeranjang? _dataKeranjang;
  List<Kurir> _daftarKurir = [];
  List<MetodePembayaran> _daftarMetode = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _kodePromoController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final hasil = await Future.wait([
      LayananApi.ambilKeranjang(),
      LayananApi.ambilKurir(),
      LayananApi.ambilMetodePembayaran(),
    ]);

    if (!mounted) return;

    final responKeranjang = hasil[0];
    final responKurir = hasil[1];
    final responMetode = hasil[2];

    final responGagal = [responKeranjang, responKurir, responMetode]
        .where((respon) => !respon.berhasil)
        .toList();

    if (responGagal.isNotEmpty) {
      final respon = responGagal.first;
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
      return;
    }

    final keranjangLengkap = DataKeranjang.fromJson(
      responKeranjang.data as Map<String, dynamic>,
    );
    final itemsTerpilih = keranjangLengkap.items
        .where((item) => widget.selectedItemIds.contains(item.id))
        .toList();
    final dataKeranjang = DataKeranjang(
      items: itemsTerpilih,
      subtotal: itemsTerpilih.fold<int>(
        0,
        (total, item) => total + item.subtotalItem,
      ),
    );

    if (dataKeranjang.items.isEmpty) {
      setState(() {
        _dataKeranjang = dataKeranjang;
        _keadaan = KeadaanMuat.kosong;
      });
      return;
    }

    final kurirList = (responKurir.data as List? ?? [])
        .map((k) => Kurir.fromJson(k as Map<String, dynamic>))
        .toList();
    final metodeList = (responMetode.data as List? ?? [])
        .map((m) => MetodePembayaran.fromJson(m as Map<String, dynamic>))
        .toList();

    setState(() {
      _dataKeranjang = dataKeranjang;
      _daftarKurir = kurirList;
      _daftarMetode = metodeList;
      _keadaan = KeadaanMuat.berhasil;
    });
  }

  int get _total => _dataKeranjang?.subtotal ?? 0;
  int get _jumlahItem => _dataKeranjang?.items.fold<int>(0, (t, i) => t + i.jumlah) ?? 0;

  void _lanjutKePengiriman() {
    if (_dataKeranjang == null) return;

    Navigator.push(
      context,
      ruteGeser(
        HalamanCheckoutAlurDua(
          dataKeranjang: _dataKeranjang!,
          selectedItemIds: widget.selectedItemIds,
          daftarKurir: _daftarKurir,
          daftarMetode: _daftarMetode,
        ),
      ),
    ).then((_) => _muatData());
  }

  void _pakaiKodePromo() {
    final kode = _kodePromoController.text.trim();
    if (kode.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur kode promo segera hadir.'),
        backgroundColor: TemaAplikasi.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          : _keadaan == KeadaanMuat.kosong
          ? WidgetKosong(
              ikon: Icons.shopping_bag_outlined,
              pesan: 'Keranjang kosong. Tambahkan produk sebelum checkout.',
              saranAksi: 'KEMBALI',
              onAksi: () => Navigator.pop(context),
            )
          : _bangunKonten(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil
          ? _bangunBilahBawah()
          : null,
    );
  }

  // 1. Header Bar & Editorial Checkout Stepper
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
                          Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: TemaAplikasi.secondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Kembali ke Tas Belanja',
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
                    'LANGKAH 01 / 03',
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
                'Checkout Pesanan',
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
                'Tinjau pesanan dan ringkasan tas belanja Anda',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const WidgetStepperCheckout(langkahAktif: 1),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Item Pesanan yang Dicheckout (Review Mode)
  Widget _bangunItemPesanan() {
    final items = _dataKeranjang!.items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ITEM PESANAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                '$_jumlahItem Barang',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(_bangunKartuItem),
        ],
      ),
    );
  }

  Widget _bangunKartuItem(ItemKeranjang item) {
    final gambar = item.gambar != null && item.gambar!.trim().isNotEmpty
        ? '${Konstan.storageUrl}/${item.gambar}'
        : '${Konstan.storageUrl}/${item.produkId}.jpg';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(color: TemaAplikasi.surfaceContainerHigh),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRect(
            child: Container(
              width: 80,
              height: 96,
              color: TemaAplikasi.surfaceContainer,
              child: FotoDummy.bangunGambar(
                url: gambar,
                fit: BoxFit.cover,
                cacheWidth: 240,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATELIER ME LINE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: TemaAplikasi.mutedGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.namaProduk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TemaAplikasi.primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Warna: ${item.warna}  •  Ukuran: ${item.ukuran}',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: TemaAplikasi.surfaceContainerHigh),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah: ${item.jumlah}',
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.0,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      Text(
                        formatRupiah(item.subtotalItem),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Voucher / Kode Promo ME
  Widget _bangunVoucher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KODE PROMOSI & HAK ISTIMEWA',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceWhite,
              border: Border.all(color: TemaAplikasi.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.sell_outlined,
                    size: 20,
                    color: TemaAplikasi.mutedGray,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _kodePromoController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'MASUKKAN KODE PROMO',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: TemaAplikasi.mutedGray,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _pakaiKodePromo(),
                  ),
                ),
                InkWell(
                  onTap: _pakaiKodePromo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: TemaAplikasi.surfaceContainerLow,
                    child: const Text(
                      'Pakai',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Ringkasan Rincian Pembayaran
  Widget _bangunRingkasan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      padding: const EdgeInsets.all(14),
      color: TemaAplikasi.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RINGKASAN PEMBAYARAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                '$_jumlahItem Barang',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _barisRingkasan('Subtotal Produk', formatRupiah(_dataKeranjang!.subtotal)),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Pengiriman',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                'Dihitung di langkah berikutnya',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pajak Pertambahan Nilai (PPN 11%)',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
              Text(
                'Sudah Termasuk',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
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
                    'TOTAL PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Harga Final Termasuk Asuransi',
                    style: TextStyle(
                      fontSize: 10,
                      color: TemaAplikasi.mutedGray,
                    ),
                  ),
                ],
              ),
              Text(
                formatRupiah(_total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
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

  Widget _barisRingkasan(String label, String nilai) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
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

  // Jaminan Belanja Tenang Editorial ME
  Widget _bangunJaminan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _BadgeJaminan(ikon: Icons.verified_outlined, teks: '100% Autentik'),
          _PemisahJaminan(),
          _BadgeJaminan(
            ikon: Icons.published_with_changes_outlined,
            teks: '30 Hari Retur',
          ),
          _PemisahJaminan(),
          _BadgeJaminan(ikon: Icons.lock_outline, teks: 'Aman Enkripsi'),
        ],
      ),
    );
  }

  Widget _bangunKonten() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _bangunHeader(),
        _bangunItemPesanan(),
        _bangunVoucher(),
        _bangunRingkasan(),
        _bangunJaminan(),
      ],
    );
  }

  // 8. Sticky Bottom Checkout Bar
  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: TemaAplikasi.surfaceContainerHigh),
        ),
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
                      'TOTAL TAGIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: TemaAplikasi.mutedGray,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _lanjutKePengiriman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplikasi.primary,
                  foregroundColor: TemaAplikasi.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LANJUT KE PENGIRIMAN',
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
          ],
        ),
      ),
    );
  }
}

class _BadgeJaminan extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _BadgeJaminan({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 16, color: TemaAplikasi.mutedGray),
        const SizedBox(width: 6),
        Text(
          teks,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: TemaAplikasi.mutedGray,
          ),
        ),
      ],
    );
  }
}

class _PemisahJaminan extends StatelessWidget {
  const _PemisahJaminan();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: TemaAplikasi.surfaceContainerHigh,
    );
  }
}
