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
     * Generate Snap token untuk pembayaran
     *
     * @param array $params - parameter transaksi
     * @return string - snap token
     */
    public function generateSnapToken(array $params): string
    {
        $transactionDetails = [
            'order_id' => $params['order_id'],
            'gross_amount' => $params['gross_amount'],
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

        return Snap::getSnapToken($transaction);
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
}
