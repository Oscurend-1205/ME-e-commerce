import 'package:flutter/material.dart';
import '../constants.dart';
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

  void _tampilkanDialogServer(BuildContext context) {
    final controller = TextEditingController(text: Konstan.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pengaturan Alamat Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih atau masukkan alamat backend server API:',
                style: TextStyle(fontSize: 13, color: _abuSedang),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL Base API',
                  hintText: 'http://127.0.0.1:8000/api',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('127.0.0.1 (USB Reverse)'),
                    onPressed: () {
                      controller.text = 'http://127.0.0.1:8000/api';
                    },
                  ),
                  ActionChip(
                    label: const Text('Wi-Fi PC (172.16.187.168)'),
                    onPressed: () {
                      controller.text = 'http://172.16.187.168:8000/api';
                    },
                  ),
                  ActionChip(
                    label: const Text('10.0.2.2 (Emulator)'),
                    onPressed: () {
                      controller.text = 'http://10.0.2.2:8000/api';
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              onPressed: () {
                Konstan.customHost = controller.text.trim();
                Navigator.pop(ctx);
                onCobaLagi?.call();
              },
              child: const Text('SIMPAN & COBA LAGI'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (jenisGalat) {
      case JenisGalat.tidakAdaSambungan:
        return _buildTampilanGalat(
          context: context,
          ikon: Icons.wifi_off_rounded,
          judul: 'Tidak Ada Koneksi',
          pesan: 'Tidak dapat terhubung ke server ($Konstan.baseUrl).\nPastikan server aktif atau atur alamat server.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.batasWaktu:
        return _buildTampilanGalat(
          context: context,
          ikon: Icons.timer_off_rounded,
          judul: 'Waktu Habis',
          pesan: 'Server terlalu lama merespons. Silakan coba lagi.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.validasi422:
        return _buildTampilanValidasi();

      case JenisGalat.bentrok409:
        return _buildTampilanGalat(
          context: context,
          ikon: Icons.error_outline_rounded,
          judul: 'Konflik Data',
          pesan: pesan,
          tampilkanCobaLagi: false,
        );

      case JenisGalat.server500:
        return _buildTampilanGalat(
          context: context,
          ikon: Icons.cloud_off_rounded,
          judul: 'Terjadi Kesalahan',
          pesan: 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.',
          tampilkanCobaLagi: true,
        );

      case JenisGalat.tidakDiketahui:
        return _buildTampilanGalat(
          context: context,
          ikon: Icons.cloud_off_rounded,
          judul: 'Terjadi Kesalahan',
          pesan: 'Terjadi kesalahan koneksi ke server. Silakan periksa jaringan Anda.',
          tampilkanCobaLagi: true,
        );
    }
  }

  Widget _buildTampilanGalat({
    required BuildContext context,
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
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: OutlinedButton(
                  onPressed: onCobaLagi,
                  child: const Text('COBA LAGI'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('ATUR ALAMAT SERVER'),
              onPressed: () => _tampilkanDialogServer(context),
            ),
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
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Validasi Gagal',
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors!.entries.map((entry) {
                    final daftarPesan = entry.value is List
                        ? (entry.value as List).join(', ')
                        : entry.value.toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${entry.key}: $daftarPesan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (onCobaLagi != null) ...[
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
}
