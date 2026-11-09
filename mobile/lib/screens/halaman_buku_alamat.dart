import 'package:flutter/material.dart';

import '../models/alamat.dart';
import '../theme.dart';
import 'halaman_tambah_alamat.dart';

class HalamanBukuAlamat extends StatefulWidget {
  const HalamanBukuAlamat({super.key});

  @override
  State<HalamanBukuAlamat> createState() => _HalamanBukuAlamatState();
}

class _HalamanBukuAlamatState extends State<HalamanBukuAlamat> {
  final List<Alamat> _daftarAlamat = [
    const Alamat(
      id: '1',
      nama: 'Clarissa Vance Adiwidjaja',
      telepon: '+62 812-3456-7890',
      alamat:
          'Apartemen Keraton At The Plaza, Lt. 28 Unit B, Jl. M.H. Thamrin No. 28-30, Gondangdia, Menteng, Jakarta Pusat, DKI Jakarta 10350',
      label: 'Apartemen',
      catatan: 'Titip di lobby concierge tower B dengan segel ME utuh.',
      utama: true,
    ),
    const Alamat(
      id: '2',
      nama: 'Clarissa Vance',
      telepon: '+62 812-3456-7890',
      alamat:
          'Jl. Senopati No. 42, RT 04 / RW 02, Selong, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12110',
      label: 'Rumah',
      catatan: 'Pagar hitam nomor 42, bel samping gerbang pos keamanan.',
    ),
    const Alamat(
      id: '3',
      nama: 'Clarissa Vance',
      telepon: '+62 811-9876-5432',
      alamat:
          'Pacific Place Mall Lt. 3 Unit 15, SCBD, Jl. Jend. Sudirman Kav. 52-53, Senayan, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12190',
      label: 'Kantor',
      catatan: 'Antar ke resepsionis kantor pada jam kerja 09.00-18.00 WIB.',
    ),
  ];

  Future<void> _bukaTambahAlamat() async {
    final alamatBaru = await Navigator.push<Alamat>(
      context,
      MaterialPageRoute(builder: (_) => const HalamanTambahAlamat()),
    );

    if (!mounted || alamatBaru == null) return;

    setState(() {
      if (alamatBaru.utama) {
        for (var i = 0; i < _daftarAlamat.length; i++) {
          final item = _daftarAlamat[i];
          if (item.utama) {
            _daftarAlamat[i] = Alamat(
              id: item.id,
              nama: item.nama,
              telepon: item.telepon,
              alamat: item.alamat,
              label: item.label,
              catatan: item.catatan,
              utama: false,
            );
          }
        }
      }
      _daftarAlamat.add(alamatBaru);
    });
  }

  Future<void> _ubahAlamat(Alamat alamat) async {
    final hasil = await Navigator.push<Alamat>(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanTambahAlamat(alamatAwal: alamat),
      ),
    );

    if (!mounted || hasil == null) return;

    setState(() {
      final index = _daftarAlamat.indexWhere((item) => item.id == hasil.id);
      if (index >= 0) {
        _daftarAlamat[index] = hasil;
      } else {
        _daftarAlamat.add(hasil);
      }
    });
  }

  void _jadikanUtama(Alamat alamat) {
    setState(() {
      for (var i = 0; i < _daftarAlamat.length; i++) {
        final item = _daftarAlamat[i];
        _daftarAlamat[i] = Alamat(
          id: item.id,
          nama: item.nama,
          telepon: item.telepon,
          alamat: item.alamat,
          label: item.label,
          catatan: item.catatan,
          utama: item.id == alamat.id,
        );
      }
    });
  }

  void _hapusAlamat(Alamat alamat) {
    if (alamat.utama) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat utama tidak dapat dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _daftarAlamat.removeWhere((item) => item.id == alamat.id);
    });
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
          'BUKU ALAMAT',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'PENGATURAN AKUN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.8,
                                    fontWeight: FontWeight.w700,
                                    color: TemaAplikasi.secondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Buku Alamat',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'PlayfairDisplay',
                                    fontWeight: FontWeight.w600,
                                    color: TemaAplikasi.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _bukaTambahAlamat,
                            style: TextButton.styleFrom(
                              foregroundColor: TemaAplikasi.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Kelola destinasi pengiriman atelier & kurir concierge prioritas dengan standar pengemasan eksklusif ME.',
                        style: TextStyle(
                          fontSize: 13,
                          color: TemaAplikasi.secondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainerLow,
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                            color: TemaAplikasi.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ME Concierge Express Jabodetabek Aktif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ),
                          Text(
                            'TERSINKRON',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: TemaAplikasi.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: TemaAplikasi.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: TemaAplikasi.mutedGray,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cari nama penerima atau alamat...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: TemaAplikasi.mutedGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _FilterChip(label: 'Semua (3)'),
                          _FilterChip(label: 'Utama'),
                          _FilterChip(label: 'Rumah'),
                          _FilterChip(label: 'Kantor / Studio'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _daftarAlamat.map(_bangunKartuAlamat).toList(),
                      ),
                    ),
                  ],
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
                    child: ElevatedButton.icon(
                      onPressed: _bukaTambahAlamat,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: TemaAplikasi.primary,
                        foregroundColor: TemaAplikasi.onPrimary,
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text(
                        'TAMBAH ALAMAT BARU',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Data alamat dienkripsi sesuai protokol privasi ME',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: TemaAplikasi.secondary,
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

  Widget _bangunKartuAlamat(Alamat alamat) {
    final labelChipColor = alamat.utama
        ? TemaAplikasi.primary
        : TemaAplikasi.surfaceContainerHigh;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (alamat.utama)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: TemaAplikasi.primary,
                        child: const Text(
                          'ALAMAT UTAMA',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.3,
                            color: TemaAplikasi.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: labelChipColor,
                      child: Text(
                        alamat.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          color: alamat.utama
                              ? TemaAplikasi.onPrimary
                              : TemaAplikasi.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!alamat.utama)
                TextButton(
                  onPressed: () => _jadikanUtama(alamat),
                  style: TextButton.styleFrom(
                    foregroundColor: TemaAplikasi.primary,
                    minimumSize: const Size(0, 0),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Jadikan Utama',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alamat.nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alamat.telepon,
            style: const TextStyle(
              fontSize: 12,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            alamat.alamat,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TemaAplikasi.primary,
            ),
          ),
          if (alamat.catatan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: TemaAplikasi.surfaceContainerLow,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: TemaAplikasi.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${alamat.catatan}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaAplikasi.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(color: TemaAplikasi.borderGray),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _ubahAlamat(alamat),
                  style: TextButton.styleFrom(
                    foregroundColor: TemaAplikasi.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _hapusAlamat(alamat),
                  style: TextButton.styleFrom(
                    foregroundColor: TemaAplikasi.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceContainerLow,
        border: Border.all(color: TemaAplikasi.borderGray),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: TemaAplikasi.primary,
        ),
      ),
    );
  }
}
