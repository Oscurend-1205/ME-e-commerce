<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('aset_tampilan', function (Blueprint $table) {
            $table->id();
            $table->string('kunci')->unique();
            $table->string('nama');
            $table->string('grup')->default('Umum');
            $table->unsignedInteger('urutan')->default(0);
            $table->string('gambar')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('aset_tampilan');
    }
};
