<?php

namespace Tests\Feature;

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
            ->assertJsonCount(12, 'data')
            ->assertJsonPath('status', 'sukses');
    }

    public function test_simulated_payment_uses_the_required_status_transitions(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->patchJson('/api/pesanan/1/status', ['status' => 'dibayar'])
            ->assertConflict();

        $this->patchJson('/api/pesanan/1/status', ['status' => 'menunggu_konfirmasi'])
            ->assertOk();

        $this->patchJson('/api/pesanan/1/status', ['status' => 'dibayar'])
            ->assertOk()
            ->assertJsonPath('data.status', 'dibayar');
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
