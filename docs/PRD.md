# PRD Toko Online Pakaian & Aksesori (Kelompok 2)

Nov 5, 2026 · @Auril Aditya

**Dokumen acuan resmi:** [`Tugas_UTS_Informatika.md`](Tugas_UTS_Informatika.md) — Tugas Pengganti UTS mata kuliah PAPB (2010MWP0507) dan Sistem Terdistribusi, S1 Informatika, ITSK RS dr. Soepraoen Kesdam V/BRW. PRD ini diselaraskan dengan seluruh aturan pada dokumen tersebut.

## 1. Ringkasan dan Tujuan

Produk ini adalah aplikasi toko online pakaian dan aksesori dengan alur katalog, keranjang, dan checkout, dibangun dari REST API Laravel (MySQL) dan aplikasi Flutter. Ini menjadi Tugas Pengganti UTS berkelompok untuk mata kuliah PAPB (2010MWP0507) dan Sistem Terdistribusi, dengan tenggat sebelum Pertemuan 8 melalui LMS.

**Pembeda domain (Kelompok 2):** stok disimpan per varian (ukuran × warna), bukan satu angka per produk. Ukuran yang habis tidak bisa dipesan walaupun produknya masih ada.

**Tujuan:**

- Semua 14 endpoint wajib berjalan dan konsisten dengan dokumentasi.
- Server Laravel menjadi satu-satunya sumber kebenaran untuk harga, subtotal, ongkos kirim, total, dan ketersediaan; Flutter hanya menampilkan.
- Checkout bersifat atomik (satu transaksi, baris varian dikunci) dan aman terhadap permintaan ulang lewat kunci idempoten.
- Lima jenis galat tampil berbeda di Flutter, dan empat keadaan layar dibedakan eksplisit.
- Setiap anggota dapat menjelaskan seluruh kode pada uji petik Pertemuan 8.

**Target nilai:** skor 4 pada Kriteria 1 sampai 8 dengan **Jalur A (backend sendiri)**. Pembobotan kedua mata kuliah berbeda meski dinilai dari pekerjaan yang sama: PAPB menekankan Kriteria 7 (20) dan Kriteria 3 (12), sedangkan Sistem Terdistribusi menekankan Kriteria 5 (20) dan Kriteria 4 (18). Rincian bobot ada pada Bagian 13.

## 2. Ruang Lingkup dan Batasan

Tiga batasan sistem dari lembar tugas berlaku untuk semua kelompok. Batasan ini **boleh dilampaui**, tetapi materi yang menjadi dasarnya belum diberikan, sehingga melampauinya tidak menambah nilai dan berisiko saat uji petik. Kolom kanan di bawah ini adalah hal yang **belum disarankan**, bukan larangan mutlak.

| Area | Yang diwajibkan tugas | Belum disarankan (boleh dilampaui) |
| --- | --- | --- |
| Pembayaran | Simulasi lewat perubahan status pesanan; metode tunai di tempat dan transfer manual | Midtrans, Xendit, Stripe |
| Pengantaran | Tabel kurir/wilayah dan tarif di MySQL; ongkir dihitung server | RajaOngkir, JNE, SiCepat |
| Autentikasi | Token statis atau pelanggan\_id tetap yang disepakati kelompok | Login JWT atau OAuth 2.0 (Pertemuan 14) |
| State management | setState, constructor, dan callback | Provider dan pustaka lain (tidak menambah nilai) |
| Jaringan Flutter | Paket http dengan .timeout | dio boleh, tetapi harus bisa dijelaskan saat uji petik |

**Aturan arsitektur:** MySQL menyimpan data. Laravel melakukan validasi, hitung subtotal dan ongkir, kurangi stok, dan pindah status. Flutter menampilkan, mengirim permintaan, dan mengelola keadaan layar. Menghitung harga, total, ongkir, atau ketersediaan di Dart membuat Kriteria 5 kehilangan nilai.

**Catatan lanjutan:** proyek yang sama dipakai sampai Pertemuan 14, jadi pengiriman token statis diletakkan di satu tempat saja di kelas LayananApi agar mudah diganti login penuh.

### Jalur pengerjaan backend (tugas Bagian 5)

| Jalur | Sumber data aplikasi Flutter | Akibat pada rubrik |
| --- | --- | --- |
| A. Backend sendiri | REST API Laravel kelompok sendiri di atas MySQL, dengan skema yang disesuaikan domain | Nilai penuh pada semua kriteria |
| B. Tiruan di dalam aplikasi | Kelas MockLayananApi di dalam proyek Flutter yang mengembalikan Future.delayed berisi data tetap | Kriteria 4 dan 5 paling tinggi pada tingkat Kurang; Kriteria 2, 3, 6, dan 7 tetap dinilai penuh |

