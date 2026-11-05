<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kurir;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class KurirController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/kurir — Daftar kurir dan tarif
     */
    public function index(): JsonResponse
    {
        $kurir = Kurir::orderBy('tarif', 'asc')->get();

        $data = $kurir->map(function ($k) {
            return [
                'id' => $k->id,
                'nama' => $k->nama,
                'wilayah' => $k->wilayah,
                'tarif' => (int) $k->tarif,
            ];
        });

        return $this->sukses($data, 'Daftar kurir berhasil diambil', 200);
    }
}
