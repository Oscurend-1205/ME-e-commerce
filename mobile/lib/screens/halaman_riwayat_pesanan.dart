import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../enums.dart';
import '../models/pesanan.dart';
import '../services/layanan_api.dart';
import '../services/state_pengguna.dart';
import '../theme.dart';
import '../widgets/format_rupiah.dart';
import '../widgets/foto_dummy.dart';
import '../widgets/transisi_geser.dart';
import '../widgets/widget_keadaan.dart';
import 'halaman_bukti_transaksi.dart';
import 'halaman_keranjang.dart';
import 'halaman_login.dart';
import 'halaman_pembayaran.dart';
import 'halaman_pembayaran_qris.dart';
import 'halaman_rincian_pesanan.dart';

/// Halaman Riwayat Pesanan — Desain Editorial Mewah mengikuti cek-daftar-pesanan.html
/// Terintegrasi dengan alur Checkout, Midtrans QRIS/Snap, dan Lacak Pengiriman RajaOngkir.
class HalamanRiwayatPesanan extends StatefulWidget {
  const HalamanRiwayatPesanan({super.key});

  @override
  State<HalamanRiwayatPesanan> createState() => _HalamanRiwayatPesananState();
}

class _HalamanRiwayatPesananState extends State<HalamanRiwayatPesanan> {
  KeadaanMuat _keadaan = KeadaanMuat.memuat;
  JenisGalat _jenisGalat = JenisGalat.tidakDiketahui;
  String _pesanGalat = '';
  List<Pesanan> _daftarSemuaPesanan = [];

  // Penanda agar pemuatan otomatis hanya dijalankan sekali,
  // sehingga daftar kosong tetap menampilkan empty state (bukan memuat terus).
  bool _sudahMemuatPertama = false;

  // Tab: 'proses' (Dalam Proses), 'selesai' (Selesai), 'dibatalkan' (Dibatalkan)
  String _tabAktif = 'proses';

