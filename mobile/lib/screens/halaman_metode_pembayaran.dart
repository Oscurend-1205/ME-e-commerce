import 'package:flutter/material.dart';

import '../theme.dart';

class HalamanMetodePembayaran extends StatefulWidget {
  const HalamanMetodePembayaran({super.key});

  @override
  State<HalamanMetodePembayaran> createState() => _HalamanMetodePembayaranState();
}

class _HalamanMetodePembayaranState extends State<HalamanMetodePembayaran> {
  int _metodeDipilih = 0;

  final List<_MetodePembayaranOption> _opsi = [
    _MetodePembayaranOption(
      title: 'Virtual Account',
      subtitle: 'BCA, Mandiri, BNI, Permata, BRI (Verifikasi Instan)',
      badge: 'Rekomendasi',
      caption: 'Bebas biaya admin perbankan. Nomor VA unik dibuat otomatis setelah konfirmasi.',
      icon: Icons.account_balance_wallet_outlined,
      detail: 'BCA Virtual Account',
    ),
    _MetodePembayaranOption(
      title: 'Kartu Kredit / Debit',
      subtitle: 'VISA • MC • AMEX',
      badge: '0% 3X',
      caption: 'Tersedia cicilan 0% hingga 12 bulan dan kartu yang tersimpan otomatis terverifikasi.',
      icon: Icons.credit_card_outlined,
      detail: '•••• 4288 • ME Privé Black',
    ),
    _MetodePembayaranOption(
      title: 'E-Wallet & QRIS',
      subtitle: 'GoPay, OVO, ShopeePay, AstraPay',
      badge: 'Semua Aplikasi',
      caption: 'Scan kode QRIS nasional dan bayar langsung dari aplikasi dompet digital Anda.',
      icon: Icons.qr_code_2_outlined,
      detail: 'QRIS Nasional',
    ),
    _MetodePembayaranOption(
      title: 'ME Privé Concierge Pay',
      subtitle: 'Bayar 30 hari tanpa bunga',
      badge: 'Limit Aktif',
      caption: 'Promo khusus member untuk pembelian premium dengan tenor 30 hari tanpa bunga.',
      icon: Icons.stars_rounded,
      detail: 'Rp 5.000.000 tersedia',
    ),
  ];

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
        title: const Text(
          'METODE PEMBAYARAN',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'UBAH',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih kanal pembayaran terenkripsi untuk merampungkan pesanan Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: TemaAplikasi.secondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainerLow,
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.schedule_rounded, size: 18, color: TemaAplikasi.primary),
                              SizedBox(width: 8),
                              Text(
                                'RESERVASI STOK EKSKLUSIF',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                              Spacer(),
                              Text(
                                '08:35',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.lock_outline_rounded, size: 16, color: TemaAplikasi.secondary),
                              SizedBox(width: 8),
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
                    ),
                    const SizedBox(height: 18),
                    _bangunRingkasanPengiriman(),
                    const SizedBox(height: 18),
                    const Text(
                      'PILIH SALURAN PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_opsi.length, (index) {
                      final option = _opsi[index];
                      final selected = _metodeDipilih == index;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceWhite,
                          border: Border.all(
                            color: selected ? TemaAplikasi.primary : TemaAplikasi.borderGray,
                            width: selected ? 1.2 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _metodeDipilih = index),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Radio<int>(
                                    value: index,
                                    groupValue: _metodeDipilih,
                                    onChanged: (value) => setState(() => _metodeDipilih = value ?? 0),
                                    activeColor: TemaAplikasi.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                option.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: TemaAplikasi.primary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: TemaAplikasi.surfaceContainer,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                option.badge,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.w700,
                                                  color: TemaAplikasi.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.subtitle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: TemaAplikasi.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (selected)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            color: TemaAplikasi.surfaceContainerLow,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(option.icon, size: 18, color: TemaAplikasi.primary),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      option.detail,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        letterSpacing: 0.8,
                                                        fontWeight: FontWeight.w700,
                                                        color: TemaAplikasi.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  option.caption,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: TemaAplikasi.secondary,
                                                    height: 1.5,
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
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainerLow,
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: Column(
                        children: [
                          _barisRincian('Subtotal Produk (2 Item)', 'Rp 2.648.000'),
                          _barisRincian('Pengiriman ME White Glove', 'Gratis'),
                          _barisRincian('Diskon Kupon (ATELIERNOIR)', '-Rp 150.000'),
                          _barisRincian('Proteksi & Kemas Hadiah', 'Gratis Privé'),
                          const SizedBox(height: 12),
                          const Divider(color: TemaAplikasi.borderGray),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL TAGIHAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.6,
                                        fontWeight: FontWeight.w700,
                                        color: TemaAplikasi.secondary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Sudah termasuk PPN 11%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: TemaAplikasi.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp 2.498.000',
                                style: TextStyle(
                                  fontSize: 28,
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
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: TemaAplikasi.surfaceWhite,
                border: Border(
                  top: BorderSide(color: TemaAplikasi.borderGray, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL PEMBAYARAN',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                                color: TemaAplikasi.secondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Rp 2.498.000',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.verified_user_outlined, size: 18, color: TemaAplikasi.primary),
                      SizedBox(width: 6),
                      Text(
                        'BCA VA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('BAYAR SEKARANG'),
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

  Widget _bangunRingkasanPengiriman() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TUJUAN PENGIRIMAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clarissa Adiwidjaja (Utama)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Senopati Suites Tower 2, Penthouse Unit 19B, Jakarta Selatan',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.local_shipping_outlined, size: 16, color: TemaAplikasi.primary),
              SizedBox(width: 6),
              Text(
                'ME White Glove • Besok Sore (14:00 - 18:00)',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: TemaAplikasi.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barisRincian(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: TemaAplikasi.secondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: TemaAplikasi.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodePembayaranOption {
  final String title;
  final String subtitle;
  final String badge;
  final String caption;
  final IconData icon;
  final String detail;

  const _MetodePembayaranOption({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.caption,
    required this.icon,
    required this.detail,
  });
}
