<?php

namespace App\Filament\Resources\Produks;

use App\Filament\Resources\Produks\Pages\CreateProduk;
use App\Filament\Resources\Produks\Pages\EditProduk;
use App\Filament\Resources\Produks\Pages\ListProduks;
use App\Models\Produk;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ProdukResource extends Resource
{
    protected static ?string $model = Produk::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShoppingBag;

    protected static string|\UnitEnum|null $navigationGroup = 'Katalog';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'Produk';

    protected static ?string $pluralModelLabel = 'Produk';

    protected static ?string $recordTitleAttribute = 'nama';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Produk')
                    ->schema([
                        Select::make('kategori_id')
                            ->label('Kategori')
                            ->relationship('kategori', 'nama')
                            ->searchable()
                            ->preload()
                            ->required(),
                        TextInput::make('nama')
                            ->label('Nama Produk')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('bahan')
                            ->label('Bahan')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('merek')
                            ->label('Merek')
                            ->required()
                            ->maxLength(255),
                        Textarea::make('deskripsi')
                            ->label('Deskripsi')
                            ->rows(4)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
                Section::make('Harga & Ketersediaan')
                    ->schema([
                        TextInput::make('harga')
                            ->label('Harga')
                            ->required()
                            ->numeric()
                            ->prefix('Rp')
                            ->minValue(0),
                        Toggle::make('tersedia')
                            ->label('Tersedia untuk Dijual')
                            ->default(true),
                    ])
                    ->columns(2),
                Section::make('Gambar Produk')
                    ->schema([
                        FileUpload::make('gambar')
                            ->label('Gambar')
                            ->image()
                            ->disk('public')
                            ->directory('produk')
                            ->visibility('public')
                            ->imagePreviewHeight('200')
                            ->helperText('Berkas disimpan di storage/app/public/produk dan disajikan melalui /api/gambar/{nama_berkas}.')
                            ->afterStateHydrated(function (FileUpload $component, ?string $state): void {
                                $component->state(filled($state) ? 'produk/' . basename($state) : null);
                            })
                            ->dehydrateStateUsing(fn (?string $state): ?string => filled($state) ? basename($state) : null)
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama')
            ->columns([
                ImageColumn::make('gambar_url')
                    ->label('Gambar'),
                TextColumn::make('nama')
                    ->label('Nama Produk')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('kategori.nama')
                    ->label('Kategori')
                    ->badge()
                    ->searchable()
                    ->sortable(),
                TextColumn::make('harga')
                    ->label('Harga')
                    ->formatStateUsing(fn (int|string|null $state): string => 'Rp ' . number_format((int) $state, 0, ',', '.'))
                    ->sortable(),
                TextColumn::make('stok')
                    ->label('Total Stok')
                    ->badge()
                    ->color(fn (int|string|null $state): string => (int) $state > 0 ? 'success' : 'danger'),
                IconColumn::make('tersedia')
                    ->label('Tersedia')
                    ->boolean(),
                TextColumn::make('merek')
                    ->label('Merek')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('updated_at')
                    ->label('Terakhir Diubah')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
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
            'index' => ListProduks::route('/'),
            'create' => CreateProduk::route('/create'),
            'edit' => EditProduk::route('/{record}/edit'),
        ];
    }
}
