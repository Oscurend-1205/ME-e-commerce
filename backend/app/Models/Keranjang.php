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

    /**
     * Kurangi isi keranjang sesuai detail pesanan yang SUDAH DIBAYAR.
     *
     * Item keranjang sengaja TIDAK dihapus saat checkout — baru berkurang
     * di sini saat pembayaran dikonfirmasi, sehingga barang tidak hilang
     * dari keranjang selama proses checkout masih berjalan. Jika pengguna
     * menambah/megubah jumlah setelah checkout, hanya porsi yang dipesan
     * yang berkurang.
     */
    public static function kurangiUntukPesanan(Pesanan $pesanan): void
    {
        $pesanan->loadMissing('detail');

        foreach ($pesanan->detail as $detail) {
            if (!$detail->varian_id) {
                continue;
            }

            $item = static::where('pelanggan_id', $pesanan->pelanggan_id)
                ->where('varian_id', $detail->varian_id)
                ->lockForUpdate()
                ->first();

            if (!$item) {
                continue;
            }

            $sisa = $item->jumlah - (int) $detail->jumlah;
            if ($sisa <= 0) {
                $item->delete();
            } else {
                $item->jumlah = $sisa;
                $item->save();
            }
        }
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
            'gambar' => $this->produk ? $this->produk->gambar : ($this->produk_id ? "{$this->produk_id}.jpg" : null),
        ];
    }
}

