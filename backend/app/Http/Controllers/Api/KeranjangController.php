<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Pelanggan;
use App\Models\VarianProduk;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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

        return DB::transaction(function () use ($pelangganId, $produkId, $varianId, $jumlah) {
            // Kunci baris varian untuk mencegah race condition
            $varianLocked = VarianProduk::where('id', $varianId)->lockForUpdate()->first();

            if (!$varianLocked || $varianLocked->stok < $jumlah) {
                $sisa = $varianLocked ? $varianLocked->stok : 0;
                return $this->gagal(
                    "Stok ukuran {$varianLocked->ukuran} warna {$varianLocked->warna} tidak mencukupi (tersedia: {$sisa}, diminta: {$jumlah}).",
                    409
                );
            }

            // Kurangi stok varian secara langsung saat masuk keranjang
            $varianLocked->decrement('stok', $jumlah);

            // Cek apakah item varian sudah ada di keranjang pelanggan
            $itemAda = Keranjang::where('pelanggan_id', $pelangganId)
                ->where('varian_id', $varianId)
                ->lockForUpdate()
                ->first();

            if ($itemAda) {
                $itemAda->jumlah += $jumlah;
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

            return $this->sukses($itemResult->formatItem(), 'Item berhasil ditambahkan ke keranjang dan stok berhasil dikurangi.', 201);
        });
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

        return DB::transaction(function () use ($item, $jumlahBaru, $varianIdBaru, $pelangganId) {
            $itemLocked = Keranjang::where('id', $item->id)->lockForUpdate()->first();
            if (!$itemLocked) {
                return $this->gagal('Item keranjang tidak ditemukan.', 404);
            }

            // Kasus 1: Varian tetap sama, hanya jumlah berubah
            if ($varianIdBaru === $itemLocked->varian_id) {
                $selisih = $jumlahBaru - $itemLocked->jumlah;
                $varianLocked = VarianProduk::where('id', $itemLocked->varian_id)->lockForUpdate()->first();

                if ($selisih > 0) {
                    // Tambah kuantitas di keranjang -> kurangi stok varian
                    if ($varianLocked->stok < $selisih) {
                        return $this->gagal(
                            "Stok varian {$varianLocked->ukuran} - {$varianLocked->warna} tidak mencukupi untuk penambahan (tersedia: {$varianLocked->stok}).",
                            409
                        );
                    }
                    $varianLocked->decrement('stok', $selisih);
                } elseif ($selisih < 0) {
                    // Kurangi kuantitas di keranjang -> kembalikan stok varian
                    $varianLocked->increment('stok', abs($selisih));
                }

                $itemLocked->jumlah = $jumlahBaru;
                $itemLocked->save();
            } else {
                // Kasus 2: Ganti varian produk
                $varianLama = VarianProduk::where('id', $itemLocked->varian_id)->lockForUpdate()->first();
                $varianBaru = VarianProduk::where('id', $varianIdBaru)->lockForUpdate()->first();

                if (!$varianBaru || $varianBaru->produk_id !== $itemLocked->produk_id) {
                    return $this->gagal('Varian tidak sesuai dengan produk ini.', 422);
                }

                if ($varianBaru->stok < $jumlahBaru) {
                    return $this->gagal(
                        "Stok varian {$varianBaru->ukuran} - {$varianBaru->warna} tidak mencukupi (tersedia: {$varianBaru->stok}).",
                        409
                    );
                }

                // Kembalikan stok varian lama
                if ($varianLama) {
                    $varianLama->increment('stok', $itemLocked->jumlah);
                }
                // Kurangi stok varian baru
                $varianBaru->decrement('stok', $jumlahBaru);

                // Cek jika varian tujuan sudah ada di item keranjang lain (merge)
                $itemLain = Keranjang::where('pelanggan_id', $pelangganId)
                    ->where('varian_id', $varianIdBaru)
                    ->where('id', '!=', $itemLocked->id)
                    ->lockForUpdate()
                    ->first();

                if ($itemLain) {
                    $itemLain->jumlah += $jumlahBaru;
                    $itemLain->save();
                    $itemLocked->delete();
                    $itemLain->load(['produk', 'varian']);
                    return $this->sukses($itemLain->formatItem(), 'Varian berhasil diperbarui dan digabungkan di keranjang', 200);
                }

                $itemLocked->jumlah = $jumlahBaru;
                $itemLocked->varian_id = $varianIdBaru;
                $itemLocked->save();
            }

            $itemLocked->load(['produk', 'varian']);
            return $this->sukses($itemLocked->formatItem(), 'Item keranjang berhasil diperbarui', 200);
        });
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

        return DB::transaction(function () use ($item) {
            // Kembalikan stok varian ke database saat item dihapus dari keranjang
            if ($item->varian_id) {
                VarianProduk::where('id', $item->varian_id)->increment('stok', $item->jumlah);
            }

            $item->delete();

            return $this->sukses(null, 'Item berhasil dihapus dari keranjang dan stok dikembalikan', 200);
        });
    }
}

