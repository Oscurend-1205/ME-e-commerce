<?php

namespace App\Http\Middleware;

use App\Models\Pelanggan;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware autentikasi pelanggan via Bearer token.
 * Membaca header Authorization: Bearer <api_token> lalu menyuntikkan
 * objek Pelanggan ke request agar controller dapat mengaksesnya.
 */
class AuthenticatePelanggan
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        $pelanggan = null;

        if (!empty($token)) {
            $pelanggan = Pelanggan::where('api_token', $token)->first();

            if (!$pelanggan) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '401',
                    'message' => 'Token tidak valid atau sesi telah berakhir. Silakan login kembali.',
                    'errors' => null,
                ], 401);
            }
        } else {
            // Mode identitas statis (PRD UTS): header X-Pelanggan-Id tetap diterima
            // sebagai pelanggan tetap ketika tidak ada token Bearer.
            $idStatis = $request->header('X-Pelanggan-Id');
            if ($idStatis && is_numeric($idStatis)) {
                $pelanggan = Pelanggan::find((int) $idStatis);
            }

            if (!$pelanggan) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '401',
                    'message' => 'Token autentikasi tidak ditemukan. Silakan login terlebih dahulu.',
                    'errors' => null,
                ], 401);
            }
        }

        // Suntikkan pelanggan & pelanggan_id ke request agar controller tinggal pakai
        $request->attributes->set('pelanggan', $pelanggan);
        $request->merge(['pelanggan_id' => $pelanggan->id]);

        return $next($request);
    }
}
