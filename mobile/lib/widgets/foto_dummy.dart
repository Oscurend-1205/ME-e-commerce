import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/produk.dart';
import '../theme.dart';

/// Mengelola URL Foto Produk & Banner yang disimpan di Backend Laravel Storage
/// (backend/storage/app/public/produk)
class FotoDummy {
  // Hero Container ME MINIMALISM
  static String get heroBanner => '${Konstan.storageUrl}/hero-banner.jpg';

  // 4 Kategori Pilihan (Curated 2x2)
  static String get katAtasan => '${Konstan.storageUrl}/kat-atasan.jpg';
  static String get katBawahan => '${Konstan.storageUrl}/kat-bawahan.jpg';
  static String get katOuterwear => '${Konstan.storageUrl}/kat-outerwear.jpg';
  static String get katAksesori => '${Konstan.storageUrl}/kat-aksesori.jpg';

  // Story Highlight Circles
  static List<String> get stories => [
        '${Konstan.storageUrl}/story-1.jpg',
        '${Konstan.storageUrl}/story-2.jpg',
        '${Konstan.storageUrl}/story-3.jpg',
        '${Konstan.storageUrl}/story-4.jpg',
        '${Konstan.storageUrl}/story-5.jpg',
      ];

  // Daftar Foto Produk Editorial untuk Katalog Koleksi Terbaru
  static List<String> get daftarProdukPakaian => [
        '${Konstan.storageUrl}/produk-pakaian-1.jpg',
        '${Konstan.storageUrl}/produk-pakaian-2.jpg',
        '${Konstan.storageUrl}/produk-pakaian-3.jpg',
        '${Konstan.storageUrl}/produk-pakaian-4.jpg',
        '${Konstan.storageUrl}/produk-pakaian-5.jpg',
      ];

  static List<String> get daftarProdukAksesori => [
        '${Konstan.storageUrl}/produk-aksesori-1.jpg',
        '${Konstan.storageUrl}/produk-aksesori-2.jpg',
      ];

  /// Mendapatkan foto produk resmi langsung dari database dan backend storage (1.jpg, 2.jpg, dst)
  static String untukProduk(Produk produk) {
    return produk.fotoUrl;
  }

  /// Widget Gambar Jaringan dengan Placeholder Anggun & Fallback
  static Widget bangunGambar({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? fallbackWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: TemaAplikasi.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: TemaAplikasi.mutedGray,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return fallbackWidget ??
            Container(
              width: width,
              height: height,
              color: TemaAplikasi.surfaceContainer,
              child: const Center(
                child: Icon(
                  Icons.checkroom_outlined,
                  size: 32,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            );
      },
    );
  }
}
