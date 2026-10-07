<?php

use App\CSRF;
use App\View;

/**
 * @var string|null $error
 * @var string $email
 */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow">
    <h1>Yönetim Paneli Girişi</h1>
    <p class="page__lead">
        Bu bölüm rol korumalıdır (admin/moderator). Oturum bilgileriniz HttpOnly/SameSite
        çerezleriyle korunur.
    </p>

    <?php if (($error ?? null) !== null && $error !== ''): ?>
        <div class="alert alert--error" role="alert">
            <p><?= View::e($error) ?></p>
        </div>
    <?php endif; ?>

    <form method="post" action="/giris" class="form">
        <?= View::e(CSRF::field()) ?>

        <div class="form__field">
            <label for="email">E-posta</label>
            <input type="email" id="email" name="email" required maxlength="190"
                   autocomplete="username" value="<?= View::e($email ?? '') ?>">
        </div>

        <div class="form__field">
            <label for="password">Parola</label>
            <input type="password" id="password" name="password" required
                   autocomplete="current-password">
        </div>

        <button type="submit" class="btn btn--primary">Giriş Yap</button>
    </form>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
