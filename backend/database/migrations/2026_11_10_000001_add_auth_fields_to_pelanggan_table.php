<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tambahkan kolom autentikasi ke tabel pelanggan:
     * email (unik), password, no_telp, foto, api_token.
     */
    public function up(): void
    {
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->string('email')->nullable()->unique()->after('nama');
            $table->string('password')->nullable()->after('email');
            $table->string('no_telp', 20)->nullable()->after('password');
            $table->string('foto')->nullable()->after('no_telp');
            $table->string('api_token', 80)->nullable()->unique()->after('foto');
        });
    }

    public function down(): void
    {
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->dropColumn(['email', 'password', 'no_telp', 'foto', 'api_token']);
        });
    }
};
