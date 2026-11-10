<?php

namespace App\Filament\Resources\AuditLogs\Pages;

use App\Filament\Resources\AuditLogs\AuditLogPembayaranResource;
use Filament\Resources\Pages\ListRecords;

class ListAuditLogPembayarans extends ListRecords
{
    protected static string $resource = AuditLogPembayaranResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}

