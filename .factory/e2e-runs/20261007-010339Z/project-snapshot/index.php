<?php

declare(strict_types=1);

/**
 * Front controller — tek giriş noktası.
 * Tüm istekler App::run() üzerinden yönlendirilir; güvenlik başlıkları,
 * oturum (HttpOnly/Secure/SameSite) ve CSRF katmanı burada ayağa kalkar.
 */

require __DIR__ . '/core/bootstrap.php';

App\App::run();
