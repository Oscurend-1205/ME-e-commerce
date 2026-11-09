import 'package:flutter/material.dart';

import '../models/alamat.dart';
import '../theme.dart';

class HalamanTambahAlamat extends StatefulWidget {
  const HalamanTambahAlamat({super.key});

  @override
  State<HalamanTambahAlamat> createState() => _HalamanTambahAlamatState();
}

class _HalamanTambahAlamatState extends State<HalamanTambahAlamat> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController(
    text: 'Clarissa Adiwidjaja',
  );
  final TextEditingController _teleponController = TextEditingController(
    text: '811 8899 21',
  );
  final TextEditingController _kotaController = TextEditingController(
    text: 'Jakarta Pusat, Menteng - 10350',
  );
  final TextEditingController _alamatController = TextEditingController(
    text:
        'Apartemen Keraton At The Plaza, Lantai 28 Unit B, Jl. M.H. Thamrin No. 9',
  );
  final TextEditingController _catatanController = TextEditingController(
    text: 'Titip di resepsionis Lobby B / concierge service',
  );

  String _labelAlamat = 'Rumah';
  bool _jadikanUtama = true;
  bool _simpanKeBukuAlamat = true;

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _kotaController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String? _wajib(String? nilai) =>
      (nilai == null || nilai.trim().isEmpty) ? 'Kolom ini wajib diisi.' : null;

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final alamatLengkap = [
      _alamatController.text.trim(),
      _kotaController.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');

    Navigator.pop(
      context,
      Alamat(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nama: _namaController.text.trim(),
        telepon: '+62 ${_teleponController.text.trim()}',
        alamat: alamatLengkap,
        label: _labelAlamat,
        catatan: _catatanController.text.trim(),
        utama: _jadikanUtama,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceBright,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'TAMBAH ALAMAT BARU',
          style: TextStyle(
            fontSize: 15,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.primary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi pengiriman ME Atelier',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceContainerLow,
                          border: Border.all(color: TemaAplikasi.borderGray),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.near_me_rounded,
                              size: 20,
                              color: TemaAplikasi.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Gunakan Lokasi Saat Ini',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TemaAplikasi.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: TemaAplikasi.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'LABEL ALAMAT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Rumah', 'Apartemen', 'Kantor', 'Lainnya']
                            .map((label) {
                              final selected = _labelAlamat == label;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _labelAlamat = label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? TemaAplikasi.primary
                                        : TemaAplikasi.surfaceContainerLow,
                                    border: Border.all(
                                      color: selected
                                          ? TemaAplikasi.primary
                                          : TemaAplikasi.borderGray,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? TemaAplikasi.onPrimary
                                          : TemaAplikasi.primary,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      _buildField(
                        label: 'NAMA LENGKAP PENERIMA',
                        controller: _namaController,
                        validator: _wajib,
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'NOMOR TELEPON',
                        controller: _teleponController,
                        prefix: const Text('+62 '),
                        keyboardType: TextInputType.phone,
                        validator: _wajib,
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'KOTA, KECAMATAN & KODE POS',
                        controller: _kotaController,
                        readOnly: true,
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'ALAMAT LENGKAP / JALAN',
                        controller: _alamatController,
                        maxLines: 3,
                        validator: _wajib,
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'PATOKAN / CATATAN COURIER (OPSIONAL)',
                        controller: _catatanController,
                      ),
                      const SizedBox(height: 22),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Jadikan Alamat Utama',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        subtitle: const Text(
                          'Gunakan sebagai tujuan pengiriman baku untuk pesanan berikutnya',
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        value: _jadikanUtama,
                        activeTrackColor: TemaAplikasi.primary,
                        onChanged: (value) =>
                            setState(() => _jadikanUtama = value),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Simpan ke Buku Alamat ME Privé',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        subtitle: const Text(
                          'Sinkronkan ke profil eksklusif anggota Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                        value: _simpanKeBukuAlamat,
                        activeTrackColor: TemaAplikasi.primary,
                        onChanged: (value) =>
                            setState(() => _simpanKeBukuAlamat = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: TemaAplikasi.surfaceWhite,
                border: Border(
                  top: BorderSide(color: TemaAplikasi.borderGray, width: 1),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _simpan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: TemaAplikasi.primary,
                        foregroundColor: TemaAplikasi.onPrimary,
                      ),
                      child: const Text(
                        'SIMPAN ALAMAT',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text(
                      'BATAL',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: TemaAplikasi.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    Widget? prefix,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: TemaAplikasi.secondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefix: prefix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: TemaAplikasi.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: TemaAplikasi.primary,
                width: 1.2,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: TemaAplikasi.primary),
        ),
      ],
    );
  }
}
