class Kurir {
  final int id;
  final String nama;
  final String wilayah;
  final int tarif;

  Kurir({
    required this.id,
    required this.nama,
    required this.wilayah,
    required this.tarif,
  });

  factory Kurir.fromJson(Map<String, dynamic> json) {
    return Kurir(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      wilayah: json['wilayah'] ?? '',
      tarif: json['tarif'] ?? 0,
    );
  }
}
