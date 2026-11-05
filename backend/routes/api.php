<?php

use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\KeranjangController;
use App\Http\Controllers\Api\KurirController;
use App\Http\Controllers\Api\MetodePembayaranController;
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

// 4. Endpoint Checkout (Transaksi atomik, lockForUpdate, idempotensi)
Route::post('/checkout', [CheckoutController::class, 'store']);

// 5. Endpoint Pesanan & Ubah Status
Route::get('/pesanan', [PesananController::class, 'index']);
Route::get('/pesanan/{id}', [PesananController::class, 'show']);
Route::patch('/pesanan/{id}/status', [PesananController::class, 'updateStatus']);

