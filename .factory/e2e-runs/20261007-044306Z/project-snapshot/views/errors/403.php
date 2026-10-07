<?php

/**
 * App-Fabrika Web Edition — 403 hatası (yetkisiz erişim / geçersiz CSRF).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="error-page">
  <div class="container">
    <p class="error-page__code">403</p>
    <h1>Erişim engellendi</h1>
    <p>Bu işlem için yetkiniz yok veya güvenlik doğrulaması geçersiz.</p>
    <a class="btn btn--primary" href="<?= e(url('/')) ?>">Anasayfaya Dön</a>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
