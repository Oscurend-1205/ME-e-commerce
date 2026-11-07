<?php

namespace App\Filament\Resources\AsetTampilans\Pages;

use App\Filament\Resources\AsetTampilans\AsetTampilanResource;
use Filament\Resources\Pages\ListRecords;

class ListAsetTampilans extends ListRecords
{
    protected static string $resource = AsetTampilanResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
