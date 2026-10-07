<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — users/roles tablosu erişim katmanı.
 *
 * Tüm sorgular PDO prepared statement; parola hash'i yalnız doğrulama için okunur,
 * arayüze asla basılmaz.
 */

final class UserRepository
{
    /**
     * E-posta ile kullanıcıyı rolleriyle birlikte bulur.
     *
     * @return array<string, mixed>|null
     */
    public static function findByEmail(string $email): ?array
    {
        $stmt = Database::get()->prepare(
            'SELECT u.id, u.role_id, u.name, u.email, u.password_hash, u.is_active, r.name AS role_name
             FROM users u
             INNER JOIN roles r ON r.id = u.role_id
             WHERE u.email = :email
             LIMIT 1'
        );
        $executed = $stmt->execute(['email' => $email]);
        if ($executed === false) {
            return null;
        }

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) {
            return null;
        }

        /** @var array<string, mixed> $row */
        return $row;
    }

    /**
     * Tüm kullanıcıları rolleriyle listeler.
     *
     * @return list<array<string, mixed>>
     */
    public static function all(): array
    {
        $stmt = Database::get()->prepare(
            'SELECT u.id, u.name, u.email, u.is_active, u.created_at, r.name AS role_name
             FROM users u
             INNER JOIN roles r ON r.id = u.role_id
             ORDER BY u.id ASC'
        );
        $executed = $stmt->execute();
        if ($executed === false) {
            return [];
        }

        /** @var list<array<string, mixed>> $rows */
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $rows;
    }
}
