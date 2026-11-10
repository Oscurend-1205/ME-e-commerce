<?php

namespace App\Services;

use Midtrans\Config;
use Midtrans\Snap;
use Midtrans\Transaction;

class MidtransService
{
    public function __construct()
    {
        Config::$serverKey = config('services.midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
        Config::$isProduction = config('services.midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));
        Config::$isSanitized = true;
        Config::$is3ds = true;
    }

    /**
     * Generate Snap token & redirect URL untuk pembayaran Midtrans
     *
     * @param array $params - parameter transaksi
     * @return array - ['token' => ..., 'redirect_url' => ...]
     */
    public function generateSnapTransaction(array $params): array
    {
        $transactionDetails = [
            'order_id' => $params['order_id'],
            'gross_amount' => (int) $params['gross_amount'],
        ];

        $customerDetails = [
            'first_name' => $params['customer_name'] ?? 'Pelanggan',
            'email' => $params['customer_email'] ?? 'customer@example.com',
            'phone' => $params['customer_phone'] ?? '',
        ];

        $itemDetails = $params['item_details'] ?? [];

        $transaction = [
            'transaction_details' => $transactionDetails,
            'customer_details' => $customerDetails,
            'item_details' => $itemDetails,
            'callbacks' => [
                'finish' => config('app.url') . '/api/payment/callback?order_id=' . $params['order_id'],
            ],
            'expiry' => [
                'unit' => 'hour',
                'duration' => 24,
            ],
        ];

        if (!empty($params['enabled_payments'])) {
            $transaction['enabled_payments'] = $params['enabled_payments'];
        }

        $res = Snap::createTransaction($transaction);
        $token = is_object($res) ? ($res->token ?? null) : ($res['token'] ?? null);
        $redirectUrl = is_object($res) ? ($res->redirect_url ?? null) : ($res['redirect_url'] ?? null);

        if (!$redirectUrl && $token) {
            $redirectUrl = Config::$isProduction
                ? "https://app.midtrans.com/snap/v4/redirection/{$token}"
                : "https://app.sandbox.midtrans.com/snap/v4/redirection/{token}";
        }

        return [
            'token' => $token,
            'redirect_url' => $redirectUrl,
        ];
    }

    /**
     * Generate Snap token untuk pembayaran
     *
     * @param array $params - parameter transaksi
     * @return string - snap token
     */
    public function generateSnapToken(array $params): string
    {
        $result = $this->generateSnapTransaction($params);
        return $result['token'] ?? '';
    }

    /**
     * Generate QRIS Core API transaction via Midtrans
     *
     * @param array $params
     * @return array
     */
    public function generateQrisTransaction(array $params): array
    {
        $payload = [
            'payment_type' => 'qris',
            'transaction_details' => [
                'order_id' => $params['order_id'],
                'gross_amount' => (int) $params['gross_amount'],
            ],
            'qris' => [
                'acquirer' => 'gopay',
            ],
            'customer_details' => [
                'first_name' => $params['customer_name'] ?? 'Pelanggan',
                'email' => $params['customer_email'] ?? 'customer@example.com',
                'phone' => $params['customer_phone'] ?? '',
            ],
            'item_details' => $params['item_details'] ?? [],
        ];

        $response = \Midtrans\CoreApi::charge($payload);

        $qrUrl = null;
        if (isset($response->actions) && (is_array($response->actions) || is_object($response->actions))) {
            foreach ($response->actions as $action) {
                $name = is_object($action) ? ($action->name ?? '') : ($action['name'] ?? '');
                $url = is_object($action) ? ($action->url ?? '') : ($action['url'] ?? '');
                if ($name === 'generate-qr-code') {
                    $qrUrl = $url;
                    break;
                }
            }
        }

        $qrString = is_object($response) ? ($response->qr_string ?? null) : ($response['qr_string'] ?? null);
        $transactionId = is_object($response) ? ($response->transaction_id ?? null) : ($response['transaction_id'] ?? null);
        $expiryTime = is_object($response) ? ($response->expiry_time ?? null) : ($response['expiry_time'] ?? null);

        return [
            'transaction_id' => $transactionId,
            'qr_url' => $qrUrl,
            'qr_string' => $qrString,
            'expired_at' => $expiryTime,
        ];
    }

    /**
     * Verifikasi signature callback
     *
     * @param string $orderId - order ID
     * @param string $statusCode - status code
     * @param string $grossAmount - gross amount
     * @param string $signatureKey - signature key dari Midtrans
     * @return bool
     */
    public function verifySignature(string $orderId, string $statusCode, string $grossAmount, string $signatureKey): bool
    {
        $hashed = hash('sha512', $orderId . $statusCode . $grossAmount . Config::$serverKey);
        return $hashed === $signatureKey;
    }

    /**
     * Ambil detail transaksi (untuk verifikasi)
     *
     * @param string $orderId - order ID
     * @return array|null
     */
    public function getTransactionDetail(string $orderId): ?array
    {
        try {
            return Transaction::status($orderId);
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Get client key untuk frontend
     *
     * @return string
     */
    public function getClientKey(): string
    {
        return config('services.midtrans.client_key', env('MIDTRANS_CLIENT_KEY'));
    }

    /**
     * Cek status kesehatan konektivitas layanan Midtrans API
     * Mengembalikan status operasional atau gangguan untuk mekanisme auto fallback
     */
    public function checkHealth(): array
    {
        $serverKey = config('services.midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
        if (empty($serverKey)) {
            return [
                'status' => 'offline',
                'tersedia' => false,
                'pesan' => 'Kunci server Midtrans belum dikonfigurasi.',
                'fallback_ke_cod' => true,
            ];
        }

        try {
            $isProduction = config('services.midtrans.is_production', false);
            $baseUrl = $isProduction ? 'https://api.midtrans.com/v2' : 'https://api.sandbox.midtrans.com/v2';
            $response = \Illuminate\Support\Facades\Http::timeout(3)
                ->withBasicAuth($serverKey, '')
                ->get("{$baseUrl}/token");

            // Midtrans endpoint token merespons 400 Bad Request jika parameter kosong tapi koneksi & autentikasi sukses
            if ($response->status() === 401) {
                return [
                    'status' => 'unauthorized',
                    'tersedia' => false,
                    'pesan' => 'Autentikasi Midtrans gagal (Server Key tidak valid).',
                    'fallback_ke_cod' => true,
                ];
            }

            if ($response->serverError()) {
                return [
                    'status' => 'degraded',
                    'tersedia' => false,
                    'pesan' => 'Server Midtrans sedang mengalami gangguan (HTTP ' . $response->status() . ').',
                    'fallback_ke_cod' => true,
                ];
            }

            return [
                'status' => 'operational',
                'tersedia' => true,
                'pesan' => 'Layanan Midtrans Payment Gateway operasional.',
                'fallback_ke_cod' => false,
            ];
        } catch (\Throwable $th) {
            return [
                'status' => 'offline',
                'tersedia' => false,
                'pesan' => 'Koneksi ke gateway Midtrans terputus: ' . $th->getMessage(),
                'fallback_ke_cod' => true,
            ];
        }
    }
}
