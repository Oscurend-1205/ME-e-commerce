# DESIGN.md --- Fashion Store

## 1. Informasi Proyek

-   **Nama proyek:** ME
-   **Jenis aplikasi:** Website e-commerce pakaian dan aksesori
-   **Referensi desain:** [ZARA Indonesia](https://www.zara.com/id/)
-   **Fokus desain:** Pengalaman belanja fashion yang modern, minimalis,
    elegan, dan mudah digunakan.
-   **Target pengguna:** Pengguna yang ingin melihat koleksi pakaian dan
    aksesori, mencari produk berdasarkan kategori, serta melakukan
    pembelian secara online.

> Catatan: Dokumen ini merupakan panduan desain untuk proyek Fashion
> Store. Referensi ZARA digunakan sebagai inspirasi tata letak,
> pendekatan editorial, dan pengalaman katalog. Identitas merek, aset
> visual, teks, dan implementasi akhir harus dibuat sendiri.

## 2. Tujuan Desain

1.  Menampilkan produk fashion dengan visual yang menarik dan menjadi
    fokus utama.
2.  Memudahkan pengguna menemukan produk melalui kategori dan pencarian.
3.  Memberikan pengalaman belanja yang sederhana dari melihat produk
    hingga checkout.
4.  Membangun kesan merek yang premium tanpa membuat antarmuka terasa
    rumit.
5.  Menjaga konsistensi tampilan pada desktop, tablet, dan perangkat
    mobile.

## 3. Arah Visual dan Referensi

Website ZARA memiliki pendekatan visual editorial: foto fashion
berukuran besar, ruang kosong yang cukup, tipografi yang kuat, serta
navigasi kategori yang terstruktur. Pendekatan tersebut diterapkan pada
Fashion Store dengan penyesuaian berikut:

-   Gunakan foto produk atau model dengan kualitas tinggi.
-   Hindari terlalu banyak ornamen, gradasi, bayangan, dan warna
    mencolok.
-   Berikan jarak antar elemen agar halaman terasa lega.
-   Gunakan judul koleksi yang singkat dan jelas.
-   Utamakan konsistensi ukuran gambar dan informasi produk.

## 4. Identitas Visual

### 4.1 Palet Warna

  Nama             Kode warna   Penggunaan
  ---------------- ------------ ---------------------------------------
  Hitam            `#111111`    Logo, teks utama, tombol utama
  Putih            `#FFFFFF`    Latar belakang utama
  Abu-abu muda     `#F3F3F3`    Latar kartu atau bagian sekunder
  Abu-abu sedang   `#777777`    Teks pendukung dan informasi tambahan
  Abu-abu garis    `#DDDDDD`    Border, pemisah, dan input

Gunakan hitam dan putih sebagai warna utama. Abu-abu hanya digunakan
sebagai pendukung agar tampilan tetap bersih.

### 4.2 Tipografi

-   **Judul dan heading:** Sans-serif tegas dengan bobot medium atau
    bold.
-   **Isi dan deskripsi:** Sans-serif sederhana yang mudah dibaca.
-   **Harga dan label produk:** Ukuran konsisten dan mudah ditemukan.
-   **Gaya penulisan:** Singkat, jelas, dan tidak berlebihan.

Contoh font yang dapat digunakan: Arial, Inter, Helvetica, atau
sans-serif bawaan sistem.

### 4.3 Gaya Komponen

-   Tombol berbentuk persegi atau sedikit membulat.
-   Border tipis berwarna abu-abu.
-   Ikon sederhana dan mudah dikenali.
-   Foto produk menggunakan rasio yang konsisten.
-   Animasi ringan pada hover dan perpindahan halaman.

## 5. Struktur Halaman (Sitemap)

``` text
Fashion Store
├── Beranda
│   ├── Hero Banner
│   ├── Koleksi Terbaru
│   ├── Produk Unggulan
│   └── Kategori Pilihan
├── Katalog Produk
│   ├── Pakaian
│   ├── Atasan
│   ├── Bawahan
│   ├── Outerwear
│   ├── Sepatu
│   └── Aksesori
├── Detail Produk
│   ├── Galeri Foto
│   ├── Nama dan Harga
│   ├── Deskripsi
│   ├── Pilihan Ukuran/Warna
│   └── Tambah ke Keranjang
├── Keranjang
├── Checkout
├── Akun Pengguna
│   ├── Masuk
│   ├── Daftar
│   └── Riwayat Pesanan
└── Bantuan dan Informasi
    ├── Tentang Kami
    ├── Kontak
    └── Kebijakan Pengembalian
```

## 6. Desain dan Isi Setiap Halaman

### 6.1 Beranda (Homepage)

**Tujuan:** Memperkenalkan identitas toko dan mengarahkan pengguna
menuju koleksi produk.

Susunan elemen:

1.  **Header**
    -   Logo Fashion Store di bagian kiri atau tengah.
    -   Menu navigasi: Beranda, Pakaian, Aksesori, Koleksi Terbaru.
    -   Ikon pencarian, akun, dan keranjang di sisi kanan.
    -   Header tetap ringkas agar tidak mengganggu area foto.
2.  **Hero Banner**
    -   Foto fashion berukuran besar sebagai fokus halaman.
    -   Judul kampanye, misalnya "NEW COLLECTION".
    -   Kalimat pendukung singkat.
    -   Tombol "Lihat Koleksi".
3.  **Kategori Pilihan**
    -   Kartu kategori dengan gambar.
    -   Contoh: Atasan, Bawahan, Outerwear, dan Aksesori.
4.  **Koleksi Terbaru**
    -   Grid produk dengan foto, nama, dan harga.
    -   Label "New" untuk produk baru jika diperlukan.
5.  **Produk Unggulan**
    -   Menampilkan produk pilihan toko.
    -   Tombol untuk melihat seluruh produk.
6.  **Footer**
    -   Informasi toko, kontak, bantuan, kebijakan, dan tautan media
        sosial.

### 6.2 Halaman Katalog Produk

**Tujuan:** Membantu pengguna menjelajahi dan memilih produk.

Elemen: - Judul kategori, misalnya "Pakaian Wanita" atau "Aksesori". -
Jumlah produk yang ditampilkan. - Filter kategori, ukuran, warna, dan
rentang harga. - Pengurutan: Terbaru, Harga Terendah, dan Harga
Tertinggi. - Grid produk responsif.

Informasi pada setiap kartu produk: - Foto produk. - Nama produk. -
Harga. - Label produk baru atau diskon jika tersedia. - Pilihan warna
atau indikator variasi bila diperlukan.

### 6.3 Halaman Detail Produk

**Tujuan:** Memberikan informasi lengkap sebelum pengguna membeli
produk.

Elemen: - Galeri foto produk. - Nama produk dan harga. - Deskripsi
singkat. - Pilihan warna. - Pilihan ukuran. - Informasi ketersediaan
stok. - Tombol "Tambah ke Keranjang". - Informasi pengiriman dan
pengembalian. - Rekomendasi produk terkait.

### 6.4 Halaman Keranjang

**Tujuan:** Meninjau produk yang akan dibeli.

Elemen: - Daftar produk yang dipilih. - Foto, nama, ukuran, warna, dan
harga produk. - Pengaturan jumlah produk. - Tombol hapus produk. -
Ringkasan subtotal. - Tombol "Lanjut ke Checkout".

Tampilkan kondisi keranjang kosong dengan pesan yang jelas dan tombol
untuk kembali berbelanja.

### 6.5 Halaman Checkout

**Tujuan:** Memproses pesanan dengan langkah yang mudah dipahami.

Elemen: - Formulir nama penerima. - Nomor telepon. - Alamat
pengiriman. - Pilihan metode pengiriman. - Pilihan metode pembayaran. -
Ringkasan pesanan. - Total pembayaran. - Tombol "Buat Pesanan".

Berikan validasi pada kolom wajib dan tampilkan ringkasan biaya sebelum
pesanan dikonfirmasi.

### 6.6 Halaman Akun Pengguna

**Tujuan:** Memungkinkan pengguna mengelola akun dan pesanan.

Elemen: - Form masuk dan daftar. - Informasi profil. - Alamat
tersimpan. - Riwayat pesanan. - Status pesanan. - Tombol keluar.

## 7. Komponen UI

  -----------------------------------------------------------------------
  Komponen                Deskripsi               Perilaku
  ----------------------- ----------------------- -----------------------
  Header                  Logo dan navigasi utama Menu dapat dibuka pada
                                                  mobile

  Search Bar              Pencarian produk        Menampilkan hasil
                                                  sesuai kata kunci

  Category Card           Gambar dan nama         Mengarahkan ke katalog
                          kategori                kategori

  Product Card            Foto, nama, dan harga   Membuka detail produk

  Filter                  Ukuran, warna,          Memperbarui daftar
                          kategori, harga         produk

  Sort                    Pengurutan produk       Mengubah urutan katalog

  Button                  Tombol aksi utama dan   Memiliki hover, fokus,
                          sekunder                dan status aktif

  Quantity Selector       Pengatur jumlah barang  Jumlah tidak boleh
                                                  kurang dari satu

  Cart Summary            Ringkasan belanja       Menghitung subtotal dan
                                                  total

  Form Input              Kolom data pengguna     Memvalidasi input

  Footer                  Informasi dan tautan    Mengarahkan ke halaman
                                                  informasi
  -----------------------------------------------------------------------

## 8. Tata Letak dan Responsivitas

### Desktop

-   Gunakan lebar konten yang proporsional.
-   Tampilkan katalog dalam 3--4 kolom sesuai lebar layar.
-   Navigasi utama ditampilkan secara horizontal.
-   Hero banner menggunakan foto lebar.

### Tablet

-   Tampilkan katalog dalam 2--3 kolom.
-   Sesuaikan ukuran teks dan jarak komponen.
-   Pastikan menu tetap mudah digunakan.

### Mobile

-   Gunakan menu navigasi ringkas atau hamburger menu.
-   Tampilkan katalog dalam 2 kolom jika ukuran layar memungkinkan.
-   Gunakan tombol dengan area sentuh yang nyaman.
-   Form checkout disusun satu kolom.
-   Pastikan gambar tidak terpotong secara tidak wajar.

## 9. Interaksi dan Alur Pengguna

### Alur Belanja

``` text
Beranda
   ↓
Pilih Kategori
   ↓
Lihat Katalog Produk
   ↓
Pilih Produk
   ↓
Lihat Detail Produk
   ↓
Pilih Ukuran dan Warna
   ↓
Tambah ke Keranjang
   ↓
Periksa Keranjang
   ↓
Checkout
   ↓
Isi Alamat dan Pembayaran
   ↓
Konfirmasi Pesanan
```

### Aturan Interaksi

-   Menu navigasi mengarahkan pengguna ke halaman yang sesuai.
-   Pencarian menampilkan produk yang cocok dengan kata kunci.
-   Filter dapat digunakan bersamaan jika memungkinkan.
-   Tombol tambah ke keranjang memperbarui jumlah item dan subtotal.
-   Pengguna dapat mengubah jumlah atau menghapus produk dari keranjang.
-   Formulir menampilkan pesan kesalahan jika data wajib belum diisi.
-   Tampilkan notifikasi setelah tindakan penting, misalnya produk
    berhasil ditambahkan.

## 10. Konten dan Data Produk

Setiap produk minimal memiliki data berikut:

  Field         Contoh
  ------------- ---------------------------------------
  ID Produk     PRD001
  Nama Produk   Oversized Shirt
  Kategori      Atasan
  Harga         Rp249.000
  Deskripsi     Kemeja kasual dengan potongan longgar
  Ukuran        S, M, L, XL
  Warna         Putih, Hitam
  Stok          20
  Foto          URL atau path gambar produk
  Status        Baru / Tersedia / Habis

Gunakan data produk fiktif untuk kebutuhan pengembangan dan pengujian.
Harga, stok, dan deskripsi harus konsisten di katalog, detail produk,
keranjang, dan checkout.

## 11. Aksesibilitas dan Usability

-   Gunakan kontras warna yang cukup antara teks dan latar.
-   Tambahkan teks alternatif pada gambar produk.
-   Gunakan label pada setiap input formulir.
-   Pastikan navigasi dapat digunakan dengan keyboard.
-   Jangan mengandalkan warna saja untuk menyampaikan status.
-   Tampilkan pesan kesalahan yang spesifik dan mudah dipahami.
-   Jaga ukuran teks agar nyaman dibaca pada layar kecil.

## 12. Prioritas Pengembangan

### Prioritas 1 --- Fitur Utama

-   Beranda.
-   Navigasi kategori.
-   Katalog produk.
-   Detail produk.
-   Keranjang belanja.

### Prioritas 2 --- Proses Transaksi

-   Checkout.
-   Form alamat.
-   Metode pembayaran (dapat berupa simulasi untuk prototipe).
-   Konfirmasi pesanan.

### Prioritas 3 --- Fitur Pendukung

-   Akun pengguna.
-   Riwayat pesanan.
-   Filter dan pengurutan lanjutan.
-   Produk rekomendasi.
-   Halaman bantuan.

## 13. Kriteria Keberhasilan Desain

Desain dianggap memenuhi kebutuhan apabila:

-   Pengguna dapat memahami navigasi tanpa kebingungan.
-   Pengguna dapat menemukan produk berdasarkan kategori.
-   Informasi produk terlihat jelas.
-   Pengguna dapat menambahkan produk ke keranjang.
-   Ringkasan belanja menampilkan jumlah dan total yang benar.
-   Tampilan dapat digunakan pada desktop, tablet, dan mobile.
-   Gaya visual konsisten pada seluruh halaman.

## 14. Referensi

-   Website referensi: [ZARA Indonesia](https://www.zara.com/id/)
-   Tanggal akses referensi: 5 November 2026.
-   Elemen yang dijadikan inspirasi: pendekatan editorial, navigasi
    kategori fashion, foto produk yang dominan, katalog, dan tampilan
    minimalis.

------------------------------------------------------------------------

**Catatan akhir:** `DESIGN.md` ini merupakan pedoman desain awal. Nama
merek, logo, foto produk, teks promosi, dan aset antarmuka Fashion Store
harus menggunakan identitas proyek sendiri.
