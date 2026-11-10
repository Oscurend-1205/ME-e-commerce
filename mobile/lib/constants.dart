import 'package:flutter/foundation.dart';

class Konstan {
  /// URL host kustom jika pengguna ingin mengganti IP host (misal IP Wi-Fi)
  static String? customHost;

  static String _normalisasiHost(String value) {
    var host = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (!host.startsWith('http://') && !host.startsWith('https://')) {
      host = 'http://$host';
    }
    return host;
  }

  /// URL API terpusat:
  /// - Jika customHost diisi, gunakan customHost.
  /// - Default: http://127.0.0.1:8000/api (berfungsi di Web, Windows, dan HP fisik via USB/ADB Reverse).
  static String get baseUrl {
    if (customHost != null && customHost!.trim().isNotEmpty) {
      final host = _normalisasiHost(customHost!);
      return host.endsWith('/api') ? host : '$host/api';
    }
    const envApi = String.fromEnvironment('API_URL');
    if (envApi.isNotEmpty) {
      final host = envApi.trim().replaceAll(RegExp(r'/+$'), '');
      return host.endsWith('/api') ? host : '$host/api';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// URL dasar penyimpanan aset gambar di backend Laravel:
  /// - Web: /api/gambar (butuh header CORS untuk Chrome)
  /// - Mobile/Desktop: /storage/produk (file statis via symlink public/storage,
  ///   dilayani langsung web server tanpa boot framework Laravel — jauh lebih cepat)
  static String get storageUrl {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (kIsWeb) {
      return base.endsWith('/api') ? '$base/gambar' : '$base/api/gambar';
    }
    final host = base.replaceAll(RegExp(r'/api$'), '');
    return '$host/storage/produk';
  }

  static const Duration batasWaktu = Duration(seconds: 20);

  /// ID pelanggan statis untuk mode tamu / identitas fallback (PRD UTS).
  /// Bearer token tetap diprioritaskan backend bila pengguna sudah login.
  static const int pelangganId = 1;
}
