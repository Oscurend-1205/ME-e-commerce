import 'package:flutter/material.dart';

import '../screens/halaman_akun.dart';
import '../screens/halaman_keranjang.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import 'foto_dummy.dart';

/// Helper Routing Universal untuk seluruh Header di aplikasi ME Atelier
class NavigasiUniversal {
  /// Routing ke Beranda (Root / Tab 0)
  static void keBeranda(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Routing ke Halaman Profil / Akun
  static Future<void> keProfil(BuildContext context) async {
    // Jika sudah di HalamanAkun, tidak perlu push ulang
    final route = ModalRoute.of(context);
    if (route != null && route.settings.name == '/akun') return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/akun'),
        builder: (context) => const HalamanAkun(),
      ),
    );
  }

  /// Routing ke Halaman Tas Belanja (Keranjang)
  static Future<void> keKeranjang(BuildContext context) async {
    // Jika sudah di HalamanKeranjang, tidak perlu push ulang
    final route = ModalRoute.of(context);
    if (route != null && route.settings.name == '/keranjang') return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/keranjang'),
        builder: (context) => const HalamanKeranjang(),
      ),
    );
    // Refresh jumlah keranjang setelah kembali
    StatePengguna.sinkronkanKeranjang();
  }

  /// Routing ke Fitur Pencarian
  static void kePencarian(BuildContext context, {VoidCallback? onAktifkanPencarian}) {
    if (onAktifkanPencarian != null) {
      onAktifkanPencarian();
    } else {
      // Jika berada di luar beranda, kembali ke halaman pertama
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Routing Kembali / Back universal
  static void kembali(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      keBeranda(context);
    }
  }
}

/// Widget Avatar Profil Reaktif di Header
/// Selalu menampilkan foto terbaru dari StatePengguna dan routing universal ke HalamanAkun
class AvatarHeaderUser extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AvatarHeaderUser({
    super.key,
    this.size = 30,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 14),
      child: InkWell(
        onTap: onTap ?? () => NavigasiUniversal.keProfil(context),
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TemaAplikasi.borderGray, width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: ValueListenableBuilder<String>(
            valueListenable: StatePengguna.fotoProfilNotifier,
            builder: (context, fotoUrl, _) {
              return FotoDummy.bangunGambar(
                url: fotoUrl,
                fit: BoxFit.cover,
                fallbackWidget: Container(
                  color: TemaAplikasi.primary,
                  child: Center(
                    child: Text(
                      StatePengguna.namaUserNotifier.value.isNotEmpty
                          ? StatePengguna.namaUserNotifier.value[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget Tombol Tas Belanja Reaktif di Header dengan Counter Badge
class TombolTasHeader extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? ikonColor;

  const TombolTasHeader({
    super.key,
    this.onTap,
    this.ikonColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StatePengguna.jumlahKeranjangNotifier,
      builder: (context, totalItem, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_bag_outlined,
                size: 22,
                color: ikonColor ?? TemaAplikasi.primary,
              ),
              tooltip: 'Tas Belanja',
              onPressed: onTap ?? () => NavigasiUniversal.keKeranjang(context),
            ),
            if (totalItem > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    totalItem > 99 ? '99+' : '$totalItem',
                    style: const TextStyle(
                      color: TemaAplikasi.onPrimary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Widget Logo Brand ME Universal di Header dengan Navigasi ke Beranda
class LogoBrandHeader extends StatelessWidget {
  final VoidCallback? onTap;

  const LogoBrandHeader({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => NavigasiUniversal.keBeranda(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: const Text(
        'ME',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          fontSize: 22,
          color: TemaAplikasi.primary,
        ),
      ),
    );
  }
}

