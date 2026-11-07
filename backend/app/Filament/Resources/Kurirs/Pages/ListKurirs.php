<?php

namespace App\Filament\Resources\Kurirs\Pages;

use App\Filament\Resources\Kurirs\KurirResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListKurirs extends ListRecords
{
    protected static string $resource = KurirResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
