<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MetodePembayaran;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class MetodePembayaranController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/metode-pembayaran — Daftar metode pembayaran yang didukung
     */
    public function index(): JsonResponse
    {
        $metode = MetodePembayaran::all();

        $data = $metode->map(function ($m) {
            return [
                'id' => $m->id,
                'kode' => $m->kode,
                'nama' => $m->nama,
            ];
        });

        return $this->sukses($data, 'Daftar metode pembayaran berhasil diambil', 200);
    }
}
