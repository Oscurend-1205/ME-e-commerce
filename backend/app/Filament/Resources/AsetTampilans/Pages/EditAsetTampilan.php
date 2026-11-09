<?php

namespace App\Filament\Resources\AsetTampilans\Pages;

use App\Filament\Resources\AsetTampilans\AsetTampilanResource;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Support\Facades\Artisan;

class EditAsetTampilan extends EditRecord
{
    protected static string $resource = AsetTampilanResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }

    protected function afterSave(): void
    {
        try {
            Artisan::call('katalog:export');
        } catch (\Throwable $e) {
            // Ignore if export encounters an issue
        }
    }
}
