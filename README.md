# ME — Toko Online Pakaian & Aksesori (Kelompok 2)

Proyek Tugas Pengganti UTS Berkelompok untuk mata kuliah **Pemrograman Aplikasi Perangkat Bergerak (PAPB)** dan **Sistem Terdistribusi**.

---

## 1. Identitas Kelompok
- **Nama Kelompok:** Kelompok 2
- **Anggota Kelompok:**
  - Auril Aditya 24102018 — Full Stack Developer (Backend Skema & Flutter)
  - Melany Kresna 24102015 — Backend, Project Manager / Project Leader
  - Devia Amanda Prameswari 24102007 — UI/UX Designer
  - Viqro Tunada Hanunnisa 24102022 — UI/UX Designer & Database Support
  - Audina Ike Wati 24102028 - API Developer & Technical Documentation
  - Syani Carissa Syawaluna 24102038 - Application Developer & Documentation
  - Fichri Aditya Nugraha 24102010 - Database Developer

---

## 2. Domain Bisnis & Aturan Khas
Aplikasi e-commerce pakaian & aksesori modern terinspirasi gaya editorial minimalis **ZARA**.
- **Pembeda Domain (Kelompok 2):** Stok disimpan secara spesifik per **kombinasi varian (ukuran $\times$ warna)** pada tabel `varian_produk`, bukan satu angka per produk.
- **Aturan Bisnis:** Penambahan ke keranjang dan checkout otomatis ditolak dengan kode status **`409 Conflict`** jika stok varian yang dipilih habis, meskipun varian lain pada produk tersebut masih tersedia.
- **Server-side Truth:** Server Laravel menjadi satu-satunya sumber kebenaran untuk harga, ketersediaan, subtotal, ongkos kirim, dan total belanja.

---

## 3. Struktur Repositori
Sesuai panduan Bagian 10 PRD:
```text
me-app/
|-- backend/          (Proyek Laravel 11/12/13 REST API)
|   |-- app/
|   |   |-- Http/Controllers/Api/   (14 Endpoint Controller)
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
- PHP >= 8.2 (dengan ekstensi `pdo`, `pdo_mysql` / `pdo_sqlite`, `mbstring`, `openssl`)
- Composer >= 2.x
- MySQL (Laragon / XAMPP) atau SQLite bawaan

### Langkah Instalasi:
```bash
# 1. Masuk ke folder backend
cd backend

# 2. Pasang dependensi PHP
composer install

# 3. Salin berkas lingkungan
cp .env.example .env

# 4. Generate Application Key
php artisan key:generate

# 5. Jalankan migrasi dan seeder data contoh
php artisan migrate --seed

# 6. Jalankan server Laravel
php artisan serve --host=0.0.0.0 --port=8000
```

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
- **Alamat Server Default:** `http://10.0.2.2:8000/api`
- **Lokasi Konfigurasi di Flutter:**
  [`mobile/lib/constants.dart`](file:///mobile/lib/constants.dart)
  ```dart
  class Konstan {
    static const String baseUrl = 'http://10.0.2.2:8000/api';
    static const int pelangganId = 1;
    static const Duration batasWaktu = Duration(seconds: 10);
  }
  ```
- **Alasan Penggunaan `10.0.2.2`:** Merupakan alias alamat IP khusus pada Android Emulator untuk mengakses `localhost` / `127.0.0.1` pada komputer host development.

---

## 7. Identitas Pelanggan (Pengujian)
- **Header Pelanggan:** `X-Pelanggan-Id: 1`
- **Data Pelanggan Tetap:**
  - `id`: `1`
  - `nama`: `Auril Aditya`

---

## 8. Ringkasan 14 Endpoint Backend

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

---

## 9. Bantuan AI
- **Bagian Kode yang Dibantu AI:**
  - Pembuatan boilerplate model Eloquent & migrasi database.
  - Implementasi alur penanganan 5 jenis galat teknis pada UI Flutter.
  - Pustaka pihak ketiga: `http`, `uuid`, `intl` pada Flutter; `laravel/framework` pada Backend.
  - merapikan file & penambahan button
    
