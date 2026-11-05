import 'package:flutter/material.dart';
import '../models/produk.dart';
import '../theme.dart';

/// Widget pemilih varian produk (ukuran + warna) dengan dua langkah penyaringan
/// Sesuai estetika minimalis ZARA / cek-beranda.html
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

  List<String> get _daftarUkuran {
    final ukuranSet = <String>{};
    for (final v in widget.daftarVarian) {
      ukuranSet.add(v.ukuran);
    }
    return ukuranSet.toList();
  }

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

  bool _ukuranHabis(String ukuran) {
    return widget.daftarVarian
        .where((v) => v.ukuran == ukuran)
        .every((v) => v.stok == 0);
  }

  bool _warnaHabis(String warna) {
    final sumber = _ukuranTerpilih != null
        ? widget.daftarVarian
            .where((v) => v.ukuran == _ukuranTerpilih && v.warna == warna)
        : widget.daftarVarian.where((v) => v.warna == warna);
    if (sumber.isEmpty) return true;
    return sumber.every((v) => v.stok == 0);
  }

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
        // Pemilih Ukuran
        const Text(
          'PILIH UKURAN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.secondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daftarUkuran.map((ukuran) {
            final dipilih = _ukuranTerpilih == ukuran;
            final habis = _ukuranHabis(ukuran);

            return ChoiceChip(
              label: Text(ukuran),
              selected: dipilih,
              onSelected: habis ? null : (_) => _pilihUkuran(ukuran),
              backgroundColor: TemaAplikasi.surfaceWhite,
              selectedColor: TemaAplikasi.primary,
              disabledColor: TemaAplikasi.surfaceContainer,
              labelStyle: TextStyle(
                color: habis
                    ? TemaAplikasi.mutedGray
                    : dipilih
                        ? TemaAplikasi.onPrimary
                        : TemaAplikasi.primary,
                fontSize: 12,
                fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: habis
                    ? TemaAplikasi.borderGray
                    : dipilih
                        ? TemaAplikasi.primary
                        : TemaAplikasi.borderGray,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Pemilih Warna
        const Text(
          'PILIH WARNA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.secondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daftarWarna.map((warna) {
            final dipilih = _warnaTerpilih == warna;
            final habis = _warnaHabis(warna);

            return ChoiceChip(
              label: Text(warna),
              selected: dipilih,
              onSelected: habis ? null : (_) => _pilihWarna(warna),
              backgroundColor: TemaAplikasi.surfaceWhite,
              selectedColor: TemaAplikasi.primary,
              disabledColor: TemaAplikasi.surfaceContainer,
              labelStyle: TextStyle(
                color: habis
                    ? TemaAplikasi.mutedGray
                    : dipilih
                        ? TemaAplikasi.onPrimary
                        : TemaAplikasi.primary,
                fontSize: 12,
                fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: habis
                    ? TemaAplikasi.borderGray
                    : dipilih
                        ? TemaAplikasi.primary
                        : TemaAplikasi.borderGray,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Informasi Stok Varian Terpilih
        if (varianCocok != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: varianCocok.stok > 0
                  ? TemaAplikasi.surfaceContainer
                  : TemaAplikasi.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  varianCocok.stok > 0
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 14,
                  color: varianCocok.stok > 0
                      ? Colors.green.shade800
                      : TemaAplikasi.errorColor,
                ),
                const SizedBox(width: 6),
                Text(
                  varianCocok.stok > 0
                      ? 'Stok varian ini tersedia: ${varianCocok.stok} unit'
                      : 'Stok varian ini habis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: varianCocok.stok > 0
                        ? Colors.green.shade900
                        : TemaAplikasi.errorColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
