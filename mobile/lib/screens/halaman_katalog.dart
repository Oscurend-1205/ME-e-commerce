import 'package:flutter/material.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../widgets/kartu_produk.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_keranjang.dart';
import 'halaman_rincian_produk.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuGaris = Color(0xFFDDDDDD);
const Color _abuSedang = Color(0xFF777777);

class HalamanKatalog extends StatefulWidget {
  const HalamanKatalog({super.key});

  @override
  State<HalamanKatalog> createState() => _HalamanKatalogState();
}

class _HalamanKatalogState extends State<HalamanKatalog> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Produk> _daftarProduk = [];

  String? _kategoriTerpilih;
  final TextEditingController _cariController = TextEditingController();
  bool _tampilkanPencarian = false;
  int _jumlahItemKeranjang = 0;

  final List<String> _kategoriList = ['Semua', 'Pakaian', 'Aksesori'];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    await Future.wait([
      _muatProduk(),
      _muatJumlahKeranjang(),
    ]);
  }

  Future<void> _muatProduk() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final respon = await LayananApi.ambilProduk(
      kategori: _kategoriTerpilih == 'Semua' ? null : _kategoriTerpilih,
      cari: _cariController.text.trim().isEmpty ? null : _cariController.text.trim(),
    );

    if (!mounted) return;

    if (respon.berhasil) {
      final List dataRaw = respon.data is List ? respon.data as List : [];
      final produkList = dataRaw
          .map((item) => Produk.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _daftarProduk = produkList;
        _keadaan = produkList.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _muatJumlahKeranjang() async {
    final respon = await LayananApi.ambilKeranjang();
    if (!mounted) return;

    if (respon.berhasil && respon.data != null) {
      final dataKeranjang = DataKeranjang.fromJson(respon.data as Map<String, dynamic>);
      int totalItem = 0;
      for (final item in dataKeranjang.items) {
        totalItem += item.jumlah;
      }
      setState(() {
        _jumlahItemKeranjang = totalItem;
      });
    }
  }

  void _pilihKategori(String kategori) {
    if (_kategoriTerpilih == kategori) return;
    setState(() {
      _kategoriTerpilih = kategori == 'Semua' ? null : kategori;
    });
    _muatProduk();
  }

  void _kirimPencarian() {
    _muatProduk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
        title: _tampilkanPencarian
            ? TextField(
                controller: _cariController,
                autofocus: true,
                style: const TextStyle(fontSize: 15, color: _hitam),
                decoration: const InputDecoration(
                  hintText: 'Cari pakaian, tas, jaket...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: _abuSedang, fontSize: 14),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _kirimPencarian(),
              )
            : const Text(
                'ME',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontSize: 16,
                ),
              ),
        centerTitle: !_tampilkanPencarian,
        actions: [
          IconButton(
            icon: Icon(_tampilkanPencarian ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_tampilkanPencarian) {
                  _cariController.clear();
                  _tampilkanPencarian = false;
                  _muatProduk();
                } else {
                  _tampilkanPencarian = true;
                }
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HalamanKeranjang(),
                    ),
                  );
                  _muatData();
                },
              ),
              if (_jumlahItemKeranjang > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _hitam,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_jumlahItemKeranjang',
                      style: const TextStyle(
                        color: _putih,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: _kategoriList.map((kat) {
                    final terpilih = (_kategoriTerpilih == null && kat == 'Semua') ||
                        _kategoriTerpilih == kat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(kat),
                        selected: terpilih,
                        onSelected: (_) => _pilihKategori(kat),
                        selectedColor: _hitam,
                        backgroundColor: _putih,
                        labelStyle: TextStyle(
                          color: terpilih ? _putih : _hitam,
                          fontSize: 13,
                          fontWeight: terpilih ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: terpilih ? _hitam : _abuGaris,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, color: _abuGaris),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _hitam,
        onRefresh: _muatData,
        child: _bangunKonten(),
      ),
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
        return WidgetKosong(
          ikon: Icons.inventory_2_outlined,
          pesan: _cariController.text.isNotEmpty
              ? 'Tidak ada produk yang cocok dengan "${_cariController.text}".'
              : 'Belum ada produk untuk kategori ini.',
          saranAksi: 'Tampilkan Semua Produk',
          onAksi: () {
            setState(() {
              _kategoriTerpilih = null;
              _cariController.clear();
              _tampilkanPencarian = false;
            });
            _muatProduk();
          },
        );
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatProduk,
        );
      case KeadaanMuat.berhasil:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 14,
            mainAxisSpacing: 20,
          ),
          itemCount: _daftarProduk.length,
          itemBuilder: (context, index) {
            final produk = _daftarProduk[index];
            return KartuProduk(
              produk: produk,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HalamanRincianProduk(produkId: produk.id),
                  ),
                );
                _muatData();
              },
            );
          },
        );
    }
  }
}
