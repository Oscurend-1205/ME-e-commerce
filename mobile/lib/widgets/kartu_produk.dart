import 'package:flutter/material.dart';
import '../models/produk.dart';
import '../theme.dart';
import 'format_rupiah.dart';
import 'foto_dummy.dart';

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

    final fotoUrl = FotoDummy.untukProduk(produk);

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
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FotoDummy.bangunGambar(
                    url: fotoUrl,
                    fit: BoxFit.cover,
                    fallbackWidget: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            produk.kategori.toLowerCase() == 'aksesori'
                                ? Icons.watch_outlined
                                : Icons.checkroom_outlined,
                            size: 36,
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
                      color: Colors.white.withValues(alpha: 0.65),
                      child: const Center(
                        child: Text(
                          'STOK HABIS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ),
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
              // Titik Warna Produk Sesuai Varian
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TemaAplikasi.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8C6C5),
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
                  fontWeight: FontWeight.w500,
                  color: TemaAplikasi.secondary,
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
              fontWeight: FontWeight.w500,
              color: TemaAplikasi.primary,
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
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }
}
