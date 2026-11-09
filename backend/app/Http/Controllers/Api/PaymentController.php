<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Services\MidtransService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    use ApiResponse;

    protected MidtransService $midtrans;

    public function __construct()
    {
        $this->midtrans = new MidtransService();
    }

    /**
     * POST /api/payment/callback - Callback dari Midtrans setelah pembayaran
     */
    public function callback(Request $request): JsonResponse
    {
        $serverKey = config('services.midtrans.server_key', env('MIDTRANS_SERVER_KEY'));

        $orderId = $request->input('order_id');
        $statusCode = $request->input('status_code');
        $grossAmount = $request->input('gross_amount');
        $signatureKey = $request->input('signature_key');
        $transactionStatus = $request->input('transaction_status');
        $fraudStatus = $request->input('fraud_status');
        $paymentType = $request->input('payment_type');

        Log::info('Midtrans callback received', [
            'order_id' => $orderId,
            'status_code' => $statusCode,
            'transaction_status' => $transactionStatus,
            'fraud_status' => $fraudStatus,
            'payment_type' => $paymentType,
        ]);

        // Verifikasi signature
        $hashed = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($hashed !== $signatureKey) {
            Log::warning('Midtrans callback signature mismatch', [
                'order_id' => $orderId,
                'expected' => $hashed,
                'received' => $signatureKey,
            ]);
            return $this->gagal('Signature tidak valid.', 400);
        }

        // Cari pesanan
        $pesanan = Pesanan::where('nomor_pesanan', $orderId)->first();

        if (!$pesanan) {
            Log::warning('Pesanan tidak ditemukan untuk order_id: ' . $orderId);
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        // Update status pesanan berdasarkan transaction status.
        // Hanya status yang disepakati PRD yang boleh ditulis ke pesanan.
        $statusBaru = $this->tentukanStatusSah($transactionStatus, $fraudStatus);

        if ($statusBaru) {
            $statusLama = $pesanan->status;
            $pesanan->update(['status' => $statusBaru]);

            Log::info('Status pesanan diperbarui', [
                'order_id' => $orderId,
                'status_lama' => $statusLama,
                'status_baru' => $statusBaru,
            ]);
        }

        return $this->sukses(null, 'Callback diproses.');
    }

    /**
     * Petakan transaction status Midtrans ke status pesanan yang sah:
     * menunggu_pembayaran, menunggu_konfirmasi, dibayar, diproses,
     * dikirim, selesai, dibatalkan.
     * Status di luar daftar (mis. refund) tidak mengubah status pesanan.
     */
    private function tentukanStatusSah(string $transactionStatus, ?string $fraudStatus): ?string
    {
        switch ($transactionStatus) {
            case 'capture':
                // Pembayaran berhasil ditahan gateway; hanya lanjut bila lolos cek fraud
                return $fraudStatus === 'accept' ? 'dibayar' : 'dibatalkan';
            case 'settlement':
                return 'dibayar';
            case 'pending':
                return 'menunggu_pembayaran';
            case 'deny':
            case 'cancel':
            case 'expire':
                return 'dibatalkan';
            default:
                // refund dsb.: dicatat di log, status pesanan tidak diubah
                return null;
        }
    }

    /**
     * GET /api/payment/status/{orderId} - Cek status pembayaran
     */
    public function checkStatus(string $orderId): JsonResponse
    {
        $pesanan = Pesanan::where('nomor_pesanan', $orderId)->first();

        if (!$pesanan) {
            return $this->gagal('Pesanan tidak ditemukan.', 404);
        }

        // Jika masih menunggu pembayaran, cek langsung ke Midtrans API
        // untuk mendukung sinkronisasi real-time tanpa harus menunggu webhook (misal di localhost)
        if ($pesanan->status === 'menunggu_pembayaran') {
            try {
                $midtransStatus = $this->midtrans->getTransactionDetail($orderId);
                if ($midtransStatus) {
                    $trxStatus = is_object($midtransStatus)
                        ? ($midtransStatus->transaction_status ?? null)
                        : ($midtransStatus['transaction_status'] ?? null);
                    $fraudStatus = is_object($midtransStatus)
                        ? ($midtransStatus->fraud_status ?? null)
                        : ($midtransStatus['fraud_status'] ?? null);

                    if ($trxStatus) {
                        $statusBaru = $this->tentukanStatusSah($trxStatus, $fraudStatus);
                        if ($statusBaru && $statusBaru !== $pesanan->status) {
                            $pesanan->update(['status' => $statusBaru]);
                        }
                    }
                }
            } catch (\Throwable $e) {
                Log::info('Cek status Midtrans silent error: ' . $e->getMessage());
            }
        }

        return $this->sukses([
            'order_id' => $pesanan->nomor_pesanan,
            'status_pesanan' => $pesanan->status,
            'total' => $pesanan->total,
            'created_at' => $pesanan->created_at->format('Y-m-d H:i:s'),
        ], 'Status pembayaran berhasil dicek');
    }
}
