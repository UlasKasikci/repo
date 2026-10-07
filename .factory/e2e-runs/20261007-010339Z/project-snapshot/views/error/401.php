<?php

use App\View;

/** @var string $message */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow">
    <h1>401 — Oturum Gerekli</h1>
    <p class="page__lead"><?= View::e($message ?? 'Bu bölüm için oturum açmanız gerekir.') ?></p>
    <p><a class="btn btn--primary" href="/giris">Giriş Yap</a></p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
