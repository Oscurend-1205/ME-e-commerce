<?php

namespace App\Filament\Resources\PengaturanTokos\Pages;

use App\Filament\Resources\PengaturanTokos\PengaturanTokoResource;
use Filament\Resources\Pages\EditRecord;

class EditPengaturanToko extends EditRecord
{
    protected static string $resource = PengaturanTokoResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}

