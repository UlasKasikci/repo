<?php

/**
 * App-Fabrika Web Edition — anasayfa.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="hero">
  <div class="container">
    <h1 class="hero__title">Kurumsal iletişim, tek çatı altında</h1>
    <p class="hero__lead">
      App-Fabrika; taleplerinizi tek bir iletişim kanalında toplayan, yönetim paneliyle
      hızlı dönüş sağlayan hafif ve güvenli bir kurumsal çözümdür.
    </p>
    <div class="hero__actions">
      <a class="btn btn--primary" href="<?= e(url('/iletisim')) ?>">Bize Yazın</a>
      <a class="btn btn--ghost" href="<?= e(url('/yasal/gizlilik')) ?>">Gizlilik Yaklaşımımız</a>
    </div>
  </div>
</section>

<section class="features" aria-labelledby="features-title">
  <div class="container">
    <h2 id="features-title" class="section-title">Neler sunuyoruz?</h2>

    <ul class="features__grid">
      <li class="feature-card">
        <h3>İletişim Formu</h3>
        <p>Talebiniz doğrudan yönetim paneline düşer; spam ve doğrulama katmanlarıyla korunur.</p>
      </li>
      <li class="feature-card">
        <h3>Rol Korumalı Panel</h3>
        <p>Admin ve moderatör rolleriyle yetki ayrımı; kullanıcı listesi yalnız admin görünümündedir.</p>
      </li>
      <li class="feature-card">
        <h3>KVKK Uyumlu</h3>
        <p>Aydınlatma metni, çerez onayı ve açık rıza kayıtları standart olarak sunulur.</p>
      </li>
    </ul>
  </div>
</section>

<section class="cta" aria-labelledby="cta-title">
  <div class="container">
    <h2 id="cta-title" class="section-title">Sorunuz mu var?</h2>
    <p>İletişim formunu doldurun; ekibimiz en kısa sürede size dönüş yapsın.</p>
    <a class="btn btn--primary" href="<?= e(url('/iletisim')) ?>">İletişim Formuna Git</a>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
