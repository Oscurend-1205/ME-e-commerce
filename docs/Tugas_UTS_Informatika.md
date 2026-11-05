## Tugas Pengganti Ujian Tengah Semester

## (Berkelompok)

Aplikasi Toko Online — Alur Katalog, Keranjang, dan Checkout

| Butir | Keterangan |
| --- | --- |
| Mata kuliah | Pemrograman Aplikasi Perangkat Bergerak (2010MWP0507) dan Sistem Terdistribusi |
| Program studi | S1 Informatika, Fakultas Sains dan Teknologi, ITSK RS dr. Soepraoen Kesdam V/BRW |
| Dosen pengampu | Ahsanun Naseh Khudori, S.Kom., M.Kom. |
| Sifat tugas | Berkelompok, memakai kelompok yang sama dengan mata kuliah Sistem Terdistribusi |
| Bobot | 20% nilai akhir pada masing-masing mata kuliah, mengisi komponen UTS |
| Pengumpulan | Sebelum Pertemuan 8, melalui LMS |
| Penilaian langsung | Pertemuan 8, review terarah dan uji petik acak |

## 1. Deskripsi Umum Proyek

Setiap kelompok membangun satu aplikasi toko online yang terdiri atas dua bagian: REST API Laravel sebagai penyedia data dan aplikasi Flutter sebagai pemakainya. Alur aplikasi mulai dari katalog produk, keranjang belanja, sampai halaman checkout. Tugas ini menggantikan ujian tulis Ujian Tengah Semester mata kuliah Sistem

Terdistribusi dan Pemrograman Aplikasi Perangkat Bergerak. Satu tugas dinilai dua kali dengan dua sudut pandang.

Dari sisi Pemrograman Aplikasi Perangkat Bergerak, yang dinilai adalah antarmuka Flutter, konsumsi API dengan paket http, penanganan galat, dan pengaturan keadaan layar. Dari sisi Sistem Terdistribusi, yang dinilai adalah kedisiplinan kontrak API, konsistensi data antara klien dan server, serta perilaku aplikasi ketika jaringan atau server tidak bekerja sebagaimana mestinya. Karena itu, nilai kedua mata kuliah hampir selalu berbeda, dan hal itu memang disengaja.

## Batasan sistem

Tiga batasan berikut berlaku bagi semua kelompok dan dapat dilampaui, tetapi materi yang menjadi dasarnya belum diberikan.

- 1. Pembayaran disimulasikan di dalam sistem sendiri. Kelompok belum disarankan memakai payment gateway pihak ketiga seperti Midtrans, Xendit, atau Stripe. Pembayaran diwujudkan sebagai perubahan status pesanan, misalnya menunggu_pembayaran menjadi menunggu_konfirmasi setelah pembeli menekan tombol bayar, lalu dibayar setelah admin mengonfirmasi. Metode yang tersedia cukup dua, yaitu bayar tunai di tempat dan transfer manual.

- 2. Pengantaran memakai data internal toko. Kelompok belum disarankan memanggil API ekspedisi seperti RajaOngkir, JNE, atau SiCepat. Tabel kurir, wilayah antar, dan tarif disimpan sendiri di basis data Laravel, lalu ongkos kirim dihitung di server berdasarkan wilayah yang dipilih pembeli.

- 3. Belum ada autentikasi penuh. Identitas pembeli diwakili token statis atau pelanggan_id tetap yang disepakati dalam kelompok. Alur login dengan JWT atau OAuth 2.0 baru diajarkan pada Pertemuan 14 dan menjadi bagian Ujian Akhir, bukan tugas ini.


## 2. Capaian Pembelajaran yang Diuji

Tugas ini menguji empat dari tujuh CPMK mata kuliah Pemrograman Aplikasi Perangkat Bergerak.

| CPMK | Rumusan pada RPS | Wujud pembuktian pada tugas ini |
| --- | --- | --- |
|   | 2 Memahami dan menganalisis program android sederhana dan user interface & activity | Halaman katalog, keranjang, dan checkout dibangun dengan widget Flutter; perpindahan antarhalaman memakai Navigator |
|   | 3 Memahami dan menganalisis widget dan debugging | Daftar produk, tata letak adaptif, form alamat, serta penelusuran galat lewat pesan Exception dan DevTools |
|   | 6 Memahami dan menganalisis aplikasi server mysql dan PHP serta mengaplikasikannya pada android | REST API Laravel di atas MySQL dikonsumsi aplikasi Flutter dengan paket http, termasuk penanganan galat dan keadaan muat |
|   | 7 Memahami dan menganalisis tugas besar sesuai topik masing-masing | Satu aplikasi toko online utuh dengan domain berbeda per kelompok, dipertanggungjawabkan pada uji petik Pertemuan 8 |

Dari sisi Sistem Terdistribusi, tiga capaian berikut diuji dari pekerjaan yang sama.

- 1. Menerapkan kontrak antarmuka layanan secara disiplin. Dibuktikan oleh kesesuaian antara dokumentasi endpoint, respons server yang sebenarnya, dan model data di Flutter. Menyambung pokok bahasan pertemuan ke-3, REST API dan API Gateway.

- 2. Menjaga konsistensi data lintas komponen. Dibuktikan oleh perilaku stok, isi keranjang, dan total pesanan yang tetap benar ketika dua permintaan datang berurutan dalam waktu sangat singkat atau ketika pesanan gagal di tengah jalan. Menyambung pokok bahasan pertemuan ke-5 dan ke-6.

- 3. Menangani kegagalan sebagian pada sistem terdistribusi. Dibuktikan oleh perilaku aplikasi ketika server mati, lambat, atau mengembalikan galat, dan oleh kemampuan menjelaskan mengapa kegagalan itu tidak boleh membuat data di server menjadi setengah jadi. Menyambung pokok bahasan pertemuan ke-1.

## 3. Pembagian Domain Bisnis per Kelompok

Setiap kelompok memakai domain toko online yang berbeda, dan perbedaan itu harus terlihat pada struktur basis data serta pada satu aturan bisnis yang memengaruhi checkout. Ketentuan ini memastikan tidak ada kelompok yang dapat menyalin pekerjaan kelompok lain.

