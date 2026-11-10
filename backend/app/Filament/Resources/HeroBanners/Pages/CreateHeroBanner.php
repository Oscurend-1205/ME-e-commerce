<?php

namespace App\Filament\Resources\HeroBanners\Pages;

use App\Filament\Resources\HeroBanners\HeroBannerResource;
use Filament\Resources\Pages\CreateRecord;

class CreateHeroBanner extends CreateRecord
{
    protected static string $resource = HeroBannerResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
