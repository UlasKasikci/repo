<?php

declare(strict_types=1);

namespace App;

/** Yasal içerik denetleyicisi — KVKK/GDPR aydınlatma, gizlilik, çerez sayfaları. */
final class LegalController
{
    public function aydinlatma(): void
    {
        echo View::render('legal/aydinlatma', [
            'title' => 'KVKK Aydınlatma Metni — E2E İletişim',
            'description' => '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında veri sorumlusu E2E İletişim tarafından hazırlanan aydınlatma metni.',
        ]);
    }

    public function gizlilik(): void
    {
        echo View::render('legal/gizlilik', [
            'title' => 'Gizlilik Politikası — E2E İletişim',
            'description' => 'Kişisel verilerinizin işlenmesi, saklanması ve korunmasına ilişkin gizlilik politikası (KVKK ve GDPR uyumlu).',
        ]);
    }

    public function cerez(): void
    {
        echo View::render('legal/cerez', [
            'title' => 'Çerez Politikası — E2E İletişim',
            'description' => 'Çerez türleri, amaçları ve açık rıza yönetimine ilişkin çerez politikası.',
        ]);
    }
}
