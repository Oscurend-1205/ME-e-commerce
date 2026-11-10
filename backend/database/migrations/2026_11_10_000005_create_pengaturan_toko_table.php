<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengaturan_toko', function (Blueprint $table) {
            $table->id();
            $table->string('nama_toko')->default('ME Atelier');
            $table->string('telepon')->nullable()->default('081234567890');
            $table->string('email')->nullable()->default('contact@me-atelier.com');
            $table->string('alamat_lengkap', 500)->nullable()->default('Jl. Kaliurang KM 5 No. 42, Sleman');
            $table->string('kota_id', 10)->default('501'); // ID kota RajaOngkir (501: Sleman, 419: Yogyakarta, 153: Jakarta Selatan)
            $table->string('nama_kota')->default('Kabupaten Sleman');
            $table->string('provinsi_id', 10)->nullable()->default('5'); // DI Yogyakarta
            $table->string('nama_provinsi')->nullable()->default('DI Yogyakarta');
            $table->string('kode_pos', 10)->nullable()->default('55281');
            $table->string('kurir_aktif')->default('jne,sicepat,jnt,pos');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengaturan_toko');
    }
};
