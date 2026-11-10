<?php

namespace App\Filament\Resources\Pesanans;

use App\Filament\Resources\Pesanans\Pages\CreatePesanan;
use App\Filament\Resources\Pesanans\Pages\EditPesanan;
use App\Filament\Resources\Pesanans\Pages\ListPesanans;
use App\Models\Pesanan;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class PesananResource extends Resource
{
    protected static ?string $model = Pesanan::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentList;

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'Pesanan';

    protected static ?string $pluralModelLabel = 'Pesanan';

    protected static ?string $recordTitleAttribute = 'nomor_pesanan';

    /**
     * Status pesanan yang dipakai backend (lihat Pesanan::TRANSISI_SAH).
     */
    public const STATUS = [
        'menunggu_pembayaran' => 'Menunggu Pembayaran',
        'menunggu_verifikasi' => 'Menunggu Verifikasi (COD)',
        'menunggu_konfirmasi' => 'Menunggu Konfirmasi',
        'dibayar' => 'Dibayar',
        'diproses' => 'Diproses',
        'dikirim' => 'Dikirim',
        'selesai' => 'Selesai',
        'dibatalkan' => 'Dibatalkan',
    ];

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Data Pesanan')
                    ->schema([
                        TextInput::make('nomor_pesanan')
                            ->label('Nomor Pesanan')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255),
                        Select::make('status')
                            ->label('Status')
                            ->options(self::STATUS)
                            ->required()
                            ->default('menunggu_pembayaran'),
                        Select::make('pelanggan_id')
                            ->label('Pelanggan')
                            ->relationship('pelanggan', 'nama')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('kurir_id')
                            ->label('Kurir')
                            ->relationship('kurir', 'nama')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('metode_pembayaran_id')
                            ->label('Metode Pembayaran')
                            ->relationship('metodePembayaran', 'nama')
                            ->searchable()
                            ->preload()
                            ->required(),
                        TextInput::make('nama_penerima')
                            ->label('Nama Penerima')
                            ->required()
                            ->maxLength(255),
                        Textarea::make('alamat')
                            ->label('Alamat Pengiriman')
                            ->required()
                            ->rows(3)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Section::make('Barang yang Dipesan')
                    ->description('Daftar varian produk yang dipesan pelanggan beserta kuantitas dan harga satuan saat checkout.')
                    ->schema([
                        Repeater::make('detail')
                            ->label('Daftar Item')
                            ->relationship('detail')
                            ->schema([
                                TextInput::make('nama_produk')
                                    ->label('Produk')
                                    ->readOnly(),
                                TextInput::make('ukuran')
                                    ->label('Ukuran')
                                    ->readOnly(),
                                TextInput::make('warna')
                                    ->label('Warna')
                                    ->readOnly(),
                                TextInput::make('jumlah')
                                    ->label('Qty')
                                    ->numeric()
                                    ->readOnly(),
                                TextInput::make('harga_satuan')
                                    ->label('Harga Satuan')
                                    ->prefix('Rp')
                                    ->numeric()
                                    ->readOnly(),
                                TextInput::make('subtotal')
                                    ->label('Subtotal')
                                    ->prefix('Rp')
                                    ->numeric()
                                    ->readOnly(),
                            ])
                            ->columns(6)
                            ->addable(false)
                            ->deletable(false)
                            ->reorderable(false)
                            ->columnSpanFull(),
                    ]),
                Section::make('Rincian Biaya')
                    ->schema([
                        TextInput::make('subtotal')
                            ->label('Subtotal')
                            ->required()
                            ->numeric()
                            ->prefix('Rp')
                            ->minValue(0),
                        TextInput::make('ongkir')
                            ->label('Ongkir')
                            ->required()
                            ->numeric()
                            ->prefix('Rp')
                            ->minValue(0),
                        TextInput::make('total')
                            ->label('Total')
                            ->required()
                            ->numeric()
                            ->prefix('Rp')
                            ->minValue(0),
                        TextInput::make('kunci_idempoten')
                            ->label('Kunci Idempoten')
                            ->required()
                            ->maxLength(255),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nomor_pesanan')
            ->columns([
                TextColumn::make('nomor_pesanan')
                    ->label('Nomor Pesanan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('pelanggan.nama')
                    ->label('Pelanggan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => self::STATUS[$state] ?? (string) $state)
                    ->color(fn (?string $state): string => match ($state) {
                        'menunggu_pembayaran' => 'warning',
                        'menunggu_konfirmasi' => 'info',
                        'dibayar' => 'primary',
                        'diproses' => 'info',
                        'dikirim' => 'primary',
                        'selesai' => 'success',
                        'dibatalkan' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('total')
                    ->label('Total')
                    ->formatStateUsing(fn (int|string|null $state): string => 'Rp ' . number_format((int) $state, 0, ',', '.'))
                    ->sortable(),
                TextColumn::make('kurir.nama')
                    ->label('Kurir')
                    ->toggleable(),
                TextColumn::make('created_at')
                    ->label('Tanggal Pesanan')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                SelectFilter::make('status')
                    ->label('Filter Status')
                    ->options(self::STATUS),
            ])
            ->recordActions([
                Action::make('verifikasi_cod')
                    ->label('Verifikasi COD')
                    ->icon(Heroicon::OutlinedShieldCheck)
                    ->color('success')
                    ->visible(fn (Pesanan $record): bool => $record->status === 'menunggu_verifikasi' && $record->isCod())
                    ->requiresConfirmation()
                    ->modalHeading('Verifikasi Pesanan COD')
                    ->modalDescription(fn (Pesanan $record) => "Verifikasi pesanan #{$record->nomor_pesanan} untuk metode Tunai di Tempat (COD)? Status akan diubah ke Diproses (pengemasan).")
                    ->modalSubmitActionLabel('Verifikasi & Proses')
                    ->action(function (Pesanan $record): void {
                        $record->status = 'diproses';
                        $record->save();

                        \App\Models\AuditLogPembayaran::catat(
                            jenisKejadian: 'verifikasi_cod',
                            pesanan: $record,
                            metode: 'tunai_di_tempat',
                            pesanError: 'Pesanan COD diverifikasi oleh Admin Filament'
                        );

                        Notification::make()
                            ->title('Pesanan COD Diverifikasi')
                            ->body("Pesanan #{$record->nomor_pesanan} berhasil diverifikasi dan siap dikemas.")
                            ->success()
                            ->send();
                    }),
                Action::make('konfirmasi')
                    ->label('Konfirmasi Pembayaran')
                    ->icon(Heroicon::OutlinedCheckBadge)
                    ->color('success')
                    ->visible(fn (Pesanan $record): bool => $record->status === 'menunggu_konfirmasi')
                    ->requiresConfirmation()
                    ->modalHeading('Konfirmasi Pembayaran')
                    ->modalDescription(fn (Pesanan $record) => "Tandai pembayaran pesanan #{$record->nomor_pesanan} sebagai Dibayar?")
                    ->modalSubmitActionLabel('Konfirmasi Dibayar')
                    ->action(function (Pesanan $record): void {
                        if (!$record->bolehPindahKe('dibayar')) {
                            Notification::make()
                                ->title('Transisi tidak diizinkan')
                                ->body("Status pesanan #{$record->nomor_pesanan} tidak dapat berpindah ke Dibayar.")
                                ->danger()
                                ->send();

                            return;
                        }

                        $record->status = 'dibayar';
                        $record->save();

                        Notification::make()
                            ->title('Pembayaran Dikonfirmasi')
                            ->body("Pesanan #{$record->nomor_pesanan} kini berstatus Dibayar.")
                            ->success()
                            ->send();
                    }),
                Action::make('kemas')
                    ->label('Kemas Barang')
                    ->icon(Heroicon::OutlinedArchiveBox)
                    ->color('warning')
                    ->visible(fn (Pesanan $record): bool => $record->status === 'dibayar')
                    ->requiresConfirmation()
                    ->modalHeading('Kemas Pesanan')
                    ->modalDescription(fn (Pesanan $record) => "Proses pesanan #{$record->nomor_pesanan} ke tahap pengemasan atelier?")
                    ->modalSubmitActionLabel('Kemas Sekarang')
                    ->action(function (Pesanan $record): void {
                        if (!$record->bolehPindahKe('diproses')) {
                            Notification::make()
                                ->title('Transisi tidak diizinkan')
                                ->body("Status pesanan #{$record->nomor_pesanan} tidak dapat berpindah ke Diproses.")
                                ->danger()
                                ->send();

                            return;
                        }

                        $record->status = 'diproses';
                        $record->save();

                        Notification::make()
                            ->title('Pesanan Siap Dikemas')
                            ->body("Pesanan #{$record->nomor_pesanan} berhasil dipindahkan ke status Diproses.")
                            ->success()
                            ->send();
                    }),
                Action::make('kirim')
                    ->label('Kirim ke Kurir')
                    ->icon(Heroicon::OutlinedTruck)
                    ->color('primary')
                    ->visible(fn (Pesanan $record): bool => $record->status === 'diproses')
                    ->requiresConfirmation()
                    ->modalHeading('Serahkan ke Kurir')
                    ->modalDescription(fn (Pesanan $record) => "Kirimkan paket #{$record->nomor_pesanan} ke kurir pengiriman?")
                    ->modalSubmitActionLabel('Kirim Paket')
                    ->action(function (Pesanan $record): void {
                        if (!$record->bolehPindahKe('dikirim')) {
                            Notification::make()
                                ->title('Transisi tidak diizinkan')
                                ->body("Status pesanan #{$record->nomor_pesanan} tidak dapat berpindah ke Dikirim.")
                                ->danger()
                                ->send();

                            return;
                        }

                        $record->status = 'dikirim';
                        $record->save();

                        Notification::make()
                            ->title('Pesanan Telah Dikirim')
                            ->body("Pesanan #{$record->nomor_pesanan} kini berstatus Dikirim (barang sedang proses pengiriman).")
                            ->success()
                            ->send();
                    }),
                Action::make('selesai_cod')
                    ->label('Tandai Lunas COD')
                    ->icon(Heroicon::OutlinedBanknotes)
                    ->color('success')
                    ->visible(fn (Pesanan $record): bool => $record->status === 'dikirim' && $record->isCod())
                    ->requiresConfirmation()
                    ->modalHeading('Konfirmasi Penerimaan & Pembayaran Tunai (COD)')
                    ->modalDescription(fn (Pesanan $record) => "Konfirmasi bahwa uang tunai sebesar Rp " . number_format($record->total, 0, ',', '.') . " telah diserahkan kurir ke kas toko dan paket #{$record->nomor_pesanan} telah diterima pemesan?")
                    ->modalSubmitActionLabel('Konfirmasi Lunas & Selesai')
                    ->action(function (Pesanan $record): void {
                        $record->status = 'selesai';
                        $record->save();

                        \App\Models\AuditLogPembayaran::catat(
                            jenisKejadian: 'cod_selesai_lunas',
                            pesanan: $record,
                            metode: 'tunai_di_tempat',
                            pesanError: 'Pembayaran tunai COD diterima dari kurir dan pesanan selesai diverifikasi admin'
                        );

                        Notification::make()
                            ->title('Pesanan COD Selesai')
                            ->body("Pesanan #{$record->nomor_pesanan} telah ditandai LUNAS dan Selesai.")
                            ->success()
                            ->send();
                    }),
                Action::make('batalkan')
                    ->label('Batalkan Pesanan')
                    ->icon(Heroicon::OutlinedXCircle)
                    ->color('danger')
                    ->visible(fn (Pesanan $record): bool => !in_array($record->status, ['dibatalkan', 'selesai']))
                    ->requiresConfirmation()
                    ->modalHeading('Batalkan Pesanan')
                    ->modalDescription(fn (Pesanan $record) => "Apakah Anda yakin ingin membatalkan pesanan #{$record->nomor_pesanan}? Seluruh stok varian barang akan otomatis dikembalikan ke katalog.")
                    ->modalSubmitActionLabel('Batalkan & Kembalikan Stok')
                    ->action(function (Pesanan $record): void {
                        DB::transaction(function () use ($record) {
                            $record->kembalikanStok();
                            $record->status = 'dibatalkan';
                            $record->save();
                        });

                        Notification::make()
                            ->title('Pesanan Dibatalkan')
                            ->body("Pesanan #{$record->nomor_pesanan} berhasil dibatalkan dan stok produk telah dikembalikan ke katalog.")
                            ->success()
                            ->send();
                    }),
                EditAction::make(),
                DeleteAction::make()
                    ->before(function (Pesanan $record): void {
                        if (!in_array($record->status, ['dibatalkan', 'selesai'])) {
                            $record->kembalikanStok();
                        }
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()
                        ->before(function (Collection $records): void {
                            foreach ($records as $record) {
                                if (!in_array($record->status, ['dibatalkan', 'selesai'])) {
                                    $record->kembalikanStok();
                                }
                            }
                        }),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListPesanans::route('/'),
            'create' => CreatePesanan::route('/create'),
            'edit' => EditPesanan::route('/{record}/edit'),
        ];
    }
}
