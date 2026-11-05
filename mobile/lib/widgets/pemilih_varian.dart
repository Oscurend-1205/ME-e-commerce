import 'package:flutter/material.dart';
import '../models/produk.dart';

// === Warna Tema ===
const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

/// Widget pemilih varian produk (ukuran + warna) dengan dua langkah penyaringan
///
/// Alur:
/// 1. Tampilkan semua ukuran unik sebagai ChoiceChip
/// 2. Tampilkan semua warna unik sebagai ChoiceChip
/// 3. Saat ukuran dipilih, filter warna hanya yang tersedia untuk ukuran itu
/// 4. Saat ukuran DAN warna dipilih, cari Varian yang cocok dan panggil onPilih
/// 5. Chip yang semua variannya stok 0 akan dinonaktifkan
class PemilihVarian extends StatefulWidget {
  final List<Varian> daftarVarian;
  final Varian? varianTerpilih;
  final ValueChanged<Varian> onPilih;

  const PemilihVarian({
    super.key,
    required this.daftarVarian,
    this.varianTerpilih,
    required this.onPilih,
  });

  @override
  State<PemilihVarian> createState() => _PemilihVarianState();
}

class _PemilihVarianState extends State<PemilihVarian> {
  String? _ukuranTerpilih;
  String? _warnaTerpilih;

  @override
  void initState() {
    super.initState();
    if (widget.varianTerpilih != null) {
      _ukuranTerpilih = widget.varianTerpilih!.ukuran;
      _warnaTerpilih = widget.varianTerpilih!.warna;
    }
  }

  @override
  void didUpdateWidget(covariant PemilihVarian oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.varianTerpilih != oldWidget.varianTerpilih) {
      setState(() {
        _ukuranTerpilih = widget.varianTerpilih?.ukuran;
        _warnaTerpilih = widget.varianTerpilih?.warna;
      });
    }
  }

  /// Daftar ukuran unik dari semua varian
  List<String> get _daftarUkuran {
    final ukuranSet = <String>{};
    for (final v in widget.daftarVarian) {
      ukuranSet.add(v.ukuran);
    }
    return ukuranSet.toList();
  }

  /// Daftar warna unik, difilter berdasarkan ukuran yang dipilih
  List<String> get _daftarWarna {
    final warnaSet = <String>{};
    final sumber = _ukuranTerpilih != null
        ? widget.daftarVarian.where((v) => v.ukuran == _ukuranTerpilih)
        : widget.daftarVarian;
    for (final v in sumber) {
      warnaSet.add(v.warna);
    }
    return warnaSet.toList();
  }

  /// Cek apakah semua varian untuk ukuran tertentu memiliki stok 0
  bool _ukuranHabis(String ukuran) {
    return widget.daftarVarian
        .where((v) => v.ukuran == ukuran)
        .every((v) => v.stok == 0);
  }

  /// Cek apakah semua varian untuk warna tertentu memiliki stok 0
  /// Jika ukuran sudah dipilih, hanya cek varian dengan ukuran tersebut
  bool _warnaHabis(String warna) {
    final sumber = _ukuranTerpilih != null
        ? widget.daftarVarian
            .where((v) => v.ukuran == _ukuranTerpilih && v.warna == warna)
        : widget.daftarVarian.where((v) => v.warna == warna);
    if (sumber.isEmpty) return true;
    return sumber.every((v) => v.stok == 0);
  }

  /// Cari varian yang cocok berdasarkan ukuran dan warna yang dipilih
  Varian? get _varianCocok {
    if (_ukuranTerpilih == null || _warnaTerpilih == null) return null;
    try {
      return widget.daftarVarian.firstWhere(
        (v) => v.ukuran == _ukuranTerpilih && v.warna == _warnaTerpilih,
      );
    } catch (_) {
      return null;
    }
  }

  void _pilihUkuran(String ukuran) {
    setState(() {
      _ukuranTerpilih = ukuran;
      // Cek apakah warna yang sedang dipilih masih tersedia untuk ukuran baru
      if (_warnaTerpilih != null) {
        final masihAda = widget.daftarVarian.any(
          (v) => v.ukuran == ukuran && v.warna == _warnaTerpilih,
        );
        if (!masihAda) {
          _warnaTerpilih = null;
        }
      }
    });
    _cekDanPanggil();
  }

  void _pilihWarna(String warna) {
    setState(() {
      _warnaTerpilih = warna;
    });
    _cekDanPanggil();
  }

  void _cekDanPanggil() {
    final varian = _varianCocok;
    if (varian != null) {
      widget.onPilih(varian);
    }
  }

  @override
  Widget build(BuildContext context) {
    final varianCocok = _varianCocok;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === Pemilih Ukuran ===
        const Text(
          'UKURAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _abuSedang,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daftarUkuran.map((ukuran) {
            final dipilih = _ukuranTerpilih == ukuran;
            final habis = _ukuranHabis(ukuran);

            return ChoiceChip(
              label: Text(ukuran),
              selected: dipilih,
              onSelected: habis
                  ? null
                  : (_) => _pilihUkuran(ukuran),
              backgroundColor: _putih,
              selectedColor: _hitam,
              disabledColor: _abuMuda,
              labelStyle: TextStyle(
                color: habis
                    ? _abuSedang.withValues(alpha: 0.5)
                    : dipilih
                        ? _putih
                        : _hitam,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              side: BorderSide(
                color: habis
                    ? _abuGaris.withValues(alpha: 0.5)
                    : dipilih
                        ? _hitam
                        : _abuGaris,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // === Pemilih Warna ===
        const Text(
          'WARNA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _abuSedang,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daftarWarna.map((warna) {
            final dipilih = _warnaTerpilih == warna;
            final habis = _warnaHabis(warna);

            return ChoiceChip(
              label: Text(warna),
              selected: dipilih,
              onSelected: habis
                  ? null
                  : (_) => _pilihWarna(warna),
              backgroundColor: _putih,
              selectedColor: _hitam,
              disabledColor: _abuMuda,
              labelStyle: TextStyle(
                color: habis
                    ? _abuSedang.withValues(alpha: 0.5)
                    : dipilih
                        ? _putih
                        : _hitam,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              side: BorderSide(
                color: habis
                    ? _abuGaris.withValues(alpha: 0.5)
                    : dipilih
                        ? _hitam
                        : _abuGaris,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            );
          }).toList(),
        ),

        // === Info Stok ===
        if (varianCocok != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _abuMuda,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              varianCocok.stok > 0
                  ? 'Stok: ${varianCocok.stok}'
                  : 'Stok habis',
              style: TextStyle(
                fontSize: 13,
                color: varianCocok.stok > 0 ? _hitam : const Color(0xFFB00020),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
