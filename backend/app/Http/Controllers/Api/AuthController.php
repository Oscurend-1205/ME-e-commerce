<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pelanggan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/auth/register — Daftar akun pelanggan baru.
     */
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:pelanggan,email',
            'password' => 'required|string|min:6|max:255',
            'no_telp' => 'nullable|string|max:20',
        ], [
            'nama.required' => 'Nama lengkap wajib diisi.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email ini sudah terdaftar. Silakan gunakan email lain atau login.',
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal 6 karakter.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi pendaftaran gagal.', 422, $validator->errors());
        }

        $pelanggan = Pelanggan::create([
            'nama' => $request->input('nama'),
            'email' => $request->input('email'),
            'password' => $request->input('password'), // auto-hashed via cast
            'no_telp' => $request->input('no_telp'),
            'api_token' => hash('sha256', Str::random(60)),
        ]);

        return $this->sukses(
            $this->formatPelangganDenganToken($pelanggan),
            'Pendaftaran berhasil. Selamat datang di ME Atelier!',
            201
        );
    }

    /**
     * POST /api/auth/login — Masuk dengan email & password.
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ], [
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi login gagal.', 422, $validator->errors());
        }

        $pelanggan = Pelanggan::where('email', $request->input('email'))->first();

        if (!$pelanggan || !Hash::check($request->input('password'), $pelanggan->password)) {
            return $this->gagal('Email atau password salah.', 401);
        }

        // Generate token baru setiap login
        $pelanggan->api_token = hash('sha256', Str::random(60));
        $pelanggan->save();

        return $this->sukses(
            $this->formatPelangganDenganToken($pelanggan),
            'Login berhasil. Selamat datang kembali!',
            200
        );
    }

    /**
     * POST /api/auth/logout — Keluar & hapus token.
     */
    public function logout(Request $request): JsonResponse
    {
        $pelanggan = $request->attributes->get('pelanggan');

        if ($pelanggan) {
            $pelanggan->api_token = null;
            $pelanggan->save();
        }

        return $this->sukses(null, 'Anda telah keluar dari akun.', 200);
    }

    /**
     * GET /api/auth/me — Ambil data pelanggan yang sedang login.
     */
    public function me(Request $request): JsonResponse
    {
        $pelanggan = $request->attributes->get('pelanggan');

        return $this->sukses(
            $this->formatPelanggan($pelanggan),
            'Data profil berhasil diambil.',
            200
        );
    }

    /**
     * Format data pelanggan + token untuk respons register/login.
     */
    protected function formatPelangganDenganToken(Pelanggan $pelanggan): array
    {
        return array_merge($this->formatPelanggan($pelanggan), [
            'token' => $pelanggan->api_token,
        ]);
    }

    /**
     * Format data dasar pelanggan (tanpa field sensitif).
     */
    protected function formatPelanggan(Pelanggan $pelanggan): array
    {
        return [
            'id' => $pelanggan->id,
            'nama' => $pelanggan->nama,
            'email' => $pelanggan->email,
            'no_telp' => $pelanggan->no_telp,
            'foto' => $pelanggan->foto,
            'created_at' => $pelanggan->created_at?->toIso8601String(),
        ];
    }
}
