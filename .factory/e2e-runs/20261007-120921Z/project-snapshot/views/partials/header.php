<?php

/**
 * Ortak sayfa başlığı (semantic HTML5 + SEO meta).
 *
 * @var string $title       <title> ve <h1> dışı sayfa başlığı
 * @var string $description meta description
 * @var string $active      aktif menü anahtarı (home|contact|login|account|admin|legal-*)
 */

use App\Core\Auth;
use App\Core\Csrf;

$title = $title ?? 'E2E İletişim';
$description = $description ?? '';
$active = $active ?? '';
$canonical = url('/' . ltrim((string) ($_SERVER['REQUEST_URI'] ?? '/'), '/'));
$canonicalPath = parse_url($canonical, PHP_URL_PATH);
$canonical = url(is_string($canonicalPath) && $canonicalPath !== '' ? $canonicalPath : '/');
?>
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="<?= e($description) ?>">
    <meta name="robots" content="index, follow">
    <link rel="canonical" href="<?= e($canonical) ?>">
    <link rel="stylesheet" href="<?= e(url('assets/css/style.css')) ?>">
    <link rel="icon" href="<?= e(url('assets/images/favicon.svg')) ?>" type="image/svg+xml">
    <title><?= e($title) ?></title>
</head>
<body>
<a class="skip-link" href="#main">İçeriğe geç</a>

<header class="site-header">
    <div class="container site-header__inner">
        <a class="site-brand" href="<?= e(url('/')) ?>">
            <span class="site-brand__mark" aria-hidden="true">E2E</span>
            <span class="site-brand__name">İletişim</span>
        </a>

        <nav class="site-nav" aria-label="Ana menü">
            <ul class="site-nav__list">
                <li><a href="<?= e(url('/')) ?>"<?= $active === 'home' ? ' aria-current="page"' : '' ?>>Ana Sayfa</a></li>
                <li><a href="<?= e(url('/iletisim')) ?>"<?= $active === 'contact' ? ' aria-current="page"' : '' ?>>İletişim</a></li>
                <?php if (Auth::check()): ?>
                    <li><a href="<?= e(url('/hesabim')) ?>"<?= $active === 'account' ? ' aria-current="page"' : '' ?>>Hesabım</a></li>
                    <?php if (Auth::isModerator()): ?>
                        <li><a href="<?= e(url('/admin')) ?>"<?= $active === 'admin' ? ' aria-current="page"' : '' ?>>Yönetim</a></li>
                    <?php endif; ?>
                    <li class="site-nav__session">
                        <span class="site-nav__user"><?= e(Auth::userName()) ?></span>
                        <form method="post" action="<?= e(url('/cikis')) ?>" class="inline-form">
                            <?= Csrf::field() ?>
                            <button type="submit" class="btn btn--ghost btn--small">Çıkış</button>
                        </form>
                    </li>
                <?php else: ?>
                    <li><a href="<?= e(url('/giris')) ?>"<?= $active === 'login' ? ' aria-current="page"' : '' ?>>Giriş</a></li>
                <?php endif; ?>
            </ul>
        </nav>
    </div>
</header>

<main id="main" class="site-main">
