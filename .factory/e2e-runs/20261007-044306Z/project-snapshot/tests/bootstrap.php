<?php

declare(strict_types=1);

/**
 * PHPUnit bootstrap — çekirdek birimler yüklenir (bağımlılık yok, DB gerekmez).
 */

require dirname(__DIR__) . '/core/Helpers.php';
require dirname(__DIR__) . '/core/Csrf.php';
require dirname(__DIR__) . '/core/Flash.php';
require dirname(__DIR__) . '/core/App.php';
require dirname(__DIR__) . '/core/Validator.php';

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}
