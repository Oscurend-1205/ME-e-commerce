<?php

namespace App\Filament\Resources\Pesanans\Pages;

use App\Filament\Resources\Pesanans\PesananResource;
use App\Models\Pesanan;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditPesanan extends EditRecord
{
    protected static string $resource = PesananResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()
                ->before(function (Pesanan $record): void {
                    if (!in_array($record->status, ['dibatalkan', 'selesai'])) {
                        $record->kembalikanStok();
                    }
                }),
        ];
    }

    protected function beforeSave(): void
    {
        $statusLama = $this->record->getOriginal('status');
        $statusBaru = $this->data['status'] ?? null;

        if ($statusBaru === 'dibatalkan' && $statusLama !== 'dibatalkan') {
            $this->record->kembalikanStok();
        }
    }
}
