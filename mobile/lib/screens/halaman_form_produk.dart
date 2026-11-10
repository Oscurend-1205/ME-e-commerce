import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/layanan_api.dart';
import '../theme.dart';

/// Form tambah/ubah produk beserta daftar varian (ukuran, warna, stok).
/// Dipakai oleh HalamanKelolaProduk; mengembalikan `true` bila tersimpan.
class HalamanFormProduk extends StatefulWidget {
  final Produk? produk;

  const HalamanFormProduk({super.key, this.produk});

  @override
  State<HalamanFormProduk> createState() => _HalamanFormProdukState();
}

class _ItemVarianForm {
  final int? id;
  final TextEditingController ukuran;
  final TextEditingController warna;
  final TextEditingController stok;

  _ItemVarianForm({
    this.id,
    String ukuran = '',
    String warna = '',
    String stok = '0',
  }) : ukuran = TextEditingController(text: ukuran),
       warna = TextEditingController(text: warna),
       stok = TextEditingController(text: stok);

  void dispose() {
    ukuran.dispose();
    warna.dispose();
    stok.dispose();
  }
}

class _HalamanFormProdukState extends State<HalamanFormProduk> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _bahanController;
  late final TextEditingController _merekController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _gambarController;

  bool _tersedia = true;
  bool _sedangMenyimpan = false;
  final List<_ItemVarianForm> _daftarVarian = [];

  bool get _modeUbah => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaController = TextEditingController(text: p?.nama ?? '');
    _hargaController = TextEditingController(
      text: p != null ? '${p.harga}' : '',
    );
    _kategoriController = TextEditingController(text: p?.kategori ?? '');
    _bahanController = TextEditingController(text: p?.bahan ?? '');
    _merekController = TextEditingController(text: p?.merek ?? '');
    _deskripsiController = TextEditingController(text: p?.deskripsi ?? '');
    _gambarController = TextEditingController(text: p?.gambar ?? '');
    _tersedia = p?.tersedia ?? true;

    final varian = p?.varian;
    if (varian != null && varian.isNotEmpty) {
      for (final v in varian) {
        _daftarVarian.add(
          _ItemVarianForm(
            id: v.id,
            ukuran: v.ukuran,
            warna: v.warna,
            stok: '${v.stok}',
          ),
        );
      }
    } else {
      _tambahBarisVarian();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _kategoriController.dispose();
    _bahanController.dispose();
    _merekController.dispose();
    _deskripsiController.dispose();
    _gambarController.dispose();
    for (final v in _daftarVarian) {
      v.dispose();
    }
    super.dispose();
  }

  void _tambahBarisVarian() {
    setState(() {
      _daftarVarian.add(_ItemVarianForm());
    });
  }

  void _hapusBarisVarian(int index) {
    setState(() {
      _daftarVarian.removeAt(index).dispose();
    });
  }

  String? _wajib(String? nilai) =>
      (nilai == null || nilai.trim().isEmpty) ? 'Wajib diisi.' : null;

  String? _angkaPositif(String? nilai) {
    final n = int.tryParse((nilai ?? '').trim());
    if (n == null || n < 1) return 'Harga harus bilangan bulat lebih dari 0.';
    return null;
  }

  String? _stokValid(String? nilai) {
    final n = int.tryParse((nilai ?? '').trim());
    if (n == null || n < 0) return 'Stok harus bilangan bulat minimal 0.';
    return null;
  }

  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_daftarVarian.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal satu varian produk wajib diisi.'),
          backgroundColor: TemaAplikasi.errorColor,
        ),
      );
      return;
    }

    for (final v in _daftarVarian) {
      if (v.ukuran.text.trim().isEmpty ||
          v.warna.text.trim().isEmpty ||
          int.tryParse(v.stok.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi ukuran, warna, dan stok setiap varian.'),
            backgroundColor: TemaAplikasi.errorColor,
          ),
        );
        return;
      }
    }

    setState(() => _sedangMenyimpan = true);

    final payload = <String, dynamic>{
      'nama': _namaController.text.trim(),
      'harga': int.parse(_hargaController.text.trim()),
      'kategori': _kategoriController.text.trim(),
      'bahan': _bahanController.text.trim(),
      'merek': _merekController.text.trim(),
      'deskripsi': _deskripsiController.text.trim().isEmpty
          ? null
          : _deskripsiController.text.trim(),
      'tersedia': _tersedia,
      if (_gambarController.text.trim().isNotEmpty)
        'gambar': _gambarController.text.trim(),
      'varian': _daftarVarian
          .map(
            (v) => {
              if (v.id != null) 'id': v.id,
              'ukuran': v.ukuran.text.trim(),
              'warna': v.warna.text.trim(),
              'stok': int.parse(v.stok.text.trim()),
            },
          )
          .toList(),
    };

    final respon = _modeUbah
        ? await LayananApi.ubahProduk(widget.produk!.id, payload)
        : await LayananApi.tambahProduk(payload);

    if (!mounted) return;
    setState(() => _sedangMenyimpan = false);

    if (respon.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modeUbah
                ? 'Produk berhasil diubah.'
                : 'Produk berhasil ditambahkan.',
          ),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _tampilkanGalat(respon.message, respon.errors);
    }
  }

  void _tampilkanGalat(String pesan, Map<String, dynamic>? errors) {
    final daftarPesan = <String>[];
    if (errors != null && errors.isNotEmpty) {
      for (final entry in errors.entries) {
        final nilai = entry.value;
        final teks = nilai is List ? nilai.join(', ') : nilai.toString();
        daftarPesan.add('${entry.key}: $teks');
      }
    }
    if (daftarPesan.isEmpty) daftarPesan.add(pesan);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        title: const Text(
          'Gagal Menyimpan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: daftarPesan
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $t',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaAplikasi.secondary,
                      height: 1.4,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('MENGERTI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _modeUbah ? 'UBAH PRODUK' : 'TAMBAH PRODUK',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _field(_namaController, 'Nama Produk *', validator: _wajib),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _hargaController,
                    'Harga (Rp) *',
                    keyboardType: TextInputType.number,
                    validator: _angkaPositif,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _kategoriController,
                    'Kategori *',
                    hint: 'Atasan / Bawahan / Aksesori',
                    validator: _wajib,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_bahanController, 'Bahan *', validator: _wajib),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_merekController, 'Merek *', validator: _wajib),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_deskripsiController, 'Deskripsi', maxLines: 3),
            const SizedBox(height: 12),
            _field(
              _gambarController,
              'Nama File Gambar (opsional)',
              hint: 'contoh: 37.jpg',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Produk Tersedia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TemaAplikasi.primary,
                ),
              ),
              subtitle: const Text(
                'Produk nonaktif tidak dapat dipesan pembeli.',
                style: TextStyle(fontSize: 11, color: TemaAplikasi.mutedGray),
              ),
              value: _tersedia,
              activeThumbColor: TemaAplikasi.primary,
              onChanged: (v) => setState(() => _tersedia = v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VARIAN (UKURAN × WARNA × STOK)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: TemaAplikasi.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _tambahBarisVarian,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('TAMBAH VARIAN'),
                ),
              ],
            ),
            ..._daftarVarian.asMap().entries.map((entry) {
              final index = entry.key;
              final v = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaAplikasi.surfaceWhite,
                  border: Border.all(color: TemaAplikasi.borderGray),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _fieldKecil(
                            v.ukuran,
                            'Ukuran',
                            hint: 'S / 32 / All Size',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _fieldKecil(v.warna, 'Warna', hint: 'Hitam'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _fieldKecil(
                            v.stok,
                            'Stok',
                            keyboardType: TextInputType.number,
                            validator: _stokValid,
                          ),
                        ),
                        IconButton(
                          onPressed: _daftarVarian.length > 1
                              ? () => _hapusBarisVarian(index)
                              : null,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                            color: TemaAplikasi.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sedangMenyimpan ? null : _simpan,
                child: _sedangMenyimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TemaAplikasi.onPrimary,
                        ),
                      )
                    : Text(_modeUbah ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _fieldKecil(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}
