import 'package:flutter/material.dart';

import '../services/state_pengguna.dart';
import '../theme.dart';
import 'halaman_login.dart';

class HalamanBuktiTransaksi extends StatelessWidget {
  const HalamanBuktiTransaksi({super.key});

  @override
  Widget build(BuildContext context) {
    if (!StatePengguna.isLoggedInNotifier.value) {
      return Scaffold(
        backgroundColor: TemaAplikasi.surfaceBright,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: TemaAplikasi.surfaceWhite,
          foregroundColor: TemaAplikasi.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'BUKTI TRANSAKSI',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: TemaAplikasi.primary),
                const SizedBox(height: 16),
                const Text(
                  'Silakan masuk untuk melihat bukti transaksi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalamanLogin()),
                    ),
                    child: const Text('MASUK SEKARANG'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final daftarBukti = [
      _BuktiTransaksiItem(
        judul: 'Invoice Pembelian',
        deskripsi: 'ME Atelier • INV-2026-1048',
        subtitle: 'PDF • 1.2 MB',
        ikon: Icons.receipt_long_outlined,
      ),
      _BuktiTransaksiItem(
        judul: 'Bukti Pembayaran',
        deskripsi: 'Transfer VA BCA • 12 Nov 2026',
        subtitle: 'JPG • 840 KB',
        ikon: Icons.image_outlined,
      ),
      _BuktiTransaksiItem(
        judul: 'E-Ticket Pengiriman',
        deskripsi: 'ME White Glove • AWB 88240177',
        subtitle: 'PDF • 540 KB',
        ikon: Icons.local_shipping_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'BUKTI TRANSAKSI',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceWhite,
                  border: Border.all(color: TemaAplikasi.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: TemaAplikasi.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PEMBAYARAN TELAH DIVERIFIKASI',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'INV-2026-1048',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ME Atelier • Pesanan NO. 1048',
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: TemaAplikasi.borderGray),
                    const SizedBox(height: 16),
                    _barisInfo('Nominal', 'Rp 2.498.000'),
                    _barisInfo('Tanggal', '12 Nov 2026'),
                    _barisInfo('Metode', 'Virtual Account BCA'),
                    _barisInfo('Status', 'Lunas'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DOKUMEN TERKAIT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 12),
              ...daftarBukti.map((item) => _kartuDokumen(item)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: TemaAplikasi.primary,
                    foregroundColor: TemaAplikasi.onPrimary,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'UNDUH SEMUA DOKUMEN',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuDokumen(_BuktiTransaksiItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceContainerLow,
            ),
            child: Icon(item.ikon, color: TemaAplikasi.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.deskripsi,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaAplikasi.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: TemaAplikasi.mutedGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: TemaAplikasi.secondary),
        ],
      ),
    );
  }

  static Widget _barisInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuktiTransaksiItem {
  final String judul;
  final String deskripsi;
  final String subtitle;
  final IconData ikon;

  const _BuktiTransaksiItem({
    required this.judul,
    required this.deskripsi,
    required this.subtitle,
    required this.ikon,
  });
}
