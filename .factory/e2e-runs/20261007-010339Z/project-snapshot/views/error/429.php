<?php

use App\View;

/** @var string $message */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow">
    <h1>429 — Çok Fazla İstek</h1>
    <p class="page__lead"><?= View::e($message ?? 'Çok fazla gönderim yaptınız. Lütfen bir süre bekleyin.') ?></p>
    <p><a class="btn btn--ghost" href="/">Geri Dön</a></p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
