import 'package:flutter/material.dart';
import '../models/produk.dart';
import '../theme.dart';

/// Daftar URL Foto Editorial Berkualitas Tinggi dari Google CDN (cek-beranda.html)
class FotoDummy {
  // Hero Container ME MINIMALISM
  static const String heroBanner =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA6LVX1bIA484vWMnD2Ifg9CMnmhCEhjzWDclPyLAfewV2UvmvJe3zgr89Que-qqsea7Ma7wymBamkjH5YsAIiA19z0TbbJETUxCSfiMu0BgVZ8LfdwQLH0IZy-FcuhxkRfjAQwDU8-DRBb3n0iCZnK9eDoIwyIvBUS6_8QGqTDmLkW78fao_nwfsuyAsDgYzf-4OZPQ13dAHq_JZJRb7_N6tNQsFlTFjRWkysiEQ-u';

  // 4 Kategori Pilihan (Curated 2x2)
  static const String katAtasan =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBHRnqvMj5GigWhs98ZfIpR2i4jCMkp-OUr8iHaaEKpkRBSJ-4KYOImfF6xaKsiaQKE8SNNmGBeOMdvDvagOCotsG35aIGN7FOaOolH8fZfrBmA0pR8pk68r2BsuK65WnsjZ0D277QuKDL4I5LlNcc8lrEY2bk5ZyjkFe9PQrYw2CeJSSW8heZ9XsHENmWjgyMs3Ov1TAkg0M0tEKGywc9hK0qOJrLKVMBQqKsr-zLM';

  static const String katBawahan =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAAB4e77HPY2a8EjYBB1pG0_fDl-WGJCPOSZ-sOczlzyjYQORb2FYMZwCHWM3B_9DD3iE1dIiQyCZD3fmQJKejbWDWWgZJ0DpN-Y2QczkZqn4iQBBV9JxoXiJERkc3IAOFQctihh5xqAeMjG8NlzGUrL0cRLfQN5TG7eBj45PsUqot4OAymobsshHYSVBhE7nnC9rNVgZDUqSc4oreVPMjGZ9KW_Z7kn2MmU3nN-AtZ';

  static const String katOuterwear =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBbSyv1vjn7424W2ZkFD13SUeIw0TmHegOmD1qVmSx3nlDfAQ_8NG8uequJpboUIm7muhwQc0jlH_EP-g5AUwnxIr_5OPIZ3nrVyww3m4uTjS2r5W4BPqE9FVATyGm3JitXRTSCk-hyQz3k9RtDhCFs40OG92ysGq5SA8l-edvloVYsUlTfCjpKn4dZajtpotMPx-2HH2mRb8dX5dSKL9wncsySVrSuSRGaw__53FS8';

  static const String katAksesori =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBPdastdeL0wZjBTsd2RrMJT1V3_60N32ey9QYGhbGsCf096WBeRVmgFTjfN3XAOu-NAyQNjYUnDxB00XcelCwk0WflESl7ZJwO2m_e41COCYZEHpmLNY9OjqGeYs58DZNCUxV4jmBQ89dy8WoTL05loQ_bXxhOmRFyb5wdP9d2GXZ-tRcRY8YQKiTKA253DJd7GzpPXWWDQkRM2mWnYnjNMo4vVXfvSBMtO92wffYk';

