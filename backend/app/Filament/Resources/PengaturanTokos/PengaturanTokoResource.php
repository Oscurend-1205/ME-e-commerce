<?php

namespace App\Filament\Resources\PengaturanTokos;

use App\Filament\Resources\PengaturanTokos\Pages\EditPengaturanToko;
use App\Filament\Resources\PengaturanTokos\Pages\ListPengaturanTokos;
use App\Models\PengaturanToko;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

class PengaturanTokoResource extends Resource
{
    protected static ?string $model = PengaturanToko::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBuildingStorefront;

    protected static string|\UnitEnum|null $navigationGroup = 'Pengaturan';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'Pengaturan Toko & Ongkir';

    protected static ?string $pluralModelLabel = 'Pengaturan Toko & Ongkir';

    protected static ?string $recordTitleAttribute = 'nama_toko';

    public static function canCreate(): bool
    {
        return PengaturanToko::count() === 0;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Identitas Toko')
                    ->description('Informasi brand dan kontak toko ME Atelier')
                    ->schema([
                        TextInput::make('nama_toko')
                            ->label('Nama Toko')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('telepon')
                            ->label('Nomor Telepon / WhatsApp')
                            ->tel()
                            ->maxLength(50),
                        TextInput::make('email')
                            ->label('Alamat Email Toko')
                            ->email()
                            ->maxLength(255),
                    ])
                    ->columns(3),

                Section::make('Lokasi Gudang & Asal Pengiriman (RajaOngkir Origin)')
                    ->description('Lokasi awal keberangkatan paket saat menghitung tarif ongkos kirim real-time')
                    ->schema([
                        TextInput::make('alamat_lengkap')
                            ->label('Alamat Lengkap Toko / Gudang')
                            ->maxLength(500)
                            ->columnSpanFull(),
                        TextInput::make('kota_id')
                            ->label('ID Kota RajaOngkir (Origin ID)')
                            ->required()
                            ->maxLength(10)
                            ->helperText('Contoh ID: 501 (Kab. Sleman), 419 (Kota Yogyakarta), 153 (Jakarta Selatan), 444 (Surabaya), 22 (Bandung)'),
                        TextInput::make('nama_kota')
                            ->label('Nama Kota / Kabupaten')
                            ->required()
                            ->maxLength(255)
                            ->helperText('Contoh: Kabupaten Sleman / Jakarta Selatan'),
                        TextInput::make('provinsi_id')
                            ->label('ID Provinsi RajaOngkir')
                            ->maxLength(10)
                            ->helperText('Contoh: 5 (DI Yogyakarta), 6 (DKI Jakarta)'),
                        TextInput::make('nama_provinsi')
                            ->label('Nama Provinsi')
                            ->maxLength(255)
                            ->helperText('Contoh: DI Yogyakarta / DKI Jakarta'),
                        TextInput::make('kode_pos')
                            ->label('Kode Pos Toko / Gudang')
                            ->maxLength(10),
                    ])
                    ->columns(2),

                Section::make('Integrasi Ekspedisi / Kurir')
                    ->description('Kurir resmi yang digunakan toko untuk kalkulasi ongkos kirim ke pelanggan')
                    ->schema([
                        TextInput::make('kurir_aktif')
                            ->label('Daftar Kurir Aktif')
                            ->required()
                            ->maxLength(255)
                            ->helperText('Pisahkan dengan koma tanpa spasi. Kurir standar RajaOngkir: jne,sicepat,jnt,pos,tiki,wahana')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nama_toko')
            ->columns([
                TextColumn::make('nama_toko')
                    ->label('Nama Toko')
                    ->weight('bold')
                    ->searchable(),
                TextColumn::make('nama_kota')
                    ->label('Kota Asal (Origin RajaOngkir)')
                    ->badge()
                    ->color('primary')
                    ->searchable(),
                TextColumn::make('kota_id')
                    ->label('ID Kota')
                    ->badge(),
                TextColumn::make('telepon')
                    ->label('Telepon / WA'),
                TextColumn::make('kurir_aktif')
                    ->label('Kurir Aktif')
                    ->badge()
                    ->color('success'),
                TextColumn::make('updated_at')
                    ->label('Terakhir Diperbarui')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->recordActions([
                EditAction::make()
                    ->label('Ubah Lokasi & Toko'),
            ])
            ->toolbarActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListPengaturanTokos::route('/'),
            'edit' => EditPengaturanToko::route('/{record}/edit'),
        ];
    }
}

