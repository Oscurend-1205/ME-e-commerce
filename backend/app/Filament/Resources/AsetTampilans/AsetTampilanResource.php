<?php

namespace App\Filament\Resources\AsetTampilans;
 
use App\Filament\Resources\AsetTampilans\Pages\EditAsetTampilan;
use App\Filament\Resources\AsetTampilans\Pages\ListAsetTampilans;
use App\Models\AsetTampilan;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\BaseFileUpload;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;
use Livewire\Features\SupportFileUploads\TemporaryUploadedFile;

class AsetTampilanResource extends Resource
{
    protected static ?string $model = AsetTampilan::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPhoto;

    protected static string|\UnitEnum|null $navigationGroup = 'Tampilan';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'Aset Tampilan';

    protected static ?string $pluralModelLabel = 'Aset Tampilan';

    protected static ?string $recordTitleAttribute = 'nama';

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Aset')
                    ->schema([
                        TextInput::make('nama')
                            ->label('Nama Aset')
                            ->disabled()
                            ->dehydrated(false),
                        TextInput::make('kunci')
                            ->label('Kunci / Nama Berkas')
                            ->disabled()
                            ->dehydrated(false)
                            ->formatStateUsing(fn (?string $state): ?string => filled($state) ? $state.'.jpg' : null),
                        TextInput::make('grup')
                            ->label('Grup')
                            ->disabled()
                            ->dehydrated(false),
                    ])
                    ->columns(3),
                Section::make('Gambar')
                    ->schema([
                        FileUpload::make('gambar')
                            ->label('Gambar')
                            ->image()
                            ->disk('public')
                            ->directory('produk')
                            ->visibility('public')
                            ->imagePreviewHeight('250')
                            ->helperText('Berkas akan menimpa file lama dengan nama tetap (mis. hero-banner.jpg) sehingga aplikasi Flutter langsung memakai gambar baru.')
                            ->getUploadedFileNameForStorageUsing(
                                fn (TemporaryUploadedFile $file, ?Model $record): string => ($record?->kunci ?? 'aset').'.jpg'
                            )
                            ->afterStateHydrated(function (FileUpload $component, ?string $state): void {
                                $component->state(filled($state) ? 'produk/'.basename($state) : null);
                            })
                            ->dehydrateStateUsing(fn (?string $state): ?string => filled($state) ? basename($state) : null)
                            ->getUploadedFileUsing(function (BaseFileUpload $component, string $file, string|array|null $storedFileNames): ?array {
                                $uploaded = $component->getUploadedFile($file, $storedFileNames);

                                if ($uploaded !== null) {
                                    $uploaded['url'] = url('storage/'.ltrim($file, '/'));
                                }

                                return $uploaded;
                            })
                            ->required()
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama')
            ->defaultSort('urutan')
            ->columns([
                ImageColumn::make('gambar_url')
                    ->label('Pratinjau')
                    ->height(48),
                TextColumn::make('nama')
                    ->label('Nama Aset')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('grup')
                    ->label('Grup')
                    ->badge()
                    ->sortable(),
                TextColumn::make('kunci')
                    ->label('Nama Berkas')
                    ->formatStateUsing(fn (?string $state): string => $state.'.jpg')
                    ->toggleable(),
                TextColumn::make('updated_at')
                    ->label('Terakhir Diubah')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->recordActions([
                EditAction::make()
                    ->label('Ubah Gambar'),
            ])
            ->toolbarActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAsetTampilans::route('/'),
            'edit' => EditAsetTampilan::route('/{record}/edit'),
        ];
    }
}
