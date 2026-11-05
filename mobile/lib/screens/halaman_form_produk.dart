import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';

class ModelVarianInput {
  int? id;
  TextEditingController ukuranController;
  TextEditingController warnaController;
  TextEditingController stokController;

  ModelVarianInput({
    this.id,
    required String ukuran,
    required String warna,
    required int stok,
  })  : ukuranController = TextEditingController(text: ukuran),
        warnaController = TextEditingController(text: warna),
        stokController = TextEditingController(text: stok.toString());

  void dispose() {
    ukuranController.dispose();
    warnaController.dispose();
    stokController.dispose();
  }
}

class HalamanFormProduk extends StatefulWidget {
  final Produk? produk;

  const HalamanFormProduk({super.key, this.produk});

  @override
  State<HalamanFormProduk> createState() => _HalamanFormProdukState();
}

class _HalamanFormProdukState extends State<HalamanFormProduk> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _merekController;
  late TextEditingController _bahanController;
  late TextEditingController _deskripsiController;

  String _kategoriTerpilih = 'Pakaian';
  bool _tersedia = true;
  bool _sedangMenyimpan = false;
  bool _sedangMemuatVarian = false;

  final List<ModelVarianInput> _daftarVarianInput = [];
  Map<String, dynamic>? _galatValidasi422;

  final List<String> _pilihanKategori = ['Pakaian', 'Aksesori'];

  bool get _modeEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaController = TextEditingController(text: p?.nama ?? '');
    _hargaController = TextEditingController(text: p?.harga != null ? p!.harga.toString() : '');
    _merekController = TextEditingController(text: p?.merek ?? 'ME Studio');
    _bahanController = TextEditingController(text: p?.bahan ?? '');
    _deskripsiController = TextEditingController(text: p?.deskripsi ?? '');
    _tersedia = p?.tersedia ?? true;
    _kategoriTerpilih = (p != null && _pilihanKategori.contains(p.kategori))
        ? p.kategori
        : 'Pakaian';

    if (_modeEdit) {
      _muatRincianVarian();
    } else {
      // Varian default untuk memudahkan input produk baru
      _tambahVarian(ukuran: 'M', warna: 'Hitam', stok: 10);
      _tambahVarian(ukuran: 'L', warna: 'Hitam', stok: 5);
    }
  }

  Future<void> _muatRincianVarian() async {
    setState(() {
      _sedangMemuatVarian = true;
    });

    final respon = await LayananApi.ambilRincianProduk(widget.produk!.id);

    if (!mounted) return;

    setState(() {
      _sedangMemuatVarian = false;
    });

    if (respon.berhasil && respon.data != null) {
      final pLengkap = Produk.fromJson(respon.data as Map<String, dynamic>);
      if (pLengkap.varian != null && pLengkap.varian!.isNotEmpty) {
        setState(() {
          for (final v in _daftarVarianInput) {
            v.dispose();
          }
          _daftarVarianInput.clear();
          for (final v in pLengkap.varian!) {
            _daftarVarianInput.add(
              ModelVarianInput(
                id: v.id,
                ukuran: v.ukuran,
                warna: v.warna,
                stok: v.stok,
              ),
            );
          }
        });
      }
    }
  }

  void _tambahVarian({String ukuran = 'All Size', String warna = 'Putih', int stok = 10}) {
    setState(() {
      _daftarVarianInput.add(
        ModelVarianInput(ukuran: ukuran, warna: warna, stok: stok),
      );
    });
  }

  void _hapusVarian(int index) {
    if (_daftarVarianInput.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk wajib memiliki minimal satu varian.')),
      );
      return;
    }
    setState(() {
      final v = _daftarVarianInput.removeAt(index);
      v.dispose();
    });
  }

  /// Preset contoh data cepat untuk memudahkan pengujian admin
  void _isiContohProduk(String tipe) {
    setState(() {
      if (tipe == 'cardigan') {
        _namaController.text = 'Cardigan Rajut Oversize Textured Knit';
        _hargaController.text = '199000';
        _kategoriTerpilih = 'Pakaian';
        _merekController.text = 'ME Studio';
        _bahanController.text = 'Wool Blend Knit 100%';
        _deskripsiController.text = 'Cardigan rajut hangat bertekstur waffle halus dengan kancing tempurung kelapa alami.';
        for (final v in _daftarVarianInput) {
          v.dispose();
        }
        _daftarVarianInput.clear();
        _daftarVarianInput.add(ModelVarianInput(ukuran: 'M', warna: 'Oatmeal', stok: 12));
        _daftarVarianInput.add(ModelVarianInput(ukuran: 'L', warna: 'Oatmeal', stok: 8));
        _daftarVarianInput.add(ModelVarianInput(ukuran: 'L', warna: 'Charcoal', stok: 6));
      } else {
        _namaController.text = 'Dompet Kartu Kulit Calfskin Leather Cardholder';
        _hargaController.text = '89000';
        _kategoriTerpilih = 'Aksesori';
        _merekController.text = 'ME Leather';
        _bahanController.text = 'Genuine Italian Calfskin';
        _deskripsiController.text = 'Dompet kartu ramping minimalis dengan 6 slot kartu dan 1 kompartemen uang tunai lipat.';
        for (final v in _daftarVarianInput) {
          v.dispose();
        }
        _daftarVarianInput.clear();
        _daftarVarianInput.add(ModelVarianInput(ukuran: 'All Size', warna: 'Hitam Matte', stok: 20));
        _daftarVarianInput.add(ModelVarianInput(ukuran: 'All Size', warna: 'Tan Brown', stok: 15));
      }
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _merekController.dispose();
    _bahanController.dispose();
    _deskripsiController.dispose();
    for (final v in _daftarVarianInput) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _simpanProduk() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_daftarVarianInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajib menambahkan minimal satu varian.')),
      );
      return;
    }

    final int? hargaParsed = int.tryParse(_hargaController.text.trim());
    if (hargaParsed == null || hargaParsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka bulat positif.')),
      );
      return;
    }

    setState(() {
      _sedangMenyimpan = true;
      _galatValidasi422 = null;
    });

    final List<Map<String, dynamic>> varianPayload = _daftarVarianInput.map((v) {
      final map = <String, dynamic>{
        'ukuran': v.ukuranController.text.trim(),
        'warna': v.warnaController.text.trim(),
        'stok': int.tryParse(v.stokController.text.trim()) ?? 0,
      };
      if (v.id != null) {
        map['id'] = v.id;
      }
      return map;
    }).toList();

    final dataPayload = <String, dynamic>{
      'nama': _namaController.text.trim(),
      'harga': hargaParsed,
      'kategori': _kategoriTerpilih,
      'merek': _merekController.text.trim(),
      'bahan': _bahanController.text.trim(),
      'deskripsi': _deskripsiController.text.trim().isEmpty ? null : _deskripsiController.text.trim(),
      'tersedia': _tersedia,
      'varian': varianPayload,
    };

    final respon = _modeEdit
        ? await LayananApi.ubahProduk(widget.produk!.id, dataPayload)
        : await LayananApi.tambahProduk(dataPayload);

    if (!mounted) return;

    setState(() {
      _sedangMenyimpan = false;
    });

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_modeEdit ? 'Produk berhasil diperbarui.' : 'Produk baru berhasil ditambahkan.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (respon.code == '422') {
        setState(() {
          _galatValidasi422 = respon.errors;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        title: Text(
          _modeEdit ? 'UBAH PRODUK' : 'TAMBAH PRODUK BARU',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _sedangMemuatVarian
          ? const Center(child: CircularProgressIndicator(color: TemaAplikasi.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tombol Preset Cepat (Untuk Memudahkan Uji Coba)
                    if (!_modeEdit) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PRESET CONTOH CEPAT',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w600,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _isiContohProduk('cardigan'),
                                child: const Text('+ Cardigan', style: TextStyle(fontSize: 11, color: TemaAplikasi.primary)),
                              ),
                              TextButton(
                                onPressed: () => _isiContohProduk('dompet'),
                                child: const Text('+ Dompet', style: TextStyle(fontSize: 11, color: TemaAplikasi.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Header Informasi Produk
                    const Text(
                      'INFORMASI UTAMA PRODUK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nama Produk
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk',
                        hintText: 'Contoh: Kemeja Linen Polos',
                        errorText: _galatValidasi422?['nama']?.toString(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi.' : null,
                    ),
                    const SizedBox(height: 14),

                    // Harga (Rupiah bulat)
                    TextFormField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rupiah)',
                        hintText: 'Contoh: 149000 (tanpa titik)',
                        errorText: _galatValidasi422?['harga']?.toString(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Harga wajib diisi.';
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Harga harus berupa angka bulat positif.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kategori
                    DropdownButtonFormField<String>(
                      initialValue: _kategoriTerpilih,
                      decoration: InputDecoration(
                        labelText: 'Kategori Produk',
                        errorText: _galatValidasi422?['kategori']?.toString(),
                      ),
                      items: _pilihanKategori.map((k) {
                        return DropdownMenuItem(value: k, child: Text(k));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _kategoriTerpilih = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kolom Khas Domain Pakaian: Merek & Bahan
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _merekController,
                            decoration: InputDecoration(
                              labelText: 'Merek',
                              hintText: 'ME Studio / ZARA',
                              errorText: _galatValidasi422?['merek']?.toString(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Merek wajib diisi.' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bahanController,
                            decoration: InputDecoration(
                              labelText: 'Bahan',
                              hintText: 'Katun / Linen',
                              errorText: _galatValidasi422?['bahan']?.toString(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bahan wajib diisi.' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Deskripsi (Nullable)
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Produk (Boleh Kosong)',
                        hintText: 'Penjelasan rincian bahan, potongan pakaian, atau spesifikasi.',
                        errorText: _galatValidasi422?['deskripsi']?.toString(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Ketersediaan (Tersedia)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceWhite,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Produk Tersedia / Aktif Dijual', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        value: _tersedia,
                        activeTrackColor: TemaAplikasi.primary,
                        onChanged: (v) => setState(() => _tersedia = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 16),

                    // Manajemen Varian Produk (Stok Per Varian)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VARIAN PRODUK (UKURAN × WARNA)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Stok diatur per kombinasi varian spesifik',
                              style: TextStyle(fontSize: 10, color: TemaAplikasi.secondary),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _tambahVarian(),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('TAMBAH'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daftar Input Varian
                    ..._daftarVarianInput.asMap().entries.map((entry) {
                      final index = entry.key;
                      final vInput = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceWhite,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TemaAplikasi.borderGray),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Ukuran
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: vInput.ukuranController,
                                decoration: const InputDecoration(
                                  labelText: 'Ukuran',
                                  hintText: 'S/M/All Size',
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Warna
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: vInput.warnaController,
                                decoration: const InputDecoration(
                                  labelText: 'Warna',
                                  hintText: 'Hitam/Putih',
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stok
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: vInput.stokController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stok',
                                  hintText: '0',
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Wajib';
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 0) return '>=0';
                                  return null;
                                },
                              ),
                            ),

                            // Hapus Baris Varian
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: TemaAplikasi.secondary),
                              onPressed: () => _hapusVarian(index),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: TemaAplikasi.surfaceWhite,
          border: Border(top: BorderSide(color: TemaAplikasi.borderGray)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _sedangMenyimpan ? null : _simpanProduk,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: TemaAplikasi.onPrimary,
              ),
              child: _sedangMenyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: TemaAplikasi.onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      _modeEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN PRODUK KE KATALOG',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
