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
use App\Models\User;
use App\Models\VarianProduk;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schema;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 0. Akun Admin untuk Panel Filament (/admin)
        User::updateOrCreate(
            ['email' => 'admin@toko-me.test'],
            [
                'name' => 'Admin Toko ME',
                'password' => 'password',
            ],
        );

        // 0b. Aset Tampilan (Gambar Banner/Beranda) yang dapat diedit dari Filament
        $this->call(AsetTampilanSeeder::class);

        // Nonaktifkan foreign keys dan bersihkan tabel transaksi & katalog agar seeder bersifat idempoten
        Schema::disableForeignKeyConstraints();
        DetailPesanan::query()->delete();
        Pesanan::query()->delete();
        Keranjang::query()->delete();
        VarianProduk::query()->delete();
        Produk::query()->delete();
        Kategori::query()->delete();
        Pelanggan::query()->delete();
        Kurir::query()->delete();
        MetodePembayaran::query()->delete();
        Schema::enableForeignKeyConstraints();

        // 1. Pelanggan Tetap untuk Pengujian (PRD Bagian 9)
        $pelanggan = Pelanggan::create([
            'id' => 1,
            'nama' => 'Auril Aditya',
            'email' => 'auril@toko-me.test',
            'password' => 'password',
            'no_telp' => '081234567890',
        ]);

        // 2. Kategori: Atasan, Bawahan, Aksesori (menggantikan Pakaian & Aksesori)
        $katAtasan = Kategori::create(['nama' => 'Atasan']);
        $katBawahan = Kategori::create(['nama' => 'Bawahan']);
        $katAksesori = Kategori::create(['nama' => 'Aksesori']);

        $kategoriMap = [
            'Atasan' => $katAtasan,
            'Bawahan' => $katBawahan,
            'Aksesori' => $katAksesori,
        ];

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

        $metodeQris = MetodePembayaran::create([
            'kode' => 'qris',
            'nama' => 'QRIS (Quick Response Code Indonesian Standard)',
        ]);

        // 5. 36 Produk ME (Kelompok 2): Atasan 15, Bawahan 12, Aksesori 9
        $daftarProduk = [
            [
                'id' => 1,
                'nama' => 'Kaos Polos Oversize Cotton Combed',
                'kategori' => 'Atasan',
                'harga' => 89000,
                'bahan' => 'Katun Combed 24s',
                'merek' => 'ME Basics',
                'deskripsi' => 'Kaos potongan oversize berbahan 100% katun combed 24s yang sejuk, tebal, dan menyerap keringat dengan baik.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Hitam', 'Putih'],
                'stok_nol' => ['M/Hitam'],
            ],
            [
                'id' => 2,
                'nama' => 'Kemeja Flanel Slim Fit Plaid',
                'kategori' => 'Atasan',
                'harga' => 189000,
                'bahan' => 'Wool-blend Flanel',
                'merek' => 'ME Studio',
                'deskripsi' => 'Kemeja flanel motif kotak-kotak klasik dengan siluet modern, cocok untuk gaya kasual maupun semi-formal.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Merah Navy', 'Hijau Botol'],
                'stok_nol' => [],
            ],
            [
                'id' => 3,
                'nama' => 'Hoodie Heavyweight Fleece Pullover',
                'kategori' => 'Atasan',
                'harga' => 279000,
                'bahan' => 'Heavyweight Cotton Fleece',
                'merek' => 'ME Originals',
                'deskripsi' => 'Hoodie tebal 380 gsm berbahan fleece lembut dengan saku kangguru dan tali serut tahan lama.',
                'tersedia' => true,
                'ukuran' => ['M', 'L'],
                'warna' => ['Abu-abu Misty', 'Hitam Pekat'],
                'stok_nol' => [],
            ],
            [
                'id' => 4,
                'nama' => 'Jaket Denim Trucker Vintage Wash',
                'kategori' => 'Atasan',
                'harga' => 349000,
                'bahan' => 'Non-stretch 13oz Denim',
                'merek' => 'ME Denim Co.',
                'deskripsi' => null, // Uji Flutter null-safety
                'tersedia' => true,
                'ukuran' => ['M', 'L'],
                'warna' => ['Light Blue Wash'],
                'stok_nol' => [],
            ],
            [
                'id' => 5,
                'nama' => 'Celana Chino Reguler Fit Straight',
                'kategori' => 'Bawahan',
                'harga' => 219000,
                'bahan' => 'Twill Cotton Stretch',
                'merek' => 'ME Basics',
                'deskripsi' => 'Celana panjang chino potongan straight dengan stretch ringan untuk kenyamanan mobilitas harian.',
                'tersedia' => true,
                'ukuran' => ['30', '32'],
                'warna' => ['Khaki', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 6,
                'nama' => 'Rok Plisket Midi Pleated Skirt',
                'kategori' => 'Bawahan',
                'harga' => 139000,
                'bahan' => 'Silk Chiffon Pleat',
                'merek' => 'ME Studio',
                'deskripsi' => 'Rok lipit midi anggun dengan pinggang elastis dan bahan jatuh berkilau lembut.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Dusty Pink', 'Mocca'],
                'stok_nol' => ['All Size/Dusty Pink', 'All Size/Mocca'],
            ],
            [
                'id' => 7,
                'nama' => 'Dress Casual Button Down Linen',
                'kategori' => 'Atasan',
                'harga' => 259000,
                'bahan' => 'Pure French Linen',
                'merek' => 'ME Minimalist',
                'deskripsi' => 'Gaun santai lengan pendek dengan kancing depan penuh dan saku tersembunyi samping.',
                'tersedia' => false, // Non-aktif test case
                'ukuran' => ['M', 'L'],
                'warna' => ['Sage Green'],
                'stok_nol' => [],
            ],
            [
                'id' => 8,
                'nama' => 'Topi Baseball Bordir Minimalis Cap',
                'kategori' => 'Aksesori',
                'harga' => 75000,
                'bahan' => 'Cotton Drill 100%',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Topi baseball 6-panel dengan pengait besi belakang yang dapat disesuaikan.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Hitam', 'Krem'],
                'stok_nol' => [],
            ],
            [
                'id' => 9,
                'nama' => 'Tas Selempang Kanvas Crossbody Bag',
                'kategori' => 'Aksesori',
                'harga' => 165000,
                'bahan' => 'Water-repellent Canvas',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Tas selempang praktis anti-air berkapasitas lega untuk membawa ponsel, dompet, dan barang esensial.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Hitam', 'Army'],
                'stok_nol' => [],
            ],
            [
                'id' => 10,
                'nama' => 'Ikat Pinggang Kulit Gesper Metal',
                'kategori' => 'Aksesori',
                'harga' => 119000,
                'bahan' => 'Genuine Cowhide Leather',
                'merek' => 'ME Leatherworks',
                'deskripsi' => 'Ikat pinggang formal elegan dengan gesper perak brushed dan jahitan rapi tepi.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Cokelat Gelap', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 11,
                'nama' => 'Kaus Kaki Crew Ribbed Katun (Isi 3 Pasang)',
                'kategori' => 'Aksesori',
                'harga' => 59000,
                'bahan' => 'Combed Cotton + Spandex',
                'merek' => 'ME Basics',
                'deskripsi' => 'Paket hemat kaus kaki crew bertumit ganda dengan karet nyaman tidak mudah melorot.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Monokrom Mix'],
                'stok_nol' => [],
            ],
            [
                'id' => 12,
                'nama' => 'Syal Rajut Musim Dingin Woven Scarf',
                'kategori' => 'Aksesori',
                'harga' => 129000,
                'bahan' => 'Soft Acrylic Wool',
                'merek' => 'ME Studio',
                'deskripsi' => 'Syal rajut panjang bermotif waffle knit halus untuk menjaga kehangatan leher.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Abu Terang', 'Burgundy'],
                'stok_nol' => [],
            ],
            [
                'id' => 13,
                'nama' => 'Blouse Satin Lengan Panjang Wanita',
                'kategori' => 'Atasan',
                'harga' => 169000,
                'bahan' => 'Satin',
                'merek' => 'ME Studio',
                'deskripsi' => 'Blouse satin feminin berpotongan longgar elegan dengan kilau lembut mewah, cocok untuk tampilan formal maupun pesta.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Putih Gading', 'Hitam', 'Dusty Pink'],
                'stok_nol' => ['M/Hitam'],
            ],
            [
                'id' => 14,
                'nama' => 'Kemeja Linen Oversize Wanita',
                'kategori' => 'Atasan',
                'harga' => 199000,
                'bahan' => 'Linen',
                'merek' => 'ME Minimalist',
                'deskripsi' => 'Kemeja santai bersiluet loose fit dari bahan linen alami yang adem, bertekstur estetik, dan nyaman seharian.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Krem', 'Hijau Sage'],
                'stok_nol' => [],
            ],
            [
                'id' => 15,
                'nama' => 'Cardigan Rajut Crop Wanita',
                'kategori' => 'Atasan',
                'harga' => 179000,
                'bahan' => 'Rajut akrilik',
                'merek' => 'ME Basics',
                'deskripsi' => 'Cardigan rajut dengan potongan crop trendi berdetail kancing depan, memberi nuansa chic dan hangat.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Cokelat Susu', 'Abu Muda'],
                'stok_nol' => [],
            ],
            [
                'id' => 16,
                'nama' => 'Tank Top Ribbed Wanita',
                'kategori' => 'Atasan',
                'harga' => 69000,
                'bahan' => 'Katun ribbed',
                'merek' => 'ME Basics',
                'deskripsi' => 'Tank top katun bertekstur rusuk elastis yang pas memeluk tubuh, esensial untuk dalaman maupun pakaian santai.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Hitam', 'Putih'],
                'stok_nol' => [],
            ],
            [
                'id' => 17,
                'nama' => 'Sweater Turtleneck Rajut Wanita',
                'kategori' => 'Atasan',
                'harga' => 219000,
                'bahan' => 'Rajut wool blend',
                'merek' => 'ME Studio',
                'deskripsi' => 'Sweater kerah tinggi hangat bermaterial campuran wool rajut halus yang lembut di kulit dan tidak gatal.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Maroon', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 18,
                'nama' => 'Kemeja Oxford Lengan Panjang Pria',
                'kategori' => 'Atasan',
                'harga' => 209000,
                'bahan' => 'Katun oxford',
                'merek' => 'ME Studio',
                'deskripsi' => 'Kemeja lengan panjang bahan oxford premium dengan kerah button-down berkarakter rapi dan maskulin.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Biru Muda', 'Putih'],
                'stok_nol' => [],
            ],
            [
                'id' => 19,
                'nama' => 'Polo Shirt Pique Pria',
                'kategori' => 'Atasan',
                'harga' => 129000,
                'bahan' => 'Katun pique',
                'merek' => 'ME Basics',
                'deskripsi' => 'Kaos polo klasik berpori sarang lebah yang sejuk dengan kerah elastis tahan kerut untuk gaya sporty kasual.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Navy', 'Hitam', 'Putih'],
                'stok_nol' => [],
            ],
            [
                'id' => 20,
                'nama' => 'Kaos Raglan Lengan Panjang Pria',
                'kategori' => 'Atasan',
                'harga' => 99000,
                'bahan' => 'Katun combed',
                'merek' => 'ME Basics',
                'deskripsi' => 'Kaos lengan panjang dua warna model sambungan raglan untuk gaya santai bernuansa retro.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Abu Misty', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 21,
                'nama' => 'Kemeja Batik Modern Lengan Pendek Pria',
                'kategori' => 'Atasan',
                'harga' => 175000,
                'bahan' => 'Katun primisima',
                'merek' => 'ME Originals',
                'deskripsi' => 'Kemeja batik cetak kontemporer bahan katun primisima halus, pas badan dengan motif bernilai seni tinggi.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Cokelat Sogan', 'Biru Indigo'],
                'stok_nol' => [],
            ],
            [
                'id' => 22,
                'nama' => 'Jaket Bomber Pria',
                'kategori' => 'Atasan',
                'harga' => 329000,
                'bahan' => 'Parasut',
                'merek' => 'ME Originals',
                'deskripsi' => 'Jaket bomber fungsional berbahan parasut windproof dengan lapisan dalam hangat dan resleting logam kokoh.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Hitam', 'Hijau Army'],
                'stok_nol' => ['*'], // stok 0 semua varian (produk tersedia tetapi habis)
            ],
            [
                'id' => 23,
                'nama' => 'Celana Kulot Linen Wanita',
                'kategori' => 'Bawahan',
                'harga' => 169000,
                'bahan' => 'Linen',
                'merek' => 'ME Minimalist',
                'deskripsi' => 'Celana kulot lebar berbahan linen sejuk dengan pinggang berkaret belakang yang nyaman untuk aktivitas santai.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Hitam', 'Krem'],
                'stok_nol' => [],
            ],
            [
                'id' => 24,
                'nama' => 'Rok Mini A-Line Denim Wanita',
                'kategori' => 'Bawahan',
                'harga' => 149000,
                'bahan' => 'Denim',
                'merek' => 'ME Denim Co.',
                'deskripsi' => 'Rok mini siluet A-line denim kokoh dengan saku depan fungsional yang memberi tampilan youthful dan kasual.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Biru Wash', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 25,
                'nama' => 'Celana Jeans Slim Fit Pria',
                'kategori' => 'Bawahan',
                'harga' => 259000,
                'bahan' => 'Denim stretch',
                'merek' => 'ME Denim Co.',
                'deskripsi' => 'Celana jeans pria pola slim fit dengan serat stretch fleksibel yang leluasa mengikuti pergerakan kaki.',
                'tersedia' => true,
                'ukuran' => ['29', '30', '31', '32'],
                'warna' => ['Biru Tua', 'Hitam'],
                'stok_nol' => ['32/Hitam'],
            ],
            [
                'id' => 26,
                'nama' => 'Celana Jogger Cargo Pria',
                'kategori' => 'Bawahan',
                'harga' => 189000,
                'bahan' => 'Katun twill',
                'merek' => 'ME Originals',
                'deskripsi' => 'Celana jogger berkantong samping cargo dengan ujung kaki berkerut rib yang trendi dan praktis.',
                'tersedia' => true,
                'ukuran' => ['M', 'L', 'XL'],
                'warna' => ['Olive', 'Hitam'],
                'stok_nol' => [],
            ],
            [
                'id' => 27,
                'nama' => 'Kacamata Persegi Frame Acetate',
                'kategori' => 'Aksesori',
                'harga' => 149000,
                'bahan' => 'Acetate',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Kacamata bingkai persegi tegas bermaterial acetate ringan yang tahan gores dan nyaman dipakai harian.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Hitam', 'Tortoise', 'Bening'],
                'stok_nol' => [],
            ],
            [
                'id' => 28,
                'nama' => 'Kacamata Bulat Retro Metal',
                'kategori' => 'Aksesori',
                'harga' => 129000,
                'bahan' => 'Stainless steel',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Kacamata berbingkai bulat tipis gaya vintage dengan material stainless steel antikarat dan nose pad empuk.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Emas', 'Perak'],
                'stok_nol' => ['All Size/Perak'],
            ],
            [
                'id' => 29,
                'nama' => 'Sabuk Anyaman Kanvas',
                'kategori' => 'Aksesori',
                'harga' => 79000,
                'bahan' => 'Kanvas',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Ikat pinggang anyam elastis berbahan serat kanvas tangguh dengan gesper pin ganda yang fleksibel.',
                'tersedia' => true,
                'ukuran' => ['90 cm', '100 cm', '110 cm'],
                'warna' => ['Hitam', 'Khaki'],
                'stok_nol' => [],
            ],
            [
                'id' => 30,
                'nama' => 'Topi Bucket Katun',
                'kategori' => 'Aksesori',
                'harga' => 85000,
                'bahan' => 'Katun twill',
                'merek' => 'ME Accessories',
                'deskripsi' => 'Topi bucket katun twill dengan jahitan presisi dan ventilasi udara, cocok untuk perlindungan cuaca luar ruangan.',
                'tersedia' => true,
                'ukuran' => ['All Size'],
                'warna' => ['Krem', 'Hitam', 'Olive'],
                'stok_nol' => [],
            ],
            [
                'id' => 31,
                'nama' => 'Rok Midi Satin Wanita',
                'kategori' => 'Bawahan',
                'harga' => 189000,
                'bahan' => 'Satin',
                'merek' => 'ME Studio',
                'deskripsi' => 'Rok panjang midi satin bersiluet bias cut yang jatuh anggun mengikuti lekuk gerak tubuh.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Champagne', 'Hitam', 'Hijau Botol'],
                'stok_nol' => [],
            ],
            [
                'id' => 32,
                'nama' => 'Rok Pensil Span Lipit Wanita',
                'kategori' => 'Bawahan',
                'harga' => 139000,
                'bahan' => 'Span scuba',
                'merek' => 'ME Basics',
                'deskripsi' => 'Rok kerja pensil span bahan scuba tebal elastis dengan aksen lipit rapi yang menunjang siluet profesional.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Hitam', 'Abu Tua'],
                'stok_nol' => [],
            ],
            [
                'id' => 33,
                'nama' => 'Celana Palazzo Wanita',
                'kategori' => 'Bawahan',
                'harga' => 159000,
                'bahan' => 'Crinkle',
                'merek' => 'ME Minimalist',
                'deskripsi' => 'Celana palazzo pipa lebar dari bahan katun crinkle bertekstur unik, flowy dan adem dipakai seharian.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Krem', 'Hitam', 'Terakota'],
                'stok_nol' => [],
            ],
            [
                'id' => 34,
                'nama' => 'Celana Bahan Slack Pria',
                'kategori' => 'Bawahan',
                'harga' => 229000,
                'bahan' => 'Wool blend',
                'merek' => 'ME Studio',
                'deskripsi' => 'Celana formal bahan wool blend premium berpotongan tailored rapi dengan lipatan presisi depan.',
                'tersedia' => true,
                'ukuran' => ['29', '30', '31', '32'],
                'warna' => ['Hitam', 'Abu Tua', 'Navy'],
                'stok_nol' => ['29/Navy'],
            ],
            [
                'id' => 35,
                'nama' => 'Celana Pendek Chino Pria',
                'kategori' => 'Bawahan',
                'harga' => 119000,
                'bahan' => 'Katun twill',
                'merek' => 'ME Basics',
                'deskripsi' => 'Celana pendek chino selutut dari bahan katun twill kokoh untuk gaya akhir pekan santai dan kasual.',
                'tersedia' => true,
                'ukuran' => ['29', '30', '31', '32'],
                'warna' => ['Khaki', 'Navy', 'Olive'],
                'stok_nol' => [],
            ],
            [
                'id' => 36,
                'nama' => 'Rok Tenis Pleated Mini Wanita',
                'kategori' => 'Bawahan',
                'harga' => 119000,
                'bahan' => 'Poliester',
                'merek' => 'ME Originals',
                'deskripsi' => 'Rok mini lipit tenis bergaya sporty preppy dengan furing celana dalaman yang aman dan nyaman bergerak.',
                'tersedia' => true,
                'ukuran' => ['S', 'M', 'L'],
                'warna' => ['Putih', 'Navy', 'Hitam'],
                'stok_nol' => [],
            ],
        ];

        $merekPrefix = [
            'ME Basics' => 'MEB',
            'ME Studio' => 'MES',
            'ME Originals' => 'MEO',
            'ME Denim Co.' => 'MED',
            'ME Minimalist' => 'MEM',
            'ME Accessories' => 'MEA',
            'ME Leatherworks' => 'MEL',
        ];

        $warnaPrefix = [
            'Hitam' => 'HTM',
            'Putih' => 'PTH',
            'Putih Gading' => 'PTH',
            'Merah Navy' => 'MNV',
            'Hijau Botol' => 'HBT',
            'Abu-abu Misty' => 'MST',
            'Hitam Pekat' => 'HTM',
            'Light Blue Wash' => 'BLU',
            'Khaki' => 'KHK',
            'Dusty Pink' => 'PNK',
            'Mocca' => 'MCC',
            'Sage Green' => 'SGE',
            'Hijau Sage' => 'SGE',
            'Krem' => 'KRM',
            'Army' => 'ARM',
            'Hijau Army' => 'ARM',
            'Cokelat Gelap' => 'CKG',
            'Monokrom Mix' => 'MNK',
            'Abu Terang' => 'ABU',
            'Burgundy' => 'BGD',
            'Cokelat Susu' => 'CSU',
            'Abu Muda' => 'ABU',
            'Maroon' => 'MRN',
            'Biru Muda' => 'BLU',
            'Navy' => 'NVY',
            'Abu Misty' => 'ABU',
            'Cokelat Sogan' => 'CSG',
            'Biru Indigo' => 'IND',
            'Biru Wash' => 'BLU',
            'Biru Tua' => 'BTU',
            'Olive' => 'OLV',
            'Tortoise' => 'TRT',
            'Bening' => 'BNG',
            'Emas' => 'EMS',
            'Perak' => 'PRK',
            'Champagne' => 'CMP',
            'Abu Tua' => 'ATU',
            'Terakota' => 'TRK',
        ];

        $ukuranPrefix = function (string $ukuran): string {
            if (str_starts_with($ukuran, 'All Size')) {
                return 'AS';
            }
            if (str_ends_with($ukuran, ' cm')) {
                return trim(str_replace(' cm', '', $ukuran));
            }

            return $ukuran;
        };

        $p1 = null;
        $p2 = null;
        $p3 = null;
        $vP1LHitam = null;

        foreach ($daftarProduk as $item) {
            $kat = $kategoriMap[$item['kategori']];

            $produk = Produk::forceCreate([
                'id' => $item['id'],
                'kategori_id' => $kat->id,
                'nama' => $item['nama'],
                'harga' => $item['harga'],
                'tersedia' => $item['tersedia'],
                'deskripsi' => $item['deskripsi'],
                'bahan' => $item['bahan'],
                'merek' => $item['merek'],
                'gambar' => $item['id'] . '.jpg',
            ]);

            if ($item['id'] === 1) {
                $p1 = $produk;
            } elseif ($item['id'] === 2) {
                $p2 = $produk;
            } elseif ($item['id'] === 3) {
                $p3 = $produk;
            }

            $prefixMerek = $merekPrefix[$item['merek']] ?? 'ME';

            foreach ($item['ukuran'] as $uk) {
                foreach ($item['warna'] as $wr) {
                    $kunciVarian = "{$uk}/{$wr}";
                    $apakahStokNol = in_array('*', $item['stok_nol'], true) || in_array($kunciVarian, $item['stok_nol'], true);

                    if ($apakahStokNol) {
                        $stok = 0;
                    } else {
                        // Stok normal antara 5 sampai 25 per varian
                        $stok = 8 + (($item['id'] * 7 + strlen($uk) * 3 + strlen($wr) * 5) % 15);
                    }

                    $uCode = $ukuranPrefix($uk);
                    $wCode = $warnaPrefix[$wr] ?? strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $wr), 0, 3));
                    $sku = "{$prefixMerek}-{$item['id']}-{$uCode}-{$wCode}";

                    $varian = VarianProduk::create([
                        'produk_id' => $produk->id,
                        'ukuran' => $uk,
                        'warna' => $wr,
                        'stok' => $stok,
                        'sku' => $sku,
                    ]);

                    if ($item['id'] === 1 && $uk === 'L' && $wr === 'Hitam') {
                        $vP1LHitam = $varian;
                    }
                }
            }
        }

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

        // Sinkronisasi data katalog & foto dari snapshot tim jika ada
        if (file_exists(database_path('data/katalog.json'))) {
            Artisan::call('katalog:import');
        }
    }
}
