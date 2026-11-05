class ItemKeranjang {
  final int id;
  final int produkId;
  final int varianId;
  final String namaProduk;
  final String ukuran;
  final String warna;
  final int hargaSatuan;
  final int jumlah;
  final int subtotalItem;

  ItemKeranjang({
    required this.id,
    required this.produkId,
    required this.varianId,
    required this.namaProduk,
    required this.ukuran,
    required this.warna,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotalItem,
  });

  factory ItemKeranjang.fromJson(Map<String, dynamic> json) {
    return ItemKeranjang(
      id: json['id'] ?? 0,
      produkId: json['produk_id'] ?? 0,
      varianId: json['varian_id'] ?? 0,
      namaProduk: json['nama_produk'] ?? '',
      ukuran: json['ukuran'] ?? '',
      warna: json['warna'] ?? '',
      hargaSatuan: json['harga_satuan'] ?? 0,
      jumlah: json['jumlah'] ?? 0,
      subtotalItem: json['subtotal_item'] ?? 0,
    );
  }
}

class DataKeranjang {
  final List<ItemKeranjang> items;
  final int subtotal;

  DataKeranjang({
    required this.items,
    required this.subtotal,
  });

  factory DataKeranjang.fromJson(Map<String, dynamic> json) {
    return DataKeranjang(
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ItemKeranjang.fromJson(item))
              .toList()
          : [],
      subtotal: json['subtotal'] ?? 0,
    );
  }
}
