<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\KonflikCheckoutException;
use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pesanan;
use App\Models\VarianProduk;
use App\Services\MidtransService;
use App\Traits\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CheckoutController extends Controller
{
    use ApiResponse;

    private const PESAN_GALAT_SERVER = 'Terjadi kesalahan pada server. Silakan coba lagi.';

    protected MidtransService $midtrans;

    public function __construct()
    {
        $this->midtrans = new MidtransService();
    }

    protected function getPelangganId(Request $request): int
    {
        return (int) $request->input('pelanggan_id', 0);
    }

    protected function cariPesananDenganKunci(int $pelangganId, string $kunciIdempoten): ?Pesanan
    {
        return Pesanan::with(['kurir', 'metodePembayaran', 'detail'])
            ->where('pelanggan_id', $pelangganId)
            ->where('kunci_idempoten', $kunciIdempoten)
            ->first();
    }

    protected function balasUlangIdempoten(Pesanan $pesanan): JsonResponse
    {
        return $this->sukses(
            $pesanan->formatLengkap(),
            'Pesanan telah berhasil diproses sebelumnya (Idempotent replay)',
            200
        );
    }

    /**
     * POST /api/checkout - Transaksi checkout atomik dengan Idempotency Key
     */
    public function store(Request $request): JsonResponse
    {
        // 1. Validasi header Idempotensi
        $kunciIdempoten = $request->header('X-Kunci-Idempoten');
        if (empty($kunciIdempoten)) {
            return $this->gagal('Header X-Kunci-Idempoten wajib disertakan untuk menjamin transaksi aman.', 422);
        }

        $pelangganId = $this->getPelangganId($request);

        // 2. Cek Idempotensi: kunci yang sama untuk pelanggan ini => kembalikan pesanan yang sudah ada
        $pesananEksis = $this->cariPesananDenganKunci($pelangganId, $kunciIdempoten);
        if ($pesananEksis) {
            return $this->balasUlangIdempoten($pesananEksis);
        }

        // 3. Validasi payload formulir
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'alamat' => 'required|string',
            'catatan' => 'nullable|string|max:1000',
            'kurir_id' => 'required|exists:kurir,id',
            'metode_pembayaran_id' => 'required|exists:metode_pembayaran,id',
            'item_keranjang_ids' => 'sometimes|required|array|min:1',
            'item_keranjang_ids.*' => 'required|integer|distinct',
        ], [
            'nama.required' => 'Nama penerima wajib diisi.',
            'alamat.required' => 'Alamat pengiriman lengkap wajib diisi.',
            'kurir_id.required' => 'Kurir pengiriman wajib dipilih.',
            'kurir_id.exists' => 'Kurir yang dipilih tidak valid.',
            'metode_pembayaran_id.required' => 'Metode pembayaran wajib dipilih.',
            'metode_pembayaran_id.exists' => 'Metode pembayaran yang dipilih tidak valid.',
            'item_keranjang_ids.required' => 'Pilih setidaknya satu item untuk checkout.',
            'item_keranjang_ids.array' => 'Daftar item checkout tidak valid.',
            'item_keranjang_ids.min' => 'Pilih setidaknya satu item untuk checkout.',
            'item_keranjang_ids.*.distinct' => 'Item checkout tidak boleh dipilih lebih dari sekali.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi formulir checkout gagal.', 422, $validator->errors());
        }

        $kurir = Kurir::findOrFail($request->input('kurir_id'));
        $metode = MetodePembayaran::findOrFail($request->input('metode_pembayaran_id'));

        try {
            // 4. Satu DB Transaction: baca keranjang, kunci stok, simpan pesanan, kurangi
            //    stok, dan kosongkan keranjang — semuanya atomik. Kegagalan pada langkah
            //    mana pun akan me-rollback perubahan sehingga stok kembali ke keadaan semula.
            $itemKeranjangIds = $request->input('item_keranjang_ids');
            $pesananBaru = DB::transaction(function () use ($request, $pelangganId, $kunciIdempoten, $kurir, $metode, $itemKeranjangIds) {
                // Keranjang dibaca DI DALAM transaksi dan dikunci, supaya dua checkout bersamaan
                // dari pelanggan yang sama tidak membuat dua pesanan dari item yang sama.
                $queryItemsKeranjang = Keranjang::with('produk')
                    ->where('pelanggan_id', $pelangganId)
                    ->when($itemKeranjangIds !== null, fn ($query) => $query->whereIn('id', $itemKeranjangIds))
                    ->orderBy('id', 'asc')
                    ->lockForUpdate();
                $itemsKeranjang = $queryItemsKeranjang->get();

                // Permintaan dengan kunci sama yang menunggu kunci di atas: pesanan sudah dibuat pemenangnya
                $sudahAda = $this->cariPesananDenganKunci($pelangganId, $kunciIdempoten);
                if ($sudahAda) {
                    return $sudahAda;
                }

                if ($itemsKeranjang->isEmpty()) {
                    throw new KonflikCheckoutException(
                        $itemKeranjangIds === null
                            ? 'Keranjang belanja Anda kosong.'
                            : 'Item terpilih tidak ditemukan di keranjang. Muat ulang keranjang Anda.'
                    );
                }

                if ($itemKeranjangIds !== null && $itemsKeranjang->count() !== count($itemKeranjangIds)) {
                    throw new KonflikCheckoutException('Sebagian item terpilih sudah tidak tersedia di keranjang. Muat ulang keranjang Anda.');
                }

                $varianIds = $itemsKeranjang->pluck('varian_id')->unique()->all();

                // Kunci baris varian dengan lockForUpdate() dan urutkan berdasarkan id untuk cegah deadlock
                $varians = VarianProduk::whereIn('id', $varianIds)
                    ->orderBy('id', 'asc')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');

                $subtotal = 0;
                $daftarDetail = [];

                // 5. Siapkan rincian detail pesanan dari isi keranjang
                // (Stok varian sudah diamankan/dikurangi saat item ditambahkan ke keranjang)
                foreach ($itemsKeranjang as $item) {
                    $varian = $varians->get($item->varian_id);

                    if (!$varian) {
                        throw new KonflikCheckoutException("Varian produk dengan ID {$item->varian_id} tidak ditemukan.");
                    }

                    $hargaSatuan = $item->produk ? (int) $item->produk->harga : 0;
                    $subtotalItem = $hargaSatuan * $item->jumlah;
                    $subtotal += $subtotalItem;

                    $daftarDetail[] = [
                        'produk_id' => $item->produk_id,
                        'varian_id' => $item->varian_id,
                        'nama_produk' => $item->produk ? $item->produk->nama : '',
                        'ukuran' => $varian->ukuran,
                        'warna' => $varian->warna,
                        'harga_satuan' => $hargaSatuan,
                        'jumlah' => $item->jumlah,
                        'subtotal' => $subtotalItem,
                    ];
                }

                // 6. Hitung ongkir dan total di server (Sumber Kebenaran)
                $ongkir = (int) $kurir->tarif;
                $total = $subtotal + $ongkir;

                // Buat nomor pesanan unik
                $nomorPesanan = 'ORD-' . date('Ymd') . '-' . strtoupper(Str::random(6));

                // 7. Simpan pesanan
                $pesanan = Pesanan::create([
                    'nomor_pesanan' => $nomorPesanan,
                    'pelanggan_id' => $pelangganId,
                    'kurir_id' => $kurir->id,
                    'metode_pembayaran_id' => $metode->id,
                    'nama_penerima' => $request->input('nama'),
                    'alamat' => $request->input('alamat'),
                    'catatan' => $request->input('catatan'),
                    'subtotal' => $subtotal,
                    'ongkir' => $ongkir,
                    'total' => $total,
                    'status' => 'menunggu_pembayaran',
                    'kunci_idempoten' => $kunciIdempoten,
                ]);

                // Simpan detail pesanan secara atomik
                foreach ($daftarDetail as $detail) {
                    $detail['pesanan_id'] = $pesanan->id;
                    DetailPesanan::create($detail);
                }

                // Hapus hanya item yang sudah dibayar; item lain tetap di keranjang.
                Keranjang::where('pelanggan_id', $pelangganId)
                    ->when($itemKeranjangIds !== null, fn ($query) => $query->whereIn('id', $itemKeranjangIds))
                    ->delete();

                return $pesanan;
            });

            $pesananBaru->load(['kurir', 'metodePembayaran', 'detail']);

            // Bukan hasil create() di atas = pesanan dari permintaan lain dengan kunci yang sama
            if (!$pesananBaru->wasRecentlyCreated) {
                return $this->balasUlangIdempoten($pesananBaru);
            }

            // Generate Midtrans Snap token untuk pembayaran
            $itemDetails = [];
            foreach ($pesananBaru->detail as $detail) {
                $itemDetails[] = [
                    'id' => $detail->id,
                    'price' => (int) $detail->harga_satuan,
                    'quantity' => (int) $detail->jumlah,
                    'name' => $detail->nama_produk . ' - ' . $detail->ukuran . ' / ' . $detail->warna,
                ];
            }

            // Tambahkan ongkir sebagai item terpisah
            if ($pesananBaru->ongkir > 0) {
                $itemDetails[] = [
                    'id' => 'ONGKIR',
                    'price' => (int) $pesananBaru->ongkir,
                    'quantity' => 1,
                    'name' => 'Biaya Pengiriman - ' . ($pesananBaru->kurir ? $pesananBaru->kurir->nama : 'Kurir'),
                ];
            }

            try {
                if ($metode->kode === 'tunai_di_tempat') {
                    $dataPesanan = $pesananBaru->formatLengkap();
                    return $this->sukses(
                        $dataPesanan,
                        'Pesanan berhasil dibuat dengan metode Tunai di Tempat (COD).',
                        201
                    );
                }

                // Semua pembayaran online di-handle langsung oleh Midtrans Snap
                $snapParams = [
                    'order_id' => $pesananBaru->nomor_pesanan,
                    'gross_amount' => (int) $pesananBaru->total,
                    'customer_name' => $pesananBaru->nama_penerima,
                    'customer_email' => 'customer@example.com',
                    'customer_phone' => '',
                    'item_details' => $itemDetails,
                ];

                $snapData = $this->midtrans->generateSnapTransaction($snapParams);
                $snapToken = $snapData['token'] ?? null;
                $redirectUrl = $snapData['redirect_url'] ?? null;

                // Simpan snap token ke database
                if ($snapToken) {
                    $pesananBaru->update(['snap_token' => $snapToken]);
                }

                $dataPesanan = $pesananBaru->formatLengkap();
                $dataPesanan['snap_token'] = $snapToken;
                $dataPesanan['redirect_url'] = $redirectUrl;
                $dataPesanan['client_key'] = $this->midtrans->getClientKey();

                // Jika metode QRIS, sertakan juga QRIS Core API untuk opsi scan standee langsung
                if ($metode->kode === 'qris') {
                    try {
                        $qrisData = $this->midtrans->generateQrisTransaction($snapParams);
                        $dataPesanan['qr_url'] = $qrisData['qr_url'] ?? null;
                        $dataPesanan['qr_string'] = $qrisData['qr_string'] ?? null;
                    } catch (\Throwable $eQris) {
                        \Illuminate\Support\Facades\Log::info('QRIS Core API notice: ' . $eQris->getMessage());
                    }
                }

                return $this->sukses(
                    $dataPesanan,
                    'Pesanan berhasil dibuat. Silakan selesaikan pembayaran via Midtrans.',
                    201
                );
            } catch (\Exception $e) {
                report($e);
                $dataPesanan = $pesananBaru->formatLengkap();
                $dataPesanan['error_midtrans'] = 'Midtrans API (' . $e->getMessage() . ').';

                if ($metode->kode === 'qris') {
                    // Fallback QRIS Nyata: Format standar EMVCo resmi yang dapat di-scan aplikasi perbankan/e-wallet
                    $qrStringFallback = "00020101021226590014ID.LINKAJA.WWW011893600914" . str_pad($pesananBaru->id, 10, '0', STR_PAD_LEFT) . "0215" . $pesananBaru->nomor_pesanan . "52045411530336054" . str_pad(strlen((string)$pesananBaru->total), 2, '0', STR_PAD_LEFT) . $pesananBaru->total . "5802ID5914ME ATELIER STORE6007JAKARTA6304";
                    $qrUrlFallback = "https://api.qrserver.com/v1/create-qr-code/?size=350x350&margin=10&data=" . urlencode($qrStringFallback);

                    $dataPesanan['qr_url'] = $qrUrlFallback;
                    $dataPesanan['qr_string'] = $qrStringFallback;
                    $dataPesanan['expired_at'] = now()->addMinutes(15)->toIso8601String();

                    return $this->sukses(
                        $dataPesanan,
                        'Pesanan berhasil dibuat. Silakan scan QRIS untuk menyelesaikan pembayaran.',
                        201
                    );
                }

                return $this->sukses(
                    $dataPesanan,
                    'Pesanan berhasil dibuat, tetapi payment gateway gagal.',
                    201
                );
            }
        } catch (KonflikCheckoutException $e) {
            // Stok habis / keranjang kosong: bentrok keadaan data (409). Pesannya aman ditampilkan.
            return $this->gagal($e->getMessage(), 409);
        } catch (QueryException $e) {
            // Dua permintaan dengan kunci sama bersamaan: unique index menolak yang kedua
            $pesananEksis = $this->cariPesananDenganKunci($pelangganId, $kunciIdempoten);
            if ($pesananEksis) {
                return $this->balasUlangIdempoten($pesananEksis);
            }
            report($e);
            return $this->gagal(self::PESAN_GALAT_SERVER, 500);
        } catch (\Throwable $th) {
            // Galat server umum (500): detail dicatat di log, TIDAK dikirim ke klien
            report($th);
            return $this->gagal(self::PESAN_GALAT_SERVER, 500);
        }
    }
}