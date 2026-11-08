import 'package:flutter/material.dart';

import '../theme.dart';

class HalamanAkun extends StatefulWidget {
  const HalamanAkun({super.key});

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  bool _notifikasiAktif = true;
  bool _biometrikAktif = true;

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
          'PROFIL & PENGATURAN',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
            color: TemaAplikasi.primary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Pencarian',
            icon: const Icon(Icons.search_rounded, size: 22),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Tas belanja',
            icon: const Icon(Icons.shopping_bag_outlined, size: 22),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _bangunRingkasanProfil(),
            _bangunStatAkun(),
            _bangunKeanggotaan(),
            _bangunGrupPengaturan(
              'Pesanan & Transaksi',
              [
                _bangunItemDaftar(
                  icon: Icons.local_mall_outlined,
                  label: 'Riwayat Pesanan & Pelacakan',
                  badge: '1 Aktif',
                ),
                _bangunItemDaftar(
                  icon: Icons.assignment_return_outlined,
                  label: 'Pengembalian & Penukaran Barang',
                ),
                _bangunItemDaftar(
                  icon: Icons.receipt_long_outlined,
                  label: 'Faktur & Bukti Transaksi',
                ),
              ],
            ),
            _bangunGrupPengaturan(
              'Preferensi & Pengaturan',
              [
                _bangunItemDaftar(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Pengiriman',
                  trailingText: '3 Tersimpan',
                ),
                _bangunItemDaftar(
                  icon: Icons.credit_card_outlined,
                  label: 'Metode Pembayaran',
                  trailingText: 'BCA & CC',
                ),
                _bangunToggleItem(
                  icon: Icons.campaign_outlined,
                  label: 'Notifikasi & Pengingat Koleksi',
                  value: _notifikasiAktif,
                  onChanged: (value) {
                    setState(() {
                      _notifikasiAktif = value;
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: TemaAplikasi.surfaceContainerLow,
                    foregroundColor: TemaAplikasi.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'KELUAR DARI AKUN',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ME ATELIER',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
                color: TemaAplikasi.mutedGray,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ME Atelier Mobile App v2.4.0 • Paris & Jakarta',
              style: TextStyle(
                fontSize: 11,
                color: TemaAplikasi.secondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'HAUTE COUTURE & READY-TO-WEAR',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: TemaAplikasi.mutedGray,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _bangunRingkasanProfil() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceContainerLow,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1D1D1D),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 16,
                    color: TemaAplikasi.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Clarissa Vance',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: TemaAplikasi.primary,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_outlined, size: 13, color: TemaAplikasi.onPrimary),
                SizedBox(width: 6),
                Text(
                  'ME PRIVÉ • NOIR MEMBER',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: TemaAplikasi.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anggota sejak 2023 • 1.450 Poin Atelier',
            style: TextStyle(fontSize: 12, color: TemaAplikasi.secondary),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: TemaAplikasi.surfaceWhite,
              foregroundColor: TemaAplikasi.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              side: const BorderSide(color: TemaAplikasi.borderGray),
            ),
            child: const Text(
              'EDIT PROFIL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunStatAkun() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: TemaAplikasi.surfaceWhite,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        children: [
          _bangunStatItem('3', 'Menunggu Bayar'),
          _bangunStatItem('1', 'Sedang Dikirim'),
          _bangunStatItem('12', 'Riwayat Pesanan'),
          _bangunStatItem('8', 'Wishlist'),
        ],
      ),
    );
  }

  Widget _bangunStatItem(String jumlah, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: TemaAplikasi.borderGray),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            jumlah,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: TemaAplikasi.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunKeanggotaan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Color(0xFF1D1B1A),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 16, color: Color(0xFFE9E3DF)),
                    SizedBox(width: 6),
                    Text(
                      'Keanggotaan Eksklusif',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Color(0xFFE9E3DF),
                      ),
                    ),
                  ],
                ),
                Text(
                  'TINGKAT TERTINGGI',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Hak Istimewa ME Privé Noir',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _ChipKeanggotaan('Akses Pratinjau Koleksi'),
                _ChipKeanggotaan('Gratis Pengiriman Express Selamanya'),
                _ChipKeanggotaan('Personal Atelier Stylist'),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Text(
                  'Lihat Detail Keanggotaan',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE9E3DF),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFE9E3DF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunGrupPengaturan(String judul, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              judul.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: TemaAplikasi.secondary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: TemaAplikasi.surfaceWhite,
              border: Border.all(color: TemaAplikasi.borderGray),
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                if (index < items.length - 1) {
                  return Column(
                    children: [
                      item,
                      const Divider(height: 1, color: TemaAplikasi.borderGray),
                    ],
                  );
                }
                return item;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunItemDaftar({
    required IconData icon,
    required String label,
    String subtitle = '',
    String badge = '',
    String trailingText = '',
    Color badgeColor = TemaAplikasi.surfaceContainerHigh,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: TemaAplikasi.secondary),
              const SizedBox(width: 14),
              Expanded(
                child: subtitle.isEmpty
                    ? Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: TemaAplikasi.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: TemaAplikasi.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                        ],
                      ),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                )
              else if (trailingText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    trailingText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 22, color: TemaAplikasi.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: TemaAplikasi.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TemaAplikasi.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _ChipKeanggotaan extends StatelessWidget {
  const _ChipKeanggotaan(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
