<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HeroBanner extends Model
{
    protected $table = 'hero_banners';

    protected $fillable = [
        'judul',
        'subjudul',
        'tag',
        'koleksi',
        'gambar',
        'gambar_tambahan',
        'urutan',
        'aktif',
    ];

    protected $casts = [
        'aktif' => 'boolean',
        'urutan' => 'integer',
        'gambar_tambahan' => 'array',
    ];

    public function getGambarUrlAttribute(): ?string
    {
        if (blank($this->gambar)) {
            return null;
        }
        if (str_starts_with($this->gambar, 'http://') || str_starts_with($this->gambar, 'https://')) {
            return $this->gambar;
        }

        return url('/api/gambar/'.basename($this->gambar));
    }
}
