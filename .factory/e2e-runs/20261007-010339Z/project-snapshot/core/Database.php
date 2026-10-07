<?php

declare(strict_types=1);

namespace App;

use PDO;
use PDOStatement;

/**
 * PDO veri katmanı — tüm sorgular prepared statement (SQL injection koruması).
 * N+1 yasağı: listeler JOIN/tek sorgu ile çekilir.
 */
final class Database
{
    private static ?PDO $pdo = null;

    /** @return array{dsn: string, user: string, pass: string} */
    private static function config(): array
    {
        return [
            'dsn' => sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
                (string) (getenv('DB_HOST') ?: '127.0.0.1'),
                (string) (getenv('DB_PORT') ?: '3306'),
                (string) (getenv('DB_NAME') ?: 'e2e_iletisim')
            ),
            'user' => (string) (getenv('DB_USER') ?: 'root'),
            'pass' => (string) (getenv('DB_PASS') ?: ''),
        ];
    }

    public static function pdo(): PDO
    {
        if (self::$pdo instanceof PDO) {
            return self::$pdo;
        }

        $config = self::config();
        $pdo = new PDO($config['dsn'], $config['user'], $config['pass'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);

        self::$pdo = $pdo;

        return self::$pdo;
    }

    /** @param list<mixed> $params */
    public static function query(string $sql, array $params = []): PDOStatement
    {
        $stmt = self::pdo()->prepare($sql);
        $stmt->execute($params);

        return $stmt;
    }

    /**
     * @param list<mixed> $params
     * @return list<array<string, mixed>>
     */
    public static function fetchAll(string $sql, array $params = []): array
    {
        $stmt = self::query($sql, $params);
        /** @var list<array<string, mixed>> $rows */
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $rows;
    }

    /**
     * @param list<mixed> $params
     * @return array<string, mixed>|null
     */
    public static function fetchOne(string $sql, array $params = []): ?array
    {
        $stmt = self::query($sql, $params);
        /** @var array<string, mixed>|false $row */
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return is_array($row) ? $row : null;
    }

    /** @param list<mixed> $params */
    public static function insert(string $sql, array $params = []): int
    {
        self::query($sql, $params);
        $id = self::pdo()->lastInsertId();

        return (int) $id;
    }

    /** @param list<mixed> $params */
    public static function execute(string $sql, array $params = []): int
    {
        return self::query($sql, $params)->rowCount();
    }
}
