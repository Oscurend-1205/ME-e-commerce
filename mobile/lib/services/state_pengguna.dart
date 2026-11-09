import 'package:flutter/material.dart';

import 'layanan_api.dart';

/// State reaktif global untuk profil pengguna dan item keranjang
/// Menjamin foto profil dan status pengguna selalu sinkron seketika di seluruh header dan halaman
class StatePengguna {
  /// Foto profil pengguna saat ini (Reaktif via ValueNotifier)
  static final ValueNotifier<String> fotoProfilNotifier = ValueNotifier<String>(
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
  );

  /// Nama lengkap pengguna
  static final ValueNotifier<String> namaUserNotifier = ValueNotifier<String>(
    'Clarissa Vance',
  );

  /// Email pengguna
  static final ValueNotifier<String> emailUserNotifier = ValueNotifier<String>(
    'clarissa.vance@atelier-me.com',
  );

  /// Jumlah total item di keranjang belanja (Reaktif di semua header)
  static final ValueNotifier<int> jumlahKeranjangNotifier = ValueNotifier<int>(0);

  /// Preset Avatar Editorial Kurasi ME Atelier (Wanita & Pria)
  static const List<Map<String, String>> daftarPresetAvatar = [
    {
      'id': 'clarissa',
      'label': 'Clarissa (Default)',
      'tipe': 'Editorial Classic',
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'elena',
      'label': 'Elena Minimalist',
      'tipe': 'Modern Clean',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'julian',
      'label': 'Julian Atelier',
      'tipe': 'Homme Sartorial',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'aria',
      'label': 'Aria Studio',
      'tipe': 'Contemporary',
      'url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'marcus',
      'label': 'Marcus Tailored',
      'tipe': 'Classic Suiting',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'sora',
      'label': 'Sora Monochrome',
      'tipe': 'Avant-Garde',
      'url': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
    },
  ];

  /// Mengubah foto profil pengguna secara global
  static void perbaruiFotoProfil(String urlBaru) {
    if (urlBaru.trim().isNotEmpty) {
      fotoProfilNotifier.value = urlBaru.trim();
    }
  }

  /// Mengubah nama pengguna
  static void perbaruiNama(String namaBaru) {
    if (namaBaru.trim().isNotEmpty) {
      namaUserNotifier.value = namaBaru.trim();
    }
  }

  /// Mengubah jumlah item di tas belanja
  static void perbaruiJumlahKeranjang(int jumlah) {
    jumlahKeranjangNotifier.value = jumlah >= 0 ? jumlah : 0;
  }

  /// Sinkronkan jumlah item keranjang dari API server
  static Future<void> sinkronkanKeranjang() async {
    final respon = await LayananApi.ambilKeranjang();
    if (respon.berhasil && respon.data != null) {
      final items = (respon.data as Map<String, dynamic>)['items'] as List?;
      final total = items?.fold<int>(0, (sum, i) => sum + ((i['jumlah'] as int?) ?? 1)) ?? 0;
      perbaruiJumlahKeranjang(total);
    }
  }

  /// Koleksi ID produk di Wishlist (Reaktif global)
  static final ValueNotifier<Set<int>> wishlistNotifier = ValueNotifier<Set<int>>({});

  /// Cek apakah produk berada di wishlist
  static bool isWishlist(int produkId) => wishlistNotifier.value.contains(produkId);

  /// Toggle wishlist produk
  static void toggleWishlist(int produkId) {
    final current = Set<int>.from(wishlistNotifier.value);
    if (current.contains(produkId)) {
      current.remove(produkId);
    } else {
      current.add(produkId);
    }
    wishlistNotifier.value = current;
  }

  /// Tambah produk ke wishlist
  static void tambahWishlist(int produkId) {
    final current = Set<int>.from(wishlistNotifier.value);
    current.add(produkId);
    wishlistNotifier.value = current;
  }
}