Domain yang berbeda saja belum cukup. Kelompok yang hanya mengganti nama produk dari nasi goreng menjadi kaus, tanpa mengubah atribut dan aturannya, dinilai sebagai pekerjaan yang tidak menyesuaikan domain dan kehilangan nilai pada Kriteria 1.


| Kel. | Domain | Atribut dan entitas khas yang wajib ada | Aturan bisnis yang wajib terlihat pada checkout |
| --- | --- | --- | --- |
| 1 | Makanan dan minuman siap saji | Varian porsi atau tingkat kepedasan, catatan pesanan per item, jam buka toko | Checkout ditolak di luar jam buka, dengan pesan yang jelas di aplikasi |
| 2 | Pakaian dan aksesori | Varian ukuran dan warna sebagai stok terpisah, bukan satu angka stok per produk | Stok dikurangi pada tingkat varian; ukuran yang habis tidak dapat dipesan meski produknya masih ada |
| 3 | Elektronik dan gawai | Berat produk dalam gram, masa garansi dalam bulan, nomor seri per unit | Ongkos kirim dihitung server dari total berat keranjang, bukan nilai tetap |
| 4 | Produk pertanian dan kebutuhan harian | Satuan jual yang beragam (kilogram, ikat, pak), penanda produk mudah rusak | Produk mudah rusak dibatasi kuantitas maksimum per pesanan dan hanya dapat memilih slot pengantaran pada hari yang sama |
| 5 | Apotek dan alat kesehatan | Penanda produk yang memerlukan resep, batas kuantitas per pembelian | Pesanan yang memuat produk bertanda resep wajib mengisi nomor resep; tanpa itu checkout ditolak |
| 6 | Buku dan alat tulis | Penanda pre-order, harga grosir mulai kuantitas tertentu | Produk pre-order boleh dipesan meski stok nol dan pesanannya berstatus menunggu stok; harga menyesuaikan kuantitas |

## Ukuran minimum data

Agar pengujian pada Pertemuan 8 dapat dilakukan, basis data setiap kelompok wajib memuat sekurang-kurangnya jumlah berikut saat dikumpulkan.

- Dua kategori produk, dengan sekurang-kurangnya dua belas produk yang tersebar pada kedua kategori

- Sekurang-kurangnya dua produk berstok nol atau bertanda tidak tersedia, untuk menguji penolakan di keranjang

- Tiga kurir atau wilayah antar internal dengan tarif berbeda

- Dua metode pembayaran simulasi, yaitu tunai di tempat dan transfer manual

- Tiga pesanan contoh dengan status berbeda, agar riwayat pesanan tidak kosong saat didemonstrasikan


## 4. Arsitektur dan Kontrak API

Server Laravel adalah satu-satunya sumber kebenaran, dan aplikasi Flutter hanya menampilkan apa yang dihitung server. Apabila harga, total, ongkos kirim, atau ketersediaan dihitung di dalam kode Dart, kelompok kehilangan nilai pada Kriteria 5, sekalipun tampilannya benar.

| Lapisan | Tanggung jawab | Yang dilarang |
| --- | --- | --- |
| MySQL | Menyimpan produk, keranjang, pesanan, detail pesanan, kurir | Menyimpan harga total sebagai satu-satunya sumber tanpa detail per item |
| Laravel | Validasi, perhitungan subtotal dan ongkos kirim, pengurangan stok, perpindahan status pesanan | Mengembalikan HTML atau pesan galat mentah dari basis data |
| Flutter | Menampilkan data, mengirim permintaan, mengelola keadaan layar, menampilkan galat | Menghitung total, memutuskan ketersediaan, atau menyimpan harga hasil hitungan sendiri |

## Endpoint yang wajib tersedia

Empat belas endpoint berikut wajib ada pada setiap kelompok. Nama jalur boleh disesuaikan domain, misalnya /api/obat menggantikan /api/produk, dengan syarat penggantian itu ditulis di dokumentasi API dan dipakai konsisten di kode Flutter.

| Metode dan jalur | Kegunaan | Ketentuan |
| --- | --- | --- |
| GET /api/produk | Daftar produk | Mendukung ?kategori= dan ?cari=; tetap 200 ketika hasilnya kosong |
| GET /api/produk/{id} | Rincian satu produk | 404 bila tidak ditemukan |
| POST /api/produk | Menambah produk | 201 bila berhasil, 422 bila validasi gagal |
| PUT /api/produk/{id} | Mengubah produk | 200 bila berhasil, 404 bila tidak ditemukan |
| DELETE /api/produk/{id} | Menghapus produk | 409 bila produk masih terpakai pada pesanan aktif |
| GET /api/keranjang | Isi keranjang beserta subtotal | Subtotal dihitung server, bukan dijumlah di Flutter |
| POST /api/keranjang | Menambah item ke keranjang | Menerima produk_id dan jumlah; 409 bila stok tidak cukup |
| PUT /api/keranjang/{id} | Mengubah jumlah item | Jumlah nol atau negatif ditolak dengan kode 422 |
| DELETE /api/keranjang/{id} | Menghapus satu item | 200 bila berhasil |
| GET /api/kurir | Daftar kurir atau wilayah antar internal beserta tarif | Dipakai halaman checkout untuk memilih pengantaran |
| POST /api/checkout | Membuat pesanan dari isi keranjang | Wajib menerima header X-Kunci-Idempoten; 201 bila berhasil |
| GET /api/pesanan | Riwayat pesanan | Diurutkan dari yang terbaru |
| GET /api/pesanan/{id} | Rincian pesanan beserta itemnya | Memuat harga saat pembelian, bukan harga produk saat ini |
| PATCH /api/pesanan/{id}/status | Mengubah status pesanan | Hanya menerima perpindahan status yang sah |


## objek wajib pada produk di tabel database

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| id | int | Pengenal produk |
| nama | String | Nama produk |
| harga | int | Rupiah bulat, tanpa pemisah ribuan dan tanpa desimal |
| kategori | String | Salah satu kategori yang didaftarkan kelompok |
| stok | int | Jumlah tersedia; nol berarti tidak dapat dipesan |
| tersedia | bool | Penanda produk aktif, terpisah dari stok |
| deskripsi | String atau null | Boleh bernilai null, dan Flutter wajib menanganinya |

