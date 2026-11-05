import 'package:flutter/material.dart';
import '../models/produk.dart';
import '../theme.dart';
import 'format_rupiah.dart';

class KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onTap;
  final VoidCallback? onTambahKeranjang;

  const KartuProduk({
    super.key,
    required this.produk,
    required this.onTap,
    this.onTambahKeranjang,
  });

  bool get _habis => produk.stok == 0 || !produk.tersedia;

  @override
  Widget build(BuildContext context) {
    // Ambil daftar ukuran unik dari varian jika ada
    final ukuranList = produk.varian != null && produk.varian!.isNotEmpty
        ? produk.varian!.map((v) => v.ukuran).toSet().take(3).join(' ')
        : 'All Size';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk (Aspek Rasio 3:4 Khas Fashion Editorial)
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          produk.kategori.toLowerCase() == 'aksesori'
                              ? Icons.watch_outlined
                              : Icons.checkroom_outlined,
                          size: 40,
                          color: TemaAplikasi.mutedGray,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          produk.merek.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.mutedGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Label Status (Habis / New Arrival)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: _habis ? TemaAplikasi.secondary : TemaAplikasi.primary,
                    child: Text(
                      _habis ? 'HABIS' : 'NEW',
                      style: const TextStyle(
                        color: TemaAplikasi.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

                // Overlay Gelap jika produk Habis
                if (_habis)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Metadata Variasi: Indikator Warna & Ukuran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: TemaAplikasi.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: TemaAplikasi.borderGray,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                ukuranList,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: TemaAplikasi.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Nama Produk
          Text(
            produk.nama,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: TemaAplikasi.primary,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Harga
          Text(
            formatRupiah(produk.harga),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }
}
