<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RajaOngkirService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OngkirController extends Controller
{
    use ApiResponse;

    protected RajaOngkirService $rajaOngkir;

    public function __construct()
    {
        $this->rajaOngkir = new RajaOngkirService();
    }

    /**
     * POST /api/ongkir - Cek ongkir real-time dari RajaOngkir
     */
    public function cekOngkir(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'origin' => 'required|string|max:10',
            'destination' => 'required|string|max:10',
            'weight' => 'required|integer|min:1|max:30000',
            'courier' => 'nullable|string|max:100',
        ], [
            'origin.required' => 'ID kota asal wajib diisi.',
            'destination.required' => 'ID kota tujuan wajib diisi.',
            'weight.required' => 'Berat paket (gram) wajib diisi.',
            'weight.integer' => 'Berat harus berupa angka.',
            'weight.min' => 'Berat minimal 1 gram.',
            'weight.max' => 'Berat maksimal 30 kg.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal.', 422, $validator->errors());
        }

        $courier = $request->input('courier', 'jne,sicepat,jnt,anteraja');

        $hasil = $this->rajaOngkir->cekOngkir(
            originId: $request->input('origin'),
            destinationId: $request->input('destination'),
            weight: (int) $request->input('weight'),
            courier: $courier,
        );

        if (!isset($hasil['status']) || !$hasil['status']) {
            return $this->gagal(
                $hasil['message'] ?? 'Gagal menghitung ongkir',
                400
            );
        }

        // Format data hasil ongkir
        $daftarOngkir = [];
        foreach ($hasil['data'] ?? [] as $kurirData) {
            $namaKurir = $kurirData['name'] ?? '';
            foreach ($kurirData['costs'] ?? [] as $cost) {
                $daftarOngkir[] = [
                    'id' => strtolower(str_replace(' ', '_', $namaKurir)) . '_' . md5($cost['service'] . $cost['description'] . $cost['cost'][0]['value'] ?? ''),
                    'nama' => $namaKurir,
                    'service' => $cost['service'] ?? '',
                    'deskripsi' => $cost['description'] ?? '',
                    'tarif' => (int) ($cost['cost'][0]['value'] ?? 0),
                    'estimasi' => $cost['etd'] ?? '',
                    'tipe' => $cost['type'] ?? 'reguler',
                ];
            }
        }

        return $this->sukses($daftarOngkir, 'Ongkir berhasil dihitung', 200);
    }

    /**
     * GET /api/kota - Ambil daftar kota untuk autocomplete
     */
    public function getKota(Request $request): JsonResponse
    {
        $search = $request->query('search');
        $hasil = $this->rajaOngkir->getKota($search);

        if (!isset($hasil['status']) || !$hasil['status']) {
            return $this->gagal(
                $hasil['message'] ?? 'Gagal mengambil daftar kota',
                400
            );
        }

        // Format data kota
        $daftarKota = [];
        foreach ($hasil['rajaongkir']['results'] ?? [] as $kota) {
            $daftarKota[] = [
                'id' => $kota['city_id'],
                'nama' => $kota['city_name'],
                'provinsi' => $kota['province'] ?? '',
                'tipe' => $kota['type'] ?? '',
            ];
        }

        return $this->sukses($daftarKota, 'Daftar kota berhasil diambil', 200);
    }

    /**
     * GET /api/provinsi - Ambil daftar provinsi
     */
    public function getProvinsi(): JsonResponse
    {
        $hasil = $this->rajaOngkir->getProvinsi();

        if (!isset($hasil['status']) || !$hasil['status']) {
            return $this->gagal(
                $hasil['message'] ?? 'Gagal mengambil daftar provinsi',
                400
            );
        }

        // Format data provinsi
        $daftarProvinsi = [];
        foreach ($hasil['rajaongkir']['results'] ?? [] as $provinsi) {
            $daftarProvinsi[] = [
                'id' => $provinsi['id'],
                'nama' => $provinsi['province'],
            ];
        }

        return $this->sukses($daftarProvinsi, 'Daftar provinsi berhasil diambil', 200);
    }

    /**
     * GET /api/kecamatan - Ambil daftar kecamatan berdasarkan kota
     */
    public function getKecamatan(Request $request): JsonResponse
    {
        $cityId = $request->query('city_id');

        if (empty($cityId)) {
            return $this->gagal('Parameter city_id wajib diisi.', 422);
        }

        $hasil = $this->rajaOngkir->getKecamatan($cityId);

        if (!isset($hasil['status']) || !$hasil['status']) {
            return $this->gagal(
                $hasil['message'] ?? 'Gagal mengambil daftar kecamatan',
                400
            );
        }

        // Format data kecamatan
        $daftarKecamatan = [];
        foreach ($hasil['rajaongkir']['results'] ?? [] as $kecamatan) {
            $daftarKecamatan[] = [
                'id' => $kecamatan['subdistrict_id'],
                'nama' => $kecamatan['subdistrict_name'],
                'kota' => $kecamatan['city'] ?? '',
                'provinsi' => $kecamatan['province'] ?? '',
                'kode_pos' => $kecamatan['zipcode'] ?? '',
            ];
        }

        return $this->sukses($daftarKecamatan, 'Daftar kecamatan berhasil diambil', 200);
    }
}
