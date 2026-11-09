import 'package:flutter/material.dart';
import '../models/produk.dart';
import '../theme.dart';
import 'format_rupiah.dart';
import 'foto_dummy.dart';

class KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onTap;
  final VoidCallback? onTambahKeranjang;
  final VoidCallback? onToggleWishlist;
  final bool isWishlist;

  const KartuProduk({
    super.key,
    required this.produk,
    required this.onTap,
    this.onTambahKeranjang,
    this.onToggleWishlist,
    this.isWishlist = false,
  });

  bool get _habis => produk.stok == 0 || !produk.tersedia;

  @override
  Widget build(BuildContext context) {
    // Ambil daftar ukuran unik dari varian jika ada
    final ukuranList = produk.varian != null && produk.varian!.isNotEmpty
        ? produk.varian!.map((v) => v.ukuran).toSet().take(4).join(' ')
        : (produk.kategori.toLowerCase() == 'aksesori' ? 'One Size' : 'S M L');

    final fotoUrl = FotoDummy.untukProduk(produk);

    // Tentukan label badge (Bestseller untuk produk tertentu, Habis, atau New Arrival)
    final String labelBadge = _habis
        ? 'HABIS'
        : (produk.id % 3 == 0 ? 'BESTSELLER' : 'NEW ARRIVAL');

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
                    cacheWidth: 600,
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

                // Label Status (New Arrival / Bestseller / Habis)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    color: _habis
                        ? TemaAplikasi.secondary
                        : (labelBadge == 'BESTSELLER'
                            ? TemaAplikasi.secondary
                            : TemaAplikasi.primary),
                    child: Text(
                      labelBadge,
                      style: const TextStyle(
                        color: TemaAplikasi.onPrimary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

                // Tombol Wishlist Bulat di Pojok Kanan Atas (cek-beranda.html)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleWishlist,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlist ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlist ? TemaAplikasi.errorColor : TemaAplikasi.primary,
                        ),
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

          // Metadata Variasi: Indikator Titik Warna & Ukuran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Titik Warna Produk Sesuai Desain Editorial
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: TemaAplikasi.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: TemaAplikasi.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: TemaAplikasi.borderGray, width: 0.5),
                    ),
                  ),
                ],
              ),
              Text(
                ukuranList,
                style: const TextStyle(
                  fontSize: 9.5,
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
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Tombol "+ Tas Belanja" Sesuai cek-beranda.html
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: _habis ? null : onTambahKeranjang,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.surfaceContainerHigh,
                foregroundColor: TemaAplikasi.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                _habis ? 'HABIS' : 'TAS BELANJA',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
