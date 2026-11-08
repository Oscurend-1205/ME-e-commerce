# ME — Toko Online Pakaian & Aksesori (Kelompok 2)

Proyek Tugas Pengganti UTS Berkelompok untuk mata kuliah **Pemrograman Aplikasi Perangkat Bergerak (PAPB)** dan **Sistem Terdistribusi**.

---

## 1. Identitas Kelompok
- **Nama Kelompok:** Kelompok 2
- **Anggota Kelompok:**
  - Auril Aditya 24102018 — Full Stack Developer (Backend Skema & Flutter)
  - Melany Kresna 24102015 — Frontend, Project Manager / Project Leader
  - Devia Amanda Prameswari 24102007 — UI/UX Designer
  - Viqro Tunada Hanunnisa 24102022 — Database Developer
  - Audina Ike Wati 24102028 - API Developer & Technical Documentation
  - Syani Carissa Syawaluna 24102038 - Application Developer & Documentation
  - Fichri Aditya Nugraha 24102010 - Database Developer

------

## 2. Domain Bisnis & Aturan Khas
Aplikasi e-commerce pakaian & aksesori modern terinspirasi gaya editorial minimalis **ZARA**.
- **Pembeda Domain (Kelompok 2):** Stok disimpan secara spesifik per **kombinasi varian (ukuran $\times$ warna)** pada tabel `varian_produk`, bukan satu angka per produk.
- **Aturan Bisnis:** Penambahan ke keranjang dan checkout otomatis ditolak dengan kode status **`409 Conflict`** jika stok varian yang dipilih habis, meskipun varian lain pada produk tersebut masih tersedia.
- **Server-side Truth:** Server Laravel menjadi satu-satunya sumber kebenaran untuk harga, ketersediaan, subtotal, ongkos kirim, dan total belanja.

### Objek Produk dan Tabel Basis Data

**Kunci wajib pada objek produk** (`GET /api/produk` dan `GET /api/produk/{id}`):

| Kunci JSON | Tipe | Asal di basis data |
|---|---|---|
| `id` | integer | `produk.id` |
| `nama` | string | `produk.nama` |
| `harga` | integer (rupiah) | `produk.harga` |
| `kategori` | string | `kategori.nama` lewat `produk.kategori_id` |
| `stok` | integer | jumlah `varian_produk.stok` seluruh varian produk |
| `tersedia` | boolean | `produk.tersedia` |
| `deskripsi` | string atau `null` | `produk.deskripsi` |

Kunci tambahan khas domain: `bahan` dan `merek` (kolom `produk`), serta `ukuran` dan `warna` pada setiap varian (`varian_produk`). Stok tidak disimpan pada produk, melainkan per varian.

**Tabel basis data (9 tabel):**

| Tabel | Isi | Kolom penting |
|---|---|---|
| `kategori` | Kategori produk | `id`, `nama` |
| `produk` | Data produk | `kategori_id`, `nama`, `harga`, `tersedia`, `deskripsi`, `bahan`, `merek`, `gambar` |
| `varian_produk` | Stok per ukuran dan warna | `produk_id`, `ukuran`, `warna`, `stok`, `sku` |
| `pelanggan` | Pelanggan pengujian | `id`, `nama` |
| `keranjang` | Item keranjang | `pelanggan_id`, `produk_id`, `varian_id`, `jumlah` |
| `kurir` | Kurir dan tarif wilayah | `nama`, `wilayah`, `tarif` |
| `metode_pembayaran` | Metode pembayaran | `kode`, `nama` |
| `pesanan` | Pesanan dan total | `nomor_pesanan`, `pelanggan_id`, `kurir_id`, `metode_pembayaran_id`, `nama_penerima`, `alamat`, `subtotal`, `ongkir`, `total`, `status`, `kunci_idempoten` |
| `detail_pesanan` | Item pesanan (salinan harga saat beli) | `pesanan_id`, `produk_id`, `varian_id`, `nama_produk`, `ukuran`, `warna`, `harga_satuan`, `jumlah`, `subtotal` |


Diagram relasi lengkap ada di [docs/api-docs.md](docs/api-docs.md).
---

## 3. Struktur Repositori
Sesuai panduan Bagian 10 PRD:
```text
me-app/
|-- backend/          (Proyek Laravel 12 REST API)
|   |-- app/
|   |   |-- Http/Controllers/Api/   (Controller endpoint REST)
|   |   |-- Models/                 (Produk, Varian, Keranjang, Pesanan, dll.)
|   |   `-- Traits/                 (ApiResponse standard wrapper)
|   |-- database/
|   |   |-- migrations/             (9 Tabel Domain Lengkap)
|   |   `-- seeders/                (DatabaseSeeder dengan data uji Bagian 9)
|   `-- .env.example                (Konfigurasi env tanpa kredensial rahasia)
|-- mobile/           (Proyek Aplikasi Flutter)
|   |-- lib/
|   |   |-- models/                 (Model Dart dengan fromJson)
|   |   |-- screens/                (7 Halaman Wajib + Form Admin)
|   |   |-- services/               (LayananApi tunggal terpusat)
|   |   `-- widgets/                (Komponen 4 keadaan layar & varian)
|   `-- pubspec.yaml
|-- DESIGN.md         (Pedoman desain editorial minimalis)
|-- PRD.md            (Dokumen Persyaratan Produk resmi)
`-- README.md
```

