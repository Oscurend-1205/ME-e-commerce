<?php

namespace App\Filament\Resources\VarianProduks;

use App\Filament\Resources\VarianProduks\Pages\CreateVarianProduk;
use App\Filament\Resources\VarianProduks\Pages\EditVarianProduk;
use App\Filament\Resources\VarianProduks\Pages\ListVarianProduks;
use App\Models\VarianProduk;
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

class VarianProdukResource extends Resource
{
    protected static ?string $model = VarianProduk::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedSwatch;

    protected static string|\UnitEnum|null $navigationGroup = 'Katalog';

    protected static ?int $navigationSort = 2;

    protected static ?string $modelLabel = 'Varian Produk';

    protected static ?string $pluralModelLabel = 'Varian Produk';

    protected static ?string $recordTitleAttribute = 'sku';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('produk_id')
                    ->label('Produk')
                    ->relationship('produk', 'nama')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('ukuran')
                    ->label('Ukuran')
                    ->required()
                    ->maxLength(255),
                TextInput::make('warna')
                    ->label('Warna')
                    ->required()
                    ->maxLength(255),
                TextInput::make('stok')
                    ->label('Stok')
                    ->required()
                    ->numeric()
                    ->minValue(0)
                    ->default(0),
                TextInput::make('sku')
                    ->label('SKU')
                    ->maxLength(255),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('produk.nama')
                    ->label('Produk')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('ukuran')
                    ->label('Ukuran')
                    ->badge()
                    ->searchable(),
                TextColumn::make('warna')
                    ->label('Warna')
                    ->searchable(),
                TextColumn::make('stok')
                    ->label('Stok')
                    ->badge()
                    ->color(fn (int|string|null $state): string => (int) $state > 0 ? 'success' : 'danger')
                    ->sortable(),
                TextColumn::make('sku')
                    ->label('SKU')
                    ->searchable()
                    ->toggleable(),
            ])
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
            'index' => ListVarianProduks::route('/'),
            'create' => CreateVarianProduk::route('/create'),
            'edit' => EditVarianProduk::route('/{record}/edit'),
        ];
    }
}
