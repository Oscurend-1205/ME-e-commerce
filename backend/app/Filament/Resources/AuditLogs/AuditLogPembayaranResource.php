<?php

namespace App\Filament\Resources\AuditLogs;

use App\Filament\Resources\AuditLogs\Pages\ListAuditLogPembayarans;
use App\Models\AuditLogPembayaran;
use BackedEnum;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

class AuditLogPembayaranResource extends Resource
{
    protected static ?string $model = AuditLogPembayaran::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentMagnifyingGlass;

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi';

    protected static ?int $navigationSort = 3;

    protected static ?string $modelLabel = 'Audit Log Pembayaran & COD';

    protected static ?string $pluralModelLabel = 'Audit Log Pembayaran & COD';

    protected static ?string $recordTitleAttribute = 'nomor_pesanan';

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
        return $schema->components([
            TextInput::make('nomor_pesanan')->label('Nomor Pesanan')->disabled(),
            TextInput::make('jenis_kejadian')->label('Jenis Kejadian')->disabled(),
            TextInput::make('metode')->label('Metode Pembayaran')->disabled(),
            TextInput::make('ip_address')->label('IP Address')->disabled(),
            Textarea::make('pesan_error')->label('Detail Log / Error')->disabled()->rows(4)->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nomor_pesanan')
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('created_at')
                    ->label('Waktu Kejadian')
                    ->dateTime('d M Y H:i:s')
                    ->sortable(),
                TextColumn::make('nomor_pesanan')
                    ->label('Nomor Pesanan')
                    ->searchable()
                    ->weight('bold'),
                TextColumn::make('jenis_kejadian')
                    ->label('Jenis Kejadian')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'midtrans_error' => 'danger',
                        'fallback_ke_cod' => 'warning',
                        'checkout_cod' => 'info',
                        'verifikasi_cod', 'cod_selesai_lunas' => 'success',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'midtrans_error' => 'Midtrans Error / Gagal',
                        'fallback_ke_cod' => 'Fallback ke COD',
                        'checkout_cod' => 'Pesanan COD Baru',
                        'verifikasi_cod' => 'COD Diverifikasi',
                        'cod_selesai_lunas' => 'COD Lunas & Selesai',
                        'cod_dibatalkan' => 'COD Dibatalkan',
                        default => $state,
                    })
                    ->searchable(),
                TextColumn::make('metode')
                    ->label('Metode')
                    ->badge()
                    ->color('primary'),
                TextColumn::make('pesan_error')
                    ->label('Keterangan / Pesan Error')
                    ->limit(60)
                    ->tooltip(fn (?string $state): ?string => $state)
                    ->searchable(),
                TextColumn::make('ip_address')
                    ->label('IP Client')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('jenis_kejadian')
                    ->label('Filter Kejadian')
                    ->options([
                        'midtrans_error' => 'Midtrans Error',
                        'fallback_ke_cod' => 'Fallback ke COD',
                        'checkout_cod' => 'Checkout COD',
                        'verifikasi_cod' => 'Verifikasi COD',
                        'cod_selesai_lunas' => 'COD Lunas & Selesai',
                    ]),
            ])
            ->recordActions([])
            ->toolbarActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAuditLogPembayarans::route('/'),
        ];
    }
}