  // Fitur Pencarian
  bool _modeCari = false;
  final TextEditingController _cariController = TextEditingController();
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    StatePengguna.isLoggedInNotifier.addListener(_onAuthStatusBerubah);
    StatePengguna.tokenNotifier.addListener(_onAuthStatusBerubah);
    if (StatePengguna.isLoggedInNotifier.value) {
      _muatPesanan();
    } else {
      _keadaan = KeadaanMuat.kosong;
    }
  }

  void _onAuthStatusBerubah() {
    if (!mounted) return;
    if (StatePengguna.isLoggedInNotifier.value) {
      _muatPesanan();
    } else {
      setState(() {
        _daftarSemuaPesanan = [];
        _keadaan = KeadaanMuat.kosong;
      });
    }
  }

  @override
  void dispose() {
    StatePengguna.isLoggedInNotifier.removeListener(_onAuthStatusBerubah);
    StatePengguna.tokenNotifier.removeListener(_onAuthStatusBerubah);
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muatPesanan() async {
    if (!StatePengguna.isLoggedInNotifier.value) {
      setState(() {
        _keadaan = KeadaanMuat.kosong;
      });
      return;
    }

    setState(() {
      _keadaan = KeadaanMuat.memuat;
      _sudahMemuatPertama = true;
    });

    final respon = await LayananApi.ambilRiwayatPesanan();

    if (!mounted) return;

    if (respon.berhasil && respon.data is List) {
      final daftar = (respon.data as List)
          .map((p) => Pesanan.fromJson(p as Map<String, dynamic>))
          .toList();
      setState(() {
        _daftarSemuaPesanan = daftar;
        _keadaan = KeadaanMuat.berhasil;
      });

      // Cek status pembayaran untuk pesanan yang masih menunggu pembayaran
      _cekStatusPembayaranBerkala(daftar);
    } else {
      setState(() {
        _keadaan = KeadaanMuat.galat;
        _jenisGalat = tentukanJenisGalat(respon.code);
        _pesanGalat = respon.message;
      });
    }
  }

  Future<void> _cekStatusPembayaranBerkala(List<Pesanan> daftar) async {
    for (final pesanan in daftar) {
      if (pesanan.status.toLowerCase() == 'menunggu_pembayaran' &&
          pesanan.snapToken != null &&
          pesanan.snapToken!.isNotEmpty) {
        try {
          final respon = await LayananApi.cekStatusPembayaran(
            pesanan.nomorPesanan,
          );
          if (respon.berhasil && respon.data != null) {
            final data = respon.data as Map<String, dynamic>;
            final statusPesanan = data['status_pesanan'] as String? ?? '';
            // Jika status berubah, reload seluruh daftar pesanan
            if (statusPesanan != 'menunggu_pembayaran' && mounted) {
              _muatPesanan();
              break;
            }
          }
        } catch (_) {
          // Abaikan error silent check
        }
      }
    }
  }

  // Filter Kategori Tab
  List<Pesanan> get _pesananProses => _daftarSemuaPesanan.where((p) {
    final s = p.status.toLowerCase();
    return s == 'menunggu_pembayaran' ||
        s == 'menunggu_konfirmasi' ||
        s == 'dibayar' ||
        s == 'diproses' ||
        s == 'dikirim';
  }).toList();

  List<Pesanan> get _pesananSelesai => _daftarSemuaPesanan.where((p) {
    return p.status.toLowerCase() == 'selesai';
  }).toList();

  List<Pesanan> get _pesananDibatalkan => _daftarSemuaPesanan.where((p) {
    return p.status.toLowerCase() == 'dibatalkan';
  }).toList();

  List<Pesanan> get _pesananTampil {
    List<Pesanan> hasil;
    switch (_tabAktif) {
      case 'selesai':
        hasil = _pesananSelesai;
        break;
      case 'dibatalkan':
        hasil = _pesananDibatalkan;
        break;
      case 'proses':
      default:
        hasil = _pesananProses;
        break;
    }

    if (_kataKunci.trim().isNotEmpty) {
      final q = _kataKunci.toLowerCase().trim();
      hasil = hasil.where((p) {
        final matchNomor = p.nomorPesanan.toLowerCase().contains(q);
        final matchKurir = (p.namaKurir ?? '').toLowerCase().contains(q);
        final matchItem =
            p.detail?.any((d) => d.namaProduk.toLowerCase().contains(q)) ??
            false;
        return matchNomor || matchKurir || matchItem;
      }).toList();
    }

    return hasil;
  }

  String _formatTanggal(String? tanggalStr) {
    if (tanggalStr == null || tanggalStr.isEmpty) return 'Hari Ini';
    try {
      final dt = DateTime.parse(tanggalStr);
      return DateFormat('d MMMM y', 'id_ID').format(dt);
    } catch (_) {
      return tanggalStr;
    }
  }

  void _bukaRincian(Pesanan pesanan) {
    Navigator.push(
      context,
      ruteGeser(HalamanRincianPesanan(pesananId: pesanan.id)),
    ).then((_) => _muatPesanan());
  }

  void _bayarSekarang(Pesanan pesanan) {
    final metode = (pesanan.metodePembayaran ?? '').toLowerCase();
    final isQris = metode.contains('qris');

    // Jika memiliki snapToken Midtrans, selalu buka pembayaran resmi Midtrans Snap
    if (pesanan.snapToken != null && pesanan.snapToken!.isNotEmpty) {
      Navigator.push(
        context,
        ruteGeser(
          HalamanPembayaran(
            pesananId: pesanan.id,
            snapToken: pesanan.snapToken!,
            redirectUrl: pesanan.redirectUrl,
            qrUrl: pesanan.qrUrl,
            qrString: pesanan.qrString,
            nomorPesanan: pesanan.nomorPesanan,
            total: pesanan.total,
          ),
        ),
      ).then((_) => _muatPesanan());
    } else if (isQris) {
      Navigator.push(
        context,
        ruteGeser(
          HalamanPembayaranQris(
            pesananId: pesanan.id,
            nomorPesanan: pesanan.nomorPesanan,
            total: pesanan.total,
            qrUrl: pesanan.qrUrl,
            qrString: pesanan.qrString,
          ),
        ),
      ).then((_) => _muatPesanan());
    } else {
      _bukaRincian(pesanan);
    }
  }

  Future<void> _beliLagi(Pesanan pesanan) async {
    final items = pesanan.detail ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail produk tidak tersedia untuk dipesan ulang.'),
          backgroundColor: TemaAplikasi.primary,
        ),
      );
      return;
    }

    // Tampilkan snackbar memuat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menambahkan produk ke tas belanja...'),
        backgroundColor: TemaAplikasi.primary,
        duration: Duration(seconds: 1),
      ),
    );

    int berhasilCount = 0;
    for (final item in items) {
      if (item.produkId != null && item.varianId != null) {
        final res = await LayananApi.tambahKeKeranjang(
          produkId: item.produkId!,
          varianId: item.varianId!,
          jumlah: item.jumlah > 0 ? item.jumlah : 1,
        );
        if (res.berhasil) berhasilCount++;
      }
    }

    await StatePengguna.sinkronkanKeranjang();

    if (!mounted) return;

    if (berhasilCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$berhasilCount produk berhasil dimasukkan ke tas belanja!',
          ),
          backgroundColor: TemaAplikasi.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'LIHAT TAS',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, ruteGeser(const HalamanKeranjang()));
            },
          ),
        ),
      );
    } else {
      // Navigasi langsung ke keranjang
      Navigator.push(context, ruteGeser(const HalamanKeranjang()));
    }
  }

  void _lacakPengirimanRajaOngkir(Pesanan pesanan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BangunModalLacak(pesanan: pesanan),
    );
  }

  void _hubungiConcierge() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaAplikasi.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: const Text(
          'ME Private Concierge',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TemaAplikasi.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Asisten pribadi Atelier ME siap melayani kebutuhan Anda 24/7:',
              style: TextStyle(
                fontSize: 13,
                color: TemaAplikasi.secondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14),
            Text(
              '• Layanan Pelanggan: +62 812-3456-7890\n• Email: concierge@atelier-me.com\n• Penyesuaian Ukuran & Pengiriman Prioritas',
              style: TextStyle(
                fontSize: 12,
                color: TemaAplikasi.primary,
                height: 1.6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'TUTUP',
              style: TextStyle(
                color: TemaAplikasi.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StatePengguna.isLoggedInNotifier,
      builder: (context, isLoggedIn, _) {
        // Jika sudah login tetapi pesanan belum pernah dimuat, muat otomatis.
        // Penanda _sudahMemuatPertama mencegah pemuatan berulang saat daftar
        // memang kosong (tanpa pesanan), agar empty state tetap tampil.
        if (isLoggedIn &&
            !_sudahMemuatPertama &&
            _keadaan != KeadaanMuat.memuat) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                StatePengguna.isLoggedInNotifier.value &&
                !_sudahMemuatPertama &&
                _keadaan != KeadaanMuat.memuat) {
              _muatPesanan();
            }
          });
        }

        return Scaffold(
          backgroundColor: TemaAplikasi.surfaceBright,
          body: SafeArea(
            child: Column(
              children: [
                _bangunAppBar(),
                if (_modeCari) _bangunKolomPencarian(),
                _bangunHeaderArsip(),
                _bangunTabBarMinimalis(),
                Expanded(child: _bangunKonten()),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. App Bar Editorial
  Widget _bangunAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ME',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: TemaAplikasi.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'PESANAN SAYA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: TemaAplikasi.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                onPressed: _keadaan == KeadaanMuat.memuat ? null : _muatPesanan,
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: TemaAplikasi.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Segarkan Pesanan',
              ),
              const SizedBox(width: 14),
              IconButton(
                onPressed: () {
                  setState(() {
                    _modeCari = !_modeCari;
                    if (!_modeCari) {
                      _cariController.clear();
                      _kataKunci = '';
                    }
                  });
                },
                icon: Icon(
                  _modeCari ? Icons.close : Icons.search,
                  size: 20,
                  color: TemaAplikasi.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Cari Pesanan',
              ),
              const SizedBox(width: 14),
              ValueListenableBuilder<int>(
                valueListenable: StatePengguna.jumlahKeranjangNotifier,
                builder: (context, jumlah, _) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        ruteGeser(const HalamanKeranjang()),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: TemaAplikasi.primary,
                        ),
                        if (jumlah > 0)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: TemaAplikasi.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                jumlah > 9 ? '9+' : '$jumlah',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Bar Pencarian Cepat
  Widget _bangunKolomPencarian() {
    return Container(
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _cariController,
        autofocus: true,
        style: const TextStyle(fontSize: 13, color: TemaAplikasi.primary),
        decoration: InputDecoration(
          hintText: 'Cari nomor pesanan, produk, atau kurir...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: TemaAplikasi.secondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: TemaAplikasi.secondary,
          ),
          filled: true,
          fillColor: TemaAplikasi.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          setState(() {
            _kataKunci = val;
          });
        },
      ),
    );
  }

  // 3. Header Arsip Pembelian
  Widget _bangunHeaderArsip() {
    return Container(
      width: double.infinity,
      color: TemaAplikasi.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ARSIP PEMBELIAN',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.secondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Daftar Transaksi',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: TemaAplikasi.primary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Tab Bar Minimalis Editorial (sesuai cek-daftar-pesanan.html)
  Widget _bangunTabBarMinimalis() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: TemaAplikasi.borderGray, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          _bangunItemTab(
            key: 'proses',
            label: 'DALAM PROSES',
            count: _pesananProses.length,
          ),
          const SizedBox(width: 20),
          _bangunItemTab(
            key: 'selesai',
            label: 'SELESAI',
            count: _pesananSelesai.length,
          ),
          const SizedBox(width: 20),
          _bangunItemTab(
            key: 'dibatalkan',
            label: 'DIBATALKAN',
            count: _pesananDibatalkan.length,
          ),
        ],
      ),
    );
  }

  Widget _bangunItemTab({
    required String key,
    required String label,
    required int count,
  }) {
    final aktif = _tabAktif == key;

    return InkWell(
      onTap: () {
        setState(() {
          _tabAktif = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: aktif ? TemaAplikasi.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                color: aktif ? TemaAplikasi.primary : TemaAplikasi.secondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: aktif
                    ? TemaAplikasi.primary
                    : TemaAplikasi.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: aktif ? Colors.white : TemaAplikasi.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Konten Daftar Pesanan
  Widget _bangunKonten() {
    if (!StatePengguna.isLoggedInNotifier.value) {
      return WidgetKosong(
        ikon: Icons.lock_outline_rounded,
        pesan:
            'Silakan masuk untuk melihat riwayat pesanan dan status pengiriman Anda.',
        saranAksi: 'MASUK',
        onAksi: () async {
          final res = await Navigator.push<bool>(
            context,
            ruteGeser(const HalamanLogin()),
          );
          if (res == true && mounted) _muatPesanan();
        },
      );
    }

    switch (_keadaan) {
      case KeadaanMuat.memuat:
        return const WidgetMemuat();
      case KeadaanMuat.galat:
        return WidgetGalat(
          jenisGalat: _jenisGalat,
          pesan: _pesanGalat,
          onCobaLagi: _muatPesanan,
        );
      case KeadaanMuat.kosong:
      case KeadaanMuat.berhasil:
        final daftar = _pesananTampil;
        if (daftar.isEmpty) {
          return _bangunEmptyTab();
        }

        return RefreshIndicator(
          onRefresh: _muatPesanan,
          color: TemaAplikasi.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: daftar.length + 1, // +1 untuk banner concierge di akhir
            separatorBuilder: (_, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == daftar.length) {
                return _bangunConciergeDanFilosofi();
              }
              return _bangunKartuPesananMewah(daftar[index]);
            },
          ),
        );
    }
  }

  // 6. Kartu Pesanan Mewah (Sesuai cek-daftar-pesanan.html)
  Widget _bangunKartuPesananMewah(Pesanan pesanan) {
    final status = pesanan.status.toLowerCase();
    final items = pesanan.detail ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final totalItem = items.fold<int>(0, (t, d) => t + d.jumlah);
    final sisaItem = totalItem > 1 ? totalItem - 1 : 0;

    return Container(
      decoration: BoxDecoration(
        color: TemaAplikasi.surfaceWhite,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: TemaAplikasi.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header Meta: Tanggal, Nomor Pesanan, Badge Status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTanggal(pesanan.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '#${pesanan.nomorPesanan}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
                _bangunBadgeStatus(status),
              ],
            ),
          ),
          const Divider(height: 1, color: TemaAplikasi.borderGray),

          // B. Product Preview Row
          if (firstItem != null)
            InkWell(
              onTap: () => _bukaRincian(pesanan),
              child: Container(
                color: TemaAplikasi.surfaceBright.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Produk
                    Container(
                      width: 72,
                      height: 88,
                      decoration: BoxDecoration(
                        color: TemaAplikasi.surfaceContainer,
                        border: Border.all(color: TemaAplikasi.borderGray),
                      ),
                      child: FotoDummy.bangunGambar(
                        url:
                            firstItem.gambar != null &&
                                firstItem.gambar!.isNotEmpty
                            ? (firstItem.gambar!.startsWith('http')
                                  ? firstItem.gambar!
                                  : '${Konstan.storageUrl}/${firstItem.gambar}')
                            : '${Konstan.storageUrl}/1.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KOLEKSI ATELIER ME',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstItem.namaProduk,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TemaAplikasi.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${firstItem.warna} • Ukuran ${firstItem.ukuran} • ${firstItem.jumlah} Item',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TemaAplikasi.secondary,
                            ),
                          ),
                          if (sisaItem > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+$sisaItem item aksesori lainnya',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TemaAplikasi.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // C. Tracking & RajaOngkir Kurir Banner
          _bangunBannerKurirRajaOngkir(pesanan),

          const Divider(height: 1, color: TemaAplikasi.borderGray),

          // D. Summary & Action Buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                    Text(
                      formatRupiah(pesanan.total),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _bangunTombolAksi(pesanan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Badge Status Desain Minimalis dengan Pulse Dot
  Widget _bangunBadgeStatus(String status) {
    Color warna;
    String teks;
    bool adaPulse = false;

    switch (status) {
      case 'dikirim':
        warna = const Color(0xFF107C41);
        teks = 'SEDANG DIKIRIM';
        adaPulse = true;
        break;
      case 'diproses':
        warna = const Color(0xFF168AAD);
        teks = 'DIPROSES ATELIER';
        adaPulse = true;
        break;
      case 'menunggu_pembayaran':
        warna = const Color(0xFFC77700);
        teks = 'MENUNGGU BAYAR';
        adaPulse = true;
        break;
      case 'menunggu_konfirmasi':
        warna = const Color(0xFF1E6091);
        teks = 'KONFIRMASI DANA';
        break;
      case 'dibayar':
        warna = const Color(0xFF184E77);
        teks = 'SUDAH DIBAYAR';
        break;
      case 'selesai':
        warna = const Color(0xFF2D6A4F);
        teks = 'SELESAI DITERIMA';
        break;
      case 'dibatalkan':
        warna = TemaAplikasi.errorColor;
        teks = 'DIBATALKAN';
        break;
      default:
        warna = TemaAplikasi.secondary;
        teks = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: warna.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (adaPulse)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
            ),
          Text(
            teks,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }

  // Banner Kurir & Lacak Pengiriman RajaOngkir
  Widget _bangunBannerKurirRajaOngkir(Pesanan pesanan) {
    final status = pesanan.status.toLowerCase();
    final kurirNama = pesanan.namaKurir ?? 'Kurir Concierge ME';

    String statusTeks;
    if (status == 'dikirim') {
      statusTeks =
          'Paket dalam perjalanan. Estimasi tiba: Besok (Sebelum 18:00 WIB)';
    } else if (status == 'diproses') {
      statusTeks = 'Tahap Quality Inspection & Pengemasan Eksklusif Atelier';
    } else if (status == 'menunggu_pembayaran') {
      statusTeks = 'Menunggu pembayaran selesai sebelum pengiriman diproses';
    } else if (status == 'selesai') {
      statusTeks = 'Pesanan telah diterima oleh Klien dengan sempurna';
    } else {
      statusTeks = 'Pengiriman dibatalkan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: TemaAplikasi.surfaceContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 16,
            color: TemaAplikasi.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kurirNama.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusTeks,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaAplikasi.secondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol Aksi Kontekstual Sesuai Alur
  Widget _bangunTombolAksi(Pesanan pesanan) {
    final status = pesanan.status.toLowerCase();

    if (status == 'menunggu_pembayaran') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _bukaRincian(pesanan),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.primary,
                side: const BorderSide(color: TemaAplikasi.borderGray),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'DETAIL PESANAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _bayarSekarang(pesanan),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'BAYAR SEKARANG',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'dikirim') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _bukaRincian(pesanan),
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.primary,
                side: const BorderSide(color: TemaAplikasi.borderGray),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'DETAIL PESANAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _lacakPengirimanRajaOngkir(pesanan),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'LACAK PENGIRIMAN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'selesai') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  ruteGeser(const HalamanBuktiTransaksi()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaAplikasi.primary,
                side: const BorderSide(color: TemaAplikasi.borderGray),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'BUKTI TRANSAKSI',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _beliLagi(pesanan),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAplikasi.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'BELI LAGI',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default (diproses / dibatalkan)
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _bukaRincian(pesanan),
        style: OutlinedButton.styleFrom(
          foregroundColor: TemaAplikasi.primary,
          side: const BorderSide(color: TemaAplikasi.borderGray),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: const Text(
          'RINCIAN & BANTUAN',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // 7. Empty State Per Tab
  Widget _bangunEmptyTab() {
    IconData ikon;
    String judul;
    String deskripsi;

    switch (_tabAktif) {
      case 'selesai':
        ikon = Icons.check_circle_outline;
        judul = 'Belum Ada Pesanan Selesai';
        deskripsi =
            'Pesanan yang telah Anda terima akan tercatat rapi di arsip ini.';
        break;
      case 'dibatalkan':
        ikon = Icons.assignment_turned_in_outlined;
        judul = 'Tidak Ada Pesanan Dibatalkan';
        deskripsi =
            'Seluruh pesanan Anda tercatat diproses dengan sempurna oleh Atelier ME tanpa pembatalan.';
        break;
      case 'proses':
      default:
        ikon = Icons.shopping_bag_outlined;
        judul = 'Tidak Ada Pesanan Aktif';
        deskripsi =
            'Anda sedang tidak memiliki pesanan yang dalam proses pengiriman.';
        break;
    }

    return RefreshIndicator(
      onRefresh: _muatPesanan,
      color: TemaAplikasi.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: TemaAplikasi.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ikon, size: 28, color: TemaAplikasi.secondary),
                ),
                const SizedBox(height: 16),
                Text(
                  judul,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: TemaAplikasi.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  deskripsi,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaAplikasi.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tabAktif = 'proses';
                      _modeCari = false;
                      _kataKunci = '';
                      _cariController.clear();
                    });
                    _muatPesanan();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaAplikasi.primary,
                    side: const BorderSide(color: TemaAplikasi.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text(
                    'LIHAT SEMUA PESANAN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. ME Private Concierge & Filosofi Footer (sesuai cek-daftar-pesanan.html)
  Widget _bangunConciergeDanFilosofi() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaAplikasi.surfaceContainer,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: TemaAplikasi.borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: TemaAplikasi.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ME Private Concierge',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: TemaAplikasi.primary,
                        ),
                      ),
                      Text(
                        'Layanan Asisten Pelanggan 24/7',
                        style: TextStyle(
                          fontSize: 10,
                          color: TemaAplikasi.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Memerlukan bantuan pengiriman khusus, perubahan alamat pengantaran, atau jadwal penyesuaian ukuran pakaian? Asisten mode pribadi kami siap mendampingi Anda.',
                style: TextStyle(
                  fontSize: 11,
                  color: TemaAplikasi.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _hubungiConcierge,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'HUBUNGI CONCIERGE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: TemaAplikasi.primary,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Respon < 5 menit',
                    style: TextStyle(
                      fontSize: 10,
                      color: TemaAplikasi.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '"Keanggunan yang abadi, dijahit dengan ketelitian sempurna."',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: TemaAplikasi.secondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ME ATELIERS • PARIS • JAKARTA',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
            color: TemaAplikasi.secondary,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Modal Lacak Pengiriman RajaOngkir Real-Time
class _BangunModalLacak extends StatelessWidget {
  final Pesanan pesanan;

  const _BangunModalLacak({required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final kurirNama = pesanan.namaKurir ?? 'Kurir Mitra RajaOngkir';
    final nomorResi = 'ME-EXP-${pesanan.nomorPesanan.replaceAll('ORD-', '')}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LACAK PENGIRIMAN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: TemaAplikasi.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nomor Resi: $nomorResi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TemaAplikasi.secondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TemaAplikasi.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 22,
                    color: TemaAplikasi.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kurirNama.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TemaAplikasi.primary,
                          ),
                        ),
                        const Text(
                          'Estimasi Kedatangan: Besok (Sebelum 18:00 WIB)',
                          style: TextStyle(
                            fontSize: 11,
                            color: TemaAplikasi.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TIMELINE PERJALANAN PAKET',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: TemaAplikasi.secondary,
              ),
            ),
            const SizedBox(height: 12),
            _stepLacak(
              'Kurir Sedang Menuju Alamat Penerima',
              'Paket telah dibawa kurir ke Jakarta Pusat',
              true,
              true,
            ),
            _stepLacak(
              'Paket Tiba di Hub Transit Jakarta DC',
              'Selesai disortir di Pusat Distribusi RajaOngkir',
              true,
              false,
            ),
            _stepLacak(
              'Diserahkan oleh Atelier ME HQ',
              'Barang dipaketkan dengan segel garansi eksklusif',
              true,
              false,
            ),
            _stepLacak(
              'Pesanan Dibuat & Pembayaran Terverifikasi',
              pesanan.createdAt ?? 'Terkonfirmasi otomatis',
              true,
              false,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplikasi.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'TUTUP PELACAKAN',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLacak(String judul, String deskripsi, bool selesai, bool aktif) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: aktif
                    ? TemaAplikasi.primary
                    : (selesai ? Colors.black : Colors.grey.shade300),
                border: aktif
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: aktif
                  ? Container(
                      margin: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : (selesai
                        ? const Icon(Icons.check, size: 9, color: Colors.white)
                        : null),
            ),
            Container(
              width: 1.5,
              height: 36,
              color: selesai ? Colors.black : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: aktif ? TemaAplikasi.primary : TemaAplikasi.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deskripsi,
                style: const TextStyle(
                  fontSize: 10,
                  color: TemaAplikasi.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
