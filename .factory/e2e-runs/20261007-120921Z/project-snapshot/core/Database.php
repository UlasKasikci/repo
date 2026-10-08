<?php

declare(strict_types=1);

namespace App\Core;

use PDO;
use PDOException;
use PDOStatement;
use RuntimeException;

/**
 * PDO bağlantı katmanı (tekil, tembel kurulum).
 *
 * Güvenlik sözleşmesi:
 *  - Tüm sorgular prepare()/execute() ile ÇALIŞTIRILIR (prepared statement).
 *  - Superglobal'lar hiçbir koşulda doğrudan sorguya girmez.
 *  - Emülatör kapalı: gerçek hazırlanmış ifadeler (MySQL native prepare).
 *  - Bağlantı bilgileri ortam değişkenlerinden okunur (AF_DB_HOST/NAME/USER/PASS).
 */
final class Database
{
    private const DEFAULT_HOST = '127.0.0.1';
    private const DEFAULT_NAME = 'app_fabrika';
    private const DEFAULT_USER = 'root';
    private const DEFAULT_PASS = '';

    private static ?PDO $connection = null;

    public static function connection(): PDO
    {
        if (self::$connection instanceof PDO) {
            return self::$connection;
        }
        $dsn = sprintf(
            'mysql:host=%s;dbname=%s;charset=utf8mb4',
            self::env('AF_DB_HOST', self::DEFAULT_HOST),
            self::env('AF_DB_NAME', self::DEFAULT_NAME)
        );
        try {
            self::$connection = new PDO(
                $dsn,
                self::env('AF_DB_USER', self::DEFAULT_USER),
                self::env('AF_DB_PASS', self::DEFAULT_PASS),
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::ATTR_STRINGIFY_FETCHES => false,
                ]
            );
        } catch (PDOException $exception) {
            // İç hata detayı (DSN/kimlik) istemciye sızdırılmaz; ileti genel kalır.
            throw new RuntimeException('Veritabanı bağlantısı kurulamadı.', 0, $exception);
        }
        return self::$connection;
    }

    /**
     * Hazırlanmış ifade çalıştırır ve ifadeyi döndürür.
     *
     * @param array<string|int, mixed> $params
     */
    public static function run(string $sql, array $params = []): PDOStatement
    {
        $statement = self::connection()->prepare($sql);
        $statement->execute($params);
        return $statement;
    }

    /**
     * Tek satır döndürür; sonuç yoksa null.
     *
     * @param array<string|int, mixed> $params
     * @return array<string, mixed>|null
     */
    public static function one(string $sql, array $params = []): ?array
    {
        $row = self::run($sql, $params)->fetch();
        return is_array($row) ? $row : null;
    }

    /**
     * Tüm satırları döndürür.
     *
     * @param array<string|int, mixed> $params
     * @return list<array<string, mixed>>
     */
    public static function all(string $sql, array $params = []): array
    {
        /** @var list<array<string, mixed>> $rows */
        $rows = self::run($sql, $params)->fetchAll();
        return $rows;
    }

    private static function env(string $key, string $default): string
    {
        $value = getenv($key);
        return is_string($value) && $value !== '' ? $value : $default;
    }
}
