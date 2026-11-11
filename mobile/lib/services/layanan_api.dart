import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/api_response.dart';
import '../models/estimasi_checkout.dart';
import 'state_pengguna.dart';

class LayananApi {
  /// HTTP client bersama agar koneksi (keep-alive) dipakai ulang
  /// antar request, bukan membuat TCP handshake baru setiap kali.
  static final http.Client _client = http.Client();

  // === Header standar ===
  static Map<String, String> _headers({Map<String, String>? tambahan}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // Jika sudah login, sertakan token Bearer untuk autentikasi
    final token = StatePengguna.tokenNotifier.value;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    // Fallback identitas statis (mode tamu / uji petik UTS).
    // Backend mengutamakan Bearer token bila keduanya dikirim.
    headers['X-Pelanggan-Id'] =
        (StatePengguna.pelangganIdNotifier.value ?? Konstan.pelangganId)
            .toString();
    if (tambahan != null) {
      headers.addAll(tambahan);
    }
    return headers;
  }

  // =====================================================================
  //  AUTENTIKASI
  // =====================================================================

  /// POST /api/auth/register — Daftar akun baru
  static Future<ApiResponse> register({
    required String nama,
    required String email,
    required String password,
    String? noTelp,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/auth/register');

      final body = <String, dynamic>{
        'nama': nama,
        'email': email,
        'password': password,
      };
      if (noTelp != null && noTelp.isNotEmpty) {
        body['no_telp'] = noTelp;
      }

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/auth/login — Masuk dengan email & password
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/auth/login');

      final body = {'email': email, 'password': password};

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/auth/logout — Keluar dari akun
  static Future<ApiResponse> logout() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/auth/logout');

      final respons = await _client
          .post(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/auth/me — Ambil data profil yang sedang login
  static Future<ApiResponse> ambilProfil() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/auth/me');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  // =====================================================================
  //  PRODUK & BANNER
  // =====================================================================

  /// GET /api/hero-banners — Ambil daftar hero banner beranda
  static Future<ApiResponse> ambilHeroBanner() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/hero-banners');
      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

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

  /// POST /api/checkout/estimasi — Ambil ringkasan tagihan hasil hitung server
  static Future<ApiResponse<EstimasiCheckout>> estimasiCheckout({
    required int kurirId,
    required List<int> itemKeranjangIds,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/checkout/estimasi');
      final respons = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({
              'kurir_id': kurirId,
              'item_keranjang_ids': itemKeranjangIds,
            }),
          )
          .timeout(Konstan.batasWaktu);

      final response = _prosesRespons(respons);
      if (!response.berhasil) {
        return ApiResponse<EstimasiCheckout>(
          status: response.status,
          code: response.code,
          message: response.message,
          errors: response.errors,
        );
      }

      if (response.data is! Map<String, dynamic>) {
        return ApiResponse<EstimasiCheckout>(
          status: 'gagal',
          code: '500',
          message: 'Respons estimasi tidak valid dari server.',
        );
      }

      return ApiResponse<EstimasiCheckout>(
        status: response.status,
        code: response.code,
        message: response.message,
        data: EstimasiCheckout.fromJson(response.data as Map<String, dynamic>),
        errors: response.errors,
      );
    } on FormatException {
      return ApiResponse<EstimasiCheckout>(
        status: 'gagal',
        code: '500',
        message: 'Respons estimasi tidak valid dari server.',
      );
    } catch (e) {
      final response = _tanganiGalat(e);
      return ApiResponse<EstimasiCheckout>(
        status: response.status,
        code: response.code,
        message: response.message,
        errors: response.errors,
      );
    }
  }

  /// POST /api/checkout — Proses checkout
  static Future<ApiResponse> checkout({
    required String nama,
    required String alamat,
    String? catatan,
    required int kurirId,
    required int metodePembayaranId,
    required String kunciIdempoten,
    required List<int> itemKeranjangIds,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/checkout');

      final body = {
        'nama': nama,
        'alamat': alamat,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        'kurir_id': kurirId,
        'metode_pembayaran_id': metodePembayaranId,
        'item_keranjang_ids': itemKeranjangIds,
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

  /// GET /api/payment/status/{orderId} — Cek status pembayaran
  static Future<ApiResponse> cekStatusPembayaran(String orderId) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/payment/status/$orderId');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/payment/status-midtrans — Cek status kesehatan gateway Midtrans
  static Future<ApiResponse> cekStatusMidtrans() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/payment/status-midtrans');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/pesanan/{id}/fallback-cod — Alihkan pesanan online yang gagal ke COD
  static Future<ApiResponse> fallbackCod({
    required int pesananId,
    String? alasan,
  }) async {
    try {
      final uri = Uri.parse(
        '${Konstan.baseUrl}/pesanan/$pesananId/fallback-cod',
      );

      final body = {if (alasan != null && alasan.isNotEmpty) 'alasan': alasan};

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// POST /api/checkout/cod — Checkout langsung menggunakan metode COD
  static Future<ApiResponse> checkoutCod({
    required String nama,
    required String alamat,
    String? catatan,
    required int kurirId,
    required String kunciIdempoten,
    required List<int> itemKeranjangIds,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/checkout/cod');

      final body = {
        'nama': nama,
        'alamat': alamat,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        'kurir_id': kurirId,
        'item_keranjang_ids': itemKeranjangIds,
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
  //  ONGKIR (RAJAONGKIR)
  // =====================================================================

  /// POST /api/ongkir — Cek ongkir real-time dari RajaOngkir
  /// Jika origin tidak diisi, backend otomatis menggunakan lokasi asal toko dari Pengaturan Toko
  static Future<ApiResponse> cekOngkir({
    String? origin,
    required String destination,
    required int weight,
    String? courier,
  }) async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/ongkir');

      final body = <String, dynamic>{
        'destination': destination,
        'weight': weight,
      };
      if (origin != null && origin.isNotEmpty) {
        body['origin'] = origin;
      }
      if (courier != null && courier.isNotEmpty) {
        body['courier'] = courier;
      }

      final respons = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/pengaturan-toko — Ambil profil toko dan lokasi gudang/origin RajaOngkir
  static Future<ApiResponse> ambilPengaturanToko() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/pengaturan-toko');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/kota — Ambil daftar kota untuk autocomplete
  static Future<ApiResponse> ambilKota({String? search}) async {
    try {
      final uri = Uri.parse(
        '${Konstan.baseUrl}/kota',
      ).replace(queryParameters: search != null ? {'search': search} : null);

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/provinsi — Ambil daftar provinsi
  static Future<ApiResponse> ambilProvinsi() async {
    try {
      final uri = Uri.parse('${Konstan.baseUrl}/provinsi');

      final respons = await _client
          .get(uri, headers: _headers())
          .timeout(Konstan.batasWaktu);

      return _prosesRespons(respons);
    } catch (e) {
      return _tanganiGalat(e);
    }
  }

  /// GET /api/kecamatan — Ambil daftar kecamatan berdasarkan kota
  static Future<ApiResponse> ambilKecamatan(String cityId) async {
    try {
      final uri = Uri.parse(
        '${Konstan.baseUrl}/kecamatan',
      ).replace(queryParameters: {'city_id': cityId});

      final respons = await _client
          .get(uri, headers: _headers())
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
