<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Konflik keadaan saat checkout (stok kurang, keranjang kosong, varian hilang).
 * Dipisahkan dari RuntimeException umum supaya galat basis data (QueryException,
 * yang juga turunan RuntimeException) TIDAK ikut dibalas sebagai 409 beserta pesan SQL mentah.
 */
class KonflikCheckoutException extends RuntimeException
{
}