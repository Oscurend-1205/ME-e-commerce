<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLogPembayaran;
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
        return (int) $request->input('pelanggan_id', 0);
    }

    /**
     * GET /api/pesanan — Riwayat pesanan (terbaru dulu)
     */
    public function index(Request $request): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);

        $query = Pesanan::with(['pelanggan', 'kurir', 'metodePembayaran', 'detail.produk'])
            ->where('pelanggan_id', $pelangganId);

        // Filter status dinamis (mis: ?status=dikirim atau ?status=diproses,dikirim)
        if ($request->has('status')) {
            $statusParam = $request->input('status');
            if (str_contains($statusParam, ',')) {
                $statuses = array_map('trim', explode(',', $statusParam));
                $query->whereIn('status', $statuses);
            } else {
                $query->where('status', $statusParam);
            }
        }

        $pesanans = $query->orderBy('id', 'desc')->get();

        $data = $pesanans->map(function ($p) {
            return $p->formatLengkap();
        });

        return $this->sukses($data, 'Riwayat pesanan berhasil diambil', 200);
    }

    /**
     * GET /api/pesanan/{id} — Rincian pesanan
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);
        $pesanan = Pesanan::with(['pelanggan', 'kurir', 'metodePembayaran', 'detail.produk'])->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        if ($pelangganId > 0 && $pesanan->pelanggan_id !== $pelangganId) {
            return $this->gagal('Anda tidak memiliki izin untuk melihat pesanan ini.', 403);
        }

        return $this->sukses($pesanan->formatLengkap(), 'Rincian pesanan berhasil diambil', 200);
    }

    /**
     * PATCH /api/pesanan/{id}/status — Ubah status pesanan dengan validasi transisi & aturan akses
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $pelangganId = $this->getPelangganId($request);
        $pesanan = Pesanan::with(['pelanggan', 'kurir', 'metodePembayaran', 'detail'])->find($id);

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        // 1. Verifikasi kepemilikan pesanan: Pelanggan hanya boleh mengubah pesanan miliknya sendiri
        if ($pelangganId > 0 && $pesanan->pelanggan_id !== $pelangganId) {
            return $this->gagal('Anda tidak memiliki izin untuk mengubah pesanan ini.', 403);
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

        // 2. Aturan Hak Akses: Pemrosesan "kemas barang" (diproses) dan "kirim ke kurir" (dikirim)
        // HANYA dapat dilakukan oleh admin Filament di backend. Sisi pengguna mobile ditolak (403 Forbidden).
        if (in_array($statusBaru, ['diproses', 'dikirim'])) {
            return $this->gagal(
                'Akses ditolak: Pemrosesan "kemas barang" dan "kirim ke kurir" hanya dapat dilakukan oleh Admin Filament di backend.',
                403
            );
        }

        // 3. Hak akses pengguna untuk konfirmasi terima:
        // Konfirmasi 'selesai' hanya dapat dilakukan jika barang saat ini sedang dikirim ('dikirim')
        if ($statusBaru === 'selesai' && $statusSaatIni !== 'dikirim') {
            return $this->gagal(
                "Pesanan belum dapat diselesaikan karena status saat ini masih '{$statusSaatIni}'. Konfirmasi selesai hanya berlaku saat barang dalam proses pengiriman (dikirim).",
                409
            );
        }

        // 3b. Aturan metode pembayaran manual: transfer manual tidak boleh langsung melompat ke 'dibayar'
        if ($statusSaatIni === 'menunggu_pembayaran' && $statusBaru === 'dibayar' && $pesanan->metodePembayaran?->kode === 'transfer_manual') {
            return $this->gagal(
                "Perpindahan status dari 'menunggu_pembayaran' ke 'dibayar' untuk metode transfer manual tidak diizinkan. Pembeli harus melalui 'menunggu_konfirmasi'.",
                409
            );
        }

        // 4. Validasi apakah status saat ini memiliki transisi sah
        $pilihanSah = $pesanan->pilihanStatusBerikutnya();

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
            // Jika pesanan dibatalkan, kembalikan stok varian di dalam transaksi yang sama
            if ($statusBaru === 'dibatalkan') {
                $pesanan->kembalikanStok();
                if ($pesanan->isCod()) {
                    AuditLogPembayaran::catat('cod_dibatalkan', $pesanan, 'tunai_di_tempat', 'Pesanan COD dibatalkan dan stok produk dikembalikan ke sistem');
                }
            }

            if ($statusBaru === 'selesai' && $pesanan->isCod()) {
                AuditLogPembayaran::catat('cod_selesai_lunas', $pesanan, 'tunai_di_tempat', 'Pesanan COD diterima pembeli dan pembayaran tunai berhasil lunas');
            }

            $pesanan->status = $statusBaru;
            $pesanan->save();

            $pesanan->load(['pelanggan', 'kurir', 'metodePembayaran', 'detail.produk']);

            return $this->sukses(
                $pesanan->formatLengkap(),
                "Status pesanan berhasil diperbarui menjadi '{$statusBaru}'",
                200
            );
        });
    }
}

