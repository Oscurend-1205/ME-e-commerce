<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HeroBanner;
use Illuminate\Http\JsonResponse;

class HeroBannerController extends Controller
{
    public function index(): JsonResponse
    {
        $banners = HeroBanner::where('aktif', true)
            ->orderBy('urutan', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        if ($banners->isEmpty()) {
            $default = new HeroBanner([
                'id' => 1,
                'judul' => 'ME MINIMALISM',
                'subjudul' => 'Eksplorasi siluet bersih, material linen premium, dan palet monokrom abadi.',
                'tag' => 'BARU TIBA // DROP 01',
                'koleksi' => 'ATELIER ÉDITION 2026',
                'gambar' => 'hero-banner.jpg',
                'urutan' => 1,
                'aktif' => true,
            ]);
            $banners = collect([$default]);
        }

        $data = $banners->flatMap(function ($banner) {
            $gambar = collect([$banner->gambar, ...($banner->gambar_tambahan ?? [])])
                ->filter(fn (?string $file): bool => filled($file))
                ->unique()
                ->values();

            return $gambar->map(function (string $file) use ($banner) {
                $gambarUrl = str_starts_with($file, 'http://') || str_starts_with($file, 'https://')
                    ? $file
                    : url('/api/gambar/'.basename($file));

                return [
                    'id' => $banner->id,
                    'judul' => $banner->judul ?? 'ME MINIMALISM',
                    'subjudul' => $banner->subjudul ?? '',
                    'tag' => $banner->tag ?? 'BARU TIBA // DROP 01',
                    'koleksi' => $banner->koleksi ?? 'ATELIER ÉDITION 2026',
                    'gambar' => $file,
                    'gambar_url' => $gambarUrl,
                    'urutan' => $banner->urutan,
                ];
            });
        });

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Daftar hero banner berhasil diambil',
            'data' => $data,
        ]);
    }
}
