<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Pelanggan;
use App\Models\VarianProduk;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class KeranjangController extends Controller
{
    use ApiResponse;

    protected function getPelangganId(Request $request): int
    {
        // Ambil dari middleware auth.pelanggan yang sudah menyuntikkan pelanggan_id
        return (int) $request->input('pelanggan_id', 0);
    }

    /**
     * GET /api/keranjang — Isi keranjang dan subtotal dari server
     */
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);

        $items = Keranjang::with(['produk', 'varian'])
            ->where('pelanggan_id', $pelangganId)
            ->get();

        $subtotal = 0;
        $itemsData = [];

        foreach ($items as $item) {
            $formatted = $item->formatItem();
            $subtotal += $formatted['subtotal_item'];
            $itemsData[] = $formatted;
        }

        $data = [
            'items' => $itemsData,
            'subtotal' => $subtotal,
        ];

        return $this->sukses($data, 'Data keranjang berhasil diambil', 200);
    }

    /**
     * POST /api/keranjang — Tambah item ke keranjang per varian
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'produk_id' => 'required|exists:produk,id',
            'varian_id' => 'required|exists:varian_produk,id',
            'jumlah' => 'required|integer|min:1',
        ], [
            'produk_id.required' => 'ID produk wajib diisi.',
            'varian_id.required' => 'ID varian produk wajib diisi.',
            'jumlah.min' => 'Jumlah item minimal 1.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi item keranjang gagal.', 422, $validator->errors());
        }

        $pelangganId = $this->getPelangganId($request);
        $produkId = (int) $request->input('produk_id');
        $varianId = (int) $request->input('varian_id');
        $jumlah = (int) $request->input('jumlah');

        $varian = VarianProduk::with('produk')->find($varianId);

        if (!$varian || $varian->produk_id !== $produkId) {
            return $this->gagal('Varian tidak sesuai dengan produk yang dipilih.', 422);
        }

        // Cek apakah produk aktif
        if (!$varian->produk->tersedia) {
            return $this->gagal('Produk ini sedang tidak tersedia untuk dibeli.', 409);
        }

        // Cek stok varian
        if ($varian->stok <= 0) {
            return $this->gagal("Stok ukuran {$varian->ukuran} warna {$varian->warna} habis.", 409);
        }

        // Cek apakah item varian sudah ada di keranjang
        $itemAda = Keranjang::where('pelanggan_id', $pelangganId)
            ->where('varian_id', $varianId)
            ->first();

        $jumlahTotal = $jumlah + ($itemAda ? $itemAda->jumlah : 0);

        if ($jumlahTotal > $varian->stok) {
            return $this->gagal(
                "Stok varian {$varian->ukuran} - {$varian->warna} tidak mencukupi (tersisa {$varian->stok}, diminta {$jumlahTotal}).",
                409
            );
        }

        if ($itemAda) {
            $itemAda->jumlah = $jumlahTotal;
            $itemAda->save();
            $itemResult = $itemAda;
        } else {
            $itemResult = Keranjang::create([
                'pelanggan_id' => $pelangganId,
                'produk_id' => $produkId,
                'varian_id' => $varianId,
                'jumlah' => $jumlah,
            ]);
        }

        $itemResult->load(['produk', 'varian']);

        return $this->sukses($itemResult->formatItem(), 'Item berhasil ditambahkan ke keranjang', 201);
    }

    /**
     * PUT /api/keranjang/{id} — Ubah jumlah atau varian item keranjang
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);
        $item = Keranjang::where('pelanggan_id', $pelangganId)->find($id);

        if (!$item) {
            return $this->gagal('Item keranjang tidak ditemukan.', 404);
        }

        $validator = Validator::make($request->all(), [
            'jumlah' => 'sometimes|integer|min:1',
            'varian_id' => 'sometimes|integer|exists:varian_produk,id',
        ], [
            'jumlah.integer' => 'Jumlah item harus berupa angka.',
            'jumlah.min' => 'Jumlah item harus minimal 1.',
            'varian_id.exists' => 'Varian produk tidak valid.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Data tidak valid.', 422, $validator->errors());
        }

        $jumlahBaru = $request->has('jumlah') ? (int) $request->input('jumlah') : $item->jumlah;
        $varianIdBaru = $request->has('varian_id') ? (int) $request->input('varian_id') : $item->varian_id;

        $varian = VarianProduk::find($varianIdBaru);
        if (!$varian || $varian->produk_id !== $item->produk_id) {
            return $this->gagal('Varian tidak sesuai dengan produk ini.', 422);
        }

        if ($varian->stok <= 0) {
            return $this->gagal("Stok ukuran {$varian->ukuran} warna {$varian->warna} habis.", 409);
        }

        if ($jumlahBaru > $varian->stok) {
            return $this->gagal(
                "Stok varian {$varian->ukuran} - {$varian->warna} tidak mencukupi (tersedia {$varian->stok}).",
                409
            );
        }

        // Jika mengubah varian, cek apakah varian tujuan sudah ada di item keranjang lain (merge)
        if ($varianIdBaru !== $item->varian_id) {
            $itemLain = Keranjang::where('pelanggan_id', $pelangganId)
                ->where('varian_id', $varianIdBaru)
                ->where('id', '!=', $item->id)
                ->first();

            if ($itemLain) {
                $totalGabung = $itemLain->jumlah + $jumlahBaru;
                if ($totalGabung > $varian->stok) {
                    $totalGabung = $varian->stok;
                }
                $itemLain->jumlah = $totalGabung;
                $itemLain->save();
                $item->delete();
                $itemLain->load(['produk', 'varian']);
                return $this->sukses($itemLain->formatItem(), 'Varian berhasil diperbarui dan digabungkan di keranjang', 200);
            }
        }

        $item->jumlah = $jumlahBaru;
        $item->varian_id = $varianIdBaru;
        $item->save();
        $item->load(['produk', 'varian']);

        return $this->sukses($item->formatItem(), 'Item keranjang berhasil diperbarui', 200);
    }

    /**
     * DELETE /api/keranjang/{id} — Hapus satu item keranjang
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);
        $item = Keranjang::where('pelanggan_id', $pelangganId)->find($id);

        if (!$item) {
            return $this->gagal('Item keranjang tidak ditemukan.', 404);
        }

        $item->delete();

        return $this->sukses(null, 'Item berhasil dihapus dari keranjang', 200);
    }
}

