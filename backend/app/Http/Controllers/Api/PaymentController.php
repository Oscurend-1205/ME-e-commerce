<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Services\MidtransService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
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
        $isProduction = config('services.midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));

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
            return response()->json(['message' => 'Invalid signature'], 400);
        }

        // Cari pesanan
        $pesanan = Pesanan::where('nomor_pesanan', $orderId)->first();

        if (!$pesanan) {
            Log::warning('Pesanan tidak ditemukan untuk order_id: ' . $orderId);
            return response()->json(['message' => 'Order not found'], 404);
        }

        // Update status pesanan berdasarkan transaction status
        $statusBaru = $this->determineStatus($transactionStatus, $fraudStatus);

        if ($statusBaru) {
            $pesanan->update(['status' => $statusBaru]);

            Log::info('Status pesanan diperbarui', [
                'order_id' => $orderId,
                'status_lama' => $pesanan->status,
                'status_baru' => $statusBaru,
            ]);
        }

        return response()->json(['message' => 'Callback processed successfully']);
    }

    /**
     * Tentukan status pesanan berdasarkan transaction status Midtrans
     */
    private function determineStatus(string $transactionStatus, ?string $fraudStatus): ?string
    {
        // Status dari Midtrans:
        // capture, settlement, pending, deny, cancel, expire, refund

        switch ($transactionStatus) {
            case 'capture':
                return $fraudStatus === 'accept' ? 'dibayar' : 'menunggu_verifikasi';
            case 'settlement':
                return 'dibayar';
            case 'pending':
                return 'menunggu_pembayaran';
            case 'deny':
            case 'cancel':
            case 'expire':
                return 'dibatalkan';
            case 'refund':
                return 'refund';
            default:
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
            return response()->json([
                'status' => false,
                'message' => 'Order tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data' => [
                'order_id' => $pesanan->nomor_pesanan,
                'status_pesanan' => $pesanan->status,
                'total' => $pesanan->total,
                'created_at' => $pesanan->created_at->format('Y-m-d H:i:s'),
            ],
        ]);
    }
}
