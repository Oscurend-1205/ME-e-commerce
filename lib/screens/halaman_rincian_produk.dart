import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/pemilih_varian.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_keranjang.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

class HalamanRincianProduk extends StatefulWidget {
  final int produkId;

  const HalamanRincianProduk({super.key, required this.produkId});

  @override
  State<HalamanRincianProduk> createState() => _HalamanRincianProdukState();
}

class _HalamanRincianProdukState extends State<HalamanRincianProduk> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  Produk? _produk;
  Varian? _varianTerpilih;
  int _jumlah = 1;
  bool _sedangMenambahkan = false;

  @override
  void initState() {
    super.initState();
    _muatRincianProduk();
  }

  Future<void> _muatRincianProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _varianTerpilih = null;
      _jumlah = 1;
    });

    final respon = await LayananApi.ambilRincianProduk(widget.produkId);

    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final p = Produk.fromJson(respon.data as Map<String, dynamic>);
      setState(() {
        _produk = p;
        _keadaan = KeadaanMuat.berhasil;

        // Auto pilih varian pertama yang ada stoknya jika tersedia
        if (p.varian != null && p.varian!.isNotEmpty) {
          final varianTersedia = p.varian!.where((v) => v.stok > 0);
          if (varianTersedia.isNotEmpty) {
            _varianTerpilih = varianTersedia.first;
          } else {
            _varianTerpilih = p.varian!.first;
          }
        }
      });
    } else {
      setState(() {
        _keadaan = respon.code == '404' ? KeadaanMuat.kosong : KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _tambahKeKeranjang() async {
    if (_produk == null || _varianTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih varian ukuran dan warna terlebih dahulu.')),
      );
      return;
    }

    if (_varianTerpilih!.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Varian yang dipilih sedang habis.')),
      );
      return;
    }

    setState(() {
      _sedangMenambahkan = true;
    });

    final respon = await LayananApi.tambahKeKeranjang(
      produkId: _produk!.id,
      varianId: _varianTerpilih!.id,
      jumlah: _jumlah,
    );

    if (!mounted) return;

    setState(() {
      _sedangMenambahkan = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_produk!.nama} (${_varianTerpilih!.ukuran}, ${_varianTerpilih!.warna}) masuk ke keranjang.'),
          action: SnackBarAction(
            label: 'LIHAT',
            textColor: _putih,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanKeranjang()),
              );
            },
          ),
          backgroundColor: _hitam,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Menangani galat 409 (stok varian kurang), 422, dll tanpa pindah halaman
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respon.message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _kurangiJumlah() {
    if (_jumlah > 1) {
      setState(() {
        _jumlah--;
      });
    }
  }

  void _tambahJumlah() {
    final maxStok = _varianTerpilih?.stok ?? _produk?.stok ?? 99;
    if (_jumlah < maxStok) {
      setState(() {
        _jumlah++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jumlah maksimal sesuai stok varian ($maxStok).'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
        title: Text(
          _produk?.nama.toUpperCase() ?? 'RINCIAN PRODUK',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanKeranjang()),
              );
            },
          ),
        ],
      ),
      body: _bangunKonten(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil && _produk != null
          ? _bangunBilahBawah()
          : null,
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.search_off_outlined,
          pesan: 'Produk tidak ditemukan atau telah dihapus.',
          saranAksi: 'Kembali ke Katalog',
          onAksi: () => Navigator.pop(context),
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatRincianProduk,
        );
      case KeadaanMuat.berhasil:
        final produk = _produk!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder Gambar Besar (Editorial ZARA style)
              Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  color: _abuMuda,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        produk.kategori.toLowerCase() == 'aksesori'
                            ? Icons.watch_outlined
                            : Icons.checkroom_outlined,
                        size: 72,
                        color: _abuSedang,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        produk.merek.toUpperCase(),
                        style: const TextStyle(
                          color: _abuSedang,
                          letterSpacing: 2.0,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kategori & Merek
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    produk.kategori.toUpperCase(),
                    style: const TextStyle(
                      color: _abuSedang,
                      letterSpacing: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _abuGaris),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      produk.merek,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _hitam,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Nama Produk
              Text(
                produk.nama,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _hitam,
                ),
              ),
              const SizedBox(height: 8),

              // Harga
              Text(
                formatRupiah(produk.harga),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _hitam,
                ),
              ),
              const SizedBox(height: 16),

              const Divider(color: _abuGaris),
              const SizedBox(height: 16),

              // Atribut Khas Domain: Bahan
              Row(
                children: [
                  const Text(
                    'Bahan: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _hitam,
                    ),
                  ),
                  Text(
                    produk.bahan.isNotEmpty ? produk.bahan : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _abuSedang,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deskripsi (nullable safe)
              if (produk.deskripsi != null && produk.deskripsi!.isNotEmpty) ...[
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _hitam,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  produk.deskripsi!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _abuSedang,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Divider(color: _abuGaris),
              const SizedBox(height: 16),

              // Pemilih Varian (Ukuran & Warna)
              if (produk.varian != null && produk.varian!.isNotEmpty) ...[
                PemilihVarian(
                  daftarVarian: produk.varian!,
                  varianTerpilih: _varianTerpilih,
                  onPilih: (varian) {
                    setState(() {
                      _varianTerpilih = varian;
                      _jumlah = 1; // reset kuantitas ke 1
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Pengatur Kuantitas
              const Text(
                'Jumlah',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: _hitam,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _abuGaris),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _kurangiJumlah,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_jumlah',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: _tambahJumlah,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
    }
  }

  Widget _bangunBilahBawah() {
    final bool bisaBeli = _produk!.tersedia &&
        _varianTerpilih != null &&
        _varianTerpilih!.stok > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _putih,
        border: const Border(top: BorderSide(color: _abuGaris)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_sedangMenambahkan || !bisaBeli) ? null : _tambahKeKeranjang,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hitam,
              disabledBackgroundColor: _abuGaris,
              foregroundColor: _putih,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: _sedangMenambahkan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _putih,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    !bisaBeli
                        ? 'VARIAN INI HABIS'
                        : 'TAMBAH KE KERANJANG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: !bisaBeli ? _abuSedang : _putih,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

