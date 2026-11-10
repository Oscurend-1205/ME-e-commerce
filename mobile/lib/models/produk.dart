import '../constants.dart';

class Produk {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;
  final String bahan;
  final String merek;
  final String? gambar;
  final String? gambarUrl;
  final List<FotoProdukItem>? fotos;
  final List<Varian>? varian;

  Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    required this.bahan,
    required this.merek,
    this.gambar,
    this.gambarUrl,
    this.fotos,
    this.varian,
  });

  /// URL resolusi gambar produk dari backend storage
  String get fotoUrl {
    if (gambar != null && gambar!.trim().isNotEmpty) {
      final g = gambar!.trim();
      if (g.startsWith('http://') || g.startsWith('https://')) {
        return g;
      }
      return '${Konstan.storageUrl}/$g';
    }
    if (gambarUrl != null && gambarUrl!.trim().isNotEmpty) {
      return gambarUrl!.trim();
    }
    return '${Konstan.storageUrl}/$id.jpg';
  }

  /// Daftar URL seluruh foto produk untuk galeri/slider (maks 5 foto)
  List<String> get daftarFotoUrl {
    if (fotos != null && fotos!.isNotEmpty) {
      final list = fotos!
          .map((f) => f.url.trim())
          .where((u) => u.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return [fotoUrl];
  }

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      kategori: json['kategori'] ?? '',
      stok: json['stok'] ?? 0,
      tersedia: json['tersedia'] ?? false,
      deskripsi: json['deskripsi'],
      bahan: json['bahan'] ?? '',
      merek: json['merek'] ?? '',
      gambar: json['gambar'],
      gambarUrl: json['gambar_url'],
      fotos: json['fotos'] != null
          ? (json['fotos'] as List)
              .map((f) => FotoProdukItem.fromJson(f as Map<String, dynamic>))
              .toList()
          : null,
      varian: json['varian'] != null
          ? (json['varian'] as List)
              .map((v) => Varian.fromJson(v))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'kategori': kategori,
      'stok': stok,
      'tersedia': tersedia,
      'deskripsi': deskripsi,
      'bahan': bahan,
      'merek': merek,
      'gambar': gambar,
      'gambar_url': gambarUrl,
      'fotos': fotos?.map((f) => f.toJson()).toList(),
      'varian': varian?.map((v) => v.toJson()).toList(),
    };
  }
}

class FotoProdukItem {
  final int id;
  final String url;
  final int urutan;

  FotoProdukItem({
    required this.id,
    required this.url,
    required this.urutan,
  });

  factory FotoProdukItem.fromJson(Map<String, dynamic> json) {
    return FotoProdukItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      url: json['url']?.toString() ?? '',
      urutan: json['urutan'] is int
          ? json['urutan'] as int
          : int.tryParse(json['urutan']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'urutan': urutan,
    };
  }
}

class Varian {
  final int id;
  final String ukuran;
  final String warna;
  final int stok;

  Varian({
    required this.id,
    required this.ukuran,
    required this.warna,
    required this.stok,
  });

  factory Varian.fromJson(Map<String, dynamic> json) {
    return Varian(
      id: json['id'] ?? 0,
      ukuran: json['ukuran'] ?? '',
      warna: json['warna'] ?? '',
      stok: json['stok'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ukuran': ukuran,
      'warna': warna,
      'stok': stok,
    };
  }
}
