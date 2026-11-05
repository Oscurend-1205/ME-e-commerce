class MetodePembayaran {
  final int id;
  final String kode;
  final String nama;

  MetodePembayaran({
    required this.id,
    required this.kode,
    required this.nama,
  });

  factory MetodePembayaran.fromJson(Map<String, dynamic> json) {
    return MetodePembayaran(
      id: json['id'] ?? 0,
      kode: json['kode'] ?? '',
      nama: json['nama'] ?? '',
    );
  }
}
