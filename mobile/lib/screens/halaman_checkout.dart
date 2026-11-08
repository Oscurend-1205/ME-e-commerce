import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../enums.dart';
import '../models/keranjang.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

class HalamanCheckout extends StatefulWidget {
  const HalamanCheckout({super.key});

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();

  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';

  List<Kurir> _daftarKurir = [];
  List<MetodePembayaran> _daftarMetode = [];
  DataKeranjang? _dataKeranjang;

  Kurir? _kurirTerpilih;
  MetodePembayaran? _metodeTerpilih;

  bool _sedangMemproses = false;
  String? _kunciIdempotenSaatIni;
  Map<String, dynamic>? _galatValidasi422;

  @override
  void initState() {
    super.initState();
    _kunciIdempotenSaatIni = const Uuid().v4();
    _muatDataReferensi();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _muatDataReferensi() async {
    setState(() {
      _keadaan = KeadaanMuat.memuat;
    });

    final responKurir = await LayananApi.ambilKurir();
    final responMetode = await LayananApi.ambilMetodePembayaran();
    final responKeranjang = await LayananApi.ambilKeranjang();

    if (!mounted) return;

    final responGagal = [
      responKurir,
      responMetode,
      responKeranjang,
    ].where((respon) => !respon.berhasil);

    if (responGagal.isNotEmpty) {
      final respon = responGagal.first;
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
      return;
    }

    final List kurirRaw = responKurir.data is List
        ? responKurir.data as List
        : [];
    final List metodeRaw = responMetode.data is List
        ? responMetode.data as List
        : [];
    final dataKeranjang = DataKeranjang.fromJson(
      responKeranjang.data as Map<String, dynamic>,
    );

    if (kurirRaw.isEmpty || metodeRaw.isEmpty) {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = JenisGalat.tidakDiketahui;
        _pesanGalat = 'Data kurir atau metode pembayaran belum tersedia.';
      });
      return;
    }

    if (dataKeranjang.items.isEmpty) {
      setState(() {
        _dataKeranjang = dataKeranjang;
        _keadaan = KeadaanMuat.kosong;
      });
      return;
    }

    final kurirList = kurirRaw
        .map((k) => Kurir.fromJson(k as Map<String, dynamic>))
        .toList();
    final metodeList = metodeRaw
        .map((m) => MetodePembayaran.fromJson(m as Map<String, dynamic>))
        .toList();

