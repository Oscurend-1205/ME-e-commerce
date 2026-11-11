<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pesanan extends Model
{
    use HasFactory;

    protected $table = 'pesanan';

    /**
     * Tabel perpindahan status pesanan yang sah (satu-satunya sumber kebenaran).
     * Urutan online: menunggu_pembayaran -> menunggu_konfirmasi -> dibayar -> diproses -> dikirim -> selesai.
     * Urutan COD: menunggu_verifikasi -> diproses -> dikirim -> selesai.
     * Fallback: menunggu_pembayaran -> menunggu_verifikasi (jika Midtrans gagal).
     */
    public const TRANSISI_SAH = [
        'menunggu_pembayaran' => ['menunggu_konfirmasi', 'menunggu_verifikasi', 'dibayar', 'dibatalkan'],
        'menunggu_verifikasi' => ['diproses', 'dibatalkan'],
        'menunggu_konfirmasi' => ['dibayar', 'diproses', 'dibatalkan'],
        'dibayar' => ['diproses'],
        'diproses' => ['dikirim', 'dibatalkan'],
        'dikirim' => ['selesai', 'dibatalkan'],
        'selesai' => [],
        'dibatalkan' => [],
    ];

    protected $fillable = [
        'nomor_pesanan',
        'pelanggan_id',
        'kurir_id',
        'metode_pembayaran_id',
        'nama_penerima',
        'alamat',
        'catatan',
        'subtotal',
        'ongkir',
        'total',
        'status',
        'kunci_idempoten',
        'snap_token',
    ];

    protected $casts = [
        'subtotal' => 'integer',
        'ongkir' => 'integer',
        'total' => 'integer',
    ];

    public function pelanggan()
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id');
    }

    public function kurir()
    {
        return $this->belongsTo(Kurir::class, 'kurir_id');
    }

    public function metodePembayaran()
    {
        return $this->belongsTo(MetodePembayaran::class, 'metode_pembayaran_id');
    }

    public function detail()
    {
        return $this->hasMany(DetailPesanan::class, 'pesanan_id');
    }

    /**
     * Daftar status tujuan yang sah dari status pesanan saat ini.
     */
    public function pilihanStatusBerikutnya(): array
    {
        return self::TRANSISI_SAH[strtolower((string) $this->status)] ?? [];
    }

    /**
     * Apakah pesanan boleh berpindah ke status tujuan tertentu.
     */
    public function bolehPindahKe(string $tujuan): bool
    {
        return in_array(strtolower($tujuan), $this->pilihanStatusBerikutnya(), true);
    }

    /**
     * Kembalikan stok untuk semua item varian dalam pesanan ini (misal saat dibatalkan).
     */
    public function kembalikanStok(): void
    {
        $this->loadMissing('detail');
        foreach ($this->detail as $item) {
            if ($item->varian_id) {
                VarianProduk::where('id', $item->varian_id)->increment('stok', $item->jumlah);
            }
        }
    }

    public function isCod(): bool
    {
        $kode = strtolower((string) ($this->metodePembayaran?->kode ?? ''));
        return in_array($kode, ['tunai_di_tempat', 'cod', 'cash_on_delivery'], true);
    }

    public function formatLengkap(): array
    {
        $isCod = $this->isCod();
        $metodeKode = $this->metodePembayaran ? $this->metodePembayaran->kode : null;

        return [
            'id' => $this->id,
            'nomor_pesanan' => $this->nomor_pesanan,
            'status' => $this->status,
            'subtotal' => (int) $this->subtotal,
            'ongkir' => (int) $this->ongkir,
            'total' => (int) $this->total,
            'nama_penerima' => $this->nama_penerima,
            'alamat' => $this->alamat,
            'catatan' => $this->catatan,
            'pelanggan' => $this->pelanggan ? [
                'id' => $this->pelanggan->id,
                'nama' => $this->pelanggan->nama,
                'email' => $this->pelanggan->email,
                'nomor_telepon' => $this->pelanggan->nomor_telepon,
            ] : null,
            'nama_kurir' => $this->kurir ? "{$this->kurir->nama} - {$this->kurir->wilayah}" : null,
            'kurir' => $this->kurir ? [
                'id' => $this->kurir->id,
                'nama' => $this->kurir->nama,
                'wilayah' => $this->kurir->wilayah,
                'tarif' => (int) $this->kurir->tarif,
                'estimasi' => str_contains(strtolower($this->kurir->wilayah ?? ''), 'jabodetabek')
                    ? 'Tiba Besok, 18:00 WIB'
                    : '2-4 Hari Kerja',
            ] : null,
            'metode_pembayaran' => $this->metodePembayaran ? $this->metodePembayaran->nama : null,
            'metode_kode' => $metodeKode,
            'is_cod' => $isCod,
            'instruksi_cod' => $isCod ? [
                'judul' => 'Instruksi Pembayaran Tunai di Tempat (COD)',
                'poin' => [
                    'Siapkan uang tunai pas sebesar Rp ' . number_format((int) $this->total, 0, ',', '.') . ' saat kurir tiba.',
                    'Pastikan nomor telepon penerima aktif untuk konfirmasi pengiriman oleh kurir.',
                    'Periksa kemasan paket segel atelier sebelum melakukan pembayaran ke kurir.',
                    'Simpan bukti tanda terima pembayaran dari kurir sebagai bukti transaksi sah.',
                ],
            ] : null,
            'fallback_cod_tersedia' => !$isCod && $this->status === 'menunggu_pembayaran' && (int) $this->total <= 2500000,
            'snap_token' => $this->snap_token,
            'redirect_url' => !empty($this->snap_token)
                ? (config('services.midtrans.is_production', false)
                    ? "https://app.midtrans.com/snap/v4/redirection/{$this->snap_token}"
                    : "https://app.sandbox.midtrans.com/snap/v4/redirection/{$this->snap_token}")
                : null,
            'qr_url' => !empty($this->snap_token)
                ? "https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=" . urlencode(
                    config('services.midtrans.is_production', false)
                        ? "https://app.midtrans.com/snap/v4/redirection/{$this->snap_token}"
                        : "https://app.sandbox.midtrans.com/snap/v4/redirection/{$this->snap_token}"
                )
                : null,
            'created_at' => $this->created_at ? $this->created_at->format('Y-m-d H:i:s') : null,
            'detail' => $this->detail->map(function ($d) {
                return [
                    'id' => $d->id,
                    'produk_id' => $d->produk_id,
                    'varian_id' => $d->varian_id,
                    'nama_produk' => $d->nama_produk,
                    'ukuran' => $d->ukuran,
                    'warna' => $d->warna,
                    'harga_satuan' => (int) $d->harga_satuan,
                    'jumlah' => (int) $d->jumlah,
                    'subtotal' => (int) $d->subtotal,
                    'gambar' => $d->produk ? $d->produk->gambar : ($d->produk_id ? "{$d->produk_id}.jpg" : null),
                ];
            })->values()->all(),
        ];
    }
}