**Kelompok 2 memilih Jalur A.** Jalur B hanya jalur cadangan bila backend mengalami kendala; kelompok pada jalur B tidak dapat memperoleh skor di atas 2 pada Kriteria 4 dan 5.

## 3. Pengguna dan Alur Utama

Aplikasi melayani dua peran tanpa login: **pembeli** (identitas dari pelanggan\_id tetap) dan **admin toko** (mengelola produk dan mengonfirmasi pembayaran). Keduanya memakai satu aplikasi Flutter.

| Peran | Kebutuhan | Halaman |
| --- | --- | --- |
| Pembeli | Menelusuri dan mencari pakaian, memilih ukuran dan warna, memasukkan ke keranjang, checkout, melihat riwayat | Katalog, Rincian produk, Keranjang, Checkout, Rincian pesanan, Riwayat pesanan |
| Admin | Menambah, mengubah, menghapus produk dan varian; mengonfirmasi pembayaran | Kelola produk, Rincian pesanan |

**Alur utama pembeli:**

1. Buka katalog, saring kategori atau cari nama (diproses server).
2. Buka rincian produk, pilih ukuran dan warna, tentukan jumlah, tambah ke keranjang.
3. Buka keranjang, ubah jumlah atau hapus item, lihat subtotal dari server.
4. Checkout: isi nama dan alamat, pilih kurir dan metode bayar, lihat ongkir dan total dari server.
5. Setelah 201, buka rincian pesanan, tekan bayar simulasi, lalu pantau status di riwayat.

## 4. Domain Pakaian dan Aksesori: Skema Basis Data

Inti pembeda domain ini adalah tabel **varian\_produk**: setiap kombinasi ukuran dan warna punya stok sendiri. Kolom stok pada objek produk di API adalah jumlah dari stok semua variannya (dihitung server), sehingga tujuh kunci inti tetap ada. Aturan bisnis wajib: **checkout dan penambahan ke keranjang ditolak 409 bila varian yang dipilih habis, walaupun produk lain variannya masih ada.**

**Tabel dan kolom utama**

| Tabel | Kolom | Catatan |
| --- | --- | --- |
| kategori | id, nama | Minimal 2 (misalnya Pakaian, Aksesori) |
| produk | id, nama, harga (int Rupiah), kategori\_id, tersedia (bool), deskripsi (nullable), **bahan**, **merek** | bahan dan merek = dua kolom khas domain (batas minimal). API menampilkan kategori sebagai nama dan stok sebagai jumlah stok varian |
| varian\_produk | id, produk\_id, ukuran, warna, stok (int), sku | Unik pada (produk\_id, ukuran, warna); stok varian tidak boleh negatif. Aksesori tanpa ukuran memakai ukuran "All Size" |
| pelanggan | id, nama | Satu pelanggan tetap untuk pengujian |
| keranjang | id, pelanggan\_id, produk\_id, varian\_id, jumlah | Satu baris per varian; tambah varian yang sama menaikkan jumlah |
| kurir | id, nama, wilayah, tarif (int) | Minimal 3 dengan tarif berbeda |
| metode\_pembayaran | id, kode, nama | tunai\_di\_tempat dan transfer\_manual |
| pesanan | id, nomor\_pesanan, pelanggan\_id, kurir\_id, metode\_pembayaran\_id, nama\_penerima, alamat, subtotal, ongkir, total, status, kunci\_idempoten | kunci\_idempoten unik per pelanggan |
| detail\_pesanan | id, pesanan\_id, produk\_id, varian\_id, nama\_produk, ukuran, warna, harga\_satuan, jumlah, subtotal | Harga dan nama disalin saat pembelian |

**Hubungan antartabel:** kategori 1—N produk; produk 1—N varian\_produk; pelanggan 1—N keranjang dan pesanan; varian\_produk 1—N keranjang dan detail\_pesanan; kurir 1—N pesanan; metode\_pembayaran 1—N pesanan; pesanan 1—N detail\_pesanan.

**Keputusan rancangan:**

- Item keranjang dan detail pesanan merujuk ke varian, bukan hanya produk.
- detail\_pesanan menyalin nama, ukuran, warna, dan harga satuan, sehingga pesanan lama tidak berubah ketika harga produk diubah (Kriteria 5).
- Ongkos kirim adalah tarif kurir/wilayah yang dipilih, diambil dari tabel kurir oleh server.
- Produk dihapus hanya bila tidak terpakai pada pesanan aktif; bila terpakai, DELETE membalas 409.

## 5. Kebutuhan Backend Laravel: 14 Endpoint Wajib (+1 tambahan)

Semua 14 endpoint wajib ada. Jalur memakai nama dari lembar tugas (/api/produk dan seterusnya) agar seragam; bila diubah, perubahan ditulis di dokumentasi dan dipakai konsisten di Flutter.

