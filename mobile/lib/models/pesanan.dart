class Pesanan {
  final int id;
  final String nomorPesanan;
  final String status;
  final int subtotal;
  final int ongkir;
  final int total;
  final String namaPenerima;
  final String alamat;
  final String? catatan;
  final String? namaKurir;
  final String? metodePembayaran;
  final String? metodeKode;
  final bool isCod;
  final bool fallbackCodTersedia;
  final String? snapToken;
  final String? redirectUrl;
  final String? qrUrl;
  final String? qrString;
  final String? createdAt;
  final List<DetailPesanan>? detail;

  Pesanan({
    required this.id,
    required this.nomorPesanan,
    required this.status,
    required this.subtotal,
    required this.ongkir,
    required this.total,
    required this.namaPenerima,
    required this.alamat,
    this.catatan,
    this.namaKurir,
    this.metodePembayaran,
    this.metodeKode,
    this.isCod = false,
    this.fallbackCodTersedia = false,
    this.snapToken,
    this.redirectUrl,
    this.qrUrl,
    this.qrString,
    this.createdAt,
    this.detail,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    final token = json['snap_token'] as String?;
    final rawRedirect = json['redirect_url'] as String?;
    final computedRedirect = (rawRedirect != null && rawRedirect.isNotEmpty)
        ? rawRedirect
        : (token != null && token.isNotEmpty
            ? 'https://app.sandbox.midtrans.com/snap/v4/redirection/$token'
            : null);

    final bool isCod = json['is_cod'] == true ||
        (json['metode_pembayaran']?.toString().toLowerCase().contains('tunai') ?? false) ||
        (json['metode_pembayaran']?.toString().toLowerCase().contains('cod') ?? false) ||
        (json['metode_kode']?.toString().toLowerCase().contains('cod') ?? false) ||
        (json['metode_kode']?.toString().toLowerCase().contains('tunai') ?? false);

    return Pesanan(
      id: json['id'] ?? 0,
      nomorPesanan: json['nomor_pesanan'] ?? '',
      status: json['status'] ?? '',
      subtotal: json['subtotal'] ?? 0,
      ongkir: json['ongkir'] ?? 0,
      total: json['total'] ?? 0,
      namaPenerima: json['nama_penerima'] ?? '',
      alamat: json['alamat'] ?? '',
      catatan: json['catatan'],
      namaKurir: json['nama_kurir'],
      metodePembayaran: json['metode_pembayaran'],
      metodeKode: json['metode_kode'],
      isCod: isCod,
      fallbackCodTersedia: json['fallback_cod_tersedia'] ?? false,
      snapToken: token,
      redirectUrl: computedRedirect,
      qrUrl: json['qr_url'],
      qrString: json['qr_string'],
      createdAt: json['created_at'],
      detail: json['detail'] != null
          ? (json['detail'] as List)
              .map((d) => DetailPesanan.fromJson(d))
              .toList()
          : null,
    );
  }
}

class DetailPesanan {
  final int id;
  final int? produkId;
  final int? varianId;
  final String namaProduk;
  final String ukuran;
  final String warna;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;
  final String? gambar;

  DetailPesanan({
    required this.id,
    this.produkId,
    this.varianId,
    required this.namaProduk,
    required this.ukuran,
    required this.warna,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    this.gambar,
  });

  factory DetailPesanan.fromJson(Map<String, dynamic> json) {
    return DetailPesanan(
      id: json['id'] ?? 0,
      produkId: json['produk_id'],
      varianId: json['varian_id'],
      namaProduk: json['nama_produk'] ?? '',
      ukuran: json['ukuran'] ?? '',
      warna: json['warna'] ?? '',
      hargaSatuan: json['harga_satuan'] ?? 0,
      jumlah: json['jumlah'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      gambar: json['gambar'],
    );
  }
}
