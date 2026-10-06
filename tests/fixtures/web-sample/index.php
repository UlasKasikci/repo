<?php
declare(strict_types=1);

// App-Fabrika Web Edition — örnek giriş noktası (front controller)
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => true,
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_start();

require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/core/App.php';

$app = new App();
$app->run();
