<?php

use App\App;
use App\Auth;
use App\View;

/**
 * @var string $title
 * @var string $description
 */
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= View::e($title ?? 'E2E İletişim') ?></title>
    <meta name="description" content="<?= View::e($description ?? '') ?>">
    <link rel="icon" type="image/svg+xml" href="<?= View::e(App::baseUrl()) ?>/assets/images/favicon.svg">
    <link rel="stylesheet" href="<?= View::e(App::baseUrl()) ?>/assets/css/style.css">
</head>
<body>
<a class="skip-link" href="#main">İçeriğe geç</a>
<header class="site-header">
    <nav class="site-nav" aria-label="Ana gezinme">
        <a class="site-nav__brand" href="/">E2E <span>İletişim</span></a>
        <ul class="site-nav__list">
            <li><a href="/">Ana Sayfa</a></li>
            <li><a href="/iletisim">İletişim</a></li>
            <?php if (Auth::check()): ?>
                <li><a href="/admin">Yönetim Paneli</a></li>
                <li>
                    <form method="post" action="/cikis" class="inline-form">
                        <?= View::e(CSRF::field()) ?>
                        <button type="submit" class="link-button">Çıkış (<?= View::e(Auth::user()['full_name'] ?? '') ?>)</button>
                    </form>
                </li>
            <?php else: ?>
                <li><a href="/giris">Giriş</a></li>
            <?php endif; ?>
        </ul>
    </nav>
</header>
<main id="main" class="site-main">
