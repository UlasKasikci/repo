<?php
/**
 * GET /kvkk/cerez — Çerez (Cookie) Politikası.
 * KVKK m.5/1 (açık rıza) + GDPR Art. 6/1-a ve ePrivacy yönlendirmeli
 * gerçek politika metni — yer tutucu değil.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow legal">
        <h1 class="page__title">Çerez (Cookie) Politikası</h1>
        <p class="legal__meta">Son güncelleme: 01.10.2026 &middot; Metin sürümü: 1.0.0</p>

        <p>
            Bu politika, E2E İletişim web sitesinde kullanılan çerezleri ve
            çerez tercihlerinizi nasıl yönetebileceğinizi açıklar. Zorunlu
            çerezler dışındaki çerezler yalnız
            <strong>açık rızanız</strong> (KVKK m.5/1, GDPR Art. 6/1-a) alındıktan
            sonra yüklenir.
        </p>

        <h2 class="section-title">1. Çerez Türleri</h2>

        <h3 class="legal__h3">1.1. Zorunlu (Teknik) Çerezler</h3>
        <p>
            Bu çerezler sitenin çalışması için zorunludur; rıza gerektirmez
            (GDPR ePrivacy Direktifi 2002/58/EC m.5/3 istisnası — iletişimin
            ifası için gerekli çerezler). Rıza olmadan da kullanılırlar.
        </p>
        <div class="table-wrap">
            <table class="table">
                <caption class="visually-hidden">Zorunlu çerezler</caption>
                <thead>
                <tr>
                    <th scope="col">Çerez</th>
                    <th scope="col">Amaç</th>
                    <th scope="col">Süre</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td data-label="Çerez">PHPSESSID</td>
                    <td data-label="Amaç">Oturum yönetimi (giriş durumu, CSRF belirteci taşıyıcısı)</td>
                    <td data-label="Süre">Oturum boyunca (30 dk inaktivite zaman aşımı)</td>
                </tr>
                </tbody>
            </table>
        </div>

        <h3 class="legal__h3">1.2. Analitik Çerezler (Rıza Gerektirir)</h3>
        <p>
            Site kullanımını anonim olarak ölçen çerezlerdir. Bu çerezler
            yalnızca onay banner'ında "Kabul Et" seçeneğini seçmeniz halinde
            yüklenir. Reddet seçeneği analitik çerezlerin hiç yüklenmemesine
            yol açar; site kullanımınızı kısıtlamaz.
        </p>
        <div class="table-wrap">
            <table class="table">
                <caption class="visually-hidden">Analitik çerezler ve tercih kaydı</caption>
                <thead>
                <tr>
                    <th scope="col">Kayıt</th>
                    <th scope="col">Amaç</th>
                    <th scope="col">Süre</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td data-label="Kayıt">cookie_consent (yerel depolama)</td>
                    <td data-label="Amaç">Çerez tercihünizin hatırlanması (banner'ın tekrar gösterilmemesi)</td>
                    <td data-label="Süre">Tarayıcı verisi silinene kadar</td>
                </tr>
                <tr>
                    <td data-label="Kayıt">user_consents (sunucu kaydı)</td>
                    <td data-label="Amaç">Rızanın kanıtı: tercih, metin sürümü, IP adresi (KVKK m.5/1 ispat yükü)</td>
                    <td data-label="Süre">Meşru ispat süresi (mevzuat uyarınca)</td>
                </tr>
                </tbody>
            </table>
        </div>

        <h2 class="section-title">2. Tercih Yönetimi</h2>
        <ul>
            <li>
                Tercihinizi ilk ziyaretinizde onay banner'ı üzerinden verirsiniz:
                <strong>Kabul Et</strong> (analitik çerezlere izin) veya
                <strong>Reddet</strong> (yalnız zorunlu çerezler).
            </li>
            <li>
                Tercihiniz tarayıcınızda saklanır ve tekrar ziyaretlerde banner
                gösterilmez.
            </li>
            <li>
                Tercihinizi dilediğiniz zaman değiştirebilirsiniz: alt bilgideki
                <button type="button" id="cookie-preferences-open-legal" class="btn btn--link">Çerez Tercihleri</button>
                bağlantısı onay banner'ını yeniden açar.
            </li>
            <li>
                Rızanız, tercihiniz verildiği anda IP adresiniz ve metin sürümü
                ile birlikte sunucuda kayıt altına alınır.
            </li>
        </ul>

        <h2 class="section-title">3. Haklarınız</h2>
        <p>
            KVKK m.11 ve GDPR Art. 7/3 uyarınca rızanızı dilediğiniz zaman
            geri alma hakkına sahipsiniz; rızanın geri alınması, rızaya dayalı
            işlemenin meşruiyetini geriye dönük etkilemez. Sorularınız için
            <a href="<?= e(url('/iletisim')) ?>">iletişim formunu</a>
            kullanabilirsiniz.
        </p>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
