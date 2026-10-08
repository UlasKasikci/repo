<?php

/**
 * Çerez onay banner'ı (KVKK m.5/1 açık rıza + GDPR Art. 6/1-a).
 *
 * Açık rıza: banner varsayılan olarak gizlidir; kullanıcı depolanmış
 * bir tercih bırakmadıysa cookie-consent.js tarafından gösterilir.
 * Tercihler: Kabul Et / Reddet — localStorage'da saklanır ve
 * POST /api/cerez-riza ile user_consents tablosuna (ip + metin sürümü)
 * kaydedilir. "Çerez Tercihleri" bağlantısı banner'ı yeniden açar.
 */

use App\Core\Csrf;

$consentVersion = '1.0.0';
?>
<aside id="cookie-consent"
       class="cookie-consent"
       role="dialog"
       aria-labelledby="cookie-consent-title"
       aria-describedby="cookie-consent-desc"
       data-consent-version="<?= e($consentVersion) ?>"
       data-csrf="<?= e(Csrf::token()) ?>"
       hidden>
    <div class="cookie-consent__inner container">
        <div class="cookie-consent__text">
            <h2 id="cookie-consent-title" class="cookie-consent__title">Çerez Tercihleriniz</h2>
            <p id="cookie-consent-desc" class="cookie-consent__desc">
                Sitemiz yalnızca oturumun çalışması için zorunlu çerezleri kullanır.
                Analitik çerezler ancak <strong>açık onayınızla</strong> yüklenir.
                Tercihinizi daha sonra
                <a href="<?= e(url('/kvkk/cerez')) ?>">Çerez Politikası</a>
                sayfasından veya alt bilgideki "Çerez Tercihleri" bağlantısından değiştirebilirsiniz.
            </p>
        </div>
        <div class="cookie-consent__actions">
            <button type="button" class="btn btn--primary" data-cookie-action="accept">
                Kabul Et
            </button>
            <button type="button" class="btn btn--ghost" data-cookie-action="reject">
                Reddet
            </button>
        </div>
    </div>
</aside>
