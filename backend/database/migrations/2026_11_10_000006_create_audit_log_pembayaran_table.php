<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_log_pembayaran', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->nullable()->constrained('pesanan')->nullOnDelete();
            $table->string('nomor_pesanan', 100)->nullable()->index();
            $table->foreignId('pelanggan_id')->nullable()->constrained('pelanggan')->nullOnDelete();
            $table->string('metode', 50)->default('midtrans');
            $table->string('jenis_kejadian', 100)->index();
            $table->text('pesan_error')->nullable();
            $table->string('ip_address', 50)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->json('data_tambahan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_log_pembayaran');
    }
};

