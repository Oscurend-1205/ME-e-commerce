<?php

namespace Tests\Feature;

use App\Models\HeroBanner;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HeroBannerControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_additional_banner_photos_are_returned_as_individual_slides(): void
    {
        HeroBanner::create([
            'judul' => 'ME MINIMALISM',
            'gambar' => 'utama.jpg',
            'gambar_tambahan' => ['tambahan-1.jpg', 'tambahan-2.jpg'],
            'urutan' => 1,
            'aktif' => true,
        ]);

        $this->getJson('/api/hero-banners')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.gambar', 'utama.jpg')
            ->assertJsonPath('data.1.gambar', 'tambahan-1.jpg')
            ->assertJsonPath('data.1.judul', 'ME MINIMALISM')
            ->assertJsonPath('data.2.gambar', 'tambahan-2.jpg');
    }
}