Tujuh kolom di atas adalah batas minimal. Setiap kelompok wajib menambah sekurang-kurangnya dua kolom khas domainnya sesuai Bagian 3, misalnya ukuran dan warna untuk kelompok pakaian atau berat_gram dan garansi_bulan untuk kelompok elektronik. Ketujuh kunci inti tetap harus ada agar rubrik dan uji petik dapat diterapkan secara seragam pada semua kelompok.

## Bentuk respons yang seragam

Seluruh respons memakai satu bentuk pembungkus yang sama, sehingga satu fungsi di Flutter cukup untuk membaca semuanya.

```
{
"status": "sukses",
"code": "200",
"message": "Daftar produk berhasil diambil",
"data": [ { "id": 1, "nama": "...", "harga": 25000 } ]
}
```

Respons gagal memakai pembungkus yang sama, dengan status bernilai gagal dan tambahan kunci errors khusus untuk galat validasi.

```
{
"status": "gagal",
"code": "422",
"message": "Data yang dikirim tidak lengkap",
"errors": { "jumlah": [ "Jumlah harus lebih besar dari nol" ] }
}
```

## Kode status HTTP dan perlakuannya di Flutter

| Kode | Dipakai ketika | Yang harus dilakukan aplikasi Flutter |
| --- | --- | --- |
| 200 | Permintaan baca atau ubah berhasil | Menampilkan data |
| 201 | Data baru berhasil dibuat | Berpindah ke halaman hasil, misalnya rincian pesanan |
| 404 | Sumber daya tidak ditemukan | Menampilkan keadaan kosong, bukan dialog galat teknis |
| 409 | Permintaan bertentangan dengan keadaan server, misalnya stok kurang | Menampilkan pesan dari server dan menolak melanjutkan |
| 422 | Validasi gagal | Menampilkan pesan per kolom dari errors di bawah kolom yang bersangkutan |
| 500 | Galat di sisi server | Menampilkan pesan umum beserta tombol coba lagi, tanpa membocorkan jejak galat |


## Status pesanan yang disepakati

Status pesanan hanya boleh berpindah mengikuti urutan menunggu_pembayaran, menunggu_konfirmasi,

dibayar, diproses, dikirim, lalu selesai. Status dibatalkan hanya boleh dicapai dari 2 status pertama.

Perpindahan yang tidak sah, misalnya dari selesai kembali ke diproses, wajib ditolak server dengan kode 409.

## Perjalanan satu permintaan checkout

Aturan pokoknya ada pada zona bertanda: pengurangan stok, penyimpanan pesanan, dan pengosongan keranjang berada di dalam satu transaksi basis data, sehingga kegagalan pada langkah mana pun akan mengembalikan stok ke keadaan semula. Header X-Kunci-Idempoten berisi satu nilai acak yang dibuat Flutter satu kali untuk setiap percobaan checkout. Apabila klien mengulang permintaan karena balasan tidak sampai, server akan mengenali kunci yang sama dan mengembalikan pesanan yang sudah ada alih-alih membuat pesanan kedua.

## Ketentuan sisi Flutter

- 1. Semua pemanggilan API berada di satu kelas layanan, misalnya LayananApi, dan tidak ditulis langsung di dalam widget.

- 2. Alamat server disimpan dalam satu konstanta. Emulator Android memakai http://10.0.2.2:8000/api, sebab localhost di emulator merujuk pada emulator itu sendiri, bukan laptop.

- 3. Paket jaringan yang dipakai adalah http, sesuai materi Pertemuan 7. Paket lain seperti dio tidak dilarang, tetapi kelompok yang memakainya wajib dapat menjelaskan perbedaannya saat uji petik.

- 4. Setiap pemanggilan diberi batas waktu, misalnya .timeout(const Duration(seconds: 10)), dan batas waktu itu ditangani sebagai galat yang terlihat di layar.


- 5. Tidak boleh ada pemanggilan jaringan di dalam metode build. Pemanggilan awal dilakukan di initState atau melalui FutureBuilder.

## 5. Prasyarat Backend

Setiap kelompok wajib memastikan REST API Laravel domainnya berjalan, karena tanpa itu bagian terbesar rubrik tidak dapat dinilai. Namun, kelompok yang backend-nya mengalami kendala tetap harus dapat menyelesaikan sisi Flutter, sehingga disediakan jalur cadangan yang diakui dengan batas nilai yang berbeda.

| Jalur | Sumber data aplikasi Flutter | Akibat pada rubrik |
| --- | --- | --- |
| A. Backend sendiri | REST API Laravel kelompok sendiri di atas MySQL, dengan skema yang disesuaikan domain | Nilai penuh pada semua kriteria |
| B. Tiruan di dalam aplikasi | Kelas MockLayananApi di dalam proyek Flutter yang mengembalikan Future.delayed berisi data tetap | Kriteria 4 dan 5 paling tinggi pada tingkat Kurang; Kriteria 2, 3, 6, dan 7 tetap dinilai penuh |

Kelompok yang memilih B tidak gagal, tetapi kehilangan nilai pada bagian yang memang tidak dapat dibuktikan.

## Cara memunculkan galat saat merekam video

Kelompok pada jalur A memunculkan galat dengan salah satu cara berikut, dan cara yang dipakai disebutkan dalam video.

- Menghentikan php artisan serve di tengah pemakaian aplikasi, untuk memperlihatkan galat sambungan

- Mengaktifkan mode pesawat pada emulator, untuk memperlihatkan galat batas waktu

- Mengirim formulir alamat dalam keadaan kosong, untuk memperlihatkan galat validasi 422 beserta pesan per kolom

- Memesan produk berstok nol, untuk memperlihatkan galat 409 beserta pesan dari server


## 6. Spesifikasi Fungsional

Aplikasi Flutter memuat tujuh halaman wajib, dan setiap halaman yang memanggil API wajib menangani empat keadaan layar. Daftar di bawah ini adalah batas minimum kelulusan fungsional; butir bertanda nilai tambah hanya menaikkan nilai setelah seluruh butir wajib terpenuhi.

## Halaman yang wajib ada

