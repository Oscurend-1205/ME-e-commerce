<?php

use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\KeranjangController;
use App\Http\Controllers\Api\KurirController;
use App\Http\Controllers\Api\MetodePembayaranController;
use App\Http\Controllers\Api\OngkirController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\ProdukController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - Toko Online Pakaian & Aksesori (ME)
|--------------------------------------------------------------------------
| Semua 14 endpoint wajib sesuai Bagian 5 PRD
| Semua respon dibungkus dalam format standar (status, code, message, data, errors)
*/

// 1. Endpoint Produk (CRUD, filter, pencarian)
Route::get('/produk', [ProdukController::class, 'index']);
Route::get('/produk/{id}', [ProdukController::class, 'show']);
Route::post('/produk', [ProdukController::class, 'store']);
Route::put('/produk/{id}', [ProdukController::class, 'update']);
Route::delete('/produk/{id}', [ProdukController::class, 'destroy']);

// 2. Endpoint Keranjang (Item per varian, subtotal server)
Route::get('/keranjang', [KeranjangController::class, 'index']);
Route::post('/keranjang', [KeranjangController::class, 'store']);
Route::put('/keranjang/{id}', [KeranjangController::class, 'update']);
Route::delete('/keranjang/{id}', [KeranjangController::class, 'destroy']);

// 3. Endpoint Kurir & Metode Pembayaran
Route::get('/kurir', [KurirController::class, 'index']);
Route::get('/metode-pembayaran', [MetodePembayaranController::class, 'index']);

// 3.5 Endpoint Ongkir Real-time (RajaOngkir)
Route::post('/ongkir', [OngkirController::class, 'cekOngkir']);
Route::get('/kota', [OngkirController::class, 'getKota']);
Route::get('/provinsi', [OngkirController::class, 'getProvinsi']);
Route::get('/kecamatan', [OngkirController::class, 'getKecamatan']);

// 4. Endpoint Checkout (Transaksi atomik, lockForUpdate, idempotensi)
Route::post('/checkout', [CheckoutController::class, 'store']);

// 4.5 Endpoint Payment (Midtrans callback)
Route::post('/payment/callback', [PaymentController::class, 'callback']);
Route::get('/payment/status/{orderId}', [PaymentController::class, 'checkStatus']);

// 5. Endpoint Pesanan & Ubah Status
Route::get('/pesanan', [PesananController::class, 'index']);
Route::get('/pesanan/{id}', [PesananController::class, 'show']);
Route::patch('/pesanan/{id}/status', [PesananController::class, 'updateStatus']);

// 6. Endpoint Gambar Produk & Banner dari Storage (CORS-enabled untuk Flutter Web & Mobile)
Route::get('/gambar/{filename}', function ($filename) {
    $cleanName = basename($filename);
    $path = storage_path('app/public/produk/' . $cleanName);
    if (!file_exists($path)) {
        $path = storage_path('app/public/' . $filename);
    }
    if (!file_exists($path)) {
        $fallback = storage_path('app/public/produk/1.jpg');
        if (file_exists($fallback)) {
            $path = $fallback;
        } else {
            abort(404, 'Gambar tidak ditemukan: ' . $cleanName);
        }
    }
    $mime = mime_content_type($path) ?: 'image/jpeg';
    return response()->file($path, [
        'Content-Type' => $mime,
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Cache-Control' => 'public, max-age=86400',
    ]);
})->where('filename', '.*');


