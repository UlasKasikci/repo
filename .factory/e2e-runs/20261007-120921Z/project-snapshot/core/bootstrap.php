<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — uygulama önyükleyici (bootstrap).
 *
 * index.php tarafından yüklenir: otomatik yükleyici, yardımcı fonksiyonlar,
 * oturum çerez yapılandırması (HttpOnly + Secure + SameSite=Strict) ve
 * çalışma zamanı sabitleri. Veritabanı bağlantısı tembel (lazy) kurulur.
 */

define('APP_ROOT', dirname(__DIR__));

require __DIR__ . '/helpers.php';

/**
 * PSR-4 benzeri otomatik yükleyici (composer bağımlılığı yoktur).
 * App\Core\*          → core/*.php
 * App\Controllers\*   → core/Controllers/*.php
 * App\Tests\*         → tests/*.php
 */
spl_autoload_register(static function (string $class): void {
    if (!str_starts_with($class, 'App\\')) {
        return;
    }
    $relative = substr($class, 4);
    if (str_starts_with($relative, 'Core\\')) {
        // App\Core\View → core/View.php (Core\ öneki düşürülür)
        $relative = substr($relative, 5);
        $file = __DIR__ . '/' . str_replace('\\', '/', $relative) . '.php';
    } elseif (str_starts_with($relative, 'Controllers\\')) {
        $file = __DIR__ . '/Controllers/' . str_replace('\\', '/', substr($relative, 13)) . '.php';
    } elseif (str_starts_with($relative, 'Tests\\')) {
        $file = APP_ROOT . '/tests/' . str_replace('\\', '/', substr($relative, 6)) . '.php';
    } else {
        return;
    }
    if (is_file($file)) {
        require $file;
    }
});

date_default_timezone_set('Europe/Istanbul');
error_reporting(E_ALL);
ini_set('display_errors', PHP_SAPI === 'cli' ? '1' : ((getenv('AF_DEBUG') === '1') ? '1' : '0'));
ini_set('log_errors', '1');

if (PHP_SAPI !== 'cli' && session_status() !== PHP_SESSION_ACTIVE) {
    $isHttps = (!empty($_SERVER['HTTPS']) && (string) $_SERVER['HTTPS'] !== 'off')
        || strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https';
    // Oturum güvenliği: HttpOnly + Secure + SameSite=Strict (§5 güvence tablosu)
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/',
        'domain' => '',
        'secure' => $isHttps,
        'httponly' => true,
        'samesite' => 'Strict',
    ]);
    session_start();
}
