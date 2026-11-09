<?php

namespace App\Console\Commands;

use App\Models\AsetTampilan;
use App\Models\Kategori;
use App\Models\Produk;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class ExportKatalogCommand extends Command
{
    protected $signature = 'katalog:export';

    protected $description = 'Ekspor data kategori, produk, varian, dan aset tampilan ke database/data/katalog.json agar tersinkron ke semua kolaborator';

    public function handle(): int
    {
        $this->info('Memulai ekspor data katalog dan aset...');

        $folderData = database_path('data');
        if (!File::exists($folderData)) {
            File::makeDirectory($folderData, 0755, true);
        }

        $kategoris = Kategori::all(['id', 'nama'])->toArray();

        $produks = Produk::with('varian')->get()->map(function ($p) {
            return [
                'id' => $p->id,
                'kategori_id' => $p->kategori_id,
                'nama' => $p->nama,
                'harga' => $p->harga,
                'tersedia' => (bool) $p->tersedia,
                'deskripsi' => $p->deskripsi,
                'bahan' => $p->bahan,
                'merek' => $p->merek,
                'gambar' => $p->gambar,
                'varian' => $p->varian->map(function ($v) {
                    return [
                        'id' => $v->id,
                        'ukuran' => $v->ukuran,
                        'warna' => $v->warna,
                        'stok' => $v->stok,
                        'sku' => $v->sku,
                    ];
                })->toArray(),
            ];
        })->toArray();

        $asetTampilans = AsetTampilan::all(['id', 'kunci', 'nama', 'grup', 'urutan', 'gambar'])->toArray();

        $data = [
            'diexport_pada' => now()->toIso8601String(),
            'total_kategori' => count($kategoris),
            'total_produk' => count($produks),
            'total_aset' => count($asetTampilans),
            'kategoris' => $kategoris,
            'produks' => $produks,
            'aset_tampilans' => $asetTampilans,
        ];

        $targetFile = database_path('data/katalog.json');
        File::put($targetFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

        $this->info("✓ Sukses mengekspor ke: {$targetFile}");
        $this->line("  - Kategori: " . count($kategoris));
        $this->line("  - Produk: " . count($produks));
        $this->line("  - Aset Tampilan: " . count($asetTampilans));

        $this->newLine();
        $this->comment('Langkah selanjutnya untuk menyinkronkan ke kolaborator:');
        $this->line('1. git add backend/database/data/katalog.json backend/storage/app/public/produk/');
        $this->line('2. git commit -m "sync: perbarui data katalog dan foto produk"');
        $this->line('3. git push origin main');
        $this->line('Kolaborator lain cukup menjalankan:');
        $this->line('   git pull origin main && php artisan katalog:import');

        return Command::SUCCESS;
    }
}