| Halaman | Isi wajib | Perpindahan |
| --- | --- | --- |
| Katalog | Daftar produk dari GET /api/produk, penyaring kategori, pencarian nama, penanda produk habis | Menuju rincian produk; menuju keranjang melalui ikon dengan lencana jumlah |
| Rincian produk | Seluruh atribut produk termasuk atribut khas domain, pemilih jumlah, tombol tambah ke keranjang | Kembali ke katalog; menuju keranjang setelah berhasil menambah |
| Keranjang | Daftar item, pengubah jumlah, penghapus item, subtotal dari server | Menuju checkout; kembali ke katalog ketika kosong |
| Checkout | Formulir nama dan alamat penerima, pemilih kurir dari GET /api/kurir, pemilih metode pembayaran simulasi, ringkasan subtotal ditambah ongkos kirim | Menuju rincian pesanan setelah 201; tetap di tempat ketika 409 atau 422 |
| Rincian pesanan | Nomor pesanan, status, item beserta harga saat pembelian, total, metode pembayaran, tombol bayar simulasi | Kembali ke katalog dengan tumpukan halaman dibersihkan |
| Riwayat pesanan | Daftar pesanan terurut dari yang terbaru beserta statusnya Menuju rincian pesanan |   |
| Kelola produk | Daftar produk dengan tombol tambah, ubah, dan hapus, memakai keempat endpoint CRUD produk | Menuju formulir produk; kembali dengan hasil berhasil atau batal |

## Katalog dan CRUD produk

- 1. Daftar produk dibangun dengan ListView.builder atau GridView.builder, bukan Column yang memuat seluruh produk.

- 2. Penyaring kategori dan pencarian mengirim ulang permintaan ke server melalui parameter ?kategori= dan ?cari=, bukan menyaring daftar yang sudah ada di memori aplikasi.

- 3. Produk berstok nol atau bertanda tidak tersedia tampil dengan penanda jelas dan tombol tambahnya dimatikan.

- 4. Keempat operasi CRUD produk berjalan dari dalam aplikasi, dan daftar produk menyegarkan diri setelah setiap operasi berhasil.

- 5. Penghapusan produk dimintakan konfirmasi lewat dialog sebelum permintaan dikirim.

## Catatan : Nilai tambah jika menerapkan konsep lazy load

## Keranjang belanja

- 1. Isi keranjang dibaca dari server, sehingga keranjang tetap utuh setelah aplikasi ditutup dan dibuka kembali.

- 2. Subtotal yang tampil berasal dari respons server. Penjumlahan ulang di Dart tidak diperkenankan.

- 3. Penambahan produk yang sudah ada di keranjang cukup menambah jumlahnya, bukan membuat baris kedua.

- 4. Permintaan jumlah yang melebihi stok ditolak server dengan kode 409, dan aplikasi menampilkan pesan dari server tersebut.

- 5. Keranjang kosong tampil sebagai keadaan kosong yang ramah, bukan layar putih atau daftar tanpa isi.


## Checkout dan simulasi transaksi

- 1. Formulir checkout memakai Form beserta validator pada setiap kolom wajib, dengan pesan galat dalam bahasa Indonesia.

- 2. Ongkos kirim berubah ketika pilihan kurir atau wilayah diganti, dan nilainya berasal dari server.

- 3. Tombol checkout dimatikan selama permintaan sedang berjalan, agar satu penekanan tidak menjadi dua pesanan.

- 4. Permintaan checkout menyertakan header X-Kunci-Idempoten yang dibuat sekali per percobaan, dan nilai itu dipakai ulang ketika pengguna menekan tombol coba lagi.

- 5. Checkout yang berhasil mengembalikan nomor pesanan, dan keranjang dikosongkan oleh server tanpa perlu dibersihkan dari sisi aplikasi.

- 6. Aturan bisnis khas domain kelompok, sesuai Bagian 3, benar-benar menolak pesanan yang melanggarnya, dan penolakan itu datang dari server.

- 7. Pembayaran simulasi mengubah status pesanan melalui PATCH /api/pesanan/{id}/status, bukan mengubah tampilan saja.

## Penanganan galat

Lima jenis galat berikut wajib ditangani secara berbeda, dan perbedaannya harus terlihat pada video demo.

| Jenis galat | Penyebab yang disimulasikan | Tampilan yang diharapkan |
| --- | --- | --- |
| Tidak ada sambungan | Server dimatikan atau mode pesawat dinyalakan | Pesan bahwa sambungan ke server gagal, beserta tombol coba lagi |
| Batas waktu terlampaui | Jaringan lambat atau .timeout terpicu | Pesan bahwa server tidak membalas, beserta tombol coba lagi |
| Validasi gagal, 422 | Kolom alamat dibiarkan kosong | Pesan per kolom di bawah kolom yang bersangkutan, bukan satu dialog umum |
| Bentrok keadaan, 409 | Produk berstok nol dipesan | Pesan dari server pada layar yang sedang dibuka, tanpa berpindah halaman |
| Galat server, 500 | Endpoint sengaja dibuat melempar galat | Pesan umum beserta tombol coba lagi, tanpa menampilkan jejak galat |

Tiga hal berikut dinilai sebagai kesalahan, bahkan ketika aplikasi tampak berjalan.

- Menampilkan isi e.toString() apa adanya kepada pengguna

- Menelan galat dalam blok catch yang kosong, sehingga layar diam tanpa penjelasan

- Memakai satu pesan galat yang sama untuk kelima jenis galat di atas

## Pengelolaan keadaan

Pengelolaan keadaan pada tugas ini memakai setState beserta pengiriman data melalui constructor dan callback, sebagaimana diajarkan sampai Pertemuan 6. Provider dan pustaka pengelola keadaan lainnya baru dibahas pada Pertemuan 9 sehingga tidak diwajibkan dan tidak menambah nilai pada tugas ini. Kelompok yang memakainya tetap wajib menjelaskan alasannya saat uji petik.

Setiap halaman yang memanggil API wajib membedakan empat keadaan berikut secara eksplisit, misalnya melalui satu enum.

enum KeadaanMuat { memuat, berhasil, kosong, galat }

| Keadaan | Yang tampil di layar |
| --- | --- |
| memuat | Indikator muat, dan tombol aksi dimatikan |


| Keadaan | Yang tampil di layar |
| --- | --- |
| berhasil | Data yang diminta |
| kosong | Keterangan bahwa data belum ada, beserta saran langkah berikutnya |
| galat | Pesan galat sesuai jenisnya, beserta tombol coba lagi |

