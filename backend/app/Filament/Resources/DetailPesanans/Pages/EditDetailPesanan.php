<?php

namespace App\Filament\Resources\DetailPesanans\Pages;

use App\Filament\Resources\DetailPesanans\DetailPesananResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditDetailPesanan extends EditRecord
{
    protected static string $resource = DetailPesananResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