| Metode dan jalur | Kegunaan | Status | Catatan domain pakaian |
| --- | --- | --- | --- |
| GET /api/produk | Daftar produk | 200 (juga saat kosong) | Mendukung ?kategori= dan ?cari=; memuat jumlah stok total |
| GET /api/produk/{id} | Rincian produk | 200, 404 | Menyertakan array varian (ukuran, warna, stok) |
| POST /api/produk | Tambah produk | 201, 422 | Menerima daftar varian awal |
| PUT /api/produk/{id} | Ubah produk | 200, 404, 422 | Dapat mengubah stok varian |
| DELETE /api/produk/{id} | Hapus produk | 200, 404, 409 | 409 bila terpakai pada pesanan aktif |
| GET /api/keranjang | Isi keranjang dan subtotal | 200 | Subtotal dari server; tiap item memuat ukuran dan warna |
| POST /api/keranjang | Tambah item | 201, 409, 422 | Menerima produk\_id, varian\_id, jumlah; 409 bila stok varian kurang; varian yang sama menaikkan jumlah |
| PUT /api/keranjang/{id} | Ubah jumlah | 200, 404, 409, 422 | Jumlah nol atau negatif ditolak 422 |
| DELETE /api/keranjang/{id} | Hapus satu item | 200, 404 |  |
| GET /api/kurir | Daftar kurir dan tarif | 200 | Dipakai checkout untuk memilih pengantaran |
| POST /api/checkout | Buat pesanan | 201, 409, 422 | Wajib header X-Kunci-Idempoten |
| GET /api/pesanan | Riwayat pesanan | 200 | Terbaru dulu |
| GET /api/pesanan/{id} | Rincian pesanan | 200, 404 | Harga saat pembelian dari detail\_pesanan |
| PATCH /api/pesanan/{id}/status | Ubah status | 200, 404, 409, 422 | Hanya perpindahan sah; sisanya 409 |

**Catatan penting:** lembar tugas menyebut POST /api/keranjang menerima produk_id dan jumlah. Karena stok disimpan per varian, kelompok menambahkan varian_id pada body. Penambahan ini harus ditulis di dokumentasi API dan README.

**Catatan tambahan:** selain 14 endpoint wajib di atas, kelompok menambahkan `GET /api/metode-pembayaran` untuk mengisi pemilih metode bayar simulasi di halaman checkout. Endpoint tambahan ini wajib ikut didokumentasikan, dipanggil dari Postman, dan dipakai konsisten di Flutter, agar tidak terhitung sebagai endpoint kode yang tidak terdokumentasi.

**Perilaku backend:**

- Validasi memakai Form Request Laravel; pesan galat dalam bahasa Indonesia.
- Ongkir dan total dihitung di server dari isi keranjang dan tarif kurir.
- Jangan pernah membalas HTML atau pesan galat mentah dari basis data; semua galat memakai pembungkus yang sama.
- Identitas pembeli diambil dari token statis atau pelanggan\_id tetap yang dikirim lewat satu header, misalnya X-Pelanggan-Id.

## 6. Kontrak API

