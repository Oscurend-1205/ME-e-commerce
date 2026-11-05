<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Models\VarianProduk;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class PesananController extends Controller
{
    use ApiResponse;

    protected function getPelangganId(Request $request): int
    {
        $id = $request->header('X-Pelanggan-Id');
        if ($id && is_numeric($id)) {
            return (int) $id;
        }
        return 1;
    }

    /**
     * Tabel aturan perpindahan status yang sah sesuai Bagian 7 PRD
     */
    protected array $transisiSah = [
        'menunggu_pembayaran' => ['menunggu_konfirmasi', 'dibatalkan'],
        'menunggu_konfirmasi' => ['dibayar', 'dibatalkan'],
        'dibayar' => ['diproses'],
        'diproses' => ['dikirim'],
        'dikirim' => ['selesai'],
        'selesai' => [],
        'dibatalkan' => [],
    ];

    /**
     * GET /api/pesanan — Riwayat pesanan (terbaru dulu)
     */
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);

        $pesanans = Pesanan::with(['kurir', 'metodePembayaran', 'detail'])
            ->where('pelanggan_id', $pelangganId)
            ->orderBy('id', 'desc')
            ->get();

        $data = $pesanans->map(function ($p) {
            return $p->formatLengkap();
        });

        return $this->sukses($data, 'Riwayat pesanan berhasil diambil', 200);
    }

    /**
     * GET /api/pesanan/{id} — Rincian pesanan
     */
    public function show(int $id): JsonResponse
    {
        $pesanan = Pesanan::with(['kurir', 'metodePembayaran', 'detail'])->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        return $this->sukses($pesanan->formatLengkap(), 'Rincian pesanan berhasil diambil', 200);
    }

    /**
     * PATCH /api/pesanan/{id}/status — Ubah status pesanan dengan validasi transisi
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $pesanan = Pesanan::with('detail')->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|string',
        ], [
            'status.required' => 'Status baru wajib disertakan.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi status gagal.', 422, $validator->errors());
        }

        $statusSaatIni = strtolower($pesanan->status);
        $statusBaru = strtolower(trim($request->input('status')));

        // Validasi apakah status saat ini memiliki transisi sah
        $pilihanSah = $this->transisiSah[$statusSaatIni] ?? [];

        if (!in_array($statusBaru, $pilihanSah)) {
            $pesanPilihan = empty($pilihanSah)
                ? 'status akhir dan tidak dapat diubah lagi.'
                : 'hanya dapat diubah ke: ' . implode(', ', $pilihanSah) . '.';
            return $this->gagal(
                "Perpindahan status dari '{$statusSaatIni}' ke '{$statusBaru}' tidak diizinkan. Status {$statusSaatIni} {$pesanPilihan}",
                409
            );
        }

        return DB::transaction(function () use ($pesanan, $statusBaru) {
            // Jika pesanan dibatalkan, kembalikan stok varian di dalam transaksi yang sama (PRD Bagian 7)
            if ($statusBaru === 'dibatalkan') {
                foreach ($pesanan->detail as $item) {
                    if ($item->varian_id) {
                        VarianProduk::where('id', $item->varian_id)->increment('stok', $item->jumlah);
                    }
                }
            }

            $pesanan->status = $statusBaru;
            $pesanan->save();

            $pesanan->load(['kurir', 'metodePembayaran', 'detail']);

            return $this->sukses(
                $pesanan->formatLengkap(),
                "Status pesanan berhasil diperbarui menjadi '{$statusBaru}'",
                200
            );
        });
    }
}

