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

    public function produk()
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }
}
