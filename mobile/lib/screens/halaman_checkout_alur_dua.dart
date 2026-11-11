import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/alamat.dart';
import '../models/estimasi_checkout.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/transisi_geser.dart';
import '../widgets/widget_stepper_checkout.dart';
import 'halaman_checkout_alur_tiga.dart';
import 'halaman_tambah_alamat.dart';

/// Halaman Checkout Alur 02 — Pilih Alamat & Kurir
/// Desain mengikuti cek-checkout2.html (list alamat + kurir, bukan form)
class HalamanCheckoutAlurDua extends StatefulWidget {
  final DataKeranjang dataKeranjang;
  final List<int> selectedItemIds;
  final List<Kurir> daftarKurir;
  final List<MetodePembayaran> daftarMetode;

  const HalamanCheckoutAlurDua({
    super.key,
    required this.dataKeranjang,
    required this.selectedItemIds,
    required this.daftarKurir,
    required this.daftarMetode,
  });

  @override
  State<HalamanCheckoutAlurDua> createState() => _HalamanCheckoutAlurDuaState();
}

class _HalamanCheckoutAlurDuaState extends State<HalamanCheckoutAlurDua> {
  // Data alamat awal (backend belum menyediakan API alamat;
  // alamat baru dari form disimpan sementara di memori alur ini)
  final List<Alamat> _daftarAlamat = [
    const Alamat(
      id: '1',
      nama: 'Clarissa Adiwidjaja',
      telepon: '+62 812-3456-7890',
      alamat:
          'Apartemen Keraton At The Plaza, Lt. 28 Unit B, Jl. M.H. Thamrin No. 9, Menteng, Jakarta Pusat, DKI Jakarta 10350',
      label: 'Rumah',
      utama: true,
    ),
    const Alamat(
      id: '2',
      nama: 'Clarissa Adiwidjaja (ME Atelier HQ)',
      telepon: '+62 812-9876-5432',
      alamat:
          'Sequis Center Lantai 12, Jl. Jend. Sudirman Kav 71, SCBD, Senayan, Kebayoran Baru, Jakarta Selatan 12190',
      label: 'Kantor',
    ),
  ];

  Alamat? _alamatTerpilih;
  Kurir? _kurirTerpilih;
  EstimasiCheckout? _estimasiCheckout;
  KeadaanMuat _keadaanEstimasi = KeadaanMuat.memuat;
  JenisGalat _jenisGalatEstimasi = JenisGalat.tidakDiketahui;
  String? _pesanGalatEstimasi;
  int _nomorPermintaanEstimasi = 0;
  bool _kemasHadiah = false;
  final TextEditingController _kartuUcapanController = TextEditingController();

  String get _pesanTampilanGalatEstimasi {
    switch (_jenisGalatEstimasi) {
      case JenisGalat.tidakAdaSambungan:
        return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      case JenisGalat.batasWaktu:
        return 'Server tidak merespons. Silakan coba lagi.';
      case JenisGalat.validasi422:
      case JenisGalat.bentrok409:
        return _pesanGalatEstimasi ?? 'Estimasi belum tersedia.';
      case JenisGalat.server500:
        return 'Terjadi kesalahan pada server. Silakan coba lagi.';
      case JenisGalat.tidakDiketahui:
        return 'Estimasi tidak dapat dimuat. Silakan coba lagi.';
    }
  }

  @override
  void initState() {
    super.initState();
    _alamatTerpilih = _daftarAlamat.firstWhere(
      (a) => a.utama,
      orElse: () => _daftarAlamat.first,
    );
    _kurirTerpilih = widget.daftarKurir.isNotEmpty
        ? widget.daftarKurir.first
        : null;
    _muatEstimasiCheckout();
  }

  @override
  void dispose() {
    _kartuUcapanController.dispose();
    super.dispose();
  }

