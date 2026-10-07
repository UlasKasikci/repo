<?php

declare(strict_types=1);

namespace App;

/** Ana sayfa denetleyicisi — DB'siz, statik kurumsal içerik. */
final class HomeController
{
    public function index(): void
    {
        echo View::render('home', [
            'title' => 'E2E İletişim — Kurumsal İletişim Platformu',
            'description' => 'E2E İletişim kurumsal platformu: KVKK uyumlu iletişim formu, rol korumalı yönetim paneli ve şeffaf veri işleme politikaları.',
        ]);
    }
}
