<?php

namespace App\Filament\Resources\Pesanans;

use App\Filament\Resources\Pesanans\Pages\CreatePesanan;
use App\Filament\Resources\Pesanans\Pages\EditPesanan;
use App\Filament\Resources\Pesanans\Pages\ListPesanans;
use App\Models\Pesanan;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

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
     * Status pesanan yang dipakai backend (lihat PesananController::transisiSah).
     */
    public const STATUS = [
        'menunggu_pembayaran' => 'Menunggu Pembayaran',
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
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
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
