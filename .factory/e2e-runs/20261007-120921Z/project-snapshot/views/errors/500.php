<?php
/**
 * 500 — beklenmeyen sunucu hatası (INTERNAL_ERROR).
 * İç detay (stack/SQL) istemciye sızdırılmaz; sunucu log'una yazılır.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 * @var string $code
 * @var string $message
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow error">
        <p class="error__code"><?= e($code) ?></p>
        <h1 class="error__title">500 — Sunucu Hatası</h1>
        <p class="error__message"><?= e($message) ?></p>
        <div class="hero__actions">
            <a class="btn btn--primary" href="<?= e(url('/')) ?>">Ana Sayfa</a>
        </div>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
