<?php
/**
 * GET /giris — giriş formu.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 * @var string $error    giriş hatası (boşsa yok)
 * @var string $oldEmail eski e-posta değeri
 */

use App\Core\Csrf;

$error = $error ?? '';
$oldEmail = $oldEmail ?? '';

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow">
        <h1 class="page__title">Giriş</h1>
        <p class="page__lead">
            Yönetim paneline ve hesap sayfanıza erişmek için giriş yapın.
        </p>

        <?php if ($error !== ''): ?>
            <div class="flash flash--error" role="alert"><?= e($error) ?></div>
        <?php endif; ?>

        <form class="form" method="post" action="<?= e(url('/giris')) ?>" novalidate>
            <?= Csrf::field() ?>

            <div class="form__field">
                <label for="email">E-posta</label>
                <input type="email" id="email" name="email" required maxlength="190"
                       autocomplete="username" value="<?= e($oldEmail) ?>">
            </div>

            <div class="form__field">
                <label for="password">Parola</label>
                <input type="password" id="password" name="password" required
                       autocomplete="current-password">
            </div>

            <div class="form__actions">
                <button type="submit" class="btn btn--primary">Giriş Yap</button>
            </div>
        </form>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
