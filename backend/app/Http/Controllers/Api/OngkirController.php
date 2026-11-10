<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PengaturanToko;
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
            'origin' => 'nullable|string|max:10',
            'destination' => 'required|string|max:10',
            'weight' => 'required|integer|min:1|max:30000',
            'courier' => 'nullable|string|max:100',
        ], [
            'destination.required' => 'ID kota tujuan wajib diisi.',
            'weight.required' => 'Berat paket (gram) wajib diisi.',
            'weight.integer' => 'Berat harus berupa angka.',
            'weight.min' => 'Berat minimal 1 gram.',
            'weight.max' => 'Berat maksimal 30 kg.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi gagal.', 422, $validator->errors());
        }

        $pengaturan = PengaturanToko::getPengaturan();
        $originId = $request->input('origin') ?: (string) ($pengaturan->kota_id ?: '501');
        $courier = $request->input('courier') ?: (string) ($pengaturan->kurir_aktif ?: 'jne,sicepat,jnt,pos');

        $hasil = $this->rajaOngkir->cekOngkir(
            originId: $originId,
            destinationId: $request->input('destination'),
            weight: (int) $request->input('weight'),
            courier: $courier,
        );

        if (isset($hasil['status']) && $hasil['status'] === false) {
            return $this->gagal(
                $hasil['message'] ?? 'Gagal menghitung ongkir',
                400
            );
        }

        $statusCode = $hasil['rajaongkir']['status']['code'] ?? null;
        if ($statusCode !== null && (int) $statusCode !== 200) {
            return $this->gagal(
                $hasil['rajaongkir']['status']['description'] ?? 'Gagal menghitung ongkir',
                400
            );
        }

        // Format data hasil ongkir
        $daftarOngkir = [];
        $daftarKurir = $hasil['rajaongkir']['results'] ?? $hasil['data'] ?? [];
        foreach ($daftarKurir as $kurirData) {
            $namaKurir = $kurirData['name'] ?? '';
            foreach ($kurirData['costs'] ?? [] as $cost) {
                $costDetail = $cost['cost'][0] ?? [];
                $daftarOngkir[] = [
                    'id' => strtolower(str_replace(' ', '_', $namaKurir)) . '_' . md5(($cost['service'] ?? '') . ($cost['description'] ?? '') . ($costDetail['value'] ?? 0)),
                    'nama' => $namaKurir,
                    'service' => $cost['service'] ?? '',
                    'deskripsi' => $cost['description'] ?? '',
                    'tarif' => (int) ($costDetail['value'] ?? 0),
                    'estimasi' => $costDetail['etd'] ?? ($cost['etd'] ?? ''),
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

        if (isset($hasil['status']) && $hasil['status'] === false) {
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

        if (isset($hasil['status']) && $hasil['status'] === false) {
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

        if (isset($hasil['status']) && $hasil['status'] === false) {
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

    /**
     * GET /api/pengaturan-toko - Ambil data profil toko dan lokasi gudang/asal pengiriman
     */
    public function getPengaturanToko(): JsonResponse
    {
        $pengaturan = PengaturanToko::getPengaturan();
        return $this->sukses($pengaturan, 'Pengaturan toko berhasil diambil', 200);
    }
}