  // Story Highlight Circles
  static const List<String> stories = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCV5JC6CTumt0cOciJgtkGrcR8OdqrP3DA8h0eCQtCZI6y7xvMu-9iLrLk1HeXxyPKPA_rhKo8QoWakC8u4HksBxvtqwSiLicFLd2SK3if4WrF2ewXMF0UvXr0jWZovRPVXqoGulgoeiIjDQUiK8lWWGbkv6vOUoAUS4uUMUV1AuudMiBxnyzniHZSCC_DXyrJkhBBeM-DEvG15CSQ9XLqnnqtzC_XKhjheOa0Jt0T2',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCvo1vu1NalhSSko1pscjgbsIg75qhcdIExf-ifrstER3ZBtUekTcpzXO1e-WVLzP1UcwsNavy2GgNUZWMNYEqfIt-TZEfn8GYcg7qGrdrxBIGsDYz47c0KO0ILLHyQNg8fhvemqQ0feFbG2wFJ5yj5jQIl8NOZo4X85wGgx7yELVhhA2ZugZuZ36Vyq8V72PcdGnMTDObeCzbMi5U6PYHJwKJ5yb6t0J4L_E6CZIcL',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDDWBWweL6H4iQJGlN9eNkOmAOO0tQRFykxzLOAi-eKXQxCORhyd_OSyrpxFo9U27ESvgf2SkgJyjfkzUerWFpt6FlZsTnf_WBs8ZYF19BN1va8Eo3qRrPZXAN4OEUE5-KkObomPWWG5Nzn8H5zL3thLTUbTtzrffRuf58pd3n5eb7fau5xG_ZLwm9cwseF9fkTkTzOsxdlBVrMr01hFdaPjtDxaDKID2fZp5iCWUCt',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBPdastdeL0wZjBTsd2RrMJT1V3_60N32ey9QYGhbGsCf096WBeRVmgFTjfN3XAOu-NAyQNjYUnDxB00XcelCwk0WflESl7ZJwO2m_e41COCYZEHpmLNY9OjqGeYs58DZNCUxV4jmBQ89dy8WoTL05loQ_bXxhOmRFyb5wdP9d2GXZ-tRcRY8YQKiTKA253DJd7GzpPXWWDQkRM2mWnYnjNMo4vVXfvSBMtO92wffYk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDRfuy_L5WtOys4Z-udx_gW9LZf-uOYxCF5jmUawc3asNkgm-1R6nn-uRI8POvoraIIINkxLqdF1wcmRS8_Ls91SZe8l-mL2ciYBupmfMZ2XoQQ_JDa0ngf0P-8YD9oWllLNSJTJ3OZLdIKDho_59f7in91KpYeqEWCbyW_HwZw-cD3x605a6Em-Jfn5WE87uS8IczofyHLfYAAWuWfN-wnrrtukea3uzIgdmszdvAG',
  ];

  // Daftar Foto Produk Editorial untuk Katalog Koleksi Terbaru
  static const List<String> daftarProdukPakaian = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBwM7fxHW7yzm9J5CWTI5MD16NA-yw6PbNl9vJ-w5Ecfae6CiKACvC9le_55cspz_2sNjoLIWbOZAJHJkaQ7CA0MSzq7v41M5aMG0gGDNM2m7sjVYFQRcNDTL_P0oimrEMT0GWHdl0dE2F3VXOlLxgFB9J-w2aAXb53S-7WLOLqX-AfXJ3XsOfM-YAqBzzbdya-QNIkY3FakFrY6aW3h4XHxNz5QETqHpgGqKggrtGf',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAV7I_9YL0P7UbbinJx7r1K5YxHu7KT4NQCkD98OAaz-dYRGdgw60UcDS_c2bJqCMzoCsNjLu_9QJHB_AfhrP7kww0d-bZuvneBSzflsahe6jDnkyMYtxHi3S7Euf1Y4Pc4EX3P6i3n9M83LYUGqEsC8f8ZfM27Q937bovtbltFcl5F9_5Ml67lVUpZ_6-iBDHMPkK9xE3jDwydty3tl6ZFskEYIB4AD5C0uk53GZJq',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDdO_Q6yKJzskik4Uk_ztUK5S6L6KbHcRUqYuSJIwEMPUaEo0EjdO1g0hGr-yo8H2jTsot3puWCyZcVv4l_dbJr3G1Cg-jQmDLlbVeDnpbEfHx9bDnleh-U48JGvE1AIPBehqGvOBxGyEjDzdt7sINxyHhWpHOAs62p_q9FtTaA9s7Ft0S75tgxLl_lTKcB28rRl--JamUpqSNME0Z-uhUhz0fWgqYWFJXOlvGIzwUk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBHRnqvMj5GigWhs98ZfIpR2i4jCMkp-OUr8iHaaEKpkRBSJ-4KYOImfF6xaKsiaQKE8SNNmGBeOMdvDvagOCotsG35aIGN7FOaOolH8fZfrBmA0pR8pk68r2BsuK65WnsjZ0D277QuKDL4I5LlNcc8lrEY2bk5ZyjkFe9PQrYw2CeJSSW8heZ9XsHENmWjgyMs3Ov1TAkg0M0tEKGywc9hK0qOJrLKVMBQqKsr-zLM',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBbSyv1vjn7424W2ZkFD13SUeIw0TmHegOmD1qVmSx3nlDfAQ_8NG8uequJpboUIm7muhwQc0jlH_EP-g5AUwnxIr_5OPIZ3nrVyww3m4uTjS2r5W4BPqE9FVATyGm3JitXRTSCk-hyQz3k9RtDhCFs40OG92ysGq5SA8l-edvloVYsUlTfCjpKn4dZajtpotMPx-2HH2mRb8dX5dSKL9wncsySVrSuSRGaw__53FS8',
  ];

  static const List<String> daftarProdukAksesori = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBPdastdeL0wZjBTsd2RrMJT1V3_60N32ey9QYGhbGsCf096WBeRVmgFTjfN3XAOu-NAyQNjYUnDxB00XcelCwk0WflESl7ZJwO2m_e41COCYZEHpmLNY9OjqGeYs58DZNCUxV4jmBQ89dy8WoTL05loQ_bXxhOmRFyb5wdP9d2GXZ-tRcRY8YQKiTKA253DJd7GzpPXWWDQkRM2mWnYnjNMo4vVXfvSBMtO92wffYk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDRfuy_L5WtOys4Z-udx_gW9LZf-uOYxCF5jmUawc3asNkgm-1R6nn-uRI8POvoraIIINkxLqdF1wcmRS8_Ls91SZe8l-mL2ciYBupmfMZ2XoQQ_JDa0ngf0P-8YD9oWllLNSJTJ3OZLdIKDho_59f7in91KpYeqEWCbyW_HwZw-cD3x605a6Em-Jfn5WE87uS8IczofyHLfYAAWuWfN-wnrrtukea3uzIgdmszdvAG',
  ];

  /// Mendapatkan foto yang konsisten untuk produk berdasarkan ID atau Kategori
  static String untukProduk(Produk produk) {
    if (produk.kategori.toLowerCase() == 'aksesori') {
      final index = produk.id % daftarProdukAksesori.length;
      return daftarProdukAksesori[index];
    } else {
      final index = produk.id % daftarProdukPakaian.length;
      return daftarProdukPakaian[index];
    }
  }

  /// Widget Gambar Jaringan dengan Placeholder Anggun & Error Fallback
  static Widget bangunGambar({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? fallbackWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: TemaAplikasi.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: TemaAplikasi.mutedGray,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return fallbackWidget ??
            Container(
              width: width,
              height: height,
              color: TemaAplikasi.surfaceContainer,
              child: const Center(
                child: Icon(
                  Icons.checkroom_outlined,
                  size: 32,
                  color: TemaAplikasi.mutedGray,
                ),
              ),
            );
      },
    );
  }
}
