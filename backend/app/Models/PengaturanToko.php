<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PengaturanToko extends Model
{
    protected $table = 'pengaturan_toko';

    protected $fillable = [
        'nama_toko',
        'telepon',
        'email',
        'alamat_lengkap',
        'kota_id',
        'nama_kota',
        'provinsi_id',
        'nama_provinsi',
        'kode_pos',
        'kurir_aktif',
    ];

    /**
     * Dapatkan satu-satunya baris data profil & konfigurasi toko.
     * Jika belum ada di database, buat otomatis dengan konfigurasi default.
     */
    public static function getPengaturan(): self
    {
        return static::firstOrCreate(
            ['id' => 1],
            [
                'nama_toko' => 'ME Atelier',
                'telepon' => '081234567890',
                'email' => 'contact@me-atelier.com',
                'alamat_lengkap' => 'Jl. Kaliurang KM 5 No. 42, Sleman',
                'kota_id' => '501', // Kabupaten Sleman
                'nama_kota' => 'Kabupaten Sleman',
                'provinsi_id' => '5', // DI Yogyakarta
                'nama_provinsi' => 'DI Yogyakarta',
                'kode_pos' => '55281',
                'kurir_aktif' => 'jne,sicepat,jnt,pos',
            ]
        );
    }

    /**
     * Ambil ID kota asal pengiriman default untuk RajaOngkir.
     */
    public static function getOriginKotaId(): string
    {
        return (string) (static::getPengaturan()->kota_id ?: '501');
    }
}

