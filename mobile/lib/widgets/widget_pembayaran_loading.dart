import 'package:flutter/material.dart';

import '../theme.dart';

/// Widget loading sederhana untuk pembayaran
class WidgetPembayaranLoading extends StatelessWidget {
  const WidgetPembayaranLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: TemaAplikasi.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Memproses Pembayaran...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon jangan tutup halaman ini',
            style: TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
