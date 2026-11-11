class EstimasiCheckout {
  final int subtotal;
  final int ongkir;
  final int total;

  const EstimasiCheckout({
    required this.subtotal,
    required this.ongkir,
    required this.total,
  });

  factory EstimasiCheckout.fromJson(Map<String, dynamic> json) {
    int bacaNilai(String kunci) {
      final nilai = json[kunci];
      if (nilai is num) return nilai.toInt();
      throw FormatException('Nilai $kunci tidak valid pada estimasi checkout.');
    }

    return EstimasiCheckout(
      subtotal: bacaNilai('subtotal'),
      ongkir: bacaNilai('ongkir'),
      total: bacaNilai('total'),
    );
  }
}
