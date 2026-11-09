import 'package:flutter/material.dart';

import '../theme.dart';

/// Stepper checkout editorial mewah dengan animasi transisi garis dan lingkaran.
/// [langkahAktif] = 1 untuk Alur 01 (TAS), 2 untuk Alur 02 (KIRIM), 3 untuk Alur 03 (BAYAR).
class WidgetStepperCheckout extends StatelessWidget {
  final int langkahAktif;

  const WidgetStepperCheckout({
    super.key,
    required this.langkahAktif,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['01. TAS', '02. KIRIM', '03. BAYAR'];
    const circleSize = 22.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row lingkaran & garis penghubung animasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Garis Penghubung (1 -> 2 dan 2 -> 3)
                Row(
                  children: [
                    const SizedBox(width: circleSize / 2),
                    // Garis dari Step 1 ke Step 2
                    Expanded(
                      child: _GarisPenghubungAnimasi(
                        aktif: langkahAktif >= 2,
                      ),
                    ),
                    const SizedBox(width: circleSize),
                    // Garis dari Step 2 ke Step 3
                    Expanded(
                      child: _GarisPenghubungAnimasi(
                        aktif: langkahAktif >= 3,
                      ),
                    ),
                    const SizedBox(width: circleSize / 2),
                  ],
                ),
                // 3 Lingkaran Indikator Langkah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LingkaranLangkah(
                      nomor: 1,
                      langkahAktif: langkahAktif,
                      circleSize: circleSize,
                    ),
                    _LingkaranLangkah(
                      nomor: 2,
                      langkahAktif: langkahAktif,
                      circleSize: circleSize,
                    ),
                    _LingkaranLangkah(
                      nomor: 3,
                      langkahAktif: langkahAktif,
                      circleSize: circleSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row Label Deskriptif Langkah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final stepNum = index + 1;
              final aktif = langkahAktif == stepNum;
              final selesai = langkahAktif > stepNum;

              return SizedBox(
                width: 74,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: (aktif || selesai) ? FontWeight.w700 : FontWeight.w500,
                    color: (aktif || selesai)
                        ? TemaAplikasi.primary
                        : TemaAplikasi.secondary.withValues(alpha: 0.55),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LingkaranLangkah extends StatelessWidget {
  final int nomor;
  final int langkahAktif;
  final double circleSize;

  const _LingkaranLangkah({
    required this.nomor,
    required this.langkahAktif,
    required this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    final aktif = langkahAktif == nomor;
    final selesai = langkahAktif > nomor;
    final tercapai = aktif || selesai;

    return AnimatedScale(
      scale: aktif ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tercapai
              ? TemaAplikasi.primary
              : const Color(0xFFE5E5E5),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: TemaAplikasi.primary.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: selesai
            ? const Icon(
                Icons.check,
                size: 13,
                color: TemaAplikasi.onPrimary,
              )
            : Text(
                '$nomor',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tercapai
                      ? TemaAplikasi.onPrimary
                      : TemaAplikasi.primary.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }
}

class _GarisPenghubungAnimasi extends StatelessWidget {
  final bool aktif;

  const _GarisPenghubungAnimasi({
    required this.aktif,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Garis dasar abu-abu
            Container(
              height: 1.5,
              width: constraints.maxWidth,
              color: const Color(0xFFE5E5E5),
            ),
            // Garis aktif hitam dengan animasi geser lebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              height: 1.5,
              width: aktif ? constraints.maxWidth : 0.0,
              color: TemaAplikasi.primary,
            ),
          ],
        );
      },
    );
  }
}
