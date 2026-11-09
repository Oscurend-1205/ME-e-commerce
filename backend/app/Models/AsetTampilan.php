<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AsetTampilan extends Model
{
    protected $table = 'aset_tampilan';

    protected $fillable = [
        'kunci',
        'nama',
        'grup',
        'urutan',
        'gambar',
    ];

    public function getGambarUrlAttribute(): ?string
    {
        if (blank($this->gambar)) {
            return null;
        }
        if (str_starts_with($this->gambar, 'http://') || str_starts_with($this->gambar, 'https://')) {
            return $this->gambar;
        }
        return url('/api/gambar/' . basename($this->gambar));
    }
}
