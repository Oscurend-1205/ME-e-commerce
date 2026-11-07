<?php

namespace App\Filament\Resources\DetailPesanans\Pages;

use App\Filament\Resources\DetailPesanans\DetailPesananResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListDetailPesanans extends ListRecords
{
    protected static string $resource = DetailPesananResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
