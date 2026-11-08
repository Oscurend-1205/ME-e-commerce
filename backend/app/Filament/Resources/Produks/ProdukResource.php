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
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Enums\FontWeight;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\Layout\Panel;
use Filament\Tables\Columns\Layout\Split;
use Filament\Tables\Columns\Layout\Stack;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

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
                            ->required()
                            ->createOptionForm([
                                TextInput::make('nama')
                                    ->label('Nama Kategori')
                                    ->required()
                                    ->maxLength(255),
                            ]),
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
                Section::make('Varian Produk')
                    ->description('Setiap baris adalah satu kombinasi ukuran, warna, dan stok. SKU boleh dikosongkan dan akan dibuat otomatis.')
                    ->schema([
                        Repeater::make('varian')
                            ->label('Daftar Varian')
                            ->relationship()
                            ->required()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => filled($state['ukuran'] ?? null) || filled($state['warna'] ?? null)
                                ? trim(($state['ukuran'] ?? '—').' / '.($state['warna'] ?? '—'))
                                : null)
                            ->schema([
                                TextInput::make('ukuran')
                                    ->label('Ukuran')
                                    ->required()
                                    ->maxLength(50)
                                    ->placeholder('cth: M, L, XL, All Size'),
                                TextInput::make('warna')
                                    ->label('Warna')
                                    ->required()
                                    ->maxLength(100)
                                    ->placeholder('cth: Hitam, Putih'),
                                TextInput::make('stok')
                                    ->label('Stok')
                                    ->required()
                                    ->numeric()
                                    ->minValue(0)
                                    ->default(0),
                                TextInput::make('sku')
                                    ->label('SKU')
                                    ->maxLength(100)
                                    ->helperText('Kosongkan untuk SKU otomatis'),
                            ])
                            ->columns(4)
                            ->defaultItems(1)
                            ->addActionLabel('Tambah Varian')
                            ->reorderable(false)
                            ->columnSpanFull(),
                    ]),
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
                                $component->state(filled($state) ? 'produk/'.basename($state) : null);
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
            ->defaultSort('id', 'desc')
            ->modifyQueryUsing(fn (Builder $query) => $query
                ->with('kategori')
                ->withCount('varian')
                ->withSum('varian as total_stok', 'stok'))
            ->columns([
                Panel::make([
                    Stack::make([
                        ImageColumn::make('gambar_url')
                            ->label('')
                            ->imageWidth('100%')
                            ->imageHeight('12rem')
                            ->extraImgAttributes(['class' => 'object-cover']),
                        TextColumn::make('nama')
                            ->label('')
                            ->weight(FontWeight::Bold)
                            ->searchable(),
                        TextColumn::make('kategori.nama')
                            ->label('Kategori')
                            ->badge()
                            ->color('gray')
                            ->searchable(),
                        TextColumn::make('merek')
                            ->label('Merek')
                            ->color('gray')
                            ->size('sm')
                            ->searchable(),
                        Split::make([
                            TextColumn::make('harga')
                                ->label('Harga')
                                ->formatStateUsing(fn (int|string|null $state): string => 'Rp '.number_format((int) $state, 0, ',', '.'))
                                ->weight(FontWeight::SemiBold),
                            TextColumn::make('total_stok')
                                ->label('Total Stok')
                                ->badge()
                                ->color(fn (int|string|null $state): string => (int) $state > 0 ? 'success' : 'danger'),
                        ]),
                        TextColumn::make('varian_count')
                            ->label('Varian')
                            ->formatStateUsing(fn (int|string|null $state): string => ($state ?? 0).' varian'),
                        TextColumn::make('tersedia')
                            ->label('Status')
                            ->formatStateUsing(fn (bool $state): string => $state ? 'Tersedia' : 'Nonaktif')
                            ->badge()
                            ->color(fn (bool $state): string => $state ? 'success' : 'danger'),
                    ]),
                ]),
            ])
            ->contentGrid([
                'md' => 2,
                'xl' => 3,
                '2xl' => 4,
            ])
            ->filters([
                SelectFilter::make('kategori_id')
                    ->label('Kategori')
                    ->relationship('kategori', 'nama')
                    ->searchable()
                    ->preload(),
                TernaryFilter::make('tersedia')
                    ->label('Ketersediaan')
                    ->trueLabel('Tersedia')
                    ->falseLabel('Nonaktif'),
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
