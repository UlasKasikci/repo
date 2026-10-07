<?php

/**
 * App-Fabrika Web Edition — KVKK açık rıza çerez onay bileşeni.
 *
 * Banner gizli başlar; assets/js/cookie-consent.js saklanan tercihe göre
 * gösterir. Açık rıza (kabul), ret (yalnızca zorunlu) ve tercih yönetimi
 * (yeniden açma) desteklenir.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];
?>
<div id="cookie-consent" class="cookie-consent" role="region" aria-live="polite" aria-labelledby="cookie-consent-title" hidden>
  <div class="cookie-consent__inner container">
    <h2 class="cookie-consent__title" id="cookie-consent-title">Çerez Tercihleri</h2>

    <p class="cookie-consent__text">
      Bu site; oturumun çalışması ve güvenlik (CSRF) gibi zorunlu çerezlerin yanı sıra
      site deneyimini geliştirmek için tercihi çerezleri kullanabilir. Zorunlu olmayan
      çerezler için
      <strong>6698 sayılı KVKK m.5/2(a)</strong> uyarınca açık rızanıza ihtiyacımız var;
      rıza vermeden siteyi kullanmaya devam edebilirsiniz.
      Ayrıntılar için <a href="<?= e(url('/yasal/cerez')) ?>">Çerez Politikamızı</a> okuyun.
    </p>

    <div class="cookie-consent__actions">
      <button type="button" id="cookie-consent-accept" class="btn btn--primary">Tümünü Kabul Et</button>
      <button type="button" id="cookie-consent-reject" class="btn btn--ghost">Yalnızca Zorunlu Çerezler</button>
      <a class="cookie-consent__more" href="<?= e(url('/yasal/cerez')) ?>">Tercihleri daha sonra yönet</a>
    </div>
  </div>
</div>
