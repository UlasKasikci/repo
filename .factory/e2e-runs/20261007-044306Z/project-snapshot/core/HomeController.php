<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — anasayfa ve yasal sayfa denetleyicisi.
 */

final class HomeController extends Controller
{
    public function index(): void
    {
        $this->view('home', [
            'pageTitle' => 'App-Fabrika — Kurumsal İletişim',
            'pageDesc' => 'Kurumsal iletişim sitesi: taleplerinizi iletin, yönetim panelimizle hızlı dönüş yapalım.',
        ]);
    }

    /**
     * Yasal sayfalar: KVKK bloğu (aydinlatma | gizlilik | cerez).
     */
    public function aydinlatma(): void
    {
        $this->renderLegal(
            'aydinlatma',
            'KVKK Aydınlatma Metni',
            '6698 sayılı KVKK m.10 uyarınca aydınlatma yükümlülüğü kapsamında bilgilendirme.'
        );
    }

    public function gizlilik(): void
    {
        $this->renderLegal(
            'gizlilik',
            'Gizlilik Politikası',
            'Kişisel verilerinizin güvenliği, işlenmesi ve korunmasına ilişkin ilkeler.'
        );
    }

    public function cerez(): void
    {
        $this->renderLegal(
            'cerez',
            'Çerez Politikası',
            'Çerez kullanımı, açık rıza ve tercih yönetimi hakkında bilgilendirme.'
        );
    }

    private function renderLegal(string $page, string $title, string $desc): void
    {
        $this->view('legal/' . $page, [
            'pageTitle' => $title . ' · App-Fabrika',
            'pageDesc' => $desc,
            'legalPage' => $page,
        ]);
    }
}
