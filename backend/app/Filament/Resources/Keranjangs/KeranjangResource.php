<?php

namespace App\Filament\Resources\Keranjangs;

use App\Filament\Resources\Keranjangs\Pages\CreateKeranjang;
use App\Filament\Resources\Keranjangs\Pages\EditKeranjang;
use App\Filament\Resources\Keranjangs\Pages\ListKeranjangs;
use App\Models\Keranjang;
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

class KeranjangResource extends Resource
{
    protected static ?string $model = Keranjang::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShoppingCart;

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi';

    protected static ?int $navigationSort = 3;

    protected static ?string $modelLabel = 'Keranjang';

    protected static ?string $pluralModelLabel = 'Keranjang';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('pelanggan_id')
                    ->label('Pelanggan')
                    ->relationship('pelanggan', 'nama')
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
                TextInput::make('jumlah')
                    ->label('Jumlah')
                    ->required()
                    ->numeric()
                    ->minValue(1)
                    ->default(1),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('pelanggan.nama')
                    ->label('Pelanggan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('produk.nama')
                    ->label('Produk')
                    ->searchable(),
                TextColumn::make('varian.ukuran')
                    ->label('Ukuran'),
                TextColumn::make('varian.warna')
                    ->label('Warna'),
                TextColumn::make('jumlah')
                    ->label('Jumlah')
                    ->numeric()
                    ->alignEnd()
                    ->sortable(),
                TextColumn::make('updated_at')
                    ->label('Terakhir Diubah')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('updated_at', 'desc')
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
            'index' => ListKeranjangs::route('/'),
            'create' => CreateKeranjang::route('/create'),
            'edit' => EditKeranjang::route('/{record}/edit'),
        ];
    }
}
