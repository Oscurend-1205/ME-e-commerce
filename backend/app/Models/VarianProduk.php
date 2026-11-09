<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VarianProduk extends Model
{
    use HasFactory;

    protected $table = 'varian_produk';

    protected $fillable = [
        'produk_id',
        'ukuran',
        'warna',
        'stok',
        'sku',
    ];

    protected $casts = [
        'stok' => 'integer',
    ];

    protected static function booted(): void
    {
        static::creating(function (VarianProduk $varian): void {
            if (blank($varian->sku)) {
                $varian->sku = static::buatSku($varian);
            }
        });
    }

    public static function buatSku(VarianProduk $varian): string
    {
        $produk = $varian->produk;
        $merekBersih = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $produk?->merek ?? 'ME'));
        $merek = substr($merekBersih !== '' ? $merekBersih : 'ME', 0, 3);
        $produkId = $produk?->id ?? $varian->produk_id ?? 0;

        return $merek.'-'.$produkId
            .'-'.strtoupper(substr($varian->ukuran, 0, 2))
            .'-'.strtoupper(substr($varian->warna, 0, 3));
    }

    public function produk()
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }
}
