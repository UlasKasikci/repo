<?php

declare(strict_types=1);

namespace App\Core;

/**
 * Kimlik doğrulama + RBAC (rol tabanlı erişim denetimi).
 *
 * Rol hiyerarşisi (roles tablosu): Admin tüm yönetim; Moderator mesaj
 * okuma/durum; User yalnız kendi kayıtları. Oturum 30 dakika inaktivite
 * timeout'una tabidir; girişte session_regenerate_id(true) ile fixation
 * koruması uygulanır. Başarısız girişte sabit hata iletisi kullanılır.
 */
final class Auth
{
    public const TIMEOUT_SECONDS = 1800; // 30 dakika

    /**
     * Giriş denemesi: e-posta + parola (Argon2id hash, password_verify).
     * Başarılıysa oturum yenilenir ve kullanıcı bağlamı yazılır.
     */
    public static function attempt(string $email, string $password): bool
    {
        $row = Database::one(
            'SELECT u.id, u.name, u.email, u.role_id, u.is_active, u.password_hash, r.name AS role_name'
            . ' FROM users AS u INNER JOIN roles AS r ON r.id = u.role_id'
            . ' WHERE u.email = :email LIMIT 1',
            [':email' => $email]
        );
        if ($row === null) {
            // Kullanıcı bulunamadı — parola doğrulaması atlanmaz, sabit ileti döner.
            return false;
        }
        $hash = (string) ($row['password_hash'] ?? '');
        if ((int) ($row['is_active'] ?? 0) !== 1 || !password_verify($password, $hash)) {
            return false;
        }
        session_regenerate_id(true);
        $_SESSION['user_id'] = (int) ($row['id'] ?? 0);
        $_SESSION['role_id'] = (int) ($row['role_id'] ?? 0);
        $_SESSION['role_name'] = (string) ($row['role_name'] ?? '');
        $_SESSION['user_name'] = (string) ($row['name'] ?? '');
        $_SESSION['user_email'] = (string) ($row['email'] ?? '');
        $_SESSION['last_activity'] = time();
        Database::run(
            'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = :id',
            [':id' => $_SESSION['user_id']]
        );
        return true;
    }

    public static function check(): bool
    {
        return isset($_SESSION['user_id']) && (int) $_SESSION['user_id'] > 0;
    }

    public static function userId(): int
    {
        return self::check() ? (int) ($_SESSION['user_id'] ?? 0) : 0;
    }

    public static function userName(): string
    {
        $name = $_SESSION['user_name'] ?? null;
        return is_string($name) ? $name : '';
    }

    public static function role(): string
    {
        $role = $_SESSION['role_name'] ?? null;
        return is_string($role) ? $role : '';
    }

    public static function isAdmin(): bool
    {
        return self::role() === 'Admin';
    }

    public static function isModerator(): bool
    {
        return self::isAdmin() || self::role() === 'Moderator';
    }

    /**
     * 30 dakika inaktivite timeout'u: süresi dolan oturumu kapatır,
     * aksi halde son etkinlik damgasını güncelleyerek devam eder.
     */
    public static function enforceTimeout(): void
    {
        if (!self::check()) {
            return;
        }
        $last = $_SESSION['last_activity'] ?? 0;
        $last = is_int($last) ? $last : (int) $last;
        if ((time() - $last) > self::TIMEOUT_SECONDS) {
            self::logout();
            return;
        }
        $_SESSION['last_activity'] = time();
    }

    public static function logout(): void
    {
        $_SESSION = [];
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_destroy();
        }
    }
}