  Future<void> _muatEstimasiCheckout() async {
    final kurir = _kurirTerpilih;
    if (kurir == null) {
      setState(() {
        _keadaanEstimasi = KeadaanMuat.kosong;
        _estimasiCheckout = null;
        _pesanGalatEstimasi = null;
      });
      return;
    }

    final nomorPermintaan = ++_nomorPermintaanEstimasi;
    setState(() {
      _keadaanEstimasi = KeadaanMuat.memuat;
      _pesanGalatEstimasi = null;
      _estimasiCheckout = null;
    });

    final respon = await LayananApi.estimasiCheckout(
      kurirId: kurir.id,
      itemKeranjangIds: widget.selectedItemIds,
    );

    if (!mounted || nomorPermintaan != _nomorPermintaanEstimasi) return;

    setState(() {
      if (respon.berhasil && respon.data != null) {
        _estimasiCheckout = respon.data;
        _keadaanEstimasi = KeadaanMuat.berhasil;
      } else {
        _jenisGalatEstimasi = tentukanJenisGalat(respon.code);
        _pesanGalatEstimasi = respon.message;
        _keadaanEstimasi = KeadaanMuat.galat;
      }
    });
  }

  Future<void> _tambahAlamat() async {
    final alamatBaru = await Navigator.push<Alamat>(
      context,
      ruteGeser(const HalamanTambahAlamat()),
    );

    if (alamatBaru == null || !mounted) return;

    setState(() {
      if (alamatBaru.utama) {
        for (var i = 0; i < _daftarAlamat.length; i++) {
          final lama = _daftarAlamat[i];
          if (lama.utama) {
            _daftarAlamat[i] = Alamat(
              id: lama.id,
              nama: lama.nama,
              telepon: lama.telepon,
              alamat: lama.alamat,
              label: lama.label,
              catatan: lama.catatan,
              utama: false,
            );
          }
        }
      }
      _daftarAlamat.add(alamatBaru);
      _alamatTerpilih = alamatBaru;
    });
  }

