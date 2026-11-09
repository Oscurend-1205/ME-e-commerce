import 'package:flutter/material.dart';

import '../theme.dart';

/// Stepper checkout reusable untuk ketiga langkah.
/// [langkahAktif] = 1 untuk Alur 01, 2 untuk Alur 02, 3 untuk Alur 03.
class WidgetStepperCheckout extends StatelessWidget {
  final int langkahAktif;

  const WidgetStepperCheckout({
    super.key,
    required this.langkahAktif,
  });

  @override
  Widget build(BuildContext context) {
    const label = ['01. TAS', '02. KIRIM', '03. BAYAR'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(3, (i) {
          final aktif = i == langkahAktif - 1;
          final selesai = i < langkahAktif - 1;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (aktif || selesai) ? TemaAplikasi.primary : TemaAplikasi.surfaceContainerHigh,
                        border: (aktif || selesai)
                            ? null
                            : Border.all(color: TemaAplikasi.surfaceContainerHigh),
                      ),
                      alignment: Alignment.center,
                      child: selesai
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: TemaAplikasi.onPrimary,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: aktif
                                    ? TemaAplikasi.onPrimary
                                    : TemaAplikasi.secondary,
                              ),
                            ),
                    ),
                    if (i < 2)
                      Expanded(
                        child: Container(
                          height: 1,
                          color: (aktif || selesai)
                              ? TemaAplikasi.primary
                              : TemaAplikasi.surfaceContainerHigh,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label[i],
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                    color: aktif ? TemaAplikasi.primary : TemaAplikasi.secondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
