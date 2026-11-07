<?php

namespace Database\Seeders;

use App\Models\AsetTampilan;
use Illuminate\Database\Seeder;

class AsetTampilanSeeder extends Seeder
{
    /**
     * Daftar slot aset tampilan beranda aplikasi Flutter.
     * Kolom `gambar` selalu memakai nama berkas tetap ({kunci}.jpg) agar
     * aplikasi Flutter (mobile/lib/widgets/foto_dummy.dart) langsung
     * memakai gambar terbaru tanpa perubahan kode.
     *
     * @var array<int, array{0: string, 1: string, 2: string}>
     */
    private array $slot = [
        // Beranda
        ['hero-banner', 'Hero Banner (ME MINIMALISM)', 'Beranda'],
        ['manifesto', 'Manifesto Editorial', 'Beranda'],
        ['siluet-baru', 'Siluet Baru', 'Beranda'],
        ['avatar', 'Avatar Profil', 'Beranda'],

        // Kategori Pilihan
        ['kat-atasan', 'Kategori: Atasan & Kemeja', 'Kategori'],
        ['kat-bawahan', 'Kategori: Bawahan & Celana', 'Kategori'],
        ['kat-outerwear', 'Kategori: Outerwear & Jas', 'Kategori'],
        ['kat-aksesori', 'Kategori: Kulit & Tas', 'Kategori'],

        // Story Highlight
        ['story-1', 'Story Highlight 1', 'Story'],
        ['story-2', 'Story Highlight 2', 'Story'],
        ['story-3', 'Story Highlight 3', 'Story'],
        ['story-4', 'Story Highlight 4', 'Story'],
        ['story-5', 'Story Highlight 5', 'Story'],
        ['story-6', 'Story Highlight 6', 'Story'],

        // Foto Editorial
        ['produk-pakaian-1', 'Editorial Pakaian 1', 'Editorial'],
        ['produk-pakaian-2', 'Editorial Pakaian 2', 'Editorial'],
        ['produk-pakaian-3', 'Editorial Pakaian 3', 'Editorial'],
        ['produk-pakaian-4', 'Editorial Pakaian 4', 'Editorial'],
        ['produk-pakaian-5', 'Editorial Pakaian 5', 'Editorial'],
        ['produk-aksesori-1', 'Editorial Aksesori 1', 'Editorial'],
        ['produk-aksesori-2', 'Editorial Aksesori 2', 'Editorial'],
    ];

    public function run(): void
    {
        foreach ($this->slot as $index => [$kunci, $nama, $grup]) {
            AsetTampilan::updateOrCreate(
                ['kunci' => $kunci],
                [
                    'nama' => $nama,
                    'grup' => $grup,
                    'urutan' => $index + 1,
                    'gambar' => $kunci . '.jpg',
                ],
            );
        }
    }
}
