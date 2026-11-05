import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/layanan_api.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

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
    _merekController = TextEditingController(text: p?.merek ?? '');
    _bahanController = TextEditingController(text: p?.bahan ?? '');
    _deskripsiController = TextEditingController(text: p?.deskripsi ?? '');
    _tersedia = p?.tersedia ?? true;
    _kategoriTerpilih = (p != null && _pilihanKategori.contains(p.kategori))
        ? p.kategori
        : 'Pakaian';

    if (_modeEdit) {
      _muatRincianVarian();
    } else {
      // Varian default untuk produk baru
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
          backgroundColor: _hitam,
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
            backgroundColor: Colors.red.shade800,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
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
          ? const Center(child: CircularProgressIndicator(color: _hitam))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi Dasar Produk
                    const Text(
                      'INFORMASI UTAMA PRODUK',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _hitam,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Produk
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk',
                        hintText: 'Contoh: Kemeja Linen Polos',
                        errorText: _galatValidasi422?['nama']?.toString(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                        hintText: 'Contoh: 149000 (tanpa titik/desimal)',
                        errorText: _galatValidasi422?['harga']?.toString(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                        labelText: 'Kategori',
                        errorText: _galatValidasi422?['kategori']?.toString(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                              hintText: 'ZARA / Studio',
                              errorText: _galatValidasi422?['merek']?.toString(),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
                        hintText: 'Penjelasan rincian bahan, potongan pakaian, atau spesifikasi aksesori.',
                        errorText: _galatValidasi422?['deskripsi']?.toString(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Ketersediaan (Tersedia)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Produk Aktif / Tersedia Dijual', style: TextStyle(fontSize: 14)),
                      value: _tersedia,
                      activeTrackColor: _hitam,
                      onChanged: (v) => setState(() => _tersedia = v),
                    ),
                    const SizedBox(height: 24),

                    const Divider(color: _abuGaris),
                    const SizedBox(height: 16),

                    // Manajemen Varian Produk (Domain Pembeda Kelompok 2: Stok Per Varian!)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VARIAN PRODUK (UKURAN × WARNA)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: _hitam,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Stok diatur per kombinasi varian',
                              style: TextStyle(fontSize: 11, color: _abuSedang),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _tambahVarian(),
                          icon: const Icon(Icons.add, size: 18, color: _hitam),
                          label: const Text('Tambah Varian', style: TextStyle(color: _hitam, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daftar Input Varian
                    ..._daftarVarianInput.asMap().entries.map((entry) {
                      final index = entry.key;
                      final vInput = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _abuMuda,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _abuGaris),
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
                                  filled: true,
                                  fillColor: _putih,
                                  isDense: true,
                                  border: OutlineInputBorder(),
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
                                  filled: true,
                                  fillColor: _putih,
                                  isDense: true,
                                  border: OutlineInputBorder(),
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
                                  filled: true,
                                  fillColor: _putih,
                                  isDense: true,
                                  border: OutlineInputBorder(),
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
                              icon: const Icon(Icons.close, size: 18, color: _abuSedang),
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
          color: _putih,
          border: Border(top: BorderSide(color: _abuGaris)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _sedangMenyimpan ? null : _simpanProduk,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hitam,
                foregroundColor: _putih,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _sedangMenyimpan
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: _putih, strokeWidth: 2),
                    )
                  : Text(
                      _modeEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN PRODUK',
                      style: const TextStyle(
                        fontSize: 14,
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
