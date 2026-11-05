<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Keranjang extends Model
{
    use HasFactory;

    protected $table = 'keranjang';

    protected $fillable = [
        'pelanggan_id',
        'produk_id',
        'varian_id',
        'jumlah',
    ];

    protected $casts = [
        'jumlah' => 'integer',
    ];

    public function pelanggan()
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function produk()
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }

    public function varian()
    {
        return $this->belongsTo(VarianProduk::class, 'varian_id');
    }

    public function formatItem(): array
    {
        $hargaSatuan = $this->produk ? (int) $this->produk->harga : 0;
        $subtotal = $hargaSatuan * (int) $this->jumlah;

        return [
            'id' => $this->id,
            'produk_id' => $this->produk_id,
            'varian_id' => $this->varian_id,
            'nama_produk' => $this->produk ? $this->produk->nama : '',
            'ukuran' => $this->varian ? $this->varian->ukuran : '',
            'warna' => $this->varian ? $this->varian->warna : '',
            'harga_satuan' => $hargaSatuan,
            'jumlah' => (int) $this->jumlah,
            'subtotal_item' => $subtotal,
        ];
    }
}

