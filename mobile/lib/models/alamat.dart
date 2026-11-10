/// Model alamat penerima untuk alur checkout.
/// Backend belum menyediakan tabel/endpoint alamat tersendiri;
/// data ini dibawa antar langkah checkout dan disimpan sebagai
/// teks `nama_penerima` + `alamat` pada pesanan.
class Alamat {
  final String id;
  final String nama;
  final String telepon;
  final String alamat;
  final String label;
  final String catatan;
  final bool utama;

  const Alamat({
    required this.id,
    required this.nama,
    required this.telepon,
    required this.alamat,
    required this.label,
    this.catatan = '',
    this.utama = false,
  });
}
