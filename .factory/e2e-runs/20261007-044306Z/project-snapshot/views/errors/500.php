<?php

/**
 * App-Fabrika Web Edition — 500 hatası (ayrıntı sızdırılmaz).
 */

require VIEW_DIR . '/layout/header.php';
?>

<section class="error-page">
  <div class="container">
    <p class="error-page__code">500</p>
    <h1>Bir hata oluştu</h1>
    <p>Beklenmeyen bir sunucu hatası yaşandı. Lütfen daha sonra tekrar deneyin.</p>
    <a class="btn btn--primary" href="<?= e(url('/')) ?>">Anasayfaya Dön</a>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
