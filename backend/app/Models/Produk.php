<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Produk extends Model
{
    use HasFactory;

    protected $table = 'produk';

    protected $fillable = [
        'kategori_id',
        'nama',
        'harga',
        'tersedia',
        'deskripsi',
        'bahan',
        'merek',
        'gambar',
    ];

    protected $casts = [
        'harga' => 'integer',
        'tersedia' => 'boolean',
    ];

    public function kategori()
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }

    public function varian()
    {
        return $this->hasMany(VarianProduk::class, 'produk_id');
    }

    public function getStokAttribute()
    {
        return (int) $this->varian()->sum('stok');
    }

    public function getGambarUrlAttribute(): ?string
    {
        return $this->gambar ? url('/api/gambar/' . $this->gambar) : null;
    }

    /**
     * Format data sesuai kontrak 7 kunci inti + 2 kolom domain
     */
    public function formatRingkas(): array
    {
        return [
            'id' => $this->id,
            'nama' => $this->nama,
            'harga' => (int) $this->harga,
            'kategori' => $this->kategori ? $this->kategori->nama : '',
            'stok' => (int) $this->varian->sum('stok'),
            'tersedia' => (bool) $this->tersedia,
            'deskripsi' => $this->deskripsi,
            'bahan' => $this->bahan,
            'merek' => $this->merek,
            'gambar' => $this->gambar,
            'gambar_url' => $this->gambar_url,
            'varian' => $this->varian ? $this->varian->map(function ($v) {
                return [
                    'id' => $v->id,
                    'ukuran' => $v->ukuran,
                    'warna' => $v->warna,
                    'stok' => (int) $v->stok,
                ];
            })->values()->all() : [],
        ];
    }

    /**
     * Format rincian produk lengkap dengan array varian
     */
    public function formatRincian(): array
    {
        $data = $this->formatRingkas();
        $data['varian'] = $this->varian->map(function ($v) {
            return [
                'id' => $v->id,
                'ukuran' => $v->ukuran,
                'warna' => $v->warna,
                'stok' => (int) $v->stok,
            ];
        })->values()->all();

        return $data;
    }
}

