import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../enums.dart';
import '../models/kurir.dart';
import '../models/metode_pembayaran.dart';
import '../services/layanan_api.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_rincian_pesanan.dart';

const Color _hitam = Color(0xFF111111);
const Color _putih = Color(0xFFFFFFFF);
const Color _abuMuda = Color(0xFFF3F3F3);
const Color _abuSedang = Color(0xFF777777);
const Color _abuGaris = Color(0xFFDDDDDD);

class HalamanCheckout extends StatefulWidget {
  final int subtotalAwal;

  const HalamanCheckout({super.key, required this.subtotalAwal});

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

  Kurir? _kurirTerpilih;
  MetodePembayaran? _metodeTerpilih;

  bool _sedangMemproses = false;
  String? _kunciIdempotenSaatIni;
  Map<String, dynamic>? _galatValidasi422;

  @override
  void initState() {
    super.initState();
    // Generate UUID idempoten pertama kali untuk sesi checkout ini
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

    if (!mounted) return;

    if (responKurir.berhasil) {
      final List kurirRaw = responKurir.data is List ? responKurir.data as List : [];
      final kurirList = kurirRaw
          .map((k) => Kurir.fromJson(k as Map<String, dynamic>))
          .toList();

      List<MetodePembayaran> metodeList = [];
      if (responMetode.berhasil && responMetode.data is List) {
        metodeList = (responMetode.data as List)
            .map((m) => MetodePembayaran.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      // Fallback metode pembayaran jika endpoint belum terisi data seed
      if (metodeList.isEmpty) {
        metodeList = [
          MetodePembayaran(id: 1, kode: 'transfer_manual', nama: 'Transfer Bank Manual'),
          MetodePembayaran(id: 2, kode: 'tunai_di_tempat', nama: 'Tunai di Tempat (COD)'),
        ];
      }

      setState(() {
        _daftarKurir = kurirList;
        _daftarMetode = metodeList;
        if (kurirList.isNotEmpty) _kurirTerpilih = kurirList.first;
        if (metodeList.isNotEmpty) _metodeTerpilih = metodeList.first;
        _keadaan = KeadaanMuat.berhasil;
      });
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(responKurir.code);
        _pesanGalat = responKurir.message;
      });
    }
  }

