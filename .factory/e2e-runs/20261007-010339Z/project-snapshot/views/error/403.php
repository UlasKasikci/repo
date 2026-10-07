<?php

use App\View;

/** @var string $message */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow">
    <h1>403 — Erişim Yasak</h1>
    <p class="page__lead"><?= View::e($message ?? 'Bu bölüm için yetkiniz bulunmuyor.') ?></p>
    <p><a class="btn btn--ghost" href="/">Ana Sayfaya Dön</a></p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
