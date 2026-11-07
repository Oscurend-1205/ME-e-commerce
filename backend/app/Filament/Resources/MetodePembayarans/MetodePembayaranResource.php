<?php

namespace App\Filament\Resources\MetodePembayarans;

use App\Filament\Resources\MetodePembayarans\Pages\CreateMetodePembayaran;
use App\Filament\Resources\MetodePembayarans\Pages\EditMetodePembayaran;
use App\Filament\Resources\MetodePembayarans\Pages\ListMetodePembayarans;
use App\Models\MetodePembayaran;
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

class MetodePembayaranResource extends Resource
{
    protected static ?string $model = MetodePembayaran::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCreditCard;

    protected static string|\UnitEnum|null $navigationGroup = 'Master Data';

    protected static ?int $navigationSort = 3;

    protected static ?string $modelLabel = 'Metode Pembayaran';

    protected static ?string $pluralModelLabel = 'Metode Pembayaran';

    protected static ?string $recordTitleAttribute = 'nama';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('kode')
                    ->label('Kode')
                    ->helperText('Contoh: tunai_di_tempat, transfer_manual')
                    ->required()
                    ->maxLength(255),
                TextInput::make('nama')
                    ->label('Nama Metode')
                    ->required()
                    ->maxLength(255),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama')
            ->columns([
                TextColumn::make('kode')
                    ->label('Kode')
                    ->badge()
                    ->searchable(),
                TextColumn::make('nama')
                    ->label('Nama Metode')
                    ->searchable()
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
            'index' => ListMetodePembayarans::route('/'),
            'create' => CreateMetodePembayaran::route('/create'),
            'edit' => EditMetodePembayaran::route('/{record}/edit'),
        ];
    }
}
