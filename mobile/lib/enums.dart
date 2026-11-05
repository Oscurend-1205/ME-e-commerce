enum KeadaanMuat { memuat, berhasil, kosong, galat }

enum JenisGalat {
  tidakAdaSambungan,
  batasWaktu,
  validasi422,
  bentrok409,
  server500,
  tidakDiketahui,
}

/// Fungsi pembantu untuk memetakan kode respons/galat ke enum JenisGalat
JenisGalat tentukanJenisGalat(String? kode) {
  switch (kode) {
    case 'NO_CONNECTION':
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
