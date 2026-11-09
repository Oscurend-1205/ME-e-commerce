import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import 'halaman_checkout_alur_tiga.dart';

/// Model sederhana untuk data alamat (sementara, backend belum ada API alamat)
class AlamatSementara {
  final String id;
  final String nama;
  final String telepon;
  final String alamat;
  final String label;
  final bool utama;

  AlamatSementara({
    required this.id,
    required this.nama,
    required this.telepon,
    required this.alamat,
    required this.label,
    this.utama = false,
  });
}

/// Halaman Checkout Alur 02 — Pilih Alamat & Kurir
/// Desain mengikuti cek-checkout2.html (list alamat + kurir, bukan form)
class HalamanCheckoutAlurDua extends StatefulWidget {
  final DataKeranjang dataKeranjang;
  final List<Kurir> daftarKurir;

  const HalamanCheckoutAlurDua({
    super.key,
    required this.dataKeranjang,
    required this.daftarKurir,
  });

  @override
  State<HalamanCheckoutAlurDua> createState() => _HalamanCheckoutAlurDuaState();
}

class _HalamanCheckoutAlurDuaState extends State<HalamanCheckoutAlurDua> {
  // Dummy data alamat (backend belum ada API alamat)
  final List<AlamatSementara> _daftarAlamat = [
    AlamatSementara(
      id: '1',
      nama: 'Clarissa Adiwidjaja',
      telepon: '+62 812-3456-7890',
      alamat: 'Apartemen Keraton At The Plaza, Lt. 28 Unit B, Jl. M.H. Thamrin No. 9, Menteng, Jakarta Pusat, DKI Jakarta 10350',
      label: 'RUMAH',
      utama: true,
    ),
    AlamatSementara(
      id: '2',
      nama: 'Clarissa Adiwidjaja (ME Atelier HQ)',
      telepon: '+62 812-9876-5432',
      alamat: 'Sequis Center Lantai 12, Jl. Jend. Sudirman Kav 71, SCBD, Senayan, Kebayoran Baru, Jakarta Selatan 12190',
      label: 'KANTOR',
    ),
  ];

  AlamatSementara? _alamatTerpilih;
  Kurir? _kurirTerpilih;
  bool _kemasHadiah = true;
  final TextEditingController _kartuUcapanController = TextEditingController(
    text: 'Untuk Clarissa terkasih, selamat atas pembukaan galeri barumu. Semoga koleksi ini melengkapi keanggunanmu.',
  );

  @override
  void initState() {
    super.initState();
    _alamatTerpilih = _daftarAlamat.firstWhere(
      (a) => a.utama,
      orElse: () => _daftarAlamat.first,
    );
    _kurirTerpilih = widget.daftarKurir.isNotEmpty ? widget.daftarKurir.first : null;
  }

  @override
  void dispose() {
    _kartuUcapanController.dispose();
    super.dispose();
  }

  int get _ongkir => _kurirTerpilih?.tarif ?? 0;
  int get _total => widget.dataKeranjang.subtotal + _ongkir;

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanCheckoutAlurTiga(
          dataKeranjang: widget.dataKeranjang,
          kurirTerpilih: _kurirTerpilih,
          alamatTerpilih: _alamatTerpilih!,
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
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        color: TemaAplikasi.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'KEMBALI KE TAS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'LANGKAH 02 / 03',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pengiriman & Alamat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
              color: TemaAplikasi.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih alamat tujuan dan kurir concierge eksklusif untuk pesanan Anda',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.mutedGray,
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
          final aktif = i == 1;
          final selesai = i < 1;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i > 0
                            ? (selesai ? TemaAplikasi.primary : TemaAplikasi.borderGray)
                            : Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (aktif || selesai) ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
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
                                    : TemaAplikasi.secondary,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i < 2
                            ? (aktif ? TemaAplikasi.primary : TemaAplikasi.borderGray)
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
                    color: aktif ? TemaAplikasi.primary : TemaAplikasi.secondary,
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur tambah alamat baru segera hadir.'),
                      backgroundColor: TemaAplikasi.primary,
                    ),
                  );
                },
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

  Widget _bangunKartuAlamat(AlamatSementara alamat) {
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
        color: terpilih ? TemaAplikasi.surfaceLight : TemaAplikasi.surfaceContainerLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceWhite,
                border: Border.all(
                  color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
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
                          alamat.label,
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
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        color: terpilih ? TemaAplikasi.surfaceLight : TemaAplikasi.surfaceContainerLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceWhite,
                border: Border.all(
                  color: terpilih ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
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

  // 4. Section: LAYANAN ME GIFTING & PROTEKSI
  Widget _bangunLayananGift() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'LAYANAN ME GIFTING & PROTEKSI',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gift Packaging Toggle
          Container(
            padding: const EdgeInsets.all(16),
            color: TemaAplikasi.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.redeem_outlined,
                          size: 20,
                          color: TemaAplikasi.primary,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kemas Sebagai Hadiah',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kotak Pita Sutra Hitam ME Signature + Kertas Tisu Putih',
                              style: TextStyle(
                                fontSize: 11,
                                color: TemaAplikasi.mutedGray,
                              ),
                            ),
                          ],
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
                if (_kemasHadiah) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: TemaAplikasi.surfaceWhite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KARTU UCAPAN PRIBADI (KALIGRAFI ME)',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _kartuUcapanController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Tuliskan pesan berkesan Anda di sini (maks. 120 kata)...',
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.all(8),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Dicetak pada kartu linen bertekstur 300gsm',
                              style: TextStyle(
                                fontSize: 10,
                                color: TemaAplikasi.mutedGray,
                              ),
                            ),
                            Text(
                              'GRATIS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Shipping Insurance
          Container(
            padding: const EdgeInsets.all(14),
            color: TemaAplikasi.surfaceLight,
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 20,
                  color: TemaAplikasi.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Proteksi Penuh Pengiriman Mewah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Garansi ganti rugi 100% atas kerusakan & kehilangan transit',
                        style: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    Icon(
                      Icons.check,
                      size: 16,
                      color: TemaAplikasi.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Section: RINGKASAN BARANG SINGKAT
  Widget _bangunRingkasanBarang() {
    final items = widget.dataKeranjang.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM DIKIRIM (${items.length} PRODUK)',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const Text(
                'Dari Butik ME Plaza Senayan',
                style: TextStyle(
                  fontSize: 11,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length > 2 ? 2 : items.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final gambar = item.gambar != null && item.gambar!.trim().isNotEmpty
                    ? '${Konstan.storageUrl}/${item.gambar}'
                    : '${Konstan.storageUrl}/${item.produkId}.jpg';

                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(8),
                  color: TemaAplikasi.surfaceLight,
                  child: Row(
                    children: [
                      ClipRect(
                        child: Container(
                          width: 48,
                          height: 56,
                          color: TemaAplikasi.surfaceContainer,
                          child: FotoDummy.bangunGambar(
                            url: gambar,
                            fit: BoxFit.cover,
                            cacheWidth: 144,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.namaProduk,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                            Text(
                              '${item.ukuran} | ${item.warna}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: TemaAplikasi.mutedGray,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              formatRupiah(item.hargaSatuan),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
        const SizedBox(height: 8),
        _bangunRingkasanBarang(),
        const SizedBox(height: 100), // Space for bottom bar
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
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
                        if (_ongkir == 0) ...[
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
                      _kurirTerpilih?.tarif == 0 ? 'Besok Sore (Concierge)' : '2-3 Hari Kerja',
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
                onPressed: _lanjutKePembayaran,
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
