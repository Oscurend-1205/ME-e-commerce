<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Kategori;
use App\Models\Produk;
use App\Models\VarianProduk;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ProdukController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/produk — Daftar produk dengan filter kategori dan pencarian
     */
    public function index(Request $request): JsonResponse
    {
        $query = Produk::with(['kategori', 'varian']);

        // Filter kategori (?kategori=)
        if ($request->filled('kategori')) {
            $namaKategori = $request->input('kategori');
            $query->whereHas('kategori', function ($q) use ($namaKategori) {
                $q->where('nama', 'like', "%{$namaKategori}%");
            });
        }

        // Pencarian nama (?cari=)
        if ($request->filled('cari')) {
            $cari = $request->input('cari');
            $query->where('nama', 'like', "%{$cari}%");
        }

        $daftarProduk = $query->orderBy('id', 'desc')->get();

        $data = $daftarProduk->map(function ($p) {
            return $p->formatRingkas();
        });

        return $this->sukses($data, 'Daftar produk berhasil diambil', 200);
    }

    /**
     * GET /api/produk/{id} — Rincian produk lengkap beserta varian
     */
    public function show(int $id): JsonResponse
    {
        $produk = Produk::with(['kategori', 'varian'])->find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan.', 404);
        }

        return $this->sukses($produk->formatRincian(), 'Rincian produk berhasil diambil', 200);
    }

    /**
     * POST /api/produk — Tambah produk baru beserta daftar varian awal
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'harga' => 'required|integer|min:1',
            'kategori' => 'required|string',
            'bahan' => 'required|string|max:255',
            'merek' => 'required|string|max:255',
            'deskripsi' => 'nullable|string',
            'tersedia' => 'nullable|boolean',
            'varian' => 'required|array|min:1',
            'varian.*.ukuran' => 'required|string',
            'varian.*.warna' => 'required|string',
            'varian.*.stok' => 'required|integer|min:0',
        ], [
            'nama.required' => 'Nama produk wajib diisi.',
            'harga.required' => 'Harga produk wajib diisi.',
            'harga.integer' => 'Harga harus berupa angka bulat positif.',
            'kategori.required' => 'Kategori produk wajib diisi.',
            'bahan.required' => 'Bahan pakaian/aksesori wajib diisi.',
            'merek.required' => 'Merek produk wajib diisi.',
            'varian.required' => 'Minimal satu varian produk wajib disertakan.',
            'varian.*.ukuran.required' => 'Ukuran varian wajib diisi.',
            'varian.*.warna.required' => 'Warna varian wajib diisi.',
            'varian.*.stok.required' => 'Stok varian wajib diisi.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi formulir gagal.', 422, $validator->errors());
        }

        // Cari atau buat kategori
        $kategori = Kategori::firstOrCreate([
            'nama' => trim($request->input('kategori')),
        ]);

        return DB::transaction(function () use ($request, $kategori) {
            $produk = Produk::create([
                'kategori_id' => $kategori->id,
                'nama' => $request->input('nama'),
                'harga' => (int) $request->input('harga'),
                'tersedia' => $request->boolean('tersedia', true),
                'deskripsi' => $request->input('deskripsi'),
                'bahan' => $request->input('bahan'),
                'merek' => $request->input('merek'),
                'gambar' => $request->input('gambar'),
            ]);

            foreach ($request->input('varian') as $v) {
                VarianProduk::create([
                    'produk_id' => $produk->id,
                    'ukuran' => $v['ukuran'],
                    'warna' => $v['warna'],
                    'stok' => (int) $v['stok'],
                    'sku' => strtoupper(substr($produk->merek, 0, 3)) . '-' . $produk->id . '-' . strtoupper(substr($v['ukuran'], 0, 2)) . '-' . strtoupper(substr($v['warna'], 0, 3)),
                ]);
            }

            $produk->load(['kategori', 'varian']);

            return $this->sukses($produk->formatRincian(), 'Produk berhasil ditambahkan', 201);
        });
    }

    /**
     * PUT /api/produk/{id} — Ubah produk dan perbarui varian
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $produk = Produk::with('varian')->find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan.', 404);
        }

        $validator = Validator::make($request->all(), [
            'nama' => 'sometimes|required|string|max:255',
            'harga' => 'sometimes|required|integer|min:1',
            'kategori' => 'sometimes|required|string',
            'bahan' => 'sometimes|required|string|max:255',
            'merek' => 'sometimes|required|string|max:255',
            'deskripsi' => 'nullable|string',
            'tersedia' => 'nullable|boolean',
            'varian' => 'nullable|array',
            'varian.*.ukuran' => 'required_with:varian|string',
            'varian.*.warna' => 'required_with:varian|string',
            'varian.*.stok' => 'required_with:varian|integer|min:0',
        ], [
            'nama.required' => 'Nama produk tidak boleh kosong.',
            'harga.integer' => 'Harga harus berupa angka bulat positif.',
            'varian.*.stok.min' => 'Stok varian tidak boleh bernilai negatif.',
        ]);

        if ($validator->fails()) {
            return $this->gagal('Validasi pembaruan gagal.', 422, $validator->errors());
        }

        return DB::transaction(function () use ($request, $produk) {
            if ($request->filled('kategori')) {
                $kategori = Kategori::firstOrCreate(['nama' => trim($request->input('kategori'))]);
                $produk->kategori_id = $kategori->id;
            }

            if ($request->has('nama')) $produk->nama = $request->input('nama');
            if ($request->has('harga')) $produk->harga = (int) $request->input('harga');
            if ($request->has('tersedia')) $produk->tersedia = $request->boolean('tersedia');
            if ($request->has('deskripsi')) $produk->deskripsi = $request->input('deskripsi');
            if ($request->has('bahan')) $produk->bahan = $request->input('bahan');
            if ($request->has('merek')) $produk->merek = $request->input('merek');
            if ($request->has('gambar')) $produk->gambar = $request->input('gambar');
            $produk->save();

            // Pembaruan varian jika dikirim
            if ($request->has('varian') && is_array($request->input('varian'))) {
                $idVarianTersedia = [];

                foreach ($request->input('varian') as $v) {
                    if (isset($v['id']) && $v['id']) {
                        $varianLama = VarianProduk::where('produk_id', $produk->id)->find($v['id']);
                        if ($varianLama) {
                            $varianLama->update([
                                'ukuran' => $v['ukuran'],
                                'warna' => $v['warna'],
                                'stok' => (int) $v['stok'],
                            ]);
                            $idVarianTersedia[] = $varianLama->id;
                            continue;
                        }
                    }

                    // Varian baru
                    $varianBaru = VarianProduk::create([
                        'produk_id' => $produk->id,
                        'ukuran' => $v['ukuran'],
                        'warna' => $v['warna'],
                        'stok' => (int) $v['stok'],
                        'sku' => strtoupper(substr($produk->merek, 0, 3)) . '-' . $produk->id . '-' . strtoupper(substr($v['ukuran'], 0, 2)) . '-' . strtoupper(substr($v['warna'], 0, 3)),
                    ]);
                    $idVarianTersedia[] = $varianBaru->id;
                }

                // Hapus varian yang dihilangkan
                if (!empty($idVarianTersedia)) {
                    VarianProduk::where('produk_id', $produk->id)
                        ->whereNotIn('id', $idVarianTersedia)
                        ->delete();
                }
            }

            $produk->load(['kategori', 'varian']);

            return $this->sukses($produk->formatRincian(), 'Produk berhasil diubah', 200);
        });
    }

    /**
     * DELETE /api/produk/{id} — Hapus produk (409 bila terpakai pada pesanan aktif)
     */
    public function destroy(int $id): JsonResponse
    {
        $produk = Produk::find($id);

        if (!$produk) {
            return $this->gagal('Produk tidak ditemukan.', 404);
        }

        // Cek apakah produk terpakai pada pesanan aktif (menunggu_pembayaran, menunggu_konfirmasi, dibayar, diproses, dikirim)
        $terpakaiPadaPesananAktif = DetailPesanan::where('produk_id', $id)
            ->whereHas('pesanan', function ($q) {
                $q->whereNotIn('status', ['selesai', 'dibatalkan']);
            })
            ->exists();

        if ($terpakaiPadaPesananAktif) {
            return $this->gagal('Produk tidak dapat dihapus karena masih terhubung dengan pesanan yang sedang aktif.', 409);
        }

        $produk->delete();

        return $this->sukses(null, 'Produk berhasil dihapus', 200);
    }
}

