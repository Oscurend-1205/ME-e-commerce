import 'dart:io' as io;
import 'package:flutter/foundation.dart';

class Konstan {
  /// URL API terpusat:
  /// - Di Web / Windows Desktop: http://127.0.0.1:8000/api
  /// - Di Android Emulator: http://10.0.2.2:8000/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    try {
      if (io.Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {
      // Fallback
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const int pelangganId = 1;
  static const Duration batasWaktu = Duration(seconds: 10);
}
