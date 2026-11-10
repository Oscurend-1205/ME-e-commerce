<?php

namespace Tests\Feature;

use App\Models\AuditLogPembayaran;
use App\Models\Kategori;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\VarianProduk;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class CodPaymentFallbackTest extends TestCase
{
    use RefreshDatabase;

    protected Pelanggan $pelanggan;
    protected Kurir $kurir;
    protected MetodePembayaran $metodeMidtrans;
    protected MetodePembayaran $metodeCod;
    protected Produk $produk;
    protected VarianProduk $varian;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pelanggan = Pelanggan::create([
            'id' => 1,
            'nama' => 'Auril Aditya',
            'email' => 'auril@toko-me.test',
            'password' => 'password',
            'no_telp' => '081234567890',
        ]);

        $this->kurir = Kurir::create([
            'nama' => 'JNE Reguler',
            'wilayah' => 'Dalam Kota (Jabodetabek)',
            'tarif' => 15000,
        ]);

        $this->metodeMidtrans = MetodePembayaran::create([
            'kode' => 'midtrans',
            'nama' => 'Midtrans Payment Gateway',
        ]);

        $this->metodeCod = MetodePembayaran::create([
            'kode' => 'tunai_di_tempat',
            'nama' => 'Tunai di Tempat (COD)',
        ]);

        $kategori = Kategori::create(['nama' => 'Atasan']);
        $this->produk = Produk::create([
            'kategori_id' => $kategori->id,
            'nama' => 'Kemeja Linen Atelier',
            'bahan' => 'Linen Premium',
            'merek' => 'ME Atelier',
            'harga' => 350000,
            'tersedia' => true,
        ]);

        $this->varian = VarianProduk::create([
            'produk_id' => $this->produk->id,
            'ukuran' => 'M',
            'warna' => 'Putih',
            'stok' => 20,
        ]);
    }

    protected function tambahKeKeranjang(int $jumlah = 1): Keranjang
    {
        return Keranjang::create([
            'pelanggan_id' => $this->pelanggan->id,
            'produk_id' => $this->produk->id,
            'varian_id' => $this->varian->id,
            'jumlah' => $jumlah,
        ]);
    }

    public function test_checkout_langsung_dengan_cod_berhasil_dan_status_menunggu_verifikasi(): void
    {
        $item = $this->tambahKeKeranjang(1);

        $response = $this->postJson(
            '/api/checkout',
            [
                'nama' => 'Auril Aditya',
                'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman',
                'kurir_id' => $this->kurir->id,
                'metode_pembayaran_id' => $this->metodeCod->id,
                'item_keranjang_ids' => [$item->id],
            ],
            [
                'X-Pelanggan-Id' => (string) $this->pelanggan->id,
                'X-Kunci-Idempoten' => (string) Str::uuid(),
            ]
        );

        $response->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.status', 'menunggu_verifikasi')
            ->assertJsonPath('data.is_cod', true)
            ->assertJsonPath('data.metode_kode', 'tunai_di_tempat');

        $this->assertDatabaseHas('pesanan', [
            'pelanggan_id' => $this->pelanggan->id,
            'status' => 'menunggu_verifikasi',
            'metode_pembayaran_id' => $this->metodeCod->id,
        ]);

        // Verifikasi audit log tercatat
        $this->assertDatabaseHas('audit_log_pembayaran', [
            'jenis_kejadian' => 'checkout_cod',
            'metode' => 'tunai_di_tempat',
        ]);
    }

    public function test_checkout_cod_gagal_jika_total_melebihi_batas_maksimal(): void
    {
        // 8 x 350.000 = 2.800.000 + 15.000 > 2.500.000 limit COD
        $item = $this->tambahKeKeranjang(8);

        $response = $this->postJson(
            '/api/checkout',
            [
                'nama' => 'Auril Aditya',
                'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman',
                'kurir_id' => $this->kurir->id,
                'metode_pembayaran_id' => $this->metodeCod->id,
                'item_keranjang_ids' => [$item->id],
            ],
            [
                'X-Pelanggan-Id' => (string) $this->pelanggan->id,
                'X-Kunci-Idempoten' => (string) Str::uuid(),
            ]
        );

        $response->assertStatus(409)
            ->assertJsonPath('message', 'Metode Tunai di Tempat (COD) hanya berlaku untuk total belanja maksimal Rp 2.500.000.');
    }

    public function test_checkout_cod_dibatasi_jika_memiliki_terlalu_banyak_pesanan_cod_aktif(): void
    {
        // Buat 2 pesanan COD aktif sebelumnya
        for ($i = 1; $i <= 2; $i++) {
            Pesanan::create([
                'nomor_pesanan' => "ORD-COD-ACTIVE-$i",
                'pelanggan_id' => $this->pelanggan->id,
                'kurir_id' => $this->kurir->id,
                'metode_pembayaran_id' => $this->metodeCod->id,
                'nama_penerima' => 'Auril Aditya',
                'alamat' => 'Alamat Pengiriman',
                'subtotal' => 350000,
                'ongkir' => 15000,
                'total' => 365000,
                'status' => 'menunggu_verifikasi',
                'kunci_idempoten' => Str::uuid(),
            ]);
        }

        $item = $this->tambahKeKeranjang(1);

        $response = $this->postJson(
            '/api/checkout',
            [
                'nama' => 'Auril Aditya',
                'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman',
                'kurir_id' => $this->kurir->id,
                'metode_pembayaran_id' => $this->metodeCod->id,
                'item_keranjang_ids' => [$item->id],
            ],
            [
                'X-Pelanggan-Id' => (string) $this->pelanggan->id,
                'X-Kunci-Idempoten' => (string) Str::uuid(),
            ]
        );

        $response->assertStatus(422)
            ->assertSee('Anda masih memiliki 2 pesanan COD aktif');
    }

    public function test_endpoint_fallback_cod_berhasil_mengalihkan_pesanan_online_ke_cod(): void
    {
        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'ORD-MIDTRANS-FAIL-01',
            'pelanggan_id' => $this->pelanggan->id,
            'kurir_id' => $this->kurir->id,
            'metode_pembayaran_id' => $this->metodeMidtrans->id,
            'nama_penerima' => 'Auril Aditya',
            'alamat' => 'Alamat Pengiriman',
            'subtotal' => 350000,
            'ongkir' => 15000,
            'total' => 365000,
            'status' => 'menunggu_pembayaran',
            'snap_token' => 'mock-snap-token-error',
            'kunci_idempoten' => Str::uuid(),
        ]);

        $response = $this->postJson(
            "/api/pesanan/{$pesanan->id}/fallback-cod",
            ['alasan' => 'Midtrans timeout pada browser klien'],
            ['X-Pelanggan-Id' => (string) $this->pelanggan->id]
        );

        $response->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.status', 'menunggu_verifikasi')
            ->assertJsonPath('data.is_cod', true)
            ->assertJsonPath('data.metode_kode', 'tunai_di_tempat');

        $pesanan->refresh();
        $this->assertEquals('menunggu_verifikasi', $pesanan->status);
        $this->assertEquals($this->metodeCod->id, $pesanan->metode_pembayaran_id);
        $this->assertNull($pesanan->snap_token);

        // Audit log tercatat
        $this->assertDatabaseHas('audit_log_pembayaran', [
            'pesanan_id' => $pesanan->id,
            'jenis_kejadian' => 'fallback_ke_cod',
        ]);
    }

    public function test_alur_transisi_status_pesanan_cod_hingga_selesai(): void
    {
        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'ORD-COD-LIFECYCLE-01',
            'pelanggan_id' => $this->pelanggan->id,
            'kurir_id' => $this->kurir->id,
            'metode_pembayaran_id' => $this->metodeCod->id,
            'nama_penerima' => 'Auril Aditya',
            'alamat' => 'Alamat Pengiriman',
            'subtotal' => 350000,
            'ongkir' => 15000,
            'total' => 365000,
            'status' => 'menunggu_verifikasi',
            'kunci_idempoten' => Str::uuid(),
        ]);

        // Verifikasi transisi yang diizinkan untuk COD
        $this->assertTrue($pesanan->bolehPindahKe('diproses'));
        $this->assertTrue($pesanan->bolehPindahKe('dibatalkan'));
        $this->assertFalse($pesanan->bolehPindahKe('dibayar'));

        // Admin verifikasi & proses
        $pesanan->status = 'diproses';
        $pesanan->save();
        $this->assertTrue($pesanan->bolehPindahKe('dikirim'));

        // Admin kirim ke kurir
        $pesanan->status = 'dikirim';
        $pesanan->save();
        $this->assertTrue($pesanan->bolehPindahKe('selesai'));

        // Kurir serahkan paket & terima uang tunai -> status selesai & lunas
        $headers = ['X-Pelanggan-Id' => (string) $this->pelanggan->id];
        $response = $this->patchJson("/api/pesanan/{$pesanan->id}/status", ['status' => 'selesai'], $headers);

        $response->assertOk()
            ->assertJsonPath('data.status', 'selesai');

        // Verifikasi audit log pembayaran lunas tercatat
        $this->assertDatabaseHas('audit_log_pembayaran', [
            'pesanan_id' => $pesanan->id,
            'jenis_kejadian' => 'cod_selesai_lunas',
        ]);
    }

    public function test_endpoint_status_midtrans_mengembalikan_kesehatan_gateway(): void
    {
        $response = $this->getJson('/api/payment/status-midtrans');

        $response->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonStructure([
                'data' => [
                    'status',
                    'tersedia',
                    'pesan',
                    'fallback_ke_cod',
                ],
            ]);
    }

    public function test_midtrans_error_saat_checkout_otomatis_mencatat_log_dan_menawarkan_fallback_cod(): void
    {
        // Mock server key invalid agar memicu error Midtrans
        config(['services.midtrans.server_key' => 'INVALID_SERVER_KEY_TEST']);

        $item = $this->tambahKeKeranjang(1);

        $response = $this->postJson(
            '/api/checkout',
            [
                'nama' => 'Auril Aditya',
                'alamat' => 'Jl. Kaliurang KM 5 No. 42, Sleman',
                'kurir_id' => $this->kurir->id,
                'metode_pembayaran_id' => $this->metodeMidtrans->id,
                'item_keranjang_ids' => [$item->id],
            ],
            [
                'X-Pelanggan-Id' => (string) $this->pelanggan->id,
                'X-Kunci-Idempoten' => (string) Str::uuid(),
            ]
        );

        $response->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.fallback_cod_tersedia', true)
            ->assertJsonPath('data.status', 'menunggu_pembayaran');

        // Verifikasi audit log kegagalan Midtrans dicatat
        $this->assertDatabaseHas('audit_log_pembayaran', [
            'jenis_kejadian' => 'midtrans_error',
            'metode' => 'midtrans',
        ]);
    }
}
