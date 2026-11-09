<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class RajaOngkirService
{
    private string $apiKey;
    private string $baseUrl = 'https://pro.rajaongkir.com/api';

    public function __construct()
    {
        $this->apiKey = config('services.rajaongkir.api_key', env('RAJAONGKIR_API_KEY'));
    }

    /**
     * Cek ongkir dari origin ke destination
     *
     * @param string $originId - ID kota origin (dari /api/v2/city)
     * @param string $destinationId - ID kota destination
     * @param int $weight - berat dalam gram
     * @param string $courier - kode kurir (jne, sicepat, jne, jnt, anteraja, dll)
     * @return array - array data ongkir
     */
    public function cekOngkir(
        string $originId,
        string $destinationId,
        int $weight = 1000,
        string $courier = 'jne,sicepat,jnt,anteraja'
    ): array {
        try {
            $response = Http::withHeaders([
                'key' => $this->apiKey,
                'Content-Type' => 'application/x-www-form-urlencoded',
            ])->post("{$this->baseUrl}/cost", [
                'origin' => $originId,
                'destination' => $destinationId,
                'weight' => $weight,
                'courier' => $courier,
            ]);

            if ($response->successful()) {
                return $response->json();
            }

            return [
                'status' => false,
                'message' => 'Gagal menghubungi RajaOngkir: ' . $response->status(),
            ];
        } catch (\Exception $e) {
            return [
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Ambil daftar kota (untuk autocomplete di frontend)
     *
     * @param string|null $search - kata kunci pencarian
     * @return array
     */
    public function getKota(?string $search = null): array
    {
        try {
            $response = Http::withHeaders([
                'key' => $this->apiKey,
            ])->get("{$this->baseUrl}/city", [
                'search' => $search,
            ]);

            if ($response->successful()) {
                return $response->json();
            }

            return [
                'status' => false,
                'message' => 'Gagal mengambil daftar kota',
            ];
        } catch (\Exception $e) {
            return [
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Ambil daftar provinsi
     *
     * @return array
     */
    public function getProvinsi(): array
    {
        try {
            $response = Http::withHeaders([
                'key' => $this->apiKey,
            ])->get("{$this->baseUrl}/province");

            if ($response->successful()) {
                return $response->json();
            }

            return [
                'status' => false,
                'message' => 'Gagal mengambil daftar provinsi',
            ];
        } catch (\Exception $e) {
            return [
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Ambil daftar kecamatan
     *
     * @param string $cityId - ID kota
     * @return array
     */
    public function getKecamatan(string $cityId): array
    {
        try {
            $response = Http::withHeaders([
                'key' => $this->apiKey,
            ])->get("{$this->baseUrl}/subdistrict", [
                'city' => $cityId,
            ]);

            if ($response->successful()) {
                return $response->json();
            }

            return [
                'status' => false,
                'message' => 'Gagal mengambil daftar kecamatan',
            ];
        } catch (\Exception $e) {
            return [
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ];
        }
    }
}