Semua respons, sukses maupun gagal, memakai satu pembungkus agar satu fungsi di Flutter cukup untuk membacanya. Kunci errors hanya ada pada galat validasi 422.

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Daftar produk berhasil diambil",
  "data": [ { "id": 1, "nama": "Kaos Polos Oversize", "harga": 89000 } ]
}
```

```json
{
  "status": "gagal",
  "code": "409",
  "message": "Stok ukuran M warna Hitam tidak mencukupi",
  "errors": null
}
```

**Objek produk.** Tujuh kunci inti wajib ada; dua kolom domain ditambahkan, dan rincian produk memuat array varian.

| Kunci | Tipe | Keterangan |
| --- | --- | --- |
| id | int | Pengenal produk |
| nama | String | Nama produk |
| harga | int | Rupiah bulat, tanpa pemisah ribuan dan desimal |
| kategori | String | Nama kategori |
| stok | int | Jumlah stok semua varian; nol berarti tidak dapat dipesan |
| tersedia | bool | Penanda produk aktif, terpisah dari stok |
| deskripsi | String atau null | Nullable; Flutter wajib menanganinya |
| bahan, merek | String | Kolom khas domain |
| varian (hanya rincian) | List | Tiap elemen: id, ukuran, warna, stok |

**Kode status dan perlakuan di Flutter**

| Kode | Dipakai ketika | Tampilan di Flutter |
| --- | --- | --- |
| 200 | Baca atau ubah berhasil | Tampilkan data |
| 201 | Data baru dibuat | Pindah ke halaman hasil (misalnya rincian pesanan) |
| 404 | Sumber daya tidak ada | Keadaan kosong, bukan dialog galat teknis |
| 409 | Bertentangan dengan keadaan server (stok varian kurang, perpindahan status tidak sah) | Pesan dari server, tetap di layar |
| 422 | Validasi gagal | Pesan per kolom di bawah kolom terkait |
| 500 | Galat server | Pesan umum dan tombol coba lagi, tanpa jejak galat |

**Pertanyaan uji petik yang perlu dijawab dari kontrak ini:** GET /api/produk yang tidak menemukan apa pun membalas 200 dengan data berupa daftar kosong, bukan 404, karena daftar kosong adalah hasil sah dan bukan sumber daya yang hilang. Mengganti nama kunci seperti harga menjadi price akan merusak model Dart (fromJson) dan setiap widget yang membaca kunci itu.

## 7. Checkout: Konsistensi Data, Idempotensi, dan Status Pesanan

Checkout adalah bagian paling berbobot untuk Sistem Terdistribusi (Kriteria 5 bernilai 20). Aturan pokoknya: pengurangan stok varian, penyimpanan pesanan, dan pengosongan keranjang berada dalam satu transaksi basis data, sehingga kegagalan di langkah mana pun mengembalikan stok ke keadaan semula.

**Urutan POST /api/checkout**

1. Flutter membuat satu nilai acak (UUID) per percobaan checkout dan mengirimnya di header X-Kunci-Idempoten.
2. Laravel memeriksa header; bila kunci yang sama sudah punya pesanan, server membalas pesanan yang ada (tanpa membuat yang kedua).
3. Laravel memvalidasi isi permintaan (nama, alamat, kurir\_id, metode\_pembayaran\_id); gagal berarti 422 dengan errors per kolom.
4. Mulai DB::transaction. Kunci baris varian yang ada di keranjang dengan lockForUpdate, diurutkan berdasarkan id agar tidak terjadi deadlock.
5. Periksa stok setiap varian. Bila ada yang kurang, rollback penuh dan balas 409 beserta daftar item yang stoknya kurang.
6. Hitung subtotal dari harga saat ini, ambil tarif kurir sebagai ongkir, hitung total. Semua di server.
7. Kurangi stok varian, simpan pesanan (status menunggu\_pembayaran) dan detail\_pesanan dengan harga disalin, lalu kosongkan keranjang.
8. Commit dan balas 201 beserta nomor pesanan. Bila jaringan putus sebelum balasan sampai, klien mengulang dengan kunci yang sama dan server membalas pesanan yang sama.

```php
DB::transaction(function () use ($pelangganId, $kunci, $data) {
    $items = Keranjang::where('pelanggan_id', $pelangganId)->get();
    $varian = VarianProduk::whereIn('id', $items->pluck('varian_id'))
        ->orderBy('id')->lockForUpdate()->get()->keyBy('id');
    // cek stok -> throw StokTidakCukup (409) -> rollback otomatis
    // hitung subtotal, ongkir, total di server
    // kurangi stok, simpan pesanan + detail_pesanan, hapus keranjang
});
```

**Dua pembeli memesan unit terakhir:** pembeli pertama mengunci baris varian dan mengurangi stok; pembeli kedua menunggu kunci, lalu membaca stok sudah nol dan menerima 409 tanpa ada perubahan data.

**Perpindahan status pesanan yang sah**

| Dari | Ke yang diizinkan |
| --- | --- |
| menunggu\_pembayaran | menunggu\_konfirmasi, dibatalkan |
| menunggu\_konfirmasi | dibayar, dibatalkan |
| dibayar | diproses |
| diproses | dikirim |
| dikirim | selesai |
| selesai, dibatalkan | (tidak ada; status akhir) |

Perpindahan selain tabel ini, misalnya selesai kembali ke diproses, ditolak server dengan 409. Tombol bayar simulasi di Flutter memanggil PATCH /api/pesanan/{id}/status (menunggu\_pembayaran ke menunggu\_konfirmasi); admin mengonfirmasi ke dibayar.

**Keputusan terbuka:** apakah stok dikembalikan ke varian ketika pesanan dibatalkan. Usulan: ya, di dalam transaksi yang sama dengan perubahan status. Mohon disepakati kelompok.

## 8. Kebutuhan Aplikasi Flutter

**Tujuh halaman wajib**

| Halaman | Isi wajib (khusus domain pakaian ditebalkan) | Perpindahan |
| --- | --- | --- |
| Katalog | GridView.builder, penyaring kategori dan pencarian nama (kirim ulang ?kategori= dan ?cari=), penanda habis, ikon keranjang berlencana | Rincian produk, Keranjang |
| Rincian produk | Semua atribut termasuk **bahan, merek**; **pemilih ukuran dan warna** (varian habis dinonaktifkan); pemilih jumlah; tombol tambah ke keranjang | Katalog, Keranjang |
| Keranjang | Daftar item (**ukuran dan warna tampil**), ubah jumlah, hapus, subtotal dari server | Checkout, Katalog (bila kosong) |
| Checkout | Form nama dan alamat dengan validator berbahasa Indonesia, pemilih kurir dari GET /api/kurir, pemilih metode bayar, ringkasan subtotal + ongkir + total dari server | Rincian pesanan setelah 201; tetap di tempat saat 409 atau 422 |
| Rincian pesanan | Nomor, status, item dengan harga saat pembelian, total, metode bayar, tombol bayar simulasi | Katalog (tumpukan halaman dibersihkan) |
| Riwayat pesanan | Daftar terbaru dulu beserta status | Rincian pesanan |
| Kelola produk | Daftar, tambah, ubah, hapus (dialog konfirmasi), **kelola varian ukuran-warna-stok**; daftar menyegarkan setelah operasi | Formulir produk |

**Empat keadaan layar.** Setiap halaman pemanggil API membedakan enum KeadaanMuat { memuat, berhasil, kosong, galat }. Keadaan kosong terpisah dari galat: daftar kosong adalah hasil sah, ditampilkan dengan keterangan dan saran langkah berikutnya (misalnya "Keranjang masih kosong, ayo lihat katalog").

**Lima jenis galat yang harus tampil berbeda dan terbukti di video**

| Galat | Pemicu simulasi | Tampilan |
| --- | --- | --- |
| Tidak ada sambungan | Matikan php artisan serve | Pesan sambungan gagal + tombol coba lagi |
| Batas waktu | Mode pesawat atau .timeout | Pesan server tidak membalas + tombol coba lagi |
| Validasi 422 | Alamat dikosongkan | Pesan per kolom di bawah kolom |
| Bentrok 409 | Pesan varian berstok nol | Pesan dari server di layar saat ini, tanpa pindah halaman |
| Galat server 500 | Endpoint sengaja melempar galat | Pesan umum + tombol coba lagi, tanpa jejak galat |

**Ketentuan kode Flutter**

- Semua pemanggilan API berada di satu kelas LayananApi; widget tidak memanggil http langsung.
- Alamat server satu konstanta: http://10.0.2.2:8000/api untuk emulator Android.
- Setiap pemanggilan memakai .timeout(const Duration(seconds: 10)) dan hasilnya terlihat di layar.
- Tidak ada pemanggilan jaringan di dalam build; gunakan initState atau FutureBuilder.
- State memakai setState, constructor, dan callback (tanpa Provider).
- Flutter tidak menghitung harga, total, ongkir, atau ketersediaan. Tombol checkout dimatikan selama permintaan berjalan; UUID idempoten dibuat sekali per percobaan dan dipakai ulang saat coba lagi.
- Dilarang: menampilkan e.toString() ke pengguna, blok catch kosong, atau satu pesan galat untuk kelima jenis galat.
- Pengiriman pelanggan\_id atau token statis diletakkan di satu tempat di LayananApi.
- Nilai tambah: lazy load (pagination) pada katalog; Postman collection.

## 9. Data Seed Minimum

Seeder harus berjalan sekali lewat php artisan migrate --seed di komputer bersih. Contoh isi di bawah adalah usulan; nama dan harga boleh diganti kelompok.

| Data | Minimal | Usulan isi |
| --- | --- | --- |
| Kategori | 2 | Pakaian, Aksesori |
| Produk | 12 (tersebar di kedua kategori) | 7 pakaian (kaos, kemeja, hoodie, jaket, celana, rok, dress) dan 5 aksesori (topi, tas, ikat pinggang, kaus kaki, syal) |
| Varian | Beberapa per produk | Pakaian: S, M, L, XL × 2 warna; aksesori: All Size |
| Produk habis | 2 produk berstok nol atau tersedia = false | Satu produk semua variannya 0; satu lagi tersedia = false |
| Varian habis pada produk yang masih ada | 1 contoh | Kaos ukuran M warna Hitam stok 0, sedangkan L masih ada. Ini yang membuktikan aturan bisnis domain |
| Kurir/wilayah | 3 dengan tarif berbeda | Misalnya Dalam Kota 10.000, Luar Kota 20.000, Luar Pulau 35.000 |
| Metode pembayaran | 2 | tunai\_di\_tempat, transfer\_manual |
| Pesanan contoh | 3 dengan status berbeda | menunggu\_pembayaran, dibayar, selesai |
| Pelanggan | 1 tetap | Dipakai sebagai pelanggan\_id atau token statis, dicatat di README |

Deskripsi bernilai null disertakan pada minimal satu produk untuk menguji penanganan null di Flutter.

## 10. Keluaran Pengumpulan

Tiga keluaran dikumpulkan sebelum Pertemuan 8 melalui LMS dan harus saling cocok. Tautan video yang tidak bisa dibuka, repositori privat tanpa undangan, atau dokumentasi yang menyebut endpoint yang tidak ada di kode dinilai tidak lengkap.

**1. Repositori (GitHub atau GitLab)**

```
nama-repositori/
|-- backend/   (Laravel: database/migrations, database/seeders, .env.example)
|-- mobile/    (Flutter: lib/)
`-- README.md
```

