<?php

namespace Database\Seeders;

use App\Models\DetailPesanan;
use App\Models\Kategori;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\VarianProduk;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Pelanggan Tetap untuk Pengujian (PRD Bagian 9)
        $pelanggan = Pelanggan::create([
            'id' => 1,
            'nama' => 'Auril Aditya',
        ]);

        // 2. Kategori (Minimal 2: Pakaian & Aksesori)
        $katPakaian = Kategori::create(['nama' => 'Pakaian']);
        $katAksesori = Kategori::create(['nama' => 'Aksesori']);

        // 3. Kurir & Tarif Wilayah (Minimal 3 tarif berbeda)
        $kurirDalamKota = Kurir::create([
            'nama' => 'JNE Reguler',
            'wilayah' => 'Dalam Kota (Jabodetabek)',
            'tarif' => 10000,
        ]);

        $kurirLuarKota = Kurir::create([
            'nama' => 'SiCepat Kilat',
            'wilayah' => 'Luar Kota (Pulau Jawa)',
            'tarif' => 20000,
        ]);

        $kurirLuarPulau = Kurir::create([
            'nama' => 'J&T Express',
            'wilayah' => 'Luar Pulau (Antar Pulau)',
            'tarif' => 35000,
        ]);

        // 4. Metode Pembayaran (Minimal 2: tunai_di_tempat & transfer_manual)
        $metodeCod = MetodePembayaran::create([
            'kode' => 'tunai_di_tempat',
            'nama' => 'Tunai di Tempat (COD)',
        ]);

        $metodeTransfer = MetodePembayaran::create([
            'kode' => 'transfer_manual',
            'nama' => 'Transfer Bank Manual (BCA/Mandiri)',
        ]);

        // 5. 12 Produk Dummy (7 Pakaian + 5 Aksesori)
        // Kasus Khusus PRD:
        // - Kaos Polos: Varian M Hitam stok 0, L masih ada (Pembuktian aturan bisnis domain pakaian!)
        // - Produk 1 habis stok total (stok 0)
        // - Produk 1 tidak tersedia (tersedia = false)
        // - Produk dengan deskripsi null untuk uji null safety Flutter

        // --- 7 PRODUK PAKAIAN ---
        // Produk 1: Kaos Polos Oversize (Dengan varian M Hitam = 0, L = 15)
        $p1 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Kaos Polos Oversize Cotton Combed',
            'harga' => 89000,
            'tersedia' => true,
            'deskripsi' => 'Kaos potongan oversize berbahan 100% katun combed 24s yang sejuk, tebal, dan menyerap keringat dengan baik.',
            'bahan' => 'Katun Combed 24s',
            'merek' => 'ME Basics',
            'gambar' => '1.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p1->id, 'ukuran' => 'S', 'warna' => 'Hitam', 'stok' => 8, 'sku' => 'MEB-1-S-BLK']);
        // Ini varian kunci pengujian: stok 0 untuk M Hitam!
        $vP1MHitam = VarianProduk::create(['produk_id' => $p1->id, 'ukuran' => 'M', 'warna' => 'Hitam', 'stok' => 0, 'sku' => 'MEB-1-M-BLK']);
        $vP1LHitam = VarianProduk::create(['produk_id' => $p1->id, 'ukuran' => 'L', 'warna' => 'Hitam', 'stok' => 15, 'sku' => 'MEB-1-L-BLK']);
        VarianProduk::create(['produk_id' => $p1->id, 'ukuran' => 'M', 'warna' => 'Putih', 'stok' => 12, 'sku' => 'MEB-1-M-WHT']);
        VarianProduk::create(['produk_id' => $p1->id, 'ukuran' => 'L', 'warna' => 'Putih', 'stok' => 20, 'sku' => 'MEB-1-L-WHT']);

        // Produk 2: Kemeja Flanel Slim Fit
        $p2 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Kemeja Flanel Slim Fit Plaid',
            'harga' => 189000,
            'tersedia' => true,
            'deskripsi' => 'Kemeja flanel motif kotak-kotak klasik dengan siluet modern, cocok untuk gaya kasual maupun semi-formal.',
            'bahan' => 'Wool-blend Flanel',
            'merek' => 'ME Studio',
            'gambar' => '2.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p2->id, 'ukuran' => 'M', 'warna' => 'Merah Navy', 'stok' => 10, 'sku' => 'MES-2-M-RED']);
        VarianProduk::create(['produk_id' => $p2->id, 'ukuran' => 'L', 'warna' => 'Merah Navy', 'stok' => 8, 'sku' => 'MES-2-L-RED']);
        VarianProduk::create(['produk_id' => $p2->id, 'ukuran' => 'XL', 'warna' => 'Hijau Botol', 'stok' => 6, 'sku' => 'MES-2-XL-GRN']);

        // Produk 3: Hoodie Heavyweight
        $p3 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Hoodie Heavyweight Fleece Pullover',
            'harga' => 279000,
            'tersedia' => true,
            'deskripsi' => 'Hoodie tebal 380 gsm berbahan fleece lembut dengan saku kangguru dan tali serut tahan lama.',
            'bahan' => 'Heavyweight Cotton Fleece',
            'merek' => 'ME Originals',
            'gambar' => '3.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p3->id, 'ukuran' => 'M', 'warna' => 'Abu-abu Misty', 'stok' => 14, 'sku' => 'MEO-3-M-GRY']);
        VarianProduk::create(['produk_id' => $p3->id, 'ukuran' => 'L', 'warna' => 'Abu-abu Misty', 'stok' => 10, 'sku' => 'MEO-3-L-GRY']);
        VarianProduk::create(['produk_id' => $p3->id, 'ukuran' => 'L', 'warna' => 'Hitam Pekat', 'stok' => 12, 'sku' => 'MEO-3-L-BLK']);

        // Produk 4: Jaket Denim Vintage (Deskripsi bernilai NULL untuk uji Flutter null-safety!)
        $p4 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Jaket Denim Trucker Vintage Wash',
            'harga' => 349000,
            'tersedia' => true,
            'deskripsi' => null, // Nullable test case!
            'bahan' => 'Non-stretch 13oz Denim',
            'merek' => 'ME Denim Co.',
            'gambar' => '4.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p4->id, 'ukuran' => 'M', 'warna' => 'Light Blue Wash', 'stok' => 7, 'sku' => 'MED-4-M-BLU']);
        VarianProduk::create(['produk_id' => $p4->id, 'ukuran' => 'L', 'warna' => 'Light Blue Wash', 'stok' => 9, 'sku' => 'MED-4-L-BLU']);

        // Produk 5: Celana Chino Reguler
        $p5 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Celana Chino Reguler Fit Straight',
            'harga' => 219000,
            'tersedia' => true,
            'deskripsi' => 'Celana panjang chino potongan straight dengan stretch ringan untuk kenyamanan mobilitas harian.',
            'bahan' => 'Twill Cotton Stretch',
            'merek' => 'ME Basics',
            'gambar' => '5.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p5->id, 'ukuran' => '30', 'warna' => 'Khaki', 'stok' => 10, 'sku' => 'MEB-5-30-KHK']);
        VarianProduk::create(['produk_id' => $p5->id, 'ukuran' => '32', 'warna' => 'Khaki', 'stok' => 12, 'sku' => 'MEB-5-32-KHK']);
        VarianProduk::create(['produk_id' => $p5->id, 'ukuran' => '32', 'warna' => 'Hitam', 'stok' => 8, 'sku' => 'MEB-5-32-BLK']);

        // Produk 6: Rok Plisket Midi (Uji Produk Habis Total: Semua varian stok 0!)
        $p6 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Rok Plisket Midi Pleated Skirt',
            'harga' => 139000,
            'tersedia' => true,
            'deskripsi' => 'Rok lipit midi anggun dengan pinggang elastis dan bahan jatuh berkilau lembut.',
            'bahan' => 'Silk Chiffon Pleat',
            'merek' => 'ME Studio',
            'gambar' => '6.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p6->id, 'ukuran' => 'All Size', 'warna' => 'Dusty Pink', 'stok' => 0, 'sku' => 'MES-6-AS-PNK']);
        VarianProduk::create(['produk_id' => $p6->id, 'ukuran' => 'All Size', 'warna' => 'Mocca', 'stok' => 0, 'sku' => 'MES-6-AS-MCC']);

        // Produk 7: Dress Casual Linen (Uji Produk Non-Aktif: tersedia = false!)
        $p7 = Produk::create([
            'kategori_id' => $katPakaian->id,
            'nama' => 'Dress Casual Button Down Linen',
            'harga' => 259000,
            'tersedia' => false, // Non-aktif test case!
            'deskripsi' => 'Gaun santai lengan pendek dengan kancing depan penuh dan saku tersembunyi samping.',
            'bahan' => 'Pure French Linen',
            'merek' => 'ME Minimalist',
            'gambar' => '7.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p7->id, 'ukuran' => 'M', 'warna' => 'Sage Green', 'stok' => 15, 'sku' => 'MEM-7-M-SGE']);
        VarianProduk::create(['produk_id' => $p7->id, 'ukuran' => 'L', 'warna' => 'Sage Green', 'stok' => 10, 'sku' => 'MEM-7-L-SGE']);

        // --- 5 PRODUK AKSESORI ---
        // Produk 8: Topi Baseball Bordir
        $p8 = Produk::create([
            'kategori_id' => $katAksesori->id,
            'nama' => 'Topi Baseball Bordir Minimalis Cap',
            'harga' => 75000,
            'tersedia' => true,
            'deskripsi' => 'Topi baseball 6-panel dengan pengait besi belakang yang dapat disesuaikan.',
            'bahan' => 'Cotton Drill 100%',
            'merek' => 'ME Accessories',
            'gambar' => '8.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p8->id, 'ukuran' => 'All Size', 'warna' => 'Hitam', 'stok' => 25, 'sku' => 'MEA-8-AS-BLK']);
        VarianProduk::create(['produk_id' => $p8->id, 'ukuran' => 'All Size', 'warna' => 'Krem', 'stok' => 18, 'sku' => 'MEA-8-AS-CRM']);

        // Produk 9: Tas Selempang Kanvas
        $p9 = Produk::create([
            'kategori_id' => $katAksesori->id,
            'nama' => 'Tas Selempang Kanvas Crossbody Bag',
            'harga' => 165000,
            'tersedia' => true,
            'deskripsi' => 'Tas selempang praktis anti-air berkapasitas lega untuk membawa ponsel, dompet, dan barang esensial.',
            'bahan' => 'Water-repellent Canvas',
            'merek' => 'ME Accessories',
            'gambar' => '9.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p9->id, 'ukuran' => 'All Size', 'warna' => 'Hitam', 'stok' => 12, 'sku' => 'MEA-9-AS-BLK']);
        VarianProduk::create(['produk_id' => $p9->id, 'ukuran' => 'All Size', 'warna' => 'Army', 'stok' => 14, 'sku' => 'MEA-9-AS-ARM']);

        // Produk 10: Ikat Pinggang Kulit
        $p10 = Produk::create([
            'kategori_id' => $katAksesori->id,
            'nama' => 'Ikat Pinggang Kulit Gesper Metal',
            'harga' => 119000,
            'tersedia' => true,
            'deskripsi' => 'Ikat pinggang formal elegan dengan gesper perak brushed dan jahitan rapi tepi.',
            'bahan' => 'Genuine Cowhide Leather',
            'merek' => 'ME Leatherworks',
            'gambar' => '10.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p10->id, 'ukuran' => 'All Size', 'warna' => 'Cokelat Gelap', 'stok' => 20, 'sku' => 'MEL-10-AS-BRN']);
        VarianProduk::create(['produk_id' => $p10->id, 'ukuran' => 'All Size', 'warna' => 'Hitam', 'stok' => 22, 'sku' => 'MEL-10-AS-BLK']);

        // Produk 11: Kaus Kaki Katun 3-Pack
        $p11 = Produk::create([
            'kategori_id' => $katAksesori->id,
            'nama' => 'Kaus Kaki Crew Ribbed Katun (Isi 3 Pasang)',
            'harga' => 59000,
            'tersedia' => true,
            'deskripsi' => 'Paket hemat kaus kaki crew bertumit ganda dengan karet nyaman tidak mudah melorot.',
            'bahan' => 'Combed Cotton + Spandex',
            'merek' => 'ME Basics',
            'gambar' => '11.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p11->id, 'ukuran' => 'All Size', 'warna' => 'Monokrom Mix', 'stok' => 30, 'sku' => 'MEB-11-AS-MNK']);

        // Produk 12: Syal Rajut Hangat
        $p12 = Produk::create([
            'kategori_id' => $katAksesori->id,
            'nama' => 'Syal Rajut Musim Dingin Woven Scarf',
            'harga' => 129000,
            'tersedia' => true,
            'deskripsi' => 'Syal rajut panjang bermotif waffle knit halus untuk menjaga kehangatan leher.',
            'bahan' => 'Soft Acrylic Wool',
            'merek' => 'ME Studio',
            'gambar' => '12.jpg',
        ]);
        VarianProduk::create(['produk_id' => $p12->id, 'ukuran' => 'All Size', 'warna' => 'Abu Terang', 'stok' => 15, 'sku' => 'MES-12-AS-LGR']);
        VarianProduk::create(['produk_id' => $p12->id, 'ukuran' => 'All Size', 'warna' => 'Burgundy', 'stok' => 11, 'sku' => 'MES-12-AS-BGD']);

        // 6. Data Contoh Keranjang Awal untuk Pelanggan 1
        Keranjang::create([
            'pelanggan_id' => $pelanggan->id,
            'produk_id' => $p1->id,
            'varian_id' => $vP1LHitam->id, // Varian L Hitam yang ada stoknya
            'jumlah' => 1,
        ]);

        // 7. Pesanan Contoh: 3 Pesanan dengan Status Berbeda (menunggu_pembayaran, dibayar, selesai)
        // Pesanan 1: Menunggu Pembayaran
        $pesanan1 = Pesanan::create([
            'nomor_pesanan' => 'ORD-20261105-SAMPLE1',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirDalamKota->id,
            'metode_pembayaran_id' => $metodeTransfer->id,
            'nama_penerima' => 'Auril Aditya',
            'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman, D.I. Yogyakarta',
            'subtotal' => 189000,
            'ongkir' => 10000,
            'total' => 199000,
            'status' => 'menunggu_pembayaran',
            'kunci_idempoten' => 'seed-idempoten-key-001',
        ]);
        DetailPesanan::create([
            'pesanan_id' => $pesanan1->id,
            'produk_id' => $p2->id,
            'varian_id' => $p2->varian()->first()->id,
            'nama_produk' => $p2->nama,
            'ukuran' => 'M',
            'warna' => 'Merah Navy',
            'harga_satuan' => 189000,
            'jumlah' => 1,
            'subtotal' => 189000,
        ]);

        // Pesanan 2: Dibayar
        $pesanan2 = Pesanan::create([
            'nomor_pesanan' => 'ORD-20261104-SAMPLE2',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirLuarKota->id,
            'metode_pembayaran_id' => $metodeTransfer->id,
            'nama_penerima' => 'Auril Aditya',
            'alamat' => 'Jl. Gejayan No. 18, Depok, Sleman, D.I. Yogyakarta',
            'subtotal' => 279000,
            'ongkir' => 20000,
            'total' => 299000,
            'status' => 'dibayar',
            'kunci_idempoten' => 'seed-idempoten-key-002',
        ]);
        DetailPesanan::create([
            'pesanan_id' => $pesanan2->id,
            'produk_id' => $p3->id,
            'varian_id' => $p3->varian()->first()->id,
            'nama_produk' => $p3->nama,
            'ukuran' => 'M',
            'warna' => 'Abu-abu Misty',
            'harga_satuan' => 279000,
            'jumlah' => 1,
            'subtotal' => 279000,
        ]);

        // Pesanan 3: Selesai
        $pesanan3 = Pesanan::create([
            'nomor_pesanan' => 'ORD-20261101-SAMPLE3',
            'pelanggan_id' => $pelanggan->id,
            'kurir_id' => $kurirDalamKota->id,
            'metode_pembayaran_id' => $metodeCod->id,
            'nama_penerima' => 'Auril Aditya',
            'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman, D.I. Yogyakarta',
            'subtotal' => 178000,
            'ongkir' => 10000,
            'total' => 188000,
            'status' => 'selesai',
            'kunci_idempoten' => 'seed-idempoten-key-003',
        ]);
        DetailPesanan::create([
            'pesanan_id' => $pesanan3->id,
            'produk_id' => $p1->id,
            'varian_id' => $vP1LHitam->id,
            'nama_produk' => $p1->nama,
            'ukuran' => 'L',
            'warna' => 'Hitam',
            'harga_satuan' => 89000,
            'jumlah' => 2,
            'subtotal' => 178000,
        ]);
    }
}
