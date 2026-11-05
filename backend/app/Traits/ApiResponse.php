<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    /**
     * Balasan sukses standar
     */
    protected function sukses(mixed $data = null, string $pesan = 'Operasi berhasil', int $statusHttp = 200): JsonResponse
    {
        return response()->json([
            'status' => 'sukses',
            'code' => (string) $statusHttp,
            'message' => $pesan,
            'data' => $data,
        ], $statusHttp);
    }

    /**
     * Balasan galat standar
     */
    protected function gagal(string $pesan = 'Terjadi kesalahan', int $statusHttp = 400, mixed $errors = null): JsonResponse
    {
        return response()->json([
            'status' => 'gagal',
            'code' => (string) $statusHttp,
            'message' => $pesan,
            'errors' => $errors,
        ], $statusHttp);
    }
}
