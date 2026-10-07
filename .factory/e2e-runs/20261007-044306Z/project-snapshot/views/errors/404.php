<?php

/**
 * App-Fabrika Web Edition — 404 hatası.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="error-page">
  <div class="container">
    <p class="error-page__code">404</p>
    <h1>Sayfa bulunamadı</h1>
    <p>Aradığınız sayfa taşınmış veya hiç var olmamış olabilir.</p>
    <a class="btn btn--primary" href="<?= e(url('/')) ?>">Anasayfaya Dön</a>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
