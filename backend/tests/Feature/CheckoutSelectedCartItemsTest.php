<?php

namespace Tests\Feature;

use App\Models\DetailPesanan;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Produk;
use App\Models\VarianProduk;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CheckoutSelectedCartItemsTest extends TestCase
{
    use RefreshDatabase;

    public function test_checkout_processes_only_selected_cart_items(): void
    {
        $this->seed(DatabaseSeeder::class);

        $produkDipilih = Produk::findOrFail(1);
        $produkTidakDipilih = Produk::findOrFail(2);
        $itemDipilih = Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produkDipilih->id,
            'varian_id' => VarianProduk::where('produk_id', $produkDipilih->id)->firstOrFail()->id,
            'jumlah' => 1,
        ]);
        $itemTidakDipilih = Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produkTidakDipilih->id,
            'varian_id' => VarianProduk::where('produk_id', $produkTidakDipilih->id)->firstOrFail()->id,
            'jumlah' => 1,
        ]);

        $response = $this->postJson('/api/checkout', [
            'nama' => 'Auril Aditya',
            'alamat' => 'Jalan Merdeka No. 10, Bandung',
            'kurir_id' => Kurir::firstOrFail()->id,
            'metode_pembayaran_id' => MetodePembayaran::where('kode', 'tunai_di_tempat')->firstOrFail()->id,
            'item_keranjang_ids' => [$itemDipilih->id],
        ], [
            'X-Pelanggan-Id' => '1',
            'X-Kunci-Idempoten' => 'checkout-selected-items-test',
        ])->assertCreated();

        $pesananId = $response->json('data.id');

        $this->assertSame(
            [$produkDipilih->id],
            DetailPesanan::where('pesanan_id', $pesananId)->pluck('produk_id')->all(),
        );
        $this->assertDatabaseMissing('keranjang', ['id' => $itemDipilih->id]);
        $this->assertDatabaseHas('keranjang', ['id' => $itemTidakDipilih->id]);
    }
}
