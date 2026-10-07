<?php

/**
 * App-Fabrika Web Edition — ortak sayfa başlığı (layout/header).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

$isLoggedIn = Auth::check();
$canModerate = $isLoggedIn && Auth::canModerate();
$isAdmin = $isLoggedIn && Auth::isAdmin();
?>
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="<?= e($data['pageDesc'] ?? '') ?>">
  <title><?= e($data['pageTitle'] ?? 'App-Fabrika') ?></title>
  <link rel="stylesheet" href="<?= e(url('/assets/css/style.css')) ?>">
</head>
<body>
  <a class="skip-link" href="#main">İçeriğe geç</a>

  <header class="site-header">
    <div class="container site-header__inner">
      <a class="site-brand" href="<?= e(url('/')) ?>">App&#8209;Fabrika</a>

      <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="site-nav">Menü</button>

      <nav id="site-nav" class="site-nav" aria-label="Ana menü">
        <ul class="site-nav__list">
          <li><a href="<?= e(url('/')) ?>">Anasayfa</a></li>
          <li><a href="<?= e(url('/iletisim')) ?>">İletişim</a></li>
          <?php if ($canModerate) : ?>
          <li><a href="<?= e(url('/admin/mesajlar')) ?>">Mesajlar</a></li>
          <?php endif; ?>
          <?php if ($isAdmin) : ?>
          <li><a href="<?= e(url('/admin/kullanicilar')) ?>">Kullanıcılar</a></li>
          <?php endif; ?>
        </ul>
      </nav>

      <div class="site-header__auth">
        <?php if ($isLoggedIn) : ?>
        <form method="post" action="<?= e(url('/cikis')) ?>">
          <?= Csrf::field() ?>
          <button class="btn btn--ghost btn--small" type="submit">Çıkış</button>
        </form>
        <?php else : ?>
        <a class="btn btn--ghost btn--small" href="<?= e(url('/giris')) ?>">Yönetim Girişi</a>
        <?php endif; ?>
      </div>
    </div>
  </header>

  <main id="main" class="site-main">
