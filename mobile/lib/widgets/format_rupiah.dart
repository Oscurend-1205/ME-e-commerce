import 'package:intl/intl.dart';

/// Format angka integer menjadi format mata uang Rupiah Indonesia
/// Contoh: 89000 → "Rp 89.000"
String formatRupiah(int nilai) {
  final format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return format.format(nilai);
}
