<?php

declare(strict_types=1);

if (!defined('BASE_PATH')) {
    define('BASE_PATH', dirname(__DIR__));
}

require_once __DIR__ . '/App.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/CSRF.php';
require_once __DIR__ . '/Auth.php';
require_once __DIR__ . '/View.php';
require_once __DIR__ . '/Response.php';
require_once __DIR__ . '/Validator.php';
require_once __DIR__ . '/HomeController.php';
require_once __DIR__ . '/LegalController.php';
require_once __DIR__ . '/AuthController.php';
require_once __DIR__ . '/ContactController.php';
require_once __DIR__ . '/AdminController.php';
