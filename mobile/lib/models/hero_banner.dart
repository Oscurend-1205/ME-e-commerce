class HeroBannerModel {
  final int id;
  final String judul;
  final String subjudul;
  final String tag;
  final String koleksi;
  final String gambar;
  final String gambarUrl;
  final int urutan;

  const HeroBannerModel({
    required this.id,
    required this.judul,
    required this.subjudul,
    required this.tag,
    required this.koleksi,
    required this.gambar,
    required this.gambarUrl,
    required this.urutan,
  });

  factory HeroBannerModel.fromJson(Map<String, dynamic> json) {
    return HeroBannerModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? 'ME MINIMALISM',
      subjudul: json['subjudul']?.toString() ?? '',
      tag: json['tag']?.toString() ?? 'BARU TIBA // DROP 01',
      koleksi: json['koleksi']?.toString() ?? 'ATELIER ÉDITION 2026',
      gambar: json['gambar']?.toString() ?? '',
      gambarUrl: json['gambar_url']?.toString() ?? '',
      urutan: json['urutan'] is int ? json['urutan'] as int : int.tryParse(json['urutan']?.toString() ?? '1') ?? 1,
    );
  }
}
