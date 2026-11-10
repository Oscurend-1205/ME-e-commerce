<?php

namespace Tests\Feature;

use App\Models\PengaturanToko;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PengaturanTokoTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_pengaturan_toko_mengembalikan_profil_dan_origin(): void
    {
        $response = $this->getJson('/api/pengaturan-toko');

        $response->assertOk()
            ->assertJsonPath('data.nama_toko', 'ME Atelier')
            ->assertJsonPath('data.kota_id', '501')
            ->assertJsonPath('data.nama_kota', 'Kabupaten Sleman');
    }

    public function test_api_ongkir_otomatis_menggunakan_origin_dari_pengaturan_toko(): void
    {
        Http::fake([
            'https://pro.rajaongkir.com/api/cost' => Http::response([
                'rajaongkir' => [
                    'status' => ['code' => 200, 'description' => 'OK'],
                    'origin_details' => ['city_id' => '501', 'city_name' => 'Sleman'],
                    'destination_details' => ['city_id' => '153', 'city_name' => 'Jakarta Selatan'],
                    'results' => [
                        [
                            'code' => 'jne',
                            'name' => 'Jalur Nugraha Ekakurir (JNE)',
                            'costs' => [
                                [
                                    'service' => 'REG',
                                    'description' => 'Layanan Reguler',
                                    'cost' => [
                                        [
                                            'value' => 18000,
                                            'etd' => '2-3',
                                            'note' => '',
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ], 200),
        ]);

        // Cek ongkir tanpa mengirimkan parameter 'origin'
        $response = $this->postJson('/api/ongkir', [
            'destination' => '153',
            'weight' => 1000,
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'sukses');

        Http::assertSent(function ($request) {
            return $request['origin'] === '501' && $request['destination'] === '153';
        });
    }

    public function test_halaman_admin_pengaturan_toko_dapat_diakses(): void
    {
        $user = User::factory()->create();
        $pengaturan = PengaturanToko::getPengaturan();

        $this->actingAs($user)
            ->get('/admin/pengaturan-tokos')
            ->assertOk();

        $this->actingAs($user)
            ->get("/admin/pengaturan-tokos/{$pengaturan->id}/edit")
            ->assertOk();
    }
}
