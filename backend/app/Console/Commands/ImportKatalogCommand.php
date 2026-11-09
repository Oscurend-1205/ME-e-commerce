<?php

namespace App\Console\Commands;

use App\Models\AsetTampilan;
use App\Models\Kategori;
use App\Models\Produk;
use App\Models\VarianProduk;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;

class ImportKatalogCommand extends Command
{
    protected $signature = 'katalog:import {--fresh : Bersihkan produk lama sebelum import}';

    protected $description = 'Impor data kategori, produk, varian, dan aset tampilan dari database/data/katalog.json ke database lokal';

    public function handle(): int
    {
        $targetFile = database_path('data/katalog.json');
        if (!File::exists($targetFile)) {
            $this->error("File snapshot tidak ditemukan di: {$targetFile}");
            $this->comment('Jalankan "php artisan katalog:export" terlebih dahulu atau jalankan "php artisan db:seed".');
            return Command::FAILURE;
        }

        $this->info("Membaca data katalog dari: {$targetFile}");
        $json = File::get($targetFile);
        $data = json_decode($json, true);

        if (!$data || !isset($data['produks'])) {
            $this->error('Format data katalog.json tidak valid.');
            return Command::FAILURE;
        }

        Schema::disableForeignKeyConstraints();

        if ($this->option('fresh')) {
            $this->warn('Membersihkan data produk dan varian lama...');
            VarianProduk::truncate();
            Produk::truncate();
            Kategori::truncate();
            AsetTampilan::truncate();
        }

        // 1. Kategori
        $kategoriMap = [];
        foreach ($data['kategoris'] ?? [] as $katData) {
            $kategori = Kategori::updateOrCreate(
                ['id' => $katData['id']],
                ['nama' => $katData['nama']]
            );
            $kategoriMap[$katData['id']] = $kategori;
        }

        // 2. Produk & Varian
        $totalProduk = 0;
        $totalVarian = 0;
        foreach ($data['produks'] ?? [] as $prodData) {
            $produk = Produk::updateOrCreate(
                ['id' => $prodData['id']],
                [
                    'kategori_id' => $prodData['kategori_id'],
                    'nama' => $prodData['nama'],
                    'harga' => $prodData['harga'],
                    'tersedia' => $prodData['tersedia'] ?? true,
                    'deskripsi' => $prodData['deskripsi'] ?? null,
                    'bahan' => $prodData['bahan'] ?? null,
                    'merek' => $prodData['merek'] ?? null,
                    'gambar' => $prodData['gambar'] ?? null,
                ]
            );
            $totalProduk++;

            if (isset($prodData['varian']) && is_array($prodData['varian'])) {
                foreach ($prodData['varian'] as $varData) {
                    VarianProduk::updateOrCreate(
                        [
                            'produk_id' => $produk->id,
                            'ukuran' => $varData['ukuran'],
                            'warna' => $varData['warna'],
                        ],
                        [
                            'stok' => $varData['stok'],
                            'sku' => $varData['sku'] ?? null,
                        ]
                    );
                    $totalVarian++;
                }
            }
        }

        // 3. Aset Tampilan
        $totalAset = 0;
        foreach ($data['aset_tampilans'] ?? [] as $asetData) {
            AsetTampilan::updateOrCreate(
                ['kunci' => $asetData['kunci']],
                [
                    'nama' => $asetData['nama'],
                    'grup' => $asetData['grup'] ?? 'Beranda',
                    'urutan' => $asetData['urutan'] ?? 1,
                    'gambar' => $asetData['gambar'] ?? ($asetData['kunci'] . '.jpg'),
                ]
            );
            $totalAset++;
        }

        Schema::enableForeignKeyConstraints();

        // 4. Pastikan storage link dan bersihkan cache
        try {
            Artisan::call('storage:link');
        } catch (\Throwable $e) {
            // Abaikan jika symlink sudah ada
        }

        Artisan::call('optimize:clear');

        $this->info("✓ Sukses mengimpor katalog ke database lokal!");
        $this->line("  - Kategori: " . count($kategoriMap));
        $this->line("  - Produk: {$totalProduk}");
        $this->line("  - Varian: {$totalVarian}");
        $this->line("  - Aset Tampilan: {$totalAset}");
        $this->newLine();
        $this->info('Database lokal Anda dan foto sekarang sudah sinkron dengan katalog tim.');

        return Command::SUCCESS;
    }
}
