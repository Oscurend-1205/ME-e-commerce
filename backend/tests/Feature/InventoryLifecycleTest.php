<?php

namespace Tests\Feature;

use App\Models\DetailPesanan;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\VarianProduk;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeded_cart_does_not_reserve_stock_but_seeded_orders_do(): void
    {
        $this->seed(DatabaseSeeder::class);

        $varian = VarianProduk::where('produk_id', 1)
            ->where('ukuran', 'L')
            ->where('warna', 'Hitam')
            ->firstOrFail();

        $this->assertSame(13, $varian->stok);
        $this->assertDatabaseHas('keranjang', [
            'pelanggan_id' => 1,
            'varian_id' => $varian->id,
            'jumlah' => 1,
        ]);
    }

    public function test_cart_add_update_and_delete_do_not_change_variant_stock(): void
    {
        $this->seed(DatabaseSeeder::class);
        $produk = Produk::findOrFail(2);
        $varian = $produk->varian()->firstOrFail();
        $stokAwal = $varian->stok;

        $response = $this->postJson('/api/keranjang', [
            'produk_id' => $produk->id,
            'varian_id' => $varian->id,
            'jumlah' => 1,
        ], ['X-Pelanggan-Id' => '1'])->assertCreated();

        $itemId = $response->json('data.id');
        $this->assertSame($stokAwal, $varian->fresh()->stok);

        $this->putJson("/api/keranjang/{$itemId}", [
            'jumlah' => 2,
        ], ['X-Pelanggan-Id' => '1'])->assertOk();
        $this->assertSame($stokAwal, $varian->fresh()->stok);

        $varianLain = $produk->varian()->where('id', '!=', $varian->id)->firstOrFail();
        $stokVarianLain = $varianLain->stok;
        $this->putJson("/api/keranjang/{$itemId}", [
            'varian_id' => $varianLain->id,
        ], ['X-Pelanggan-Id' => '1'])->assertOk();
        $this->assertSame($stokAwal, $varian->fresh()->stok);
        $this->assertSame($stokVarianLain, $varianLain->fresh()->stok);

        $this->deleteJson("/api/keranjang/{$itemId}", [], [
            'X-Pelanggan-Id' => '1',
        ])->assertOk();
        $this->assertSame($stokAwal, $varian->fresh()->stok);
        $this->assertSame($stokVarianLain, $varianLain->fresh()->stok);
    }

    public function test_checkout_decrements_stock_and_cancellation_restores_it(): void
    {
        $this->seed(DatabaseSeeder::class);
        $produk = Produk::findOrFail(1);
        $varian = $produk->varian()
            ->where('ukuran', 'L')
            ->where('warna', 'Hitam')
            ->firstOrFail();
        $stokAwal = $varian->stok;
        $item = Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produk->id,
            'varian_id' => $varian->id,
            'jumlah' => 2,
        ]);

        $response = $this->postJson('/api/checkout', [
            'nama' => 'Auril Aditya',
            'alamat' => 'Jalan Merdeka No. 10, Bandung',
            'kurir_id' => Kurir::firstOrFail()->id,
            'metode_pembayaran_id' => MetodePembayaran::where('kode', 'tunai_di_tempat')->firstOrFail()->id,
            'item_keranjang_ids' => [$item->id],
        ], [
            'X-Pelanggan-Id' => '1',
            'X-Kunci-Idempoten' => 'inventory-lifecycle-test',
        ])->assertCreated();

        $pesananId = $response->json('data.id');
        $this->assertSame($stokAwal - 2, $varian->fresh()->stok);
        $this->assertDatabaseMissing('keranjang', ['id' => $item->id]);
        $this->assertDatabaseHas('detail_pesanan', [
            'pesanan_id' => $pesananId,
            'varian_id' => $varian->id,
            'jumlah' => 2,
        ]);

        $this->patchJson("/api/pesanan/{$pesananId}/status", [
            'status' => 'dibatalkan',
        ], ['X-Pelanggan-Id' => '1'])->assertOk();

        $this->assertSame($stokAwal, $varian->fresh()->stok);
    }

    public function test_checkout_rejects_insufficient_stock_without_partial_changes(): void
    {
        $this->seed(DatabaseSeeder::class);
        $produk = Produk::findOrFail(1);
        $varianTersedia = $produk->varian()
            ->where('ukuran', 'L')
            ->where('warna', 'Hitam')
            ->firstOrFail();
        $varianKurangStok = $produk->varian()
            ->where('ukuran', 'L')
            ->where('warna', 'Putih')
            ->firstOrFail();
        $stokTersediaAwal = $varianTersedia->stok;
        $stokKurangAwal = $varianKurangStok->stok;
        $itemTersedia = Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produk->id,
            'varian_id' => $varianTersedia->id,
            'jumlah' => 1,
        ]);
        $itemKurangStok = Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produk->id,
            'varian_id' => $varianKurangStok->id,
            'jumlah' => $stokKurangAwal + 1,
        ]);
        $jumlahPesananAwal = Pesanan::count();
        $jumlahDetailAwal = DetailPesanan::count();

        $this->postJson('/api/checkout', [
            'nama' => 'Auril Aditya',
            'alamat' => 'Jalan Merdeka No. 10, Bandung',
            'kurir_id' => Kurir::firstOrFail()->id,
            'metode_pembayaran_id' => MetodePembayaran::where('kode', 'tunai_di_tempat')->firstOrFail()->id,
            'item_keranjang_ids' => [$itemTersedia->id, $itemKurangStok->id],
        ], [
            'X-Pelanggan-Id' => '1',
            'X-Kunci-Idempoten' => 'inventory-insufficient-stock-test',
        ])->assertConflict();

        $this->assertSame($stokTersediaAwal, $varianTersedia->fresh()->stok);
        $this->assertSame($stokKurangAwal, $varianKurangStok->fresh()->stok);
        $this->assertDatabaseHas('keranjang', ['id' => $itemTersedia->id]);
        $this->assertDatabaseHas('keranjang', ['id' => $itemKurangStok->id]);
        $this->assertSame($jumlahPesananAwal, Pesanan::count());
        $this->assertSame($jumlahDetailAwal, DetailPesanan::count());
    }
}
