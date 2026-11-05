<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Keranjang;
use App\Models\Kurir;
use App\Models\MetodePembayaran;
use App\Models\Pesanan;
use App\Models\VarianProduk;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CheckoutController extends Controller
{
    use ApiResponse;

    protected function getPelangganId(Request $request): int
    {
        $id = $request->header('X-Pelanggan-Id');
        if ($id && is_numeric($id)) {
            return (int) $id;
        }
        return 1;
    }

    /**
     * POST /api/checkout — Transaksi checkout atomik dengan Idempotency Key
     */
    public function store(Request $request): JsonResponse
    {
        // 1. Validasi header Idempotensi
        $kunciIdempoten = $request->header('X-Kunci-Idempoten');
        if (empty($kunciIdempoten)) {
            return $this->gagal('Header X-Kunci-Idempoten wajib disertakan untuk menjamin transaksi aman.', 422);
        }

        $pelangganId = $this->getPelangganId($request);

        // 2. Cek Idempotensi: Jika kunci idempoten sudah pernah diproses untuk pelanggan ini, kembalikan pesanan yang sudah ada
        $pesananEksis = Pesanan::with(['kurir', 'metodePembayaran', 'detail'])
            ->where('pelanggan_id', $pelangganId)
            ->where('kunci_idempoten', $kunciIdempoten)
            ->first();

        if ($pesananEksis) {
            return $this->sukses(
                $pesananEksis->formatLengkap(),
                'Pesanan telah berhasil diproses sebelumnya (Idempotent replay)',
                200
            );
        }

        // 3. Validasi payload formulir
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'alamat' => 'required|string',
            'kurir_id' => 'required|exists:kurir,id',
            'metode_pembayaran_id' => 'required|exists:metode_pembayaran,id',
        ], [
            'nama.required' => 'Nama penerima wajib diisi.',
            'alamat.required' => 'Alamat pengiriman lengkap wajib diisi.',
            'kurir_id.required' => 'Kurir pengiriman wajib dipilih.',
            'kurir_id.exists' => 'Kurir yang dipilih tidak valid.',
            'metode_pembayaran_id.required' => 'Metode pembayaran wajib dipilih.',
            'metode_pembayaran_id.exists' => 'Metode pembayaran yang dipilih tidak valid.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi formulir checkout gagal.', 422, $validator->errors());
        }

        // Ambil item keranjang pelanggan
        $itemsKeranjang = Keranjang::with('produk')
            ->where('pelanggan_id', $pelangganId)
            ->get();

        if ($itemsKeranjang->isEmpty()) {
            return $this->gagal('Keranjang belanja Anda kosong.', 409);
        }

        $kurir = Kurir::findOrFail($request->input('kurir_id'));
        $metode = MetodePembayaran::findOrFail($request->input('metode_pembayaran_id'));

        try {
            // 4. Memulai DB Transaction untuk memastikan atomic checkout (Kriteria 5 Sistem Terdistribusi)
            $pesananBaru = DB::transaction(function () use ($request, $pelangganId, $kunciIdempoten, $itemsKeranjang, $kurir, $metode) {
                $varianIds = $itemsKeranjang->pluck('varian_id')->unique()->all();

                // Kunci baris varian dengan lockForUpdate() dan urutkan berdasarkan id untuk cegah deadlock
                $varians = VarianProduk::whereIn('id', $varianIds)
                    ->orderBy('id', 'asc')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');

                $subtotal = 0;
                $daftarDetail = [];

                // 5. Periksa ketersediaan stok setiap varian
                foreach ($itemsKeranjang as $item) {
                    $varian = $varians->get($item->varian_id);

                    if (!$varian) {
                        throw new \Exception("Varian produk dengan ID {$item->varian_id} tidak ditemukan.");
                    }

                    if ($varian->stok < $item->jumlah) {
                        $namaProduk = $item->produk ? $item->produk->nama : 'Produk';
                        // Lempar exception khusus untuk di-catch dan dijadikan respon 409
                        throw new \RuntimeException(
                            "Stok untuk {$namaProduk} ukuran {$varian->ukuran} warna {$varian->warna} tidak mencukupi (tersedia: {$varian->stok}, diminta: {$item->jumlah})."
                        );
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
                    'subtotal' => $subtotal,
                    'ongkir' => $ongkir,
                    'total' => $total,
                    'status' => 'menunggu_pembayaran',
                    'kunci_idempoten' => $kunciIdempoten,
                ]);

                // Simpan detail pesanan & kurangi stok varian secara atomik
                foreach ($daftarDetail as $detail) {
                    $detail['pesanan_id'] = $pesanan->id;
                    DetailPesanan::create($detail);

                    // Kurangi stok varian
                    $varian = $varians->get($detail['varian_id']);
                    $varian->decrement('stok', $detail['jumlah']);
                }

                // 8. Kosongkan keranjang pelanggan
                Keranjang::where('pelanggan_id', $pelangganId)->delete();

                return $pesanan;
            });

            $pesananBaru->load(['kurir', 'metodePembayaran', 'detail']);

            return $this->sukses(
                $pesananBaru->formatLengkap(),
                'Pesanan berhasil dibuat',
                201
            );
        } catch (\RuntimeException $re) {
            // Galat stok habis / bentrok keadaan data (409)
            return $this->gagal($re->getMessage(), 409);
        } catch (\Throwable $th) {
            // Galat server umum (500)
            return $this->gagal('Gagal memproses pesanan: ' . $th->getMessage(), 500);
        }
    }
}
