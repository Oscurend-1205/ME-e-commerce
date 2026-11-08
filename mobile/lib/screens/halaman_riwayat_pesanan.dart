import 'package:flutter/material.dart';

import '../theme.dart';

class HalamanRiwayatPesanan extends StatelessWidget {
  const HalamanRiwayatPesanan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Column(
          children: [
            Text(
              'Pelacakan Eksklusif',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.8,
                color: TemaAplikasi.mutedGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pesanan #ME-892401',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: TemaAplikasi.primary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Bantuan Concierge',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _bangunStatusHeader(),
            _bangunPetaPreview(),
            _bangunJejakPengiriman(),
            _bangunAlamatTujuan(),
            _bangunProdukDipesan(),
            _bangunRincianPembayaran(),
            _bangunAksi(),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Widget _bangunStatusHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: TemaAplikasi.surfaceLight,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: TemaAplikasi.primary,
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: TemaAplikasi.onPrimary),
                      SizedBox(width: 6),
                      Text(
                        'DALAM PENGIRIMAN',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'ME PRIVÉ COURIER',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.mutedGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PERKIRAAN WAKTU TIBA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tiba Besok, 18.00 WIB',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: TemaAplikasi.surfaceWhite,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ME EXPRESS CONCIERGE COURIER',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.3,
                            color: TemaAplikasi.mutedGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ME-EXP-77291048',
                          style: TextStyle(
                            fontSize: 15,
                            color: TemaAplikasi.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: TemaAplikasi.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'SALIN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _bangunPetaPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceContainer,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0x99000000),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.near_me_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Kurir berjarak 3.4 km',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: TemaAplikasi.surfaceWhite,
                    child: const Text(
                      'PETA LENGKAP',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunJejakPengiriman() {
    final timeline = [
      _ItemTimeline(
        title: 'Sedang Diantar',
        waktu: '14:20 WIB',
        deskripsi: 'Pesanan sedang diantar oleh kurir ME Atelier ke alamat tujuan.',
        detail: 'Hub Transit Jakarta Selatan',
        aktif: true,
      ),
      _ItemTimeline(
        title: 'Sorting Hub',
        waktu: 'Kemarin, 21:15 WIB',
        deskripsi: 'Tiba di Sorting Hub ME Atelier Jakarta Pusat.',
        aktif: false,
      ),
      _ItemTimeline(
        title: 'Pengemasan Khusus',
        waktu: 'Kemarin, 15:30 WIB',
        deskripsi: 'Pesanan telah dikemas rapi dengan Signature Atelier Box & Pita Sutra.',
        aktif: false,
      ),
      _ItemTimeline(
        title: 'Pembayaran Berhasil',
        waktu: 'Kemarin, 14:00 WIB',
        deskripsi: 'Transaksi terverifikasi melalui BCA Virtual Account.',
        aktif: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jejak Pengiriman',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                'AKTIF',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...timeline.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: item.aktif ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.aktif ? Icons.local_shipping_rounded : Icons.check_rounded,
                            size: 12,
                            color: item.aktif ? TemaAplikasi.onPrimary : TemaAplikasi.primary,
                          ),
                        ),
                        if (item != timeline.last)
                          Container(
                            width: 2,
                            height: 54,
                            color: TemaAplikasi.borderGray,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.title.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  color: item.aktif ? TemaAplikasi.primary : TemaAplikasi.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.waktu,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: TemaAplikasi.mutedGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.deskripsi,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TemaAplikasi.primary,
                              height: 1.4,
                            ),
                          ),
                          if (item.detail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.detail!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: TemaAplikasi.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _bangunAlamatTujuan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tujuan Pengiriman',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                'UTAMA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.mutedGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: TemaAplikasi.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.apartment_rounded, size: 18, color: TemaAplikasi.primary),
                    SizedBox(width: 8),
                    Text(
                      'Clarissa Vance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(+62 812-3456-7890)',
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Senopati Suites Tower 2, Penthouse Unit 18B, Jl. Senopati No. 41, Kebayoran Baru, Jakarta Selatan 12190',
                  style: TextStyle(
                    fontSize: 14,
                    color: TemaAplikasi.primary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: TemaAplikasi.surfaceWhite,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.room_service_rounded, size: 18, color: TemaAplikasi.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'INSTRUKSI KHUSUS',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: TemaAplikasi.mutedGray,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '"Titipkan ke concierge resepsionis lobi jika tidak berada di tempat."',
                              style: TextStyle(
                                fontSize: 12,
                                color: TemaAplikasi.primary,
                                fontStyle: FontStyle.italic,
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
          ),
        ],
      ),
    );
  }

  Widget _bangunProdukDipesan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Koleksi Dipesan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                '2 KURASI',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.mutedGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bangunItemProduk(
            imageUrl: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=800&q=80',
            kategori: 'Fall / Winter Atelier',
            nama: 'Double-Breasted Wool Blazer',
            detail: 'Noir • Size S • Qty: 1',
            harga: 'Rp 1.890.000',
          ),
          const Divider(height: 1, color: TemaAplikasi.borderGray),
          _bangunItemProduk(
            imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80',
            kategori: 'Signature Essentials',
            nama: 'Pleated Wide Linen Trousers',
            detail: 'Slate Grey • Size M • Qty: 1',
            harga: 'Rp 1.350.000',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            color: TemaAplikasi.surfaceLight,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  color: TemaAplikasi.primary,
                  child: const Icon(Icons.redeem_rounded, color: TemaAplikasi.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Signature Gift Packaging',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Atelier Signature Gift Box Included (Gratis Keanggotaan Noir)',
                        style: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: TemaAplikasi.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunItemProduk({
    required String imageUrl,
    required String kategori,
    required String nama,
    required String detail,
    required String harga,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 120,
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceContainer,
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategori.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    color: TemaAplikasi.mutedGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      harga,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const Text(
                      'DETAIL',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _bangunRincianPembayaran() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.primary,
                ),
              ),
              Text(
                'BCA VA LUNAS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: TemaAplikasi.mutedGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: TemaAplikasi.surfaceLight,
            child: Column(
              children: const [
                _ItemRincian(label: 'Subtotal Produk', value: 'Rp 3.240.000'),
                SizedBox(height: 10),
                _ItemRincian(label: 'Pengiriman Express Concierge', value: 'Rp 0'),
                SizedBox(height: 10),
                _ItemRincian(label: 'Diskon Kupon Atelier', value: '- Rp 150.000'),
                SizedBox(height: 10),
                _ItemRincian(label: 'Asuransi Koleksi Mewah', value: 'Bebas Biaya'),
                SizedBox(height: 14),
                Divider(color: TemaAplikasi.borderGray, height: 1),
                SizedBox(height: 14),
                _ItemRincian(label: 'Total Pembayaran', value: 'Rp 3.090.000', strong: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunAksi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text(
                'HUBUNGI KURIR ATELIER',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: TemaAplikasi.surfaceContainer,
                    foregroundColor: TemaAplikasi.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'FAKTUR PDF',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: TemaAplikasi.surfaceContainer,
                    foregroundColor: TemaAplikasi.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text(
                    'BELI LAGI',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemTimeline {
  const _ItemTimeline({
    required this.title,
    required this.waktu,
    required this.deskripsi,
    this.detail,
    required this.aktif,
  });

  final String title;
  final String waktu;
  final String deskripsi;
  final String? detail;
  final bool aktif;
}

class _ItemRincian extends StatelessWidget {
  const _ItemRincian({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: strong ? TemaAplikasi.primary : TemaAplikasi.secondary,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: strong ? TemaAplikasi.primary : TemaAplikasi.primary,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
