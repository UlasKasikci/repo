<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\View;

/**
 * GET / — ana sayfa (kurumsal iletişim sitesi vitrini).
 */
final class HomeController
{
    public function index(): void
    {
        View::render('home', [
            'title' => 'E2E İletişim — Kurumsal İletişim Platformu',
            'description' => 'E2E İletişim: kurumsal iletişim sitesi. Soru, öneri ve iş birliği talepleriniz için iletişim formunu kullanabilirsiniz.',
            'active' => 'home',
        ]);
    }
}
