<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\View;

/**
 * GET /kvkk/{aydinlatma,gizlilik,cerez} — yasal bilgi sayfaları.
 * Gerçek KVKK/GDPR referanslı metinler (yer tutucu değil).
 */
final class PageController
{
    public function aydinlatma(): void
    {
        View::render('legal/aydinlatma', [
            'title' => 'KVKK Aydınlatma Metni — E2E İletişim',
            'description' => '6698 sayılı KVKK m.10 uyarınca kişisel verilerinizin işlenmesine ilişkin aydınlatma metni.',
            'active' => 'legal-aydinlatma',
        ]);
    }

    public function gizlilik(): void
    {
        View::render('legal/gizlilik', [
            'title' => 'Gizlilik Politikası — E2E İletişim',
            'description' => 'Kişisel verilerin korunması ve gizlilik politikası (KVKK + GDPR uyumlu).',
            'active' => 'legal-gizlilik',
        ]);
    }

    public function cerez(): void
    {
        View::render('legal/cerez', [
            'title' => 'Çerez (Cookie) Politikası — E2E İletişim',
            'description' => 'Çerez kullanımına ilişkin politika: zorunlu ve analitik çerezler, açık rıza yönetimi.',
            'active' => 'legal-cerez',
        ]);
    }
}
