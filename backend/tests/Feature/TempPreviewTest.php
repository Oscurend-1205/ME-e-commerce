<?php

namespace Tests\Feature;

use App\Models\Kategori;
use App\Models\Produk;
use App\Models\User;
use App\Models\VarianProduk;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TempPreviewTest extends TestCase
{
    use RefreshDatabase;

    public function test_inspect_edit_page_image_urls(): void
    {
        $user = User::factory()->create();
        $kategori = Kategori::create(['nama' => 'Pakaian']);
        $produk = Produk::create([
            'kategori_id' => $kategori->id,
            'nama' => 'Kaos Polos',
            'harga' => 89000,
            'tersedia' => true,
            'bahan' => 'Katun',
            'merek' => 'ME Basics',
            'gambar' => '1.jpg',
        ]);
        VarianProduk::create([
            'produk_id' => $produk->id,
            'ukuran' => 'M',
            'warna' => 'Hitam',
            'stok' => 10,
        ]);

        $html = $this->actingAs($user)->get("/admin/produks/{$produk->id}/edit")->assertOk()->getContent();

        preg_match_all('#https?://[^"\'\s]+|/storage/[^"\'\s]+|/api/gambar/[^"\'\s]+#', $html, $m);
        fwrite(STDERR, "\n=== URLS ===\n" . implode("\n", array_unique($m[0])) . "\n=== END ===\n");
        $this->assertTrue(true);
    }
}
