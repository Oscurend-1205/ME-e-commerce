import 'package:flutter/material.dart';

import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/komponen_header.dart';
import 'halaman_buku_alamat.dart';
import 'halaman_bukti_transaksi.dart';
import 'halaman_kelola_produk.dart';
import 'halaman_login.dart';
import 'halaman_metode_pembayaran.dart';
import 'halaman_riwayat_pesanan.dart';

class HalamanAkun extends StatefulWidget {
  const HalamanAkun({super.key});

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  bool _notifikasiAktif = true;
  bool _biometrikAktif = true;

  Future<void> _logout() async {
    final respon = await LayananApi.logout();
    StatePengguna.setLoggedOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respon.berhasil ? 'Anda telah keluar.' : 'Sesi lokal diakhiri.',
          ),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _keHalamanLogin() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HalamanLogin()),
    );
    if (berhasil == true && mounted) {
      setState(() {});
      StatePengguna.sinkronkanKeranjang();
    }
  }

  Future<void> _bukaLoginDanLanjut(Widget halamanTujuan) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HalamanLogin()),
    );
    if (berhasil != true || !mounted) return;

    setState(() {});
    await StatePengguna.sinkronkanKeranjang();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => halamanTujuan),
    );
  }

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
          onPressed: () => NavigasiUniversal.kembali(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: const [
          TombolTasHeader(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _bangunRingkasanProfil(),
            _bangunStatAkun(),
            _bangunKeanggotaan(),
            _bangunGrupPengaturan('Pesanan & Transaksi', [
              _bangunItemDaftar(
                icon: Icons.local_mall_outlined,
                label: 'Riwayat Pesanan & Pelacakan',
                badge: '1 Aktif',
                onTap: () {
                  if (!StatePengguna.isLoggedInNotifier.value) {
                    _bukaLoginDanLanjut(const HalamanRiwayatPesanan());
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HalamanRiwayatPesanan()),
                  );
                },
              ),
              _bangunItemDaftar(
                icon: Icons.receipt_long_outlined,
                label: 'Faktur & Bukti Transaksi',
                onTap: () {
                  if (!StatePengguna.isLoggedInNotifier.value) {
                    _bukaLoginDanLanjut(const HalamanBuktiTransaksi());
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HalamanBuktiTransaksi(),
                    ),
                  );
                },
              ),
            ]),
            _bangunGrupPengaturan('Preferensi & Pengaturan', [
              _bangunItemDaftar(
                icon: Icons.location_on_outlined,
                label: 'Alamat Pengiriman',
                trailingText: '3 Tersimpan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HalamanBukuAlamat(),
                    ),
                  );
                },
              ),
              _bangunItemDaftar(
                key: const ValueKey('metode_pembayaran_item'),
                icon: Icons.credit_card_outlined,
                label: 'Metode Pembayaran',
                trailingText: 'BCA & CC',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HalamanMetodePembayaran(),
                    ),
                  );
                },
              ),
              _bangunToggleItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi Eksklusif ME',
                value: _notifikasiAktif,
                onChanged: (val) {
                  setState(() {
                    _notifikasiAktif = val;
                  });
                },
              ),
              _bangunToggleItem(
                icon: Icons.fingerprint_rounded,
                label: 'Keamanan Biometrik & FaceID',
                value: _biometrikAktif,
                onChanged: (val) {
                  setState(() {
                    _biometrikAktif = val;
                  });
                },
              ),
            ]),
            _bangunGrupPengaturan('Admin Toko', [
              _bangunItemDaftar(
                icon: Icons.inventory_2_outlined,
                label: 'Kelola Produk',
                trailingText: 'CRUD Katalog',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HalamanKelolaProduk(),
                    ),
                  );
                },
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: ValueListenableBuilder<bool>(
                valueListenable: StatePengguna.isLoggedInNotifier,
                builder: (context, isLoggedIn, _) {
                  if (!isLoggedIn) return const SizedBox.shrink();
                  return SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _logout,
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
                  );
                },
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
              style: TextStyle(fontSize: 11, color: TemaAplikasi.secondary),
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
    return ValueListenableBuilder<bool>(
      valueListenable: StatePengguna.isLoggedInNotifier,
      builder: (context, isLoggedIn, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          decoration:
              const BoxDecoration(color: TemaAplikasi.surfaceContainerLow),
          child: Column(
            children: [
              GestureDetector(
                onTap: isLoggedIn
                    ? () => _tampilkanPemilihAvatar(context)
                    : _keHalamanLogin,
                child: Stack(
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
                        child: isLoggedIn
                            ? ValueListenableBuilder<String>(
                                valueListenable:
                                    StatePengguna.fotoProfilNotifier,
                                builder: (context, fotoUrl, _) {
                                  return FotoDummy.bangunGambar(
                                    url: fotoUrl,
                                    fit: BoxFit.cover,
                                    fallbackWidget: Container(
                                      color: const Color(0xFF1D1D1D),
                                      child: Center(
                                        child: Text(
                                          StatePengguna.namaUserNotifier
                                                  .value.isNotEmpty
                                              ? StatePengguna.namaUserNotifier
                                                  .value[0]
                                                  .toUpperCase()
                                              : 'M',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 38,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: TemaAplikasi.surfaceContainerHigh,
                                child: const Center(
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 48,
                                    color: TemaAplikasi.secondary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isLoggedIn)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: TemaAplikasi.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
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
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<String>(
                valueListenable: StatePengguna.namaUserNotifier,
                builder: (context, nama, _) {
                  return Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: TemaAplikasi.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String>(
                valueListenable: StatePengguna.emailUserNotifier,
                builder: (context, email, _) {
                  return Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: TemaAplikasi.secondary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              if (isLoggedIn)
                TextButton(
                  onPressed: () => _tampilkanEditProfil(context),
                  style: TextButton.styleFrom(
                    backgroundColor: TemaAplikasi.surfaceWhite,
                    foregroundColor: TemaAplikasi.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
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
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _keHalamanLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaAplikasi.primary,
                      foregroundColor: TemaAplikasi.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'MASUK / DAFTAR',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _tampilkanPemilihAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaAplikasi.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final urlKustomController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PILIH AVATAR EDITORIAL',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kurasi identitas visual studio ME Atelier',
                        style: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: TemaAplikasi.borderGray),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: StatePengguna.fotoProfilNotifier,
                builder: (context, currentFoto, _) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: StatePengguna.daftarPresetAvatar.length,
                    itemBuilder: (context, idx) {
                      final preset = StatePengguna.daftarPresetAvatar[idx];
                      final isSelected = currentFoto == preset['url'];

                      return InkWell(
                        onTap: () {
                          StatePengguna.perbaruiFotoProfil(preset['url']!);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Avatar diubah: ${preset['label']}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? TemaAplikasi.primary
                                  : TemaAplikasi.borderGray,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? TemaAplikasi.surfaceContainerLow
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 54,
                                      height: 54,
                                      child: FotoDummy.bangunGambar(
                                        url: preset['url']!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: TemaAplikasi.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                preset['label'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: TemaAplikasi.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                preset['tipe'] ?? '',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  color: TemaAplikasi.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: TemaAplikasi.borderGray),
              const SizedBox(height: 14),
              const Text(
                'ATAU GUNAKAN URL FOTO LAIN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlKustomController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'https://images.unsplash.com/...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: TemaAplikasi.mutedGray,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: TemaAplikasi.borderGray,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TemaAplikasi.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final url = urlKustomController.text.trim();
                      if (url.isNotEmpty) {
                        StatePengguna.perbaruiFotoProfil(url);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Foto profil kustom berhasil diterapkan.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaAplikasi.primary,
                      foregroundColor: TemaAplikasi.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'TERAPKAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _tampilkanEditProfil(BuildContext context) {
    final namaController = TextEditingController(
      text: StatePengguna.namaUserNotifier.value,
    );
    final emailController = TextEditingController(
      text: StatePengguna.emailUserNotifier.value,
    );
    final fotoController = TextEditingController(
      text: StatePengguna.fotoProfilNotifier.value,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaAplikasi.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EDIT PROFIL ME ATELIER',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                      color: TemaAplikasi.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'NAMA LENGKAP',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: namaController,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nama lengkap Anda',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ALAMAT EMAIL',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'nama@domain.com',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'URL FOTO PROFIL',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: fotoController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: TemaAplikasi.primary),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: TemaAplikasi.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'BATAL',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final nama = namaController.text.trim();
                        final email = emailController.text.trim();
                        final foto = fotoController.text.trim();

                        if (nama.isNotEmpty) {
                          StatePengguna.perbaruiNama(nama);
                        }
                        if (email.isNotEmpty) {
                          StatePengguna.emailUserNotifier.value = email;
                        }
                        if (foto.isNotEmpty) {
                          StatePengguna.perbaruiFotoProfil(foto);
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil berhasil diperbarui.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaAplikasi.primary,
                        foregroundColor: TemaAplikasi.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SIMPAN',
                        style: TextStyle(
                          fontSize: 11,
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
      },
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
        border: Border(right: BorderSide(color: TemaAplikasi.borderGray)),
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
        decoration: const BoxDecoration(color: Color(0xFF1D1B1A)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Color(0xFFE9E3DF),
                    ),
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
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFFE9E3DF),
                ),
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
    Key? key,
    required IconData icon,
    required String label,
    String subtitle = '',
    String badge = '',
    String trailingText = '',
    Color badgeColor = TemaAplikasi.surfaceContainerHigh,
    VoidCallback? onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: TemaAplikasi.secondary,
              ),
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
            activeTrackColor: TemaAplikasi.primary,
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