Keadaan kosong sengaja dipisahkan dari berhasil, sebab daftar kosong bukan kegagalan dan tidak boleh ditampilkan sebagai galat. Pemisahan inilah yang paling sering terlewat sehingga menjadi butir pemeriksaan pada uji petik Pertemuan 8.


## 7. Ketentuan Pengumpulan

Tiga keluaran dikumpulkan bersama sebelum Pertemuan 8, dan ketiganya harus saling cocok. Tautan video yang tidak dapat dibuka, repositori yang bersifat privat tanpa undangan, atau dokumentasi yang menyebut endpoint yang tidak ada di kode dinilai sebagai keluaran yang tidak lengkap.

## Keluaran 1: repositori

Repositori diletakkan di GitHub atau GitLab dengan susunan berikut, sehingga penguji tidak perlu mencari-cari.

```
nama-repositori/
|-- backend/ proyek Laravel
| |-- database/migrations/
| |-- database/seeders/ wajib memuat data contoh Bagian 3
| `-- .env.example tanpa kata sandi sebenarnya
|-- mobile/ proyek Flutter
| `-- lib/
`-- README.md
```

Berkas README.md wajib memuat sembilan butir berikut. README yang hanya memuat judul proyek dinilai Kurang pada Kriteria 8.

- 1. Nama kelompok, nama lengkap seluruh anggota beserta nomor induk mahasiswa, dan peran masing- masing

- 2. Domain bisnis yang diambil beserta satu aturan bisnis khasnya

- 3. Cara menjalankan backend, dari composer install sampai php artisan serve

- 4. Cara menjalankan aplikasi Flutter, termasuk tempat mengubah alamat server

- 5. Alamat server yang dipakai saat pengembangan beserta alasannya, misalnya http://10.0.2.2:8000/api untuk emulator

- 6. Pengenal pelanggan atau token statis yang dipakai agar penguji dapat langsung mencoba

- 7. Daftar endpoint secara ringkas, dengan tautan ke dokumentasi lengkap

- 8. Tautan video demo

Riwayat commit ikut dinilai. Setiap anggota wajib memiliki sekurang-kurangnya lima commit atas namanya sendiri dengan pesan yang menerangkan perubahannya. Satu commit besar berjudul final pada hari pengumpulan dinilai sebagai bukti bahwa pekerjaan tidak dibagi.

## Keluaran 2: dokumentasi endpoint API

Dokumentasi berupa satu berkas PDF sepanjang enam sampai sepuluh halaman, memuat tujuh bagian berikut.

- 1. Diagram relasi antartabel basis data kelompok, termasuk tabel khas domainnya

- 2. Tabel seluruh endpoint beserta metode, jalur, parameter, dan kode status yang mungkin keluar

- 3. Contoh permintaan dan balasan nyata untuk lima endpoint inti, yaitu daftar produk, tambah keranjang, lihat keranjang, checkout, dan rincian pesanan

- 4. Penjelasan cara server menghitung subtotal, ongkos kirim, dan total

- 5. Penjelasan aturan bisnis khas domain beserta kode status yang dipakai untuk menolaknya

- 6. Penjelasan cara kerja header X-Kunci-Idempoten pada endpoint checkout

- 7. Daftar perpindahan status pesanan yang sah pada domain kelompok

Contoh permintaan dan balasan harus merupakan hasil pemanggilan sungguhan, bukan karangan. Lampiran berupa berkas ekspor koleksi Postman sangat dianjurkan dan menjadi nilai tambah pada Kriteria 4.


## Cara dan nama berkas

Pengumpulan dilakukan melalui LMS, dengan mengisi tautan repositori, dan mengunggah berkas PDF. Nama

berkas PDF mengikuti pola PAPB-UTS_Kelompok-NN_Domain.pdf, misalnya PAPB-UTS_Kelompok-

03_Elektronik.pdf. Masing-masing anggota menggumpulkan tugas kelompok yang sama.

## 8. Penggunaan AI dan Kejujuran Akademik

## Aturan penggunaan kecerdasan buatan

Aturan yang disampaikan pada Pertemuan 1 tetap berlaku dan dipertegas di sini. Alat bantu kecerdasan buatan boleh dipakai sebagai asisten pemrograman, dan setiap mahasiswa wajib dapat menjelaskan setiap baris kode yang dikumpulkan kelompoknya.

- 1. Bagian kode yang dibantu alat kecerdasan buatan dituliskan pada README, cukup pada tingkat berkas atau fungsi.

- 2. Uji petik Pertemuan 8 menguji pemahaman, bukan hafalan. Pertanyaannya menyangkut alasan di balik kode, bukan nama parameter.

- 3. Anggota yang tidak dapat menjelaskan kode yang di-commit-nya sendiri memperoleh nilai nol pada Kriteria 9, dan nilai kelompok pada Kriteria 7 diturunkan satu tingkat.

- 4. Menyerahkan kode yang tidak dipahami seorang pun di dalam kelompok dinilai sama dengan tidak mengumpulkan bagian tersebut.

## Kejujuran akademik

| Perbuatan | Akibat |
| --- | --- |
| Menyalin repositori kelompok lain, seluruhnya atau sebagian besar | Nilai nol bagi kedua kelompok, kecuali terbukti satu pihak tidak mengetahuinya |
| Memakai templat atau proyek jadi dari internet tanpa menyebutkannya | Nilai nol pada Kriteria 1, 2, 3, dan 7 |
| Memakai templat, tutorial, atau pustaka pihak ketiga dengan penyebutan di README | Diperbolehkan, dan tidak mengurangi nilai |
| Memakai video demo kelompok lain atau video yang tidak merekam aplikasi sendiri | Nilai nol pada seluruh tugas |
| Mencantumkan nama anggota yang tidak mengerjakan apa pun | Nilai nol pada Kriteria 9 bagi anggota tersebut |

Pemakaian pustaka publik dari pub.dev dan Packagist adalah hal yang wajar dalam pengembangan perangkat lunak dan tidak termasuk pelanggaran, sepanjang pustaka itu disebutkan dan kelompok dapat menjelaskan alasan pemilihannya.


## 9. Rubrik Penilaian

Satu pekerjaan dinilai dengan sembilan kriteria yang sama, tetapi dengan dua pembobotan yang berbeda, sehingga menghasilkan nilai PAPB dan nilai Sistem Terdistribusi yang terpisah. Kriteria 1 sampai 8 dinilai per kelompok, sedangkan Kriteria 9 dinilai per mahasiswa pada uji petik Pertemuan 8.

## Cara menghitung

```
nilai kriteria = (skor / 4) x bobot kriteria
nilai akhir = jumlah nilai Kriteria 1 sampai 8 (kelompok)
+ nilai Kriteria 9 (individu)
```

Skor 0 diberikan apabila bagian yang dinilai tidak ada sama sekali. Tingkat Kurang, yaitu skor 1, menandakan bagian itu ada tetapi belum bekerja sebagaimana mestinya.

## Ringkasan bobot

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
| Jumlah |   | 100 | 100 |   |

Perbedaan pembobotan itu disengaja. Mata kuliah PAPB memberikan bobot lebih besar pada kualitas kode dan keadaan layar, yaitu Kriteria 7, sedangkan Sistem Terdistribusi memberikan bobot lebih besar pada kontrak antarlayanan dan konsistensi data, yaitu Kriteria 4 dan 5.

Batas yang disebut pada Bagian 5 tetap berlaku di atas rubrik ini. Kelompok pada jalur B tidak dapat memperoleh skor di atas 2 pada Kriteria 4 dan 5, dan kelompok pada jalur C tidak dapat memperoleh skor di atas 1 pada kedua kriteria tersebut.

## Kriteria 1. Penyesuaian domain bisnis dan skema basis data

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Skema memuat seluruh atribut khas domain, dan aturan bisnis khasnya benar-benar ditegakkan server pada saat checkout. Entitas tambahan dirancang sendiri, bukan salinan contoh kelas |
| 3 Baik | Atribut khas domain ada dan aturan bisnisnya menolak pesanan yang melanggar, tetapi penegakannya terjadi di sisi Flutter, bukan di server |
| 2 Cukup | Atribut khas domain ada di basis data, tetapi tidak ada satu pun aturan bisnis yang benar-benar menolak pesanan |


| Skor | Deskriptor |
| --- | --- |
| 1 Kurang | Hanya nama produk yang diganti; skema dan atributnya sama dengan contoh kelas |

## Kriteria 2. Katalog dan CRUD produk

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Keempat operasi CRUD berjalan dari dalam aplikasi, penyaring dan pencarian dikerjakan server, produk habis ditandai dan tombolnya dimatikan, daftar dibangun dengan ListView.builder atau GridView.builder |
| 3 Baik | Keempat operasi berjalan, tetapi penyaring atau pencarian dikerjakan atas daftar yang sudah ada di memori aplikasi |
| 2 Cukup | Hanya baca dan tambah yang berjalan; ubah atau hapus produk belum dapat dilakukan dari aplikasi |
| 1 Kurang | Hanya daftar produk yang tampil, tanpa penyaring, pencarian, maupun operasi tulis |

## Kriteria 3. Keranjang dan checkout

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Seluruh alur dari katalog sampai pesanan tersimpan berjalan; subtotal dan ongkos kirim berasal dari server; ongkos berubah ketika kurir diganti; pembayaran simulasi mengubah status melalui endpoint |
| 3 Baik | Alur sampai pesanan tersimpan berjalan, tetapi ongkos kirim bernilai tetap atau status pembayaran hanya berubah di tampilan |
| 2 Cukup | Keranjang berjalan dan checkout menyimpan pesanan, tetapi totalnya tidak cocok dengan isi keranjang atau keranjang tidak dikosongkan |
| 1 Kurang | Checkout belum menyimpan pesanan di server; halaman berhasil hanya berupa tampilan |

## Kriteria 4. Kedisiplinan kontrak API dan dokumentasinya

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Seluruh endpoint wajib ada, bentuk pembungkus respons seragam, dokumentasi cocok dengan perilaku server pada setiap endpoint yang diuji penguji, contoh permintaan dan balasan merupakan hasil pemanggilan nyata, koleksi Postman dilampirkan |
| 3 Baik | Seluruh endpoint ada dan dokumentasinya cocok, tetapi bentuk pembungkus respons tidak seragam pada beberapa endpoint |
| 2 Cukup | Ada endpoint yang didokumentasikan tetapi tidak ada di kode, atau ada endpoint di kode yang tidak terdokumentasi |
| 1 Kurang | Dokumentasi endpoint tidak ada, atau isinya tidak berhubungan dengan kode yang dikumpulkan |

## Kriteria 5. Konsistensi data dan transaksi

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Pengurangan stok, penyimpanan pesanan, dan pengosongan keranjang berada dalam satu transaksi dengan baris produk dikunci; checkout yang gagal tidak meninggalkan perubahan apa pun; kunci idempoten mencegah pesanan ganda; harga disalin ke detail pesanan |
| 3 Baik | Transaksi dipakai dan stok tetap konsisten, tetapi kunci idempoten belum diterapkan atau harga tidak disalin ke detail pesanan sehingga pesanan lama berubah ketika harga produk diubah |
| 2 Cukup | Stok dikurangi tanpa transaksi, sehingga kegagalan di tengah proses dapat meninggalkan data setengah jadi |


| Skor | Deskriptor |
| --- | --- |
| 1 Kurang | Stok atau total dihitung di sisi Flutter, atau stok tidak berubah sama sekali setelah checkout |

## Kriteria 6. Penanganan galat dan ketahanan jaringan

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Kelima jenis galat pada Bagian 6 ditangani dengan tampilan yang berbeda dan terbukti di video; galat validasi tampil per kolom; setiap pemanggilan memiliki batas waktu dan tombol coba lagi; tidak ada jejak galat teknis yang tampil kepada pengguna |
| 3 Baik | Kelima jenis galat tertangani, tetapi dua di antaranya memakai pesan yang sama, atau tombol coba lagi belum tersedia di semua halaman |
| 2 Cukup | Hanya galat sambungan yang ditangani; galat validasi 422 dan bentrok 409 belum dibedakan dari galat umum |
| 1 Kurang | Galat membuat aplikasi diam tanpa penjelasan, berhenti, atau menampilkan isi e.toString() kepada pengguna |

## Kriteria 7. Pengelolaan keadaan dan kualitas kode Flutter

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Keempat keadaan dibedakan secara eksplisit pada setiap halaman pemanggil API, keadaan kosong terpisah dari keadaan galat, seluruh pemanggilan terkumpul di satu kelas layanan, tidak ada pemanggilan jaringan di dalam build, penamaan berkas dan kelas konsisten, tidak ada kode mati yang ditinggalkan |
| 3 Baik | Keempat keadaan dibedakan, tetapi sebagian pemanggilan API masih tertulis langsung di dalam widget |
| 2 Cukup | Hanya keadaan memuat dan berhasil yang dibedakan; daftar kosong ditampilkan sebagai galat atau sebagai layar kosong |
| 1 Kurang | Tidak ada pembedaan keadaan; layar berubah tanpa indikator, atau terdapat pemanggilan jaringan di dalam build |

## Kriteria 8. Repositori, README, video, dan dokumentasi

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Susunan repositori sesuai ketentuan, README memuat sembilan butir, seeder berhasil dijalankan dalam sekali eksekusi, setiap anggota memiliki sekurang-kurangnya lima commit bermakna, video memuat seluruh adegan wajib dalam lima menit |
| 3 Baik | Seluruh keluaran ada dan dapat dibuka, tetapi satu butir README hilang atau sebaran commit antaranggota tidak merata |
| 2 Cukup | Video melebihi lima menit atau tidak memuat demonstrasi galat; README hanya memuat cara menjalankan |
| 1 Kurang | Salah satu dari tiga keluaran tidak ada, tidak dapat dibuka, atau seeder tidak dapat dijalankan sehingga aplikasi tidak dapat diuji |

## Kriteria 9. Kesiapan uji petik, dinilai per mahasiswa

| Skor | Deskriptor |
| --- | --- |
| 4 Sangat baik | Menjawab seluruh pertanyaan dengan benar, termasuk alasan di balik rancangan, dan menyelesaikan tugas modifikasi langsung tanpa bantuan |


| Skor | Deskriptor |
| --- | --- |
| 3 Baik | Menjawab sebagian besar pertanyaan dengan benar dan menyelesaikan tugas modifikasi setelah satu kali petunjuk |
| 2 Cukup | Menjelaskan dengan baik bagian yang ia kerjakan sendiri, tetapi tidak memahami bagian anggota lain yang ditanyakan |
| 1 Kurang | Tidak dapat menjelaskan kode yang di-commit-nya sendiri |

## Contoh perhitungan

Misalkan sebuah kelompok memperoleh skor 4 pada Kriteria 1, 3, 5, dan 6; skor 3 pada Kriteria 2, 4, dan 8; serta skor 2 pada Kriteria 7.

| Kriteria | Skor | Nilai PAPB | Nilai ST |
| --- | --- | --- | --- |
| 1 | 4 | 8,0 | 10,0 |
| 2 | 3 | 7,5 | 3,8 |
| 3 | 4 | 12,0 | 8,0 |
| 4 | 3 | 6,0 | 13,5 |
| 5 | 4 | 8,0 | 20,0 |
| 6 | 4 | 12,0 | 12,0 |
| 7 | 2 | 10,0 | 3,5 |
| 8 | 3 | 5,3 | 3,8 |
| Jumlah kelompok |   | 68,8 | 74,5 |

Anggota dengan skor uji petik 4 memperoleh tambahan 15,0 sehingga nilai PAPB-nya 83,8 dan nilai Sistem Terdistribusi 89,5. Anggota dengan skor 2 memperoleh tambahan 7,5 sehingga nilainya 76,3 dan 82,0. Contoh ini memperlihatkan dua hal: kualitas kode yang lemah pada Kriteria 7 menurunkan nilai PAPB jauh lebih besar daripada nilai Sistem Terdistribusi, dan uji petik menjadi pembeda antaranggota dalam satu kelompok yang sama.


## 10. Sesi Pertemuan 8 dan Kisi-kisi Uji Petik

Pertemuan 8 bukan presentasi, melainkan pemeriksaan. Kelompok tidak menyiapkan slide, dan yang dibuka pada hari itu adalah kode, Postman, serta basis data yang sudah dikumpulkan.

| Waktu | Kegiatan |
| --- | --- |
| 10 menit | Pembukaan, penjelasan aturan sesi, dan undian urutan kelompok |
| 90 menit | Uji petik enam kelompok, lima belas menit per kelompok |
| 40 menit | Review terarah bersama atas tiga kesalahan yang paling sering muncul hari itu |
| 10 menit | Penutup dan pengarahan menuju Pertemuan 9 |

Lima belas menit per kelompok dibagi menjadi tiga bagian: tiga menit demonstrasi singkat atas satu alur yang diminta penguji secara acak, tujuh menit tanya jawab dengan anggota yang ditunjuk undian, dan lima menit tugas modifikasi langsung di laptop kelompok.

Pengacakan dilakukan di depan kelompok. Penguji mengundi nomor anggota, lalu mengundi nomor pertanyaan dari bank pertanyaan di bawah ini. Setiap anggota menerima sekurang-kurangnya dua pertanyaan, dan sekurang-kurangnya satu di antaranya berasal dari kategori yang bukan bagian pekerjaannya sendiri. Ketentuan terakhir itu penting: tugas ini menilai pemahaman kelompok, bukan pembagian tugas yang rapi, tetapi anggotanya tidak memahami pekerjaan satu sama lain.

Anggota yang tidak hadir pada Pertemuan 8 memperoleh skor 0 pada Kriteria 9. Mahasiswa dengan alasan ketidakhadiran yang sah diuji pada kesempatan terpisah paling lambat Pertemuan 10.

Seluruh pertanyaan diumumkan sejak awal melalui daftar berikut. Pertanyaan-pertanyaan ini tidak dapat dihafal: semuanya meminta Anda menunjuk baris kode sendiri atau menerangkan akibat dari sebuah pilihan rancangan.

## Kategori A: keadaan layar dan kode Flutter

- 1. Tunjukkan di kode tempat keadaan memuat diubah, lalu terangkan mengapa keadaan itu perlu dibedakan dari keadaan kosong.

- 2. Apa yang terjadi bila setState dipanggil setelah halaman ditutup, dan bagaimana kode kelompok Anda mencegah hal itu?

- 3. Mengapa pemanggilan API tidak boleh diletakkan di dalam build? Apa akibatnya bila tetap dilakukan?

- 4. Di mana isi keranjang disimpan ketika pengguna berpindah dari katalog ke halaman keranjang, dan mengapa di tempat itu?

- 5. Tunjukkan tempat batas waktu ditetapkan. Bila batas waktu itu dihapus, apa yang dilihat pengguna ketika server mati?

- 6. Mengapa daftar produk Anda memakai builder dan bukan Column? Apa yang terjadi bila produknya menjadi seribu?

## Kategori B: kontrak API

- 1. Pilih satu endpoint dalam dokumentasi Anda, lalu panggil endpoint itu sekarang. Apakah balasannya sama dengan yang tertulis?

- 2. Apa yang dibalas server Anda ketika GET /api/produk tidak menemukan apa pun, dan mengapa bukan 404?

- 3. Apa beda 404, 409, dan 422 pada sistem Anda? Berikan satu contoh nyata untuk masing-masing.

- 4. Kunci apa saja yang boleh bernilai null pada objek produk Anda, dan bagaimana Flutter menanganinya?


- 5. Bila besok backend Anda mengubah nama kunci harga menjadi price, bagian mana saja di Flutter yang rusak?

- 6. Mengapa pembungkus respons dibuat seragam? Apa yang terjadi bila satu endpoint membalas daftar mentah tanpa pembungkus?

## Kategori C: konsistensi dan transaksi

- 1. Tunjukkan baris kode tempat stok dikurangi. Apa yang terjadi bila proses mati tepat setelah baris itu dijalankan?

- 2. Dua pembeli memesan unit terakhir pada saat yang hampir sama. Terangkan apa yang terjadi di server Anda, langkah demi langkah.

- 3. Mengapa harga disalin ke tabel detail pesanan? Apa yang terjadi pada pesanan lama bila tidak disalin?

- 4. Tombol checkout tertekan dua kali karena jaringan lambat. Berapa pesanan yang terbentuk, dan apa yang membuatnya begitu?

- 5. Di mana total pesanan dihitung? Buktikan sekarang bahwa Flutter tidak menghitungnya sendiri.

- 6. Bila keranjang dikosongkan sebelum pesanan tersimpan, kerugian apa yang mungkin dialami pembeli?

## Kategori D: domain dan rancangan

- 1. Apa aturan bisnis khas domain Anda, dan di baris mana server menolak pesanan yang melanggarnya?

- 2. Tunjukkan satu tabel yang tidak akan ada pada domain kelompok lain, lalu terangkan mengapa tabel itu diperlukan.

- 3. Bila domain Anda ditukar dengan domain kelompok lain, bagian mana dari kode Anda yang harus diubah dan bagian mana yang tetap?

- 4. Status pesanan apa saja yang mungkin pada domain Anda, dan perpindahan mana yang kelompok Anda larang? Mengapa?

- 5. Bagaimana ongkos kirim dihitung pada domain Anda, dan mengapa cara itu yang dipilih?

- 6. Sebutkan satu keputusan rancangan yang kelompok Anda sesali, dan apa yang akan diubah bila ada waktu seminggu lagi.

## Tugas modifikasi langsung

Satu tugas diundi per kelompok dan dikerjakan dalam lima menit di laptop kelompok, dengan seluruh anggota boleh berdiskusi. Yang dinilai bukan kecepatan, melainkan apakah kelompok tahu berkas mana yang harus

dibuka.

- 1. Tambahkan satu keterangan baru pada kartu produk di katalog, diambil dari kunci yang sudah ada di

- respons server. 2. Ubah penyaring kategori agar sekaligus menyaring hanya produk yang tersedia. 3. Tambahkan satu validasi baru pada satu kolom formulir checkout, lalu perlihatkan pesan galatnya muncul. 4. Ubah urutan daftar riwayat pesanan menjadi dari yang terlama ke yang terbaru. 5. Tambahkan satu endpoint baru di Laravel yang membalas jumlah produk per kategori, lalu panggil dari Postman.

- 6. Tambahkan tombol coba lagi pada satu halaman yang belum memilikinya.


## 11. Daftar Periksa Sebelum Mengumpulkan

Seluruh butir berikut diperiksa sendiri oleh kelompok pada malam sebelum tenggat. Setiap butir yang belum tercentang berarti nilai yang hilang, dan hampir semuanya dapat diselesaikan dalam beberapa menit.

Repositori dapat dibuka oleh penguji, atau dosen sudah diundang sebagai kolaborator bila repositorinya privat

php artisan migrate --seed berhasil dijalankan dalam sekali eksekusi di komputer yang bersih

Basis data memuat sekurang-kurangnya dua belas produk, dua di antaranya berstok nol

Tiga kurir atau wilayah antar internal sudah terisi dengan tarif berbeda

Seluruh endpoint wajib dipanggil sekali dari Postman dan hasilnya sesuai dokumentasi

Aturan bisnis khas domain diuji sampai server benar-benar menolak pesanan

Stok benar-benar berkurang setelah checkout, diperiksa langsung di basis data

Checkout yang gagal di tengah tidak meninggalkan perubahan stok

Tombol checkout ditekan dua kali berturut-turut dan hanya satu pesanan terbentuk

Kelima jenis galat dicoba satu per satu di aplikasi dan tampilannya berbeda

Daftar kosong tampil sebagai keadaan kosong, bukan sebagai galat

Tidak ada pemanggilan jaringan di dalam metode build

Tidak ada print sisa penelusuran galat dan tidak ada kode mati yang ditinggalkan

Berkas .env sebenarnya tidak ikut terunggah, hanya .env.example

README memuat kesembilan butir Bagian 7

Video berdurasi tidak lebih dari lima menit dan tautannya dibuka dari peramban lain untuk memastikan izinnya benar

Berkas PDF dokumentasi API dinamai sesuai pola yang ditentukan

Setiap anggota memiliki sekurang-kurangnya lima commit atas namanya sendiri

Setiap anggota sudah membaca kode anggota lain sekurang-kurangnya sekali

Proyek ini dilanjutkan pada Pertemuan 9 sampai 14. Kelompok tidak membuat proyek baru, dan setiap pertemuan hanya menambah satu lapisan pada aplikasi yang sudah ada. Token statis yang dipakai pada tugas ini digantikan alur login penuh pada Pertemuan 14. Karena itu, kelompok dianjurkan meletakkan pengiriman token di satu tempat saja di kelas layanan, agar penggantiannya nanti cukup satu berkas.