README wajib memuat sembilan butir; butir terakhir di bawah mengikuti aturan AI pada Bagian 8 lembar tugas:

- Nama kelompok, nama lengkap, NIM, dan peran tiap anggota.
- Domain bisnis (pakaian dan aksesori) dan aturan khas: stok per varian ukuran-warna.
- Cara menjalankan backend (composer install sampai php artisan serve).
- Cara menjalankan Flutter dan tempat mengubah alamat server.
- Alamat server pengembangan beserta alasan (http://10.0.2.2:8000/api untuk emulator).
- Pelanggan\_id atau token statis untuk penguji.
- Daftar endpoint ringkas dengan tautan ke dokumentasi.
- Tautan video demo.
- Bagian kode yang dibantu AI (tingkat berkas atau fungsi) serta pustaka pihak ketiga yang dipakai.

Setiap anggota memiliki minimal 5 commit atas namanya dengan pesan bermakna; jangan ada satu commit besar "final". Berkas .env asli tidak diunggah.

**2. Dokumentasi endpoint API (PDF, 6 sampai 10 halaman)**

Nama berkas: PAPB-UTS\_Kelompok-02\_Pakaian.pdf (pola tugas: PAPB-UTS_Kelompok-NN_Domain.pdf). Isi tujuh bagian:

1. Diagram relasi antartabel termasuk varian\_produk.
2. Tabel seluruh endpoint: metode, jalur, parameter, kode status.
3. Contoh permintaan dan balasan **nyata** untuk lima endpoint inti: daftar produk, tambah keranjang, lihat keranjang, checkout, rincian pesanan.
4. Cara server menghitung subtotal, ongkir, dan total.
5. Aturan bisnis khas domain dan kode penolakannya (409 untuk varian habis).
6. Cara kerja header X-Kunci-Idempoten.
7. Daftar perpindahan status yang sah.

Koleksi Postman sangat dianjurkan (nilai tambah Kriteria 4).

**3. Video demo (maksimal 5 menit)**

Memuat seluruh adegan wajib, termasuk lima jenis galat dan penyebutan cara memunculkan galat. Tautan dibuka dari peramban lain untuk memastikan izinnya benar.

## 11. Rencana Kerja dan Pembagian Tugas

Tanggal Pertemuan 8 belum tertulis di lembar tugas, jadi rencana disusun berdasarkan urutan tahap. Sesuaikan tenggat tiap tahap setelah tanggal pastinya diketahui.

**Tahap 1. Fondasi (backend dan kontrak)**

- [ ] Sepakati nama jalur, pembungkus respons, dan header pelanggan
- [ ] Migrasi: kategori, produk, varian\_produk, keranjang, kurir, metode\_pembayaran, pesanan, detail\_pesanan
- [ ] Seeder sesuai Bagian 9, uji php artisan migrate --seed dari nol
- [ ] Endpoint produk (CRUD, filter, pencarian) dengan Form Request dan penanganan 404, 422, 409

**Tahap 2. Alur transaksi (backend)**

- [ ] Endpoint keranjang (tambah per varian, ubah, hapus, subtotal dari server)
- [ ] Endpoint kurir, checkout (transaksi, lockForUpdate, idempotensi), pesanan, dan PATCH status dengan validasi perpindahan
- [ ] Uji manual semua endpoint di Postman; uji dua permintaan checkout berturut-turut dengan kunci sama dan kunci berbeda

**Tahap 3. Aplikasi Flutter**

- [ ] Kelas LayananApi, konstanta alamat server, model data dengan fromJson (deskripsi nullable), enum KeadaanMuat
- [ ] Katalog, rincian produk dengan pemilih ukuran-warna, keranjang
- [ ] Checkout, rincian pesanan, riwayat, kelola produk
- [ ] Penanganan lima jenis galat dan keadaan kosong

**Tahap 4. Penyelesaian**

- [ ] Dokumentasi PDF dengan contoh respons hasil panggilan nyata, ekspor Postman
- [ ] README sembilan butir, video demo di bawah 5 menit, cek tautan dari peramban lain
- [ ] Daftar periksa Bagian 12, latihan uji petik antaranggota

**Pembagian anggota (isi sesuai kelompok)**

| Anggota | Peran utama | Commit minimal |
| --- | --- | --- |
| (nama dan NIM) | Backend: skema, seeder, endpoint produk | 5 |
| (nama dan NIM) | Backend: keranjang, checkout, transaksi | 5 |
| (nama dan NIM) | Flutter: katalog, keranjang, checkout | 5 |
| (nama dan NIM) | Flutter: galat, state, dokumentasi, video | 5 |

Pembagian tugas hanya menentukan siapa yang mengerjakan lebih dulu. Pada uji petik, setiap anggota mendapat minimal satu pertanyaan dari kategori yang bukan pekerjaannya, sehingga semua orang perlu membaca kode anggota lain.

## 12. Kriteria Penerimaan, Risiko, dan Kesiapan Uji Petik

**Daftar periksa penerimaan (malam sebelum tenggat)**

- [ ] Repositori terbuka untuk penguji, atau dosen sudah diundang bila privat
- [ ] php artisan migrate --seed berhasil sekali jalan di komputer bersih
- [ ] Minimal 12 produk, 2 berstok nol, 3 kurir, 2 metode bayar, 3 pesanan contoh berstatus beda
- [ ] Seluruh 14 endpoint dipanggil dari Postman dan cocok dengan dokumentasi
- [ ] Varian habis ditolak server dengan 409 (bukti aturan bisnis domain); produk lain tetap bisa dipesan
- [ ] Stok varian benar-benar berkurang setelah checkout (cek langsung di basis data)
- [ ] Checkout yang gagal di tengah tidak mengubah stok
- [ ] Tombol checkout ditekan dua kali, hanya satu pesanan terbentuk
- [ ] Lima jenis galat dicoba satu per satu dan tampilannya berbeda
- [ ] Daftar kosong tampil sebagai keadaan kosong, bukan galat
- [ ] Tidak ada pemanggilan jaringan di build, tidak ada print sisa dan kode mati
- [ ] .env asli tidak terunggah; hanya .env.example
- [ ] Koleksi Postman diekspor dan dilampirkan (nilai tambah Kriteria 4)
- [ ] README sembilan butir, video maksimal 5 menit, PDF bernama sesuai pola
- [ ] Tautan video dibuka dari peramban lain untuk memastikan izinnya benar
- [ ] Tiap anggota minimal 5 commit sendiri, dan sudah membaca kode anggota lain

**Risiko dan penanganan**

| Risiko | Dampak | Penanganan |
| --- | --- | --- |
| Stok dihitung atau divalidasi di Flutter | Kriteria 5 turun ke 1 | Semua keputusan stok di Laravel; Flutter hanya menampilkan pesan server |
| Deadlock saat checkout paralel | Pesanan gagal acak | Kunci varian dengan urutan id yang sama |
| Idempotensi tidak diterapkan | Pesanan ganda saat coba lagi | Kolom kunci\_idempoten unik per pelanggan; UUID baru hanya per percobaan baru |
| Dokumentasi tidak cocok dengan kode | Kriteria 4 turun | Contoh respons diambil dari Postman, bukan ditulis tangan |
| Hanya mengganti nama produk | Kriteria 1 skor 1 | Varian ukuran-warna dengan stok sendiri benar-benar ditegakkan server |
| Anggota tidak memahami kode sendiri | Kriteria 9 nol dan Kriteria 7 turun satu tingkat | Latihan tanya jawab silang memakai bank pertanyaan Pertemuan 8 |
| Backend bermasalah mendekati tenggat | Kriteria 4 dan 5 mentok di tingkat Kurang | Jalur B (MockLayananApi) hanya cadangan; prioritaskan backend sejak Tahap 1 |

**Persiapan uji petik:** setiap anggota harus bisa menunjuk baris tempat stok varian dikurangi, menjelaskan apa yang terjadi bila proses mati tepat setelahnya (rollback transaksi), menjelaskan perbedaan 404, 409, dan 422 dengan contoh dari sistem sendiri, serta mengerjakan salah satu tugas modifikasi lima menit (misalnya menambah keterangan pada kartu produk, atau endpoint jumlah produk per kategori) tanpa bantuan.

## 13. Rubrik dan Pembobotan Resmi

Satu pekerjaan dinilai dengan sembilan kriteria yang sama, tetapi dua pembobotan berbeda, sehingga menghasilkan nilai PAPB dan nilai Sistem Terdistribusi yang terpisah. Kriteria 1 sampai 8 dinilai per kelompok, sedangkan Kriteria 9 dinilai per mahasiswa pada uji petik Pertemuan 8.

```
nilai kriteria = (skor / 4) x bobot kriteria
nilai akhir    = jumlah nilai Kriteria 1 sampai 8 (kelompok)
               + nilai Kriteria 9 (individu)
```

Skor 0 diberikan bila bagian yang dinilai tidak ada sama sekali. Tingkat Kurang (skor 1) berarti bagian itu ada tetapi belum bekerja sebagaimana mestinya.

| Kriteria | Blok | PAPB | ST | Dinilai per |
| --- | --- | --- | --- | --- |
| 1. Penyesuaian domain bisnis dan skema basis data | A. Fungsionalitas dan domain | 8 | 10 | Kelompok |
| 2. Katalog dan CRUD produk | A. Fungsionalitas dan domain | 10 | 5 | Kelompok |
| 3. Keranjang dan checkout | A. Fungsionalitas dan domain | 12 | 8 | Kelompok |
| 4. Kedisiplinan kontrak API dan dokumentasinya | B. Integrasi sistem terdistribusi | 8 | 18 | Kelompok |
| 5. Konsistensi data dan transaksi | B. Integrasi sistem terdistribusi | 8 | 20 | Kelompok |
| 6. Penanganan galat dan ketahanan jaringan | B. Integrasi sistem terdistribusi | 12 | 12 | Kelompok |
| 7. Pengelolaan keadaan dan kualitas kode Flutter | C. Kualitas kode dan keadaan | 20 | 7 | Kelompok |
| 8. Repositori, README, video, dan dokumentasi | D. Keluaran | 7 | 5 | Kelompok |
| 9. Kesiapan uji petik | E. Pertanggungjawaban individu | 15 | 15 | Mahasiswa |
| **Jumlah** |  | **100** | **100** |  |

**Implikasi prioritas:** Kriteria 4 dan 5 menyumbang 38 dari 100 nilai Sistem Terdistribusi, sehingga transaksi atomik, kunci idempoten, penyalinan harga ke detail pesanan, dan keseragaman pembungkus respons adalah pekerjaan bernilai tertinggi di sana. Kriteria 7 menyumbang 20 dari 100 nilai PAPB, sehingga pemisahan empat keadaan layar dan pemusatan seluruh pemanggilan API di satu kelas layanan tidak boleh dikorbankan. Batas jalur tetap berlaku di atas rubrik ini: kelompok jalur B tidak dapat memperoleh skor di atas 2 pada Kriteria 4 dan 5.

## 14. Aturan Penggunaan AI, Kejujuran Akademik, dan Kisi-kisi Uji Petik

**Penggunaan AI.** Alat bantu AI boleh dipakai sebagai asisten pemrograman, dengan syarat:

1. Bagian kode yang dibantu AI dituliskan pada README, cukup pada tingkat berkas atau fungsi.
2. Setiap mahasiswa wajib dapat menjelaskan setiap baris kode yang dikumpulkan kelompoknya.
3. Anggota yang tidak dapat menjelaskan kode yang di-commit-nya sendiri memperoleh nilai nol pada Kriteria 9 dan menurunkan nilai kelompok pada Kriteria 7 satu tingkat.
4. Kode yang tidak dipahami siapa pun di dalam kelompok dinilai sama dengan tidak mengumpulkan bagian tersebut.

Pemakaian pustaka publik dari pub.dev dan Packagist wajar dan tidak mengurangi nilai, sepanjang disebutkan di README dan alasan pemilihannya dapat dijelaskan.

**Kejujuran akademik**

| Perbuatan | Akibat |
| --- | --- |
| Menyalin repositori kelompok lain, seluruhnya atau sebagian besar | Nilai nol bagi kedua kelompok, kecuali terbukti satu pihak tidak mengetahuinya |
| Memakai templat atau proyek jadi dari internet tanpa menyebutkan | Nilai nol pada Kriteria 1, 2, 3, dan 7 |
| Memakai templat, tutorial, atau pustaka pihak ketiga dengan penyebutan di README | Diperbolehkan, dan tidak mengurangi nilai |
| Memakai video demo kelompok lain atau video yang tidak merekam aplikasi sendiri | Nilai nol pada seluruh tugas |
| Mencantumkan nama anggota yang tidak mengerjakan apa pun | Nilai nol pada Kriteria 9 bagi anggota tersebut |

**Kisi-kisi uji petik.** Bank pertanyaan diumumkan sejak awal pada tugas Bagian 10 dan terbagi empat kategori: A keadaan layar dan kode Flutter, B kontrak API, C konsistensi dan transaksi, D domain dan rancangan. Setiap anggota menerima minimal dua pertanyaan, dan minimal satu di antaranya berasal dari kategori yang bukan bagian pekerjaannya. Selain tanya jawab, ada enam tugas modifikasi lima menit (menambah keterangan pada kartu produk, menyaring produk tersedia, menambah validasi checkout, membalik urutan riwayat pesanan, menambah endpoint jumlah produk per kategori, atau menambah tombol coba lagi). Teks lengkap bank pertanyaan dan tugas modifikasi ada pada [`Tugas_UTS_Informatika.md`](Tugas_UTS_Informatika.md) Bagian 10.
