<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — front controller.
 *
 * Ortam yapılandırması, güvenli oturum çerezi (HttpOnly/Secure/SameSite),
 * rota tablosu ve hata işleyicisi tek noktadan kurulur.
 */

define('APP_ROOT', __DIR__);
define('VIEW_DIR', APP_ROOT . '/views');

define('DB_HOST', getenv('DB_HOST') !== false ? (string) getenv('DB_HOST') : '127.0.0.1');
define('DB_PORT', getenv('DB_PORT') !== false ? (string) getenv('DB_PORT') : '3306');
define('DB_NAME', getenv('DB_NAME') !== false ? (string) getenv('DB_NAME') : 'app_fabrika');
define('DB_USER', getenv('DB_USER') !== false ? (string) getenv('DB_USER') : 'root');
define('DB_PASS', getenv('DB_PASS') !== false ? (string) getenv('DB_PASS') : '');
define('BASE_URL', getenv('BASE_URL') !== false ? (string) getenv('BASE_URL') : '');

require APP_ROOT . '/core/Helpers.php';
require APP_ROOT . '/core/Database.php';
require APP_ROOT . '/core/Csrf.php';
require APP_ROOT . '/core/Flash.php';
require APP_ROOT . '/core/Auth.php';
require APP_ROOT . '/core/Validator.php';
require APP_ROOT . '/core/MessageRepository.php';
require APP_ROOT . '/core/UserRepository.php';
require APP_ROOT . '/core/ConsentRepository.php';
require APP_ROOT . '/core/Controller.php';
require APP_ROOT . '/core/ErrorView.php';
require APP_ROOT . '/core/HomeController.php';
require APP_ROOT . '/core/ContactController.php';
require APP_ROOT . '/core/AuthController.php';
require APP_ROOT . '/core/AdminController.php';
require APP_ROOT . '/core/App.php';

// --- Güvenli oturum çerezi: HttpOnly, Secure (TLS altında), SameSite=Lax ---
$https = isset($_SERVER['HTTPS']) && is_string($_SERVER['HTTPS'])
    && $_SERVER['HTTPS'] !== '' && $_SERVER['HTTPS'] !== 'off';

session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'domain' => '',
    'secure' => $https,
    'httponly' => true,
    'samesite' => 'Lax',
]);
session_start();

// --- Yakalanmayan hatalar: ayrıntı sızmadan 500 yanıtı ---
set_exception_handler(static function (Throwable $exception): void {
    error_log('[app-fabrika] ' . $exception->getMessage());
    ErrorView::render('500');
});

// --- Rota tablosu ---
$app = new App();

$app->get('/', static function (): void {
    (new HomeController())->index();
});
$app->get('/iletisim', static function (): void {
    (new ContactController())->form();
});
$app->post('/iletisim', static function (): void {
    (new ContactController())->submit();
});
$app->get('/giris', static function (): void {
    (new AuthController())->form();
});
$app->post('/giris', static function (): void {
    (new AuthController())->login();
});
$app->post('/cikis', static function (): void {
    (new AuthController())->logout();
});
$app->get('/admin/mesajlar', static function (): void {
    (new AdminController())->messages();
});
$app->post('/admin/mesajlar/durum', static function (): void {
    (new AdminController())->updateStatus();
});
$app->get('/admin/kullanicilar', static function (): void {
    (new AdminController())->users();
});
$app->get('/yasal/aydinlatma', static function (): void {
    (new HomeController())->aydinlatma();
});
$app->get('/yasal/gizlilik', static function (): void {
    (new HomeController())->gizlilik();
});
$app->get('/yasal/cerez', static function (): void {
    (new HomeController())->cerez();
});

$app->dispatch();
