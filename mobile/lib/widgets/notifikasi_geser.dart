import 'package:flutter/material.dart';
import '../theme.dart';

/// Notifikasi kustom yang muncul dari atas layar dengan animasi bergeser ke
/// bawah, lalu menghilang otomatis setelah durasi tertentu.
///
/// Berbeda dengan [SnackBar] bawaan (muncul dari bawah), notifikasi ini
/// dirancang agar menonjol di bagian atas tanpa mengganggu area konten utama.
class NotifikasiGeser {
  /// Menampilkan notifikasi geser dari atas.
  ///
  /// - [context] konteks untuk mendapatkan overlay.
  /// - [pesan] teks utama yang ditampilkan.
  /// - [warnaLatar] warna latar (default: [TemaAplikasi.primary]).
  /// - [durasi] lama notifikasi ditampilkan sebelum hilang otomatis.
  /// - [labelAksi] label tombol aksi (jika null, tombol tidak ditampilkan).
  /// - [onAksi] callback ketika tombol aksi ditekan.
  static void tampilkan(
    BuildContext context, {
    required String pesan,
    Color? warnaLatar,
    Color warnaTeks = Colors.white,
    Duration durasi = const Duration(milliseconds: 2200),
    String? labelAksi,
    VoidCallback? onAksi,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NotifikasiGeserWidget(
        pesan: pesan,
        warnaLatar: warnaLatar ?? TemaAplikasi.primary,
        warnaTeks: warnaTeks,
        durasi: durasi,
        labelAksi: labelAksi,
        onAksi: onAksi,
        onSelesai: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _NotifikasiGeserWidget extends StatefulWidget {
  final String pesan;
  final Color warnaLatar;
  final Color warnaTeks;
  final Duration durasi;
  final String? labelAksi;
  final VoidCallback? onAksi;
  final VoidCallback onSelesai;

  const _NotifikasiGeserWidget({
    required this.pesan,
    required this.warnaLatar,
    required this.warnaTeks,
    required this.durasi,
    required this.onSelesai,
    this.labelAksi,
    this.onAksi,
  });

  @override
  State<_NotifikasiGeserWidget> createState() => _NotifikasiGeserWidgetState();
}

class _NotifikasiGeserWidgetState extends State<_NotifikasiGeserWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animasiSlide;
  late final Animation<double> _animasiOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Mulai dari luar layar bagian atas (y: -1.0) lalu turun ke posisi normal.
    _animasiSlide = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _animasiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Setelah durasi tampil, jalankan animasi keluar lalu hapus overlay.
    Future.delayed(widget.durasi, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onSelesai();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final atas = media.padding.top + 8;

    return Positioned(
      top: atas,
      left: 12,
      right: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _animasiSlide,
            child: Opacity(
              opacity: _animasiOpacity.value,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.warnaLatar,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.pesan,
                    style: TextStyle(
                      color: widget.warnaTeks,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
                if (widget.labelAksi != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      widget.onAksi?.call();
                      // Tutup notifikasi setelah aksi ditekan.
                      _controller.reverse().then((_) => widget.onSelesai());
                    },
                    child: Text(
                      widget.labelAksi!,
                      style: TextStyle(
                        color: widget.warnaTeks,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
