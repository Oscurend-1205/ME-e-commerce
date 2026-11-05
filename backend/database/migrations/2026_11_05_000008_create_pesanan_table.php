<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pesanan', function (Blueprint $table) {
            $table->id();
            $table->string('nomor_pesanan')->unique();
            $table->foreignId('pelanggan_id')->constrained('pelanggan')->cascadeOnDelete();
            $table->foreignId('kurir_id')->constrained('kurir');
            $table->foreignId('metode_pembayaran_id')->constrained('metode_pembayaran');
            $table->string('nama_penerima');
            $table->text('alamat');
            $table->unsignedInteger('subtotal');
            $table->unsignedInteger('ongkir');
            $table->unsignedInteger('total');
            $table->string('status')->default('menunggu_pembayaran');
            $table->string('kunci_idempoten');
            $table->timestamps();

            $table->unique(['pelanggan_id', 'kunci_idempoten'], 'unique_pelanggan_idempoten');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pesanan');
    }
};
