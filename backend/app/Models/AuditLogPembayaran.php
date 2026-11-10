<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class AuditLogPembayaran extends Model
{
    use HasFactory;

    protected $table = 'audit_log_pembayaran';

    protected $fillable = [
        'pesanan_id',
        'nomor_pesanan',
        'pelanggan_id',
        'metode',
        'jenis_kejadian',
        'pesan_error',
        'ip_address',
        'user_agent',
        'data_tambahan',
    ];

    protected $casts = [
        'data_tambahan' => 'array',
    ];

    public function pesanan()
    {
        return $this->belongsTo(Pesanan::class, 'pesanan_id');
    }

    public function pelanggan()
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    /**
     * Catat kejadian audit pembayaran
     */
    public static function catat(
        string $jenisKejadian,
        ?Pesanan $pesanan = null,
        string $metode = 'midtrans',
        ?string $pesanError = null,
        ?array $dataTambahan = null,
        ?Request $request = null
    ): self {
        $req = $request ?? request();

        return static::create([
            'pesanan_id' => $pesanan?->id,
            'nomor_pesanan' => $pesanan?->nomor_pesanan,
            'pelanggan_id' => $pesanan?->pelanggan_id,
            'metode' => $metode,
            'jenis_kejadian' => $jenisKejadian,
            'pesan_error' => $pesanError,
            'ip_address' => $req?->ip(),
            'user_agent' => $req?->header('User-Agent'),
            'data_tambahan' => $dataTambahan,
        ]);
    }
}

