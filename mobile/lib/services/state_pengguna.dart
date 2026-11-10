import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'layanan_api.dart';

/// State reaktif global untuk profil pengguna dan item keranjang
/// Menjamin foto profil dan status pengguna selalu sinkron seketika di seluruh header dan halaman
class StatePengguna {
  // =====================================================================
  //  STATE AUTENTIKASI
  // =====================================================================

  /// Apakah pengguna sudah login (true) atau masih guest (false)
  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);

  /// Token API untuk request yang membutuhkan autentikasi
  static final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);

  /// ID pelanggan yang sedang login (null jika guest)
  static final ValueNotifier<int?> pelangganIdNotifier = ValueNotifier<int?>(null);

  /// Nomor telepon pengguna
  static final ValueNotifier<String?> noTelpNotifier = ValueNotifier<String?>(null);

  // === Kunci penyimpanan sesi lokal (SharedPreferences) ===
  static const String _kToken = 'sesi_token';
  static const String _kPelangganId = 'sesi_pelanggan_id';
  static const String _kNama = 'sesi_nama';
  static const String _kEmail = 'sesi_email';
  static const String _kNoTelp = 'sesi_no_telp';
  static const String _kFoto = 'sesi_foto';

  /// Memulihkan sesi login yang tersimpan saat aplikasi dibuka kembali,
  /// lalu memvalidasinya ke server lewat GET /api/auth/me.
  /// Token yang sudah tidak berlaku akan dibersihkan otomatis.
  static Future<void> muatSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null || token.isEmpty) return;

    tokenNotifier.value = token;
    isLoggedInNotifier.value = true;

    final respon = await LayananApi.ambilProfil();
    // Hanya keluarkan sesi bila server secara eksplisit menolak token (401).
    // Gangguan jaringan/timeout tidak boleh menghapus sesi tersimpan.
    if (respon.code == '401') {
      await _hapusSesiTersimpan();
      setLoggedOut();
      return;
    }
    if (!respon.berhasil || respon.data == null) {
      // Server belum bisa dihubungi: pertahankan sesi, coba lagi nanti.
      return;
    }

    final data = respon.data as Map<String, dynamic>;
    pelangganIdNotifier.value = data['id'] is int
        ? data['id'] as int
        : int.tryParse('${data['id']}');
    namaUserNotifier.value = data['nama']?.toString() ?? 'Pengguna';
    emailUserNotifier.value = data['email']?.toString() ?? '';
    noTelpNotifier.value = data['no_telp']?.toString();
    final foto = data['foto']?.toString();
    if (foto != null && foto.isNotEmpty) {
      fotoProfilNotifier.value = foto;
    }
    await _simpanSesiTersimpan();
  }

  static Future<void> _simpanSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = tokenNotifier.value;
    if (token == null || token.isEmpty) return;

    await prefs.setString(_kToken, token);
    final id = pelangganIdNotifier.value;
    if (id != null) await prefs.setInt(_kPelangganId, id);
    await prefs.setString(_kNama, namaUserNotifier.value);
    await prefs.setString(_kEmail, emailUserNotifier.value);
    final telp = noTelpNotifier.value;
    if (telp != null && telp.isNotEmpty) {
      await prefs.setString(_kNoTelp, telp);
    }
    await prefs.setString(_kFoto, fotoProfilNotifier.value);
  }

  static Future<void> _hapusSesiTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kPelangganId);
    await prefs.remove(_kNama);
    await prefs.remove(_kEmail);
    await prefs.remove(_kNoTelp);
    await prefs.remove(_kFoto);
  }

  // =====================================================================
  //  PROFIL PENGGUNA
  // =====================================================================

  /// Foto profil pengguna saat ini (Reaktif via ValueNotifier)
  static final ValueNotifier<String> fotoProfilNotifier = ValueNotifier<String>(
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
  );

  /// Nama lengkap pengguna
  static final ValueNotifier<String> namaUserNotifier = ValueNotifier<String>(
    'Tamu',
  );

  /// Email pengguna
  static final ValueNotifier<String> emailUserNotifier = ValueNotifier<String>(
    '',
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

  /// Sinkronkan jumlah item keranjang dari API server.
  /// Berfungsi untuk pengguna login (Bearer token) maupun tamu
  /// (fallback X-Pelanggan-Id statis di backend).
  static Future<void> sinkronkanKeranjang() async {
    final respon = await LayananApi.ambilKeranjang();
    if (respon.berhasil && respon.data != null) {
      final items = (respon.data as Map<String, dynamic>)['items'] as List?;
      final total = items?.fold<int>(0, (sum, i) => sum + ((i['jumlah'] as int?) ?? 1)) ?? 0;
      perbaruiJumlahKeranjang(total);
    }
  }

  // =====================================================================
  //  AUTENTIKASI
  // =====================================================================

  /// Set state pengguna sudah login dengan data dari server
  static void setLoggedIn({
    required int pelangganId,
    required String token,
    required String nama,
    required String email,
    String? noTelp,
    String? foto,
  }) {
    pelangganIdNotifier.value = pelangganId;
    tokenNotifier.value = token;
    namaUserNotifier.value = nama;
    emailUserNotifier.value = email;
    noTelpNotifier.value = noTelp;
    if (foto != null && foto.isNotEmpty) {
      fotoProfilNotifier.value = foto;
    }
    isLoggedInNotifier.value = true;
    _simpanSesiTersimpan();
  }

  /// Set state pengguna logout (kembali ke guest)
  static void setLoggedOut() {
    pelangganIdNotifier.value = null;
    tokenNotifier.value = null;
    namaUserNotifier.value = 'Tamu';
    emailUserNotifier.value = '';
    noTelpNotifier.value = null;
    jumlahKeranjangNotifier.value = 0;
    isLoggedInNotifier.value = false;
    _hapusSesiTersimpan();
  }

  // =====================================================================
  //  WISHLIST
  // =====================================================================

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
