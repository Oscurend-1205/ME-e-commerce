<?php

namespace App\Filament\Resources\HeroBanners;

use App\Filament\Resources\HeroBanners\Pages\CreateHeroBanner;
use App\Filament\Resources\HeroBanners\Pages\EditHeroBanner;
use App\Filament\Resources\HeroBanners\Pages\ListHeroBanners;
use App\Models\HeroBanner;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\BaseFileUpload;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class HeroBannerResource extends Resource
{
    protected static ?string $model = HeroBanner::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedSparkles;

    protected static string|\UnitEnum|null $navigationGroup = 'Tampilan';

    protected static ?int $navigationSort = 0;

    protected static ?string $modelLabel = 'Hero Banner (ME MINIMALISM)';

    protected static ?string $pluralModelLabel = 'Hero Banner Beranda';

    protected static ?string $recordTitleAttribute = 'judul';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Foto Banner')
                    ->description('Unggah foto untuk slider Hero Banner beranda aplikasi mobile.')
                    ->schema([
                        FileUpload::make('gambar')
                            ->label('Foto Utama')
                            ->image()
                            ->disk('public')
                            ->directory('produk')
                            ->visibility('public')
                            ->imagePreviewHeight('260')
                            ->helperText('Disarankan foto beresolusi tinggi orientasi lanskap/portrait proporsional. Foto akan disajikan ke aplikasi melalui endpoint gambar.')
                            ->afterStateHydrated(function (FileUpload $component, ?string $state): void {
                                $component->state(filled($state) ? 'produk/'.basename($state) : null);
                            })
                            ->dehydrateStateUsing(fn (?string $state): ?string => filled($state) ? basename($state) : null)
                            ->getUploadedFileUsing(function (BaseFileUpload $component, string $file, string|array|null $storedFileNames): ?array {
                                $uploaded = $component->getUploadedFile($file, $storedFileNames);

                                if ($uploaded !== null) {
                                    $uploaded['url'] = url('/api/gambar/'.basename($file));
                                }

                                return $uploaded;
                            })
                            ->required()
                            ->columnSpanFull(),
                        FileUpload::make('gambar_tambahan')
                            ->label('Foto Tambahan')
                            ->multiple()
                            ->reorderable()
                            ->image()
                            ->disk('public')
                            ->directory('produk')
                            ->visibility('public')
                            ->imagePreviewHeight('180')
                            ->helperText('Tambahkan satu atau beberapa foto. Semua foto banner akan bergeser horizontal otomatis di aplikasi.')
                            ->afterStateHydrated(function (FileUpload $component, array|string|null $state): void {
                                $files = is_array($state) ? $state : (filled($state) ? [$state] : []);
                                $component->state(array_map(
                                    fn (string $file): string => 'produk/'.basename($file),
                                    $files,
                                ));
                            })
                            ->dehydrateStateUsing(fn (?array $state): array => array_values(array_map(
                                fn (string $file): string => basename($file),
                                $state ?? [],
                            )))
                            ->getUploadedFileUsing(function (BaseFileUpload $component, string $file, string|array|null $storedFileNames): ?array {
                                $uploaded = $component->getUploadedFile($file, $storedFileNames);

                                if ($uploaded !== null) {
                                    $uploaded['url'] = url('/api/gambar/'.basename($file));
                                }

                                return $uploaded;
                            })
                            ->columnSpanFull(),
                    ]),

                Section::make('Teks & Pengaturan Banner')
                    ->description('Pengaturan teks editorial overlay di atas foto banner.')
                    ->schema([
                        TextInput::make('judul')
                            ->label('Judul Utama')
                            ->default('ME MINIMALISM')
                            ->placeholder('ME MINIMALISM')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('tag')
                            ->label('Label Tag Atas')
                            ->default('BARU TIBA // DROP 01')
                            ->placeholder('BARU TIBA // DROP 01')
                            ->maxLength(100),
                        TextInput::make('koleksi')
                            ->label('Label Koleksi')
                            ->default('ATELIER ÉDITION 2026')
                            ->placeholder('ATELIER ÉDITION 2026')
                            ->maxLength(100),
                        TextInput::make('urutan')
                            ->label('Urutan Slide')
                            ->numeric()
                            ->default(1)
                            ->required(),
                        TextInput::make('subjudul')
                            ->label('Deskripsi / Subjudul')
                            ->default('Eksplorasi siluet bersih, material linen premium, dan palet monokrom abadi.')
                            ->placeholder('Tulis deskripsi singkat...')
                            ->maxLength(500)
                            ->columnSpanFull(),
                        Toggle::make('aktif')
                            ->label('Tampilkan di Banner Beranda')
                            ->default(true),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('judul')
            ->defaultSort('urutan')
            ->columns([
                ImageColumn::make('gambar_url')
                    ->label('Pratinjau')
                    ->height(60)
                    ->width(90)
                    ->extraImgAttributes(['class' => 'object-cover rounded']),
                TextColumn::make('judul')
                    ->label('Judul')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('tag')
                    ->label('Tag')
                    ->badge()
                    ->color('gray'),
                TextColumn::make('koleksi')
                    ->label('Koleksi')
                    ->toggleable(),
                TextColumn::make('urutan')
                    ->label('Urutan')
                    ->sortable(),
                TextColumn::make('aktif')
                    ->label('Status')
                    ->formatStateUsing(fn (bool $state): string => $state ? 'Aktif' : 'Nonaktif')
                    ->badge()
                    ->color(fn (bool $state): string => $state ? 'success' : 'danger'),
                TextColumn::make('updated_at')
                    ->label('Diperbarui')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->recordActions([
                EditAction::make()->label('Ubah'),
                DeleteAction::make()->label('Hapus'),
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
            'index' => ListHeroBanners::route('/'),
            'create' => CreateHeroBanner::route('/create'),
            'edit' => EditHeroBanner::route('/{record}/edit'),
        ];
    }
}
