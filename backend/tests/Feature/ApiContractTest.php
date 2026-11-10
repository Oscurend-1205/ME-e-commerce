<?php

namespace Tests\Feature;

use App\Models\Pesanan;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use RuntimeException;
use Tests\TestCase;

class ApiContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeded_catalog_contains_required_products(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->getJson('/api/produk')
            ->assertOk()
            ->assertJsonCount(36, 'data')
            ->assertJsonPath('status', 'sukses');
    }

    public function test_simulated_payment_uses_the_required_status_transitions(): void
    {
        $this->seed(DatabaseSeeder::class);

        // Route status diproteksi auth.pelanggan; pakai identitas statis (X-Pelanggan-Id)
        // milik pemesan agar validasi transisi yang diuji, bukan kegagalan autentikasi.
        $pesanan = Pesanan::where('nomor_pesanan', 'ORD-20261105-SAMPLE1')->firstOrFail();
        $headers = ['X-Pelanggan-Id' => (string) $pesanan->pelanggan_id];
        $url = "/api/pesanan/{$pesanan->id}/status";

        // menunggu_pembayaran -> dibayar melompati menunggu_konfirmasi: ditolak 409
        $this->patchJson($url, ['status' => 'dibayar'], $headers)
            ->assertConflict();

        // menunggu_pembayaran -> menunggu_konfirmasi sah
        $this->patchJson($url, ['status' => 'menunggu_konfirmasi'], $headers)
            ->assertOk();

        // menunggu_konfirmasi -> dibayar sah
        $this->patchJson($url, ['status' => 'dibayar'], $headers)
            ->assertOk()
            ->assertJsonPath('data.status', 'dibayar');

        // dibayar -> menunggu_pembayaran mundur: ditolak 409
        $this->patchJson($url, ['status' => 'menunggu_pembayaran'], $headers)
            ->assertConflict();
    }

    public function test_api_exception_response_does_not_expose_exception_details(): void
    {
        Route::get('/api/_test-error', function () {
            throw new RuntimeException('database password must not be exposed');
        });

        $this->getJson('/api/_test-error')
            ->assertInternalServerError()
            ->assertJsonPath('message', 'Terjadi kesalahan pada server.')
            ->assertDontSee('database password must not be exposed');
    }
}
