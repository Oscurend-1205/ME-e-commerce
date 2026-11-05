<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('varian_produk', function (Blueprint $table) {
            $table->id();
            $table->foreignId('produk_id')->constrained('produk')->cascadeOnDelete();
            $table->string('ukuran');
            $table->string('warna');
            $table->unsignedInteger('stok')->default(0);
            $table->string('sku')->nullable();
            $table->timestamps();

            $table->unique(['produk_id', 'ukuran', 'warna'], 'unique_varian_produk');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('varian_produk');
    }
};
