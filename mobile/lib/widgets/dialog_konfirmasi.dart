import 'package:flutter/material.dart';

// === Warna Tema ===
const Color _hitam = Color(0xFF111111);
const Color _abuSedang = Color(0xFF777777);

/// Menampilkan dialog konfirmasi sederhana dengan tombol batal dan konfirmasi
/// Mengembalikan `true` jika pengguna mengonfirmasi, `false` jika membatalkan
Future<bool> tampilkanDialogKonfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  String tekstBatal = 'BATAL',
  String tekstKonfirmasi = 'KONFIRMASI',
  String? teksKonfirmasi,
  bool aksiMerah = false,
  Color? warnaKonfirmasi,
}) async {
  final labelKonfirmasi = teksKonfirmasi ?? tekstKonfirmasi;
  final isMerah = aksiMerah || warnaKonfirmasi != null;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext konteks) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Text(
              judul,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _hitam,
                letterSpacing: 0.2,
              ),
            ),
            content: Text(
              pesan,
              style: const TextStyle(
                fontSize: 14,
                color: _abuSedang,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(konteks).pop(false),
                child: Text(
                  tekstBatal,
                  style: const TextStyle(
                    color: _abuSedang,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(konteks).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warnaKonfirmasi ??
                      (isMerah ? const Color(0xFFB00020) : _hitam),
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  labelKonfirmasi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          );
        },
      ) ??
      false;
}
