<?php

namespace App\Filament\Resources\Kurirs;

use App\Filament\Resources\Kurirs\Pages\CreateKurir;
use App\Filament\Resources\Kurirs\Pages\EditKurir;
use App\Filament\Resources\Kurirs\Pages\ListKurirs;
use App\Models\Kurir;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class KurirResource extends Resource
{
    protected static ?string $model = Kurir::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTruck;

    protected static string|\UnitEnum|null $navigationGroup = 'Master Data';

    protected static ?int $navigationSort = 2;

    protected static ?string $modelLabel = 'Kurir';

    protected static ?string $pluralModelLabel = 'Kurir';

    protected static ?string $recordTitleAttribute = 'nama';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama')
                    ->label('Nama Layanan Kurir')
                    ->required()
                    ->maxLength(255),
                TextInput::make('wilayah')
                    ->label('Wilayah Pengiriman')
                    ->required()
                    ->maxLength(255),
                TextInput::make('tarif')
                    ->label('Tarif Ongkir')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->minValue(0),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama')
            ->columns([
                TextColumn::make('nama')
                    ->label('Nama Layanan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('wilayah')
                    ->label('Wilayah')
                    ->searchable(),
                TextColumn::make('tarif')
                    ->label('Tarif Ongkir')
                    ->formatStateUsing(fn (int|string|null $state): string => 'Rp ' . number_format((int) $state, 0, ',', '.'))
                    ->sortable(),
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
            'index' => ListKurirs::route('/'),
            'create' => CreateKurir::route('/create'),
            'edit' => EditKurir::route('/{record}/edit'),
        ];
    }
}