    setState(() {
      _dataKeranjang = dataKeranjang;
      _daftarKurir = kurirList;
      _daftarMetode = metodeList;
      _kurirTerpilih = kurirList.first;
      _metodeTerpilih = metodeList.first;
      _keadaan = KeadaanMuat.berhasil;
    });
  }

  Future<void> _kirimPesanan() async {
    setState(() {
      _galatValidasi422 = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_kurirTerpilih == null || _metodeTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kurir dan metode pembayaran terlebih dahulu.'),
          backgroundColor: TemaAplikasi.primary,
        ),
      );
      return;
    }

    setState(() {
      _sedangMemproses = true;
    });

    final respon = await LayananApi.checkout(
      kunciIdempoten: _kunciIdempotenSaatIni!,
      nama: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      kurirId: _kurirTerpilih!.id,
      metodePembayaranId: _metodeTerpilih!.id,
    );

    if (!mounted) return;

    setState(() {
      _sedangMemproses = false;
    });

    if (respon.berhasil && respon.data != null) {
      final pesananMap = respon.data as Map<String, dynamic>;
      final int pesananId = pesananMap['id'] is int
          ? pesananMap['id'] as int
          : int.tryParse(pesananMap['id'].toString()) ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan Anda berhasil dibuat.'),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanRincianPesanan(pesananId: pesananId),
        ),
      );
    } else {
      // 409 Conflict: Stok Habis saat Checkout Atomic
      if (respon.code == '409') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: TemaAplikasi.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            title: const Text(
              'Stok Tidak Mencukupi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: TemaAplikasi.primary,
              ),
            ),
            content: Text(
              respon.message,
              style: const TextStyle(
                color: TemaAplikasi.secondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'MENGERTI',
                  style: TextStyle(
                    color: TemaAplikasi.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (respon.code == '422') {
        setState(() {
          _galatValidasi422 = respon.errors;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: TemaAplikasi.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplikasi.surfaceWhite,
      appBar: AppBar(
        backgroundColor: TemaAplikasi.surfaceWhite,
        foregroundColor: TemaAplikasi.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'CHECKOUT PESANAN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _keadaan == KeadaanMuat.memuat
          ? const WidgetMemuat()
          : _keadaan == KeadaanMuat.galat
          ? WidgetGalat(
              jenisGalat: _jenisGalat,
              pesan: _pesanGalat,
              onCobaLagi: _muatDataReferensi,
            )
          : _keadaan == KeadaanMuat.kosong
          ? WidgetKosong(
              ikon: Icons.shopping_bag_outlined,
              pesan: 'Keranjang kosong. Tambahkan produk sebelum checkout.',
              saranAksi: 'KEMBALI',
              onAksi: () => Navigator.pop(context),
            )
          : _bangunFormulir(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil
          ? _bangunBilahBawah()
          : null,
    );
  }

  Widget _bangunFormulir() {
    final ongkir = _kurirTerpilih?.tarif ?? 0;
    final subtotal = _dataKeranjang!.subtotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe Idempotency Header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceBright,
                border: Border.all(color: TemaAplikasi.borderGray),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: TemaAplikasi.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Idempotensi aktif: Transaksi atomik & aman ganda.',
                      style: TextStyle(
                        fontSize: 11,
                        color: TemaAplikasi.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bagian Penerima
            const Text(
              'INFORMASI PENERIMA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Penerima',
                hintText: 'Misal: Budi Santoso',
                errorText: _galatValidasi422?['nama'] is List
                    ? (_galatValidasi422!['nama'] as List).first.toString()
                    : null,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama penerima wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _alamatController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alamat Pengiriman Lengkap',
                hintText: 'Jalan, nomor rumah, RT/RW, kecamatan, kota',
                errorText: _galatValidasi422?['alamat'] is List
                    ? (_galatValidasi422!['alamat'] as List).first.toString()
                    : null,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Alamat pengiriman wajib diisi'
                  : null,
            ),
            const SizedBox(height: 28),

            // Pilihan Kurir
            const Text(
              'PILIH JASA PENGIRIMAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 12),

            ..._daftarKurir.map((kurir) {
              final terpilih = _kurirTerpilih?.id == kurir.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _kurirTerpilih = kurir;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: terpilih
                        ? TemaAplikasi.surfaceBright
                        : TemaAplikasi.surfaceWhite,
                    border: Border.all(
                      color: terpilih
                          ? TemaAplikasi.primary
                          : TemaAplikasi.borderGray,
                      width: terpilih ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        terpilih
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: terpilih
                            ? TemaAplikasi.primary
                            : TemaAplikasi.mutedGray,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kurir.nama,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                            Text(
                              kurir.wilayah.isNotEmpty
                                  ? 'Wilayah: ${kurir.wilayah}'
                                  : 'Standar',
                              style: const TextStyle(
                                fontSize: 11,
                                color: TemaAplikasi.mutedGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(kurir.tarif),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Pilihan Metode Pembayaran
            const Text(
              'METODE PEMBAYARAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 12),

            ..._daftarMetode.map((metode) {
              final terpilih = _metodeTerpilih?.id == metode.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _metodeTerpilih = metode;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: terpilih
                        ? TemaAplikasi.surfaceBright
                        : TemaAplikasi.surfaceWhite,
                    border: Border.all(
                      color: terpilih
                          ? TemaAplikasi.primary
                          : TemaAplikasi.borderGray,
                      width: terpilih ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        terpilih
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: terpilih
                            ? TemaAplikasi.primary
                            : TemaAplikasi.mutedGray,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          metode.nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ),
                      Icon(
                        metode.kode.contains('transfer')
                            ? Icons.account_balance_outlined
                            : Icons.payments_outlined,
                        size: 18,
                        color: TemaAplikasi.secondary,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),

            // Rincian Perhitungan
            const Text(
              'RINGKASAN PEMBAYARAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: TemaAplikasi.primary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceBright,
                border: Border.all(color: TemaAplikasi.borderGray),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal Belanja',
                        style: TextStyle(
                          fontSize: 12,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      Text(
                        formatRupiah(subtotal),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ongkos Kirim',
                        style: TextStyle(
                          fontSize: 12,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                      Text(
                        formatRupiah(ongkir),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: TemaAplikasi.borderGray),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Total akhir dihitung oleh server setelah checkout.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(top: BorderSide(color: TemaAplikasi.borderGray)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _sedangMemproses ? null : _kirimPesanan,
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaAplikasi.primary,
              foregroundColor: TemaAplikasi.onPrimary,
              disabledBackgroundColor: TemaAplikasi.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              elevation: 0,
            ),
            child: _sedangMemproses
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: TemaAplikasi.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'BUAT PESANAN SEKARANG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
