class Pesanan {
  final int id;
  final String nomorPesanan;
  final String status;
  final int subtotal;
  final int ongkir;
  final int total;
  final String namaPenerima;
  final String alamat;
  final String? namaKurir;
  final String? metodePembayaran;
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
    this.namaKurir,
    this.metodePembayaran,
    this.createdAt,
    this.detail,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      id: json['id'] ?? 0,
      nomorPesanan: json['nomor_pesanan'] ?? '',
      status: json['status'] ?? '',
      subtotal: json['subtotal'] ?? 0,
      ongkir: json['ongkir'] ?? 0,
      total: json['total'] ?? 0,
      namaPenerima: json['nama_penerima'] ?? '',
      alamat: json['alamat'] ?? '',
      namaKurir: json['nama_kurir'],
      metodePembayaran: json['metode_pembayaran'],
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
  final String namaProduk;
  final String ukuran;
  final String warna;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;
  final String? gambar;

  DetailPesanan({
    required this.id,
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
