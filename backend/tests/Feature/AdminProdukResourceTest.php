<?php

namespace Tests\Feature;

use App\Filament\Resources\Produks\Pages\EditProduk;
use App\Models\Kategori;
use App\Models\Produk;
use App\Models\User;
use App\Models\VarianProduk;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class AdminProdukResourceTest extends TestCase
{
    use RefreshDatabase;

    public function test_halaman_daftar_produk_admin_tampil(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/admin/produks')
            ->assertOk();
    }

    public function test_halaman_input_produk_admin_tampil(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/admin/produks/create')
            ->assertOk();
    }

    public function test_halaman_edit_produk_admin_tampil(): void
    {
        $user = User::factory()->create();
        $kategori = Kategori::create(['nama' => 'Pakaian']);
        $produk = Produk::create([
            'kategori_id' => $kategori->id,
            'nama' => 'Kaos Polos',
            'harga' => 89000,
            'tersedia' => true,
            'deskripsi' => null,
            'bahan' => 'Katun Combed',
            'merek' => 'ME Basics',
            'gambar' => null,
        ]);
        VarianProduk::create([
            'produk_id' => $produk->id,
            'ukuran' => 'M',
            'warna' => 'Hitam',
            'stok' => 10,
        ]);

        $this->actingAs($user)
            ->get("/admin/produks/{$produk->id}/edit")
            ->assertOk();
    }

    public function test_sku_varian_dibuat_otomatis_bila_kosong(): void
    {
        $kategori = Kategori::create(['nama' => 'Pakaian']);
        $produk = Produk::create([
            'kategori_id' => $kategori->id,
            'nama' => 'Kemeja Flanel',
            'harga' => 189000,
            'tersedia' => true,
            'bahan' => 'Wool-blend',
            'merek' => 'ME Studio',
        ]);

        $varian = VarianProduk::create([
            'produk_id' => $produk->id,
            'ukuran' => 'L',
            'warna' => 'Merah Navy',
            'stok' => 8,
        ]);

        $this->assertSame('MES-'.$produk->id.'-L-MER', $varian->sku);
    }

    public function test_preview_gambar_memakai_url_storage(): void
    {
        $user = User::factory()->create();
        $kategori = Kategori::create(['nama' => 'Pakaian']);
        $produk = Produk::create([
            'kategori_id' => $kategori->id,
            'nama' => 'Kaos Polos',
            'harga' => 89000,
            'tersedia' => true,
            'bahan' => 'Katun Combed',
            'merek' => 'ME Basics',
            'gambar' => '1.jpg',
        ]);
        VarianProduk::create([
            'produk_id' => $produk->id,
            'ukuran' => 'M',
            'warna' => 'Hitam',
            'stok' => 10,
        ]);

        $this->actingAs($user);

        $component = Livewire::test(EditProduk::class, ['record' => $produk->id]);
        $fileUpload = $component->instance()->getSchema('form')->getComponent('gambar');
        $files = $fileUpload->getUploadedFiles();

        $this->assertNotEmpty($files);
        $this->assertStringEndsWith('/api/gambar/1.jpg', $files[array_key_first($files)]['url']);
    }
}
