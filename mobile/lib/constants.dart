class Konstan {
  /// URL host kustom jika pengguna ingin mengganti IP host (misal IP Wi-Fi)
  static String? customHost;

  /// URL API terpusat:
  /// - Jika customHost diisi, gunakan customHost.
  /// - Default: http://127.0.0.1:8000/api (berfungsi di Web, Windows, dan HP fisik via USB/ADB Reverse).
  static String get baseUrl {
    if (customHost != null && customHost!.trim().isNotEmpty) {
      final host = customHost!.trim().replaceAll(RegExp(r'/+$'), '');
      return host.endsWith('/api') ? host : '$host/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// URL dasar penyimpanan aset gambar di backend Laravel:
  /// Menggunakan /api/gambar agar mendukung header CORS untuk Flutter Web (Chrome) & HP fisik
  static String get storageUrl {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return base.endsWith('/api') ? '$base/gambar' : '$base/api/gambar';
  }

  static const int pelangganId = 1;
  static const Duration batasWaktu = Duration(seconds: 10);
}
