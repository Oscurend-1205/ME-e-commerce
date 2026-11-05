import 'package:flutter/material.dart';
import '../enums.dart';

// === Warna Tema ===
const Color _hitam = Color(0xFF111111);
const Color _abuSedang = Color(0xFF777777);

/// Widget untuk keadaan memuat — menampilkan indikator loading
class WidgetMemuat extends StatelessWidget {
  const WidgetMemuat({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _hitam),
    );
  }
}

/// Widget untuk keadaan kosong — menampilkan ikon, pesan, dan tombol aksi opsional
class WidgetKosong extends StatelessWidget {
  final IconData ikon;
  final String pesan;
  final String? saranAksi;
  final VoidCallback? onAksi;

  const WidgetKosong({
    super.key,
    required this.ikon,
    required this.pesan,
    this.saranAksi,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikon,
              size: 80,
              color: _abuSedang,
            ),
            const SizedBox(height: 24),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _abuSedang,
                letterSpacing: 0.3,
                height: 1.5,
              ),
            ),
            if (saranAksi != null && onAksi != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAksi,
                  child: Text(saranAksi!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget untuk keadaan galat — menampilkan UI berbeda sesuai jenis galat
class WidgetGalat extends StatelessWidget {
  final JenisGalat jenisGalat;
  final String pesan;
  final Map<String, dynamic>? errors;
  final VoidCallback? onCobaLagi;

  const WidgetGalat({
    super.key,
    required this.jenisGalat,
    required this.pesan,
    this.errors,
    this.onCobaLagi,
  });

  @override
  Widget build(BuildContext context) {
    switch (jenisGalat) {
      case JenisGalat.tidakAdaSambungan:
        return _buildTampilanGalat(
          ikon: Icons.wifi_off_rounded,
          judul: 'Tidak Ada Koneksi',
          pesan: 'Periksa koneksi internet Anda dan coba lagi.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.batasWaktu:
        return _buildTampilanGalat(
          ikon: Icons.timer_off_rounded,
          judul: 'Waktu Habis',
          pesan: 'Server terlalu lama merespons. Silakan coba lagi.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.validasi422:
        return _buildTampilanValidasi();

      case JenisGalat.bentrok409:
        return _buildTampilanGalat(
          ikon: Icons.error_outline_rounded,
          judul: 'Konflik Data',
          pesan: pesan,
          tampilkanCobaLagi: false,
        );

      case JenisGalat.server500:
        return _buildTampilanGalat(
          ikon: Icons.cloud_off_rounded,
          judul: 'Terjadi Kesalahan',
          pesan: 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.tidakDiketahui:
        return _buildTampilanGalat(
          ikon: Icons.cloud_off_rounded,
          judul: 'Terjadi Kesalahan',
          pesan: 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
          tampilkanCobaLagi: true,
        );
    }
  }

  Widget _buildTampilanGalat({
    required IconData ikon,
    required String judul,
    required String pesan,
    required bool tampilkanCobaLagi,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikon,
              size: 72,
              color: _abuSedang,
            ),
            const SizedBox(height: 20),
            Text(
              judul,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _hitam,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _abuSedang,
                height: 1.5,
              ),
            ),
            if (tampilkanCobaLagi && onCobaLagi != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: OutlinedButton(
                  onPressed: onCobaLagi,
                  child: const Text('COBA LAGI'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTampilanValidasi() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 72,
              color: _abuSedang,
            ),
            const SizedBox(height: 20),
            const Text(
              'Data Tidak Valid',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _hitam,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _abuSedang,
                height: 1.5,
              ),
            ),
            if (errors != null && errors!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...errors!.entries.map((entry) {
                final pesanError = entry.value is List
                    ? (entry.value as List).join(', ')
                    : entry.value.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          color: _hitam,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.key}: $pesanError',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _abuSedang,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Menentukan jenis galat berdasarkan kode dari ApiResponse
JenisGalat tentukanJenisGalat(String code) {
  switch (code) {
    case 'NETWORK':
      return JenisGalat.tidakAdaSambungan;
    case 'TIMEOUT':
      return JenisGalat.batasWaktu;
    case '422':
      return JenisGalat.validasi422;
    case '409':
      return JenisGalat.bentrok409;
    case '500':
      return JenisGalat.server500;
    default:
      return JenisGalat.tidakDiketahui;
  }
}
