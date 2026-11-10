<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FotoProduk extends Model
{
    use HasFactory;

    protected $table = 'foto_produk';

    protected $fillable = [
        'produk_id',
        'nama_file',
        'urutan',
    ];

    protected $casts = [
        'urutan' => 'integer',
    ];

    public function produk()
    {
        return $this->belongsTo(Produk::class, 'produk_id');
    }

    public function getUrlAttribute(): string
    {
        if (blank($this->nama_file)) {
            return url('/api/gambar/1.jpg');
        }
        if (str_starts_with($this->nama_file, 'http://') || str_starts_with($this->nama_file, 'https://')) {
            return $this->nama_file;
        }
        return url('/api/gambar/' . basename($this->nama_file));
    }
}

