<?php

/**
 * App-Fabrika Web Edition — yönetim girişi.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

$flash = arr($data['flash'] ?? null);
$errors = arr($flash['errors'] ?? null);
$old = arr($flash['old'] ?? null);

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>Yönetim Girişi</h1>
    <p>Panel erişimi yetkili kullanıcılar içindir.</p>
  </div>
</section>

<section class="login">
  <div class="container login__wrap">
    <?php if (isset($errors['form'])) : ?>
    <p class="alert alert--error" role="alert"><?= e($errors['form']) ?></p>
    <?php endif; ?>

    <form class="login-form" method="post" action="<?= e(url('/giris')) ?>">
      <?= Csrf::field() ?>

      <div class="form-field">
        <label for="login-email">E-posta</label>
        <input id="login-email" name="email" type="email" maxlength="190" required
               autocomplete="username" value="<?= e($old['email'] ?? '') ?>">
      </div>

      <div class="form-field">
        <label for="login-password">Şifre</label>
        <input id="login-password" name="password" type="password" required
               autocomplete="current-password">
      </div>

      <button class="btn btn--primary" type="submit">Giriş Yap</button>
    </form>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
