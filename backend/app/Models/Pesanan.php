<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pesanan extends Model
{
    use HasFactory;

    protected $table = 'pesanan';

    protected $fillable = [
        'nomor_pesanan',
        'pelanggan_id',
        'kurir_id',
        'metode_pembayaran_id',
        'nama_penerima',
        'alamat',
        'subtotal',
        'ongkir',
        'total',
        'status',
        'kunci_idempoten',
    ];

    protected $casts = [
        'subtotal' => 'integer',
        'ongkir' => 'integer',
        'total' => 'integer',
    ];

    public function pelanggan()
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function kurir()
    {
        return $this->belongsTo(Kurir::class, 'kurir_id');
    }

    public function metodePembayaran()
    {
        return $this->belongsTo(MetodePembayaran::class, 'metode_pembayaran_id');
    }

    public function detail()
    {
        return $this->hasMany(DetailPesanan::class, 'pesanan_id');
    }

    public function formatLengkap(): array
    {
        return [
            'id' => $this->id,
            'nomor_pesanan' => $this->nomor_pesanan,
            'status' => $this->status,
            'subtotal' => (int) $this->subtotal,
            'ongkir' => (int) $this->ongkir,
            'total' => (int) $this->total,
            'nama_penerima' => $this->nama_penerima,
            'alamat' => $this->alamat,
            'nama_kurir' => $this->kurir ? "{$this->kurir->nama} - {$this->kurir->wilayah}" : null,
            'metode_pembayaran' => $this->metodePembayaran ? $this->metodePembayaran->nama : null,
            'created_at' => $this->created_at ? $this->created_at->format('Y-m-d H:i:s') : null,
            'detail' => $this->detail->map(function ($d) {
                return [
                    'id' => $d->id,
                    'nama_produk' => $d->nama_produk,
                    'ukuran' => $d->ukuran,
                    'warna' => $d->warna,
                    'harga_satuan' => (int) $d->harga_satuan,
                    'jumlah' => (int) $d->jumlah,
                    'subtotal' => (int) $d->subtotal,
                ];
            })->values()->all(),
        ];
    }
}