  void _lanjutKePembayaran() {
    if (_alamatTerpilih == null || _kurirTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alamat dan kurir terlebih dahulu.'),
          backgroundColor: TemaAplikasi.primary,
        ),
      );
      return;
    }

    final estimasi = _estimasiCheckout;
    if (estimasi == null) {
      _muatEstimasiCheckout();
      return;
    }

    Navigator.push(
      context,
      ruteGeser(
        HalamanCheckoutAlurTiga(
          dataKeranjang: widget.dataKeranjang,
          estimasiCheckout: estimasi,
          selectedItemIds: widget.selectedItemIds,
          kurirTerpilih: _kurirTerpilih,
          alamatTerpilih: _alamatTerpilih!,
          daftarMetode: widget.daftarMetode,
          kemasHadiah: _kemasHadiah,
          kartuUcapan: _kartuUcapanController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      body: _bangunKonten(),
      bottomNavigationBar: _bangunBilahBawah(),
    );
  }

  // 1. Header Bar & Stepper (Langkah 02)
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
                            'Kembali ke Review Pesanan',
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
                    'LANGKAH 02 / 03',
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
                'Pengiriman & Alamat',
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
                'Pilih alamat tujuan dan kurir eksklusif untuk pesanan Anda',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaAplikasi.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const WidgetStepperCheckout(langkahAktif: 2),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Section: ALAMAT PENERIMA
  Widget _bangunAlamatPenerima() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: TemaAplikasi.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ALAMAT PENERIMA',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _tambahAlamat,
                child: const Text(
                  '+ TAMBAH BARU',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._daftarAlamat.map((alamat) => _bangunKartuAlamat(alamat)),
        ],
      ),
    );
  }

  Widget _bangunKartuAlamat(Alamat alamat) {
    final terpilih = _alamatTerpilih?.id == alamat.id;

    return InkWell(
      onTap: () {
        setState(() {
          _alamatTerpilih = alamat;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        color: terpilih
            ? TemaAplikasi.surfaceLight
            : TemaAplikasi.surfaceContainerLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: terpilih
                    ? TemaAplikasi.primary
                    : TemaAplikasi.surfaceWhite,
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
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TemaAplikasi.onPrimary,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        alamat.nama,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      if (alamat.utama)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          color: TemaAplikasi.primary,
                          child: const Text(
                            'UTAMA',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: TemaAplikasi.onPrimary,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: TemaAplikasi.surfaceContainerHigh,
                        child: Text(
                          alamat.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alamat.telepon,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alamat.alamat,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaAplikasi.primary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Section: PILIHAN KURIR PENGIRIMAN
  Widget _bangunPilihanKurir() {
    if (widget.daftarKurir.isEmpty) return const SizedBox.shrink();

    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 18,
                    color: TemaAplikasi.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PILIHAN KURIR PENGIRIMAN',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.daftarKurir.length} Opsi Tersedia',
                style: const TextStyle(
                  fontSize: 10,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.daftarKurir.map((kurir) => _bangunKartuKurir(kurir)),
        ],
      ),
    );
  }

  Widget _bangunKartuKurir(Kurir kurir) {
    final terpilih = _kurirTerpilih?.id == kurir.id;
    final estimasi = kurir.tarif == 0 ? 'GRATIS' : formatRupiah(kurir.tarif);

    return InkWell(
      onTap: () {
        setState(() {
          _kurirTerpilih = kurir;
        });
        _muatEstimasiCheckout();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        color: terpilih
            ? TemaAplikasi.surfaceLight
            : TemaAplikasi.surfaceContainerLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: terpilih
                    ? TemaAplikasi.primary
                    : TemaAplikasi.surfaceWhite,
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
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TemaAplikasi.onPrimary,
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
                    children: [
                      Expanded(
                        child: Text(
                          kurir.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ),
                      if (kurir.id == widget.daftarKurir.first.id)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          color: TemaAplikasi.primary,
                          child: const Text(
                            'EKSKLUSIF',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: TemaAplikasi.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kurir.wilayah.isNotEmpty
                        ? 'Wilayah ${kurir.wilayah}'
                        : 'Layanan prioritas ME Atelier',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengiriman ${kurir.nama} dengan estimasi tiba ${kurir.tarif == 0 ? 'Besok' : '2-3 Hari Kerja'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  estimasi,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: TemaAplikasi.primary,
                  ),
                ),
                if (kurir.tarif > 0)
                  const Text(
                    'Rp 0',
                    style: TextStyle(
                      fontSize: 10,
                      color: TemaAplikasi.mutedGray,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Section: LAYANAN ME GIFTING (OPSIONAL)
  Widget _bangunLayananGift() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 18,
                    color: TemaAplikasi.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'KEMAS SEBAGAI HADIAH',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _kemasHadiah,
                onChanged: (value) {
                  setState(() {
                    _kemasHadiah = value;
                  });
                },
                activeThumbColor: TemaAplikasi.onPrimary,
                activeTrackColor: TemaAplikasi.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Kotak pita sutra hitam ME Signature dan kertas tisu atelier (Bebas Biaya)',
            style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
          ),
          if (_kemasHadiah) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _kartuUcapanController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tuliskan pesan kartu ucapan khusus (opsional)...',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: TemaAplikasi.mutedGray,
                ),
                filled: true,
                fillColor: TemaAplikasi.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(
                    color: TemaAplikasi.surfaceContainerHigh,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(
                    color: TemaAplikasi.surfaceContainerHigh,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 12, color: TemaAplikasi.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bangunKonten() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _bangunHeader(),
        const SizedBox(height: 8),
        _bangunAlamatPenerima(),
        const SizedBox(height: 8),
        _bangunPilihanKurir(),
        const SizedBox(height: 8),
        _bangunLayananGift(),
        const SizedBox(height: 80),
      ],
    );
  }

  // 6. Sticky Bottom Checkout Action Panel
  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: const Border(
          top: BorderSide(color: TemaAplikasi.surfaceContainerHigh),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL TAGIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: TemaAplikasi.mutedGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_keadaanEstimasi == KeadaanMuat.memuat)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_keadaanEstimasi == KeadaanMuat.berhasil &&
                        _estimasiCheckout != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatRupiah(_estimasiCheckout!.total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                              color: TemaAplikasi.primary,
                              height: 1.2,
                            ),
                          ),
                          if (_estimasiCheckout!.ongkir == 0) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '(BEBAS ONGKIR)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: TemaAplikasi.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_keadaanEstimasi == KeadaanMuat.kosong)
                      const Text(
                        'Pilih kurir untuk melihat estimasi.',
                        style: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.mutedGray,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pesanTampilanGalatEstimasi,
                            style: const TextStyle(
                              fontSize: 11,
                              color: TemaAplikasi.errorColor,
                            ),
                          ),
                          TextButton(
                            onPressed: _muatEstimasiCheckout,
                            child: const Text('Coba hitung ulang'),
                          ),
                        ],
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ESTIMASI TIBA',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _kurirTerpilih?.tarif == 0
                          ? 'Besok Sore (Concierge)'
                          : '2-3 Hari Kerja',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    _keadaanEstimasi != KeadaanMuat.berhasil ||
                        _estimasiCheckout == null
                    ? null
                    : _lanjutKePembayaran,
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
                      'LANJUT KE PEMBAYARAN',
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
