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
        return $this->gambar ? url('/api/gambar/' . $this->gambar) : null;
    }
}
