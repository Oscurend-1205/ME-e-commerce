<?php

namespace App\Filament\Resources\PengaturanTokos\Pages;

use App\Filament\Resources\PengaturanTokos\PengaturanTokoResource;
use App\Models\PengaturanToko;
use Filament\Resources\Pages\ListRecords;

class ListPengaturanTokos extends ListRecords
{
    protected static string $resource = PengaturanTokoResource::class;

    public function mount(): void
    {
        // Pastikan record konfigurasi default selalu ada
        PengaturanToko::getPengaturan();

        parent::mount();
    }

    protected function getHeaderActions(): array
    {
        return [];
    }
}

