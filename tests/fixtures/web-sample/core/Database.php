<?php
declare(strict_types=1);

final class Database
{
    private ?PDO $pdo = null;

    public function pdo(): PDO
    {
        if ($this->pdo === null) {
            $dsn = 'mysql:host=127.0.0.1;dbname=appfabrika_web;charset=utf8mb4';
            $this->pdo = new PDO($dsn, 'app_user', '', [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        }

        return $this->pdo;
    }
}
