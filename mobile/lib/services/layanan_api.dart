import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/api_response.dart';

class LayananApi {
  /// HTTP client bersama agar koneksi (keep-alive) dipakai ulang
  /// antar request, bukan membuat TCP handshake baru setiap kali.
  static final http.Client _client = http.Client();

  // === Header standar ===
  static Map<String, String> _headers({Map<String, String>? tambahan}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Pelanggan-Id': Konstan.pelangganId.toString(),
    };
    if (tambahan != null) {
      headers.addAll(tambahan);
    }
    return headers;
  }

  // =====================================================================
  //  PRODUK
  // =====================================================================

  /// GET /api/produk — Ambil daftar produk (opsional: filter kategori, cari)
  static Future<ApiResponse> ambilProduk({
    String? kategori,
    String? cari,
  }) async {
    try {
      final params = <String, String>{};
      if (kategori != null && kategori.isNotEmpty) {
        params['kategori'] = kategori;
      }
      if (cari != null && cari.isNotEmpty) params['cari'] = cari;

      final uri = Uri.parse(
        '${Konstan.baseUrl}/produk',
      ).replace(queryParameters: params.isNotEmpty ? params : null);

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/produk/{id} — Ambil rincian produk
  static Future<ApiResponse> ambilRincianProduk(int id) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/produk/$id');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/produk — Tambah produk baru
  static Future<ApiResponse> tambahProduk(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/produk');

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(data))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// PUT /api/produk/{id} — Ubah produk
  static Future<ApiResponse> ubahProduk(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/produk/$id');

      final respons = await _client
          .put(uri, headers: _headers(), body: jsonEncode(data))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// DELETE /api/produk/{id} — Hapus produk
  static Future<ApiResponse> hapusProduk(int id) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/produk/$id');

      final respons = await _client
          .delete(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  KERANJANG
  // =====================================================================

  /// GET /api/keranjang — Ambil isi keranjang
  static Future<ApiResponse> ambilKeranjang() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/keranjang');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/keranjang — Tambahkan item ke keranjang
  static Future<ApiResponse> tambahKeKeranjang({
    required int produkId,
    required int varianId,
    required int jumlah,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/keranjang');

      final body = {
        'produk_id': produkId,
        'varian_id': varianId,
        'jumlah': jumlah,
      };

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// PUT /api/keranjang/{id} — Ubah item keranjang (jumlah dan/atau varian)
  static Future<ApiResponse> ubahItemKeranjang(
    int id, {
    int? jumlah,
    int? varianId,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/keranjang/$id');

      final body = <String, dynamic>{};
      if (jumlah != null) body['jumlah'] = jumlah;
      if (varianId != null) body['varian_id'] = varianId;

      final respons = await _client
          .put(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// PUT /api/keranjang/{id} — Ubah jumlah item keranjang
  static Future<ApiResponse> ubahJumlahKeranjang(int id, int jumlah) {
    return ubahItemKeranjang(id, jumlah: jumlah);
  }

  /// DELETE /api/keranjang/{id} — Hapus item dari keranjang
  static Future<ApiResponse> hapusDariKeranjang(int id) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/keranjang/$id');

      final respons = await _client
          .delete(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  KURIR
  // =====================================================================

  /// GET /api/kurir — Ambil daftar kurir
  static Future<ApiResponse> ambilKurir() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/kurir');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  CHECKOUT
  // =====================================================================

  /// POST /api/checkout — Proses checkout
  static Future<ApiResponse> checkout({
    required String nama,
    required String alamat,
    String? catatan,
    required int kurirId,
    required int metodePembayaranId,
    required String kunciIdempoten,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/checkout');

      final body = {
        'nama': nama,
        'alamat': alamat,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        'kurir_id': kurirId,
        'metode_pembayaran_id': metodePembayaranId,
      };

      final respons = await _client
          .post(
            uri,
            headers: _headers(tambahan: {'X-Kunci-Idempoten': kunciIdempoten}),
            body: jsonEncode(body),
          )
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  PESANAN
  // =====================================================================

  /// GET /api/pesanan — Ambil riwayat pesanan
  static Future<ApiResponse> ambilRiwayatPesanan() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/pesanan');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/pesanan/{id} — Ambil rincian pesanan
  static Future<ApiResponse> ambilRincianPesanan(int id) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/pesanan/$id');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// PATCH /api/pesanan/{id}/status — Ubah status pesanan
  static Future<ApiResponse> ubahStatusPesanan(int id, String status) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/pesanan/$id/status');

      final body = {'status': status};

      final respons = await _client
          .patch(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  METODE PEMBAYARAN
  // =====================================================================

  /// GET /api/metode-pembayaran — Ambil daftar metode pembayaran
  static Future<ApiResponse> ambilMetodePembayaran() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/metode-pembayaran');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  HELPER PRIVAT
  // =====================================================================

  /// Memproses HTTP Response menjadi ApiResponse
  static ApiResponse _prosesRespons(http.Response respons) {
    try {
      final json = jsonDecode(respons.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, null);
    } catch (_) {
      // Jika body bukan JSON yang valid
      return ApiResponse(
        status: 'gagal',
        code: respons.statusCode.toString(),
        message: 'Respons tidak valid dari server.',
      );
    }
  }

  /// Menangani exception jaringan / timeout / lainnya
  static ApiResponse _tanganiGalat(Object e) {
    if (e is SocketException) {
      return ApiResponse(
        status: 'gagal',
        code: 'NO_CONNECTION',
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    if (e is TimeoutException) {
      return ApiResponse(
        status: 'gagal',
        code: 'TIMEOUT',
        message: 'Server tidak merespons. Silakan coba lagi.',
      );
    }

    return ApiResponse(
      status: 'gagal',
      code: '500',
      message: 'Terjadi kesalahan. Silakan coba lagi.',
    );
  }
}
