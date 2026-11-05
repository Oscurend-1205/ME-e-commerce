import 'package:flutter/material.dart';
import '../models/produk.dart';
import 'format_rupiah.dart';

// === Warna Tema ===
const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);

/// Kartu produk untuk grid katalog
/// Menampilkan gambar placeholder, nama, harga, dan badge "Habis" jika stok 0
class KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onTap;

  const KartuProduk({
    super.key,
    required this.produk,
    required this.onTap,
  });

  bool get _habis => produk.stok == 0 || !produk.tersedia;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar produk / placeholder
          Expanded(
            child: Stack(
              children: [
                // Placeholder gambar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _abuMuda,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.checkroom,
                      size: 48,
                      color: _abuSedang,
                    ),
                  ),
                ),

                // Badge "Habis" jika stok kosong
                if (_habis)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _hitam.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'HABIS',
                          style: TextStyle(
                            color: _putih,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Nama produk
          Text(
            produk.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _hitam,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 4),

          // Harga
          Text(
            formatRupiah(produk.harga),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _hitam,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