---

## 4. Cara Menjalankan Backend (Laravel)

### Prasyarat:
- PHP >= 8.2 (dengan ekstensi `pdo_sqlite`, `pdo_mysql`, `mbstring`, `openssl`, `intl`, `zip`)
- Composer >= 2.x
- MySQL (Laragon / XAMPP) atau SQLite bawaan

### Langkah Instalasi:
```bash
# 1. Masuk ke folder backend
cd backend

# 2. Siapkan dependency, konfigurasi SQLite, application key, migrasi, dan data contoh
composer run setup

# 3. Jalankan server Laravel
php artisan serve --host=0.0.0.0 --port=8000
```

SQLite dipakai secara default agar backend dapat dicoba tanpa memasang MySQL. Untuk memakai MySQL, sesuaikan `DB_CONNECTION` dan variabel `DB_*` di `backend/.env`, buat database `me_store`, lalu jalankan `php artisan migrate --seed`.

---

## 5. Cara Menjalankan Aplikasi Flutter (Mobile)

### Prasyarat:
- Flutter SDK >= 3.x
- Android Studio / VS Code dengan Android Emulator

### Langkah Menjalankan:
```bash
# 1. Masuk ke folder mobile
cd mobile

# 2. Ambil paket dependensi
flutter pub get

# 3. Jalankan aplikasi ke emulator atau perangkat
flutter run
```

---

## 6. Alamat Server & Konfigurasi Emulator
- **Alamat Server Default:** Android Emulator memakai `http://10.0.2.2:8000/api`; Web/desktop memakai `http://127.0.0.1:8000/api`.
- **Lokasi Konfigurasi di Flutter:**
  [`mobile/lib/constants.dart`](mobile/lib/constants.dart)
  ```dart
  // Konstan.baseUrl memilih alamat emulator Android atau localhost secara otomatis.
  // Atur Konstan.customHost untuk perangkat fisik atau host lain.
  ```
- **Alasan Penggunaan `10.0.2.2`:** Merupakan alias alamat IP khusus pada Android Emulator untuk mengakses `localhost` / `127.0.0.1` pada komputer host development.

---

## 7. Identitas Pelanggan (Pengujian)
- **Header Pelanggan:** `X-Pelanggan-Id: 1`
- **Data Pelanggan Tetap:**
  - `id`: `1`
  - `nama`: `Auril Aditya`

---

## 8. Ringkasan Endpoint Backend

Dokumentasi detail endpoint dan koleksi Postman: [api-docs (1).md](api-docs%20(1).md) dan [ME-Kelompok02.postman_collection.json](docs/ME-Kelompok02.postman_collection.json).

| No | Metode & Jalur | Kegunaan | Status Sukses |
|---|---|---|---|
| 1 | `GET /api/produk` | Daftar produk (?kategori= & ?cari=) | `200 OK` |
| 2 | `GET /api/produk/{id}` | Rincian produk lengkap beserta varian | `200 OK` |
| 3 | `POST /api/produk` | Tambah produk baru beserta varian awal | `201 Created` |
| 4 | `PUT /api/produk/{id}` | Ubah produk dan stok varian | `200 OK` |
| 5 | `DELETE /api/produk/{id}` | Hapus produk (ditolak 409 bila pada pesanan aktif) | `200 OK` |
| 6 | `GET /api/keranjang` | Daftar item keranjang & subtotal server | `200 OK` |
| 7 | `POST /api/keranjang` | Tambah varian ke keranjang (409 bila stok kurang) | `201 Created` |
| 8 | `PUT /api/keranjang/{id}` | Ubah jumlah item keranjang | `200 OK` |
| 9 | `DELETE /api/keranjang/{id}` | Hapus item dari keranjang | `200 OK` |
| 10 | `GET /api/kurir` | Daftar kurir dan tarif wilayah | `200 OK` |
| 11 | `GET /api/metode-pembayaran` | Daftar metode pembayaran yang didukung | `200 OK` |
| 12 | `POST /api/checkout` | Checkout atomik (`X-Kunci-Idempoten`, lockForUpdate) | `201 Created` |
| 13 | `GET /api/pesanan` | Riwayat pesanan (terbaru dulu) | `200 OK` |
| 14 | `GET /api/pesanan/{id}` | Rincian pesanan & snapshot harga pembelian | `200 OK` |
| 15 | `PATCH /api/pesanan/{id}/status` | Ubah status pesanan (409 bila transisi tidak sah) | `200 OK` |
| 16 | `GET /api/gambar/{filename}` | Ambil gambar produk dari storage | `200 OK` |

---

## 9. Bantuan AI
- **Bagian Kode yang Dibantu AI:**
  - Pembuatan boilerplate model Eloquent & migrasi database.
  - Implementasi alur penanganan 5 jenis galat teknis pada UI Flutter.
  - Pustaka pihak ketiga: `http`, `uuid`, `intl` pada Flutter; `laravel/framework` pada Backend.
  - merapikan file & penambahan button
  - add AI assistance section to README
  - add AI contributions for database migration and UI error handling
  - update README.md
    
