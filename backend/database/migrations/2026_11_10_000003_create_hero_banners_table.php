<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hero_banners', function (Blueprint $table) {
            $table->id();
            $table->string('judul')->default('ME MINIMALISM');
            $table->text('subjudul')->nullable();
            $table->string('tag')->default('BARU TIBA // DROP 01');
            $table->string('koleksi')->default('ATELIER ÉDITION 2026');
            $table->string('gambar');
            $table->unsignedInteger('urutan')->default(1);
            $table->boolean('aktif')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hero_banners');
    }
};
