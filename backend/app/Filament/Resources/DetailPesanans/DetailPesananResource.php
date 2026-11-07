<?php

namespace App\Filament\Resources\DetailPesanans;

use App\Filament\Resources\DetailPesanans\Pages\CreateDetailPesanan;
use App\Filament\Resources\DetailPesanans\Pages\EditDetailPesanan;
use App\Filament\Resources\DetailPesanans\Pages\ListDetailPesanans;
use App\Models\DetailPesanan;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class DetailPesananResource extends Resource
{
    protected static ?string $model = DetailPesanan::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi';

    protected static ?int $navigationSort = 2;

    protected static ?string $modelLabel = 'Detail Pesanan';

    protected static ?string $pluralModelLabel = 'Detail Pesanan';

    protected static ?string $recordTitleAttribute = 'nama_produk';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('pesanan_id')
                    ->label('Nomor Pesanan')
                    ->relationship('pesanan', 'nomor_pesanan')
                    ->searchable()
                    ->preload()
                    ->required(),
                Select::make('produk_id')
                    ->label('Produk')
                    ->relationship('produk', 'nama')
                    ->searchable()
                    ->preload()
                    ->required(),
                Select::make('varian_id')
                    ->label('Varian')
                    ->relationship('varian', 'ukuran')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('nama_produk')
                    ->label('Nama Produk (tersimpan)')
                    ->required()
                    ->maxLength(255),
                TextInput::make('ukuran')
                    ->label('Ukuran')
                    ->required()
                    ->maxLength(255),
                TextInput::make('warna')
                    ->label('Warna')
                    ->required()
                    ->maxLength(255),
                TextInput::make('harga_satuan')
                    ->label('Harga Satuan')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->minValue(0),
                TextInput::make('jumlah')
                    ->label('Jumlah')
                    ->required()
                    ->numeric()
                    ->minValue(1),
                TextInput::make('subtotal')
                    ->label('Subtotal')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->minValue(0),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama_produk')
            ->columns([
                TextColumn::make('pesanan.nomor_pesanan')
                    ->label('Nomor Pesanan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('nama_produk')
                    ->label('Produk')
                    ->searchable(),
                TextColumn::make('ukuran')
                    ->label('Ukuran')
                    ->badge(),
                TextColumn::make('warna')
                    ->label('Warna'),
                TextColumn::make('harga_satuan')
                    ->label('Harga Satuan')
                    ->formatStateUsing(fn (int|string|null $state): string => 'Rp ' . number_format((int) $state, 0, ',', '.'))
                    ->sortable(),
                TextColumn::make('jumlah')
                    ->label('Jumlah')
                    ->numeric()
                    ->alignEnd(),
                TextColumn::make('subtotal')
                    ->label('Subtotal')
                    ->formatStateUsing(fn (int|string|null $state): string => 'Rp ' . number_format((int) $state, 0, ',', '.'))
                    ->sortable(),
            ])
            ->defaultSort('pesanan_id')
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
            'index' => ListDetailPesanans::route('/'),
            'create' => CreateDetailPesanan::route('/create'),
            'edit' => EditDetailPesanan::route('/{record}/edit'),
        ];
    }
}