  Future<void> _lakukanCheckout() async {
    // Validasi form lokal
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_kurirTerpilih == null || _metodeTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kurir dan metode pembayaran.')),
      );
      return;
    }

    setState(() {
      _sedangMemproses = true;
      _galatValidasi422 = null;
    });

    // Pastikan kunci idempoten ada (gunakan yang lama jika pengulangan koneksi gagal)
    _kunciIdempotenSaatIni ??= const Uuid().v4();

    final respon = await LayananApi.checkout(
      nama: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      kurirId: _kurirTerpilih!.id,
      metodePembayaranId: _metodeTerpilih!.id,
      kunciIdempoten: _kunciIdempotenSaatIni!,
    );

    if (!mounted) return;

    setState(() {
      _sedangMemproses = false;
    });

    if (respon.berhasil && respon.data != null) {
      // 201 Created -> Pesanan berhasil dibuat secara atomik
      final dataPesanan = respon.data as Map<String, dynamic>;
      final int pesananId = dataPesanan['id'] ?? 0;

      // Navigasi ke HalamanRincianPesanan dan bersihkan tumpukan halaman
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HalamanRincianPesanan(pesananId: pesananId),
        ),
        (route) => route.isFirst,
      );
    } else {
      final code = respon.code;
      if (code == '422') {
        // Validasi gagal di server: tampilkan pesan per kolom
        setState(() {
          _galatValidasi422 = respon.errors;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      } else if (code == '409') {
        // Bentrok stok varian habis -> tetap di layar dan tampilkan pesan server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Galat jaringan, batas waktu, atau server 500
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respon.message),
            backgroundColor: Colors.red.shade800,
            action: SnackBarAction(
              label: 'COBA LAGI',
              textColor: _putih,
              onPressed: _lakukanCheckout,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _putih,
      appBar: AppBar(
        title: const Text(
          'CHECKOUT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _bangunKonten(),
      bottomNavigationBar: _keadaan == KeadaanMuat.berhasil ? _bangunBilahBawah() : null,
    );
  }

  Widget _bangunKonten() {
    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.kosong:
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatDataReferensi,
        );
      case KeadaanMuat.berhasil:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Idempoten (Sistem Terdistribusi Kriteria 5)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _abuMuda,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _abuGaris),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: _abuSedang),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kunci Idempoten: ${_kunciIdempotenSaatIni?.substring(0, 8)}... (Aman dari pesanan ganda)',
                          style: const TextStyle(fontSize: 11, color: _abuSedang),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _hitam,
                  ),
                ),
                const SizedBox(height: 16),

                // Nama Penerima
                TextFormField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap Penerima',
                    hintText: 'Contoh: Auril Aditya',
                    errorText: _galatValidasi422?['nama']?.toString(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama penerima wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Alamat Pengiriman
                TextFormField(
                  controller: _alamatController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alamat Pengiriman Lengkap',
                    hintText: 'Nama jalan, nomor rumah, RT/RW, kelurahan, kecamatan',
                    errorText: _galatValidasi422?['alamat']?.toString(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat pengiriman wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Bagian Kurir & Pengiriman
                const Text(
                  'PILIHAN PENGANTARAN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _hitam,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<Kurir>(
                  initialValue: _kurirTerpilih,
                  decoration: InputDecoration(
                    labelText: 'Kurir & Wilayah',
                    errorText: _galatValidasi422?['kurir_id']?.toString(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  items: _daftarKurir.map((kurir) {
                    return DropdownMenuItem<Kurir>(
                      value: kurir,
                      child: Text(
                        '${kurir.nama} - ${kurir.wilayah} (${formatRupiah(kurir.tarif)})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (kurir) {
                    setState(() {
                      _kurirTerpilih = kurir;
                    });
                  },
                  validator: (value) => value == null ? 'Silakan pilih kurir.' : null,
                ),
                const SizedBox(height: 28),

                // Bagian Pembayaran
                const Text(
                  'METODE PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _hitam,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<MetodePembayaran>(
                  initialValue: _metodeTerpilih,
                  decoration: InputDecoration(
                    labelText: 'Metode Pembayaran',
                    errorText: _galatValidasi422?['metode_pembayaran_id']?.toString(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  items: _daftarMetode.map((metode) {
                    return DropdownMenuItem<MetodePembayaran>(
                      value: metode,
                      child: Text(
                        metode.nama,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (metode) {
                    setState(() {
                      _metodeTerpilih = metode;
                    });
                  },
                  validator: (value) => value == null ? 'Silakan pilih metode pembayaran.' : null,
                ),
                const SizedBox(height: 32),

                // Ringkasan Biaya (Preview Informasi - Server Tetap Sumber Kebenaran)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _abuMuda,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _abuGaris),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RINGKASAN ESTIMASI BIAYA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: _hitam,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal Produk', style: TextStyle(color: _abuSedang, fontSize: 13)),
                          Text(formatRupiah(widget.subtotalAwal), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ongkos Kirim', style: TextStyle(color: _abuSedang, fontSize: 13)),
                          Text(
                            _kurirTerpilih != null ? formatRupiah(_kurirTerpilih!.tarif) : 'Pilih kurir',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: _abuGaris),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimasi Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            formatRupiah(widget.subtotalAwal + (_kurirTerpilih?.tarif ?? 0)),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '* Ongkir dan total resmi dihitung mutlak oleh server saat checkout.',
                        style: TextStyle(fontSize: 10, color: _abuSedang, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
    }
  }

  Widget _bangunBilahBawah() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _putih,
        border: const Border(top: BorderSide(color: _abuGaris)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _sedangMemproses ? null : _lakukanCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hitam,
              disabledBackgroundColor: _abuSedang,
              foregroundColor: _putih,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: _sedangMemproses
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: _putih, strokeWidth: 2),
                  )
                : const Text(
                    'KONFIRMASI PESANAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

