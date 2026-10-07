<?php

declare(strict_types=1);

namespace App;

/**
 * Oturum katmanı — HttpOnly/Secure/SameSite çerezler, session fixation
 * koruması (session_regenerate_id(true)), PASSWORD_ARGON2ID + password_verify.
 */
final class Auth
{
    private const SESSION_NAME = 'FABRIKASESS';
    private const USER_KEY = 'auth_user';

    /** @var array{id: int, email: string, full_name: string, role_id: int, role_name: string}|null */
    private static ?array $cachedUser = null;

    public static function boot(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            return;
        }

        ini_set('session.use_strict_mode', '1');
        ini_set('session.use_only_cookies', '1');
        session_name(self::SESSION_NAME);
        session_set_cookie_params([
            'lifetime' => 0,
            'path' => '/',
            'domain' => '',
            'secure' => self::isHttps(),
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        session_start();
    }

    public static function isHttps(): bool
    {
        $https = $_SERVER['HTTPS'] ?? '';
        if (is_string($https) && $https !== '' && $https !== 'off') {
            return true;
        }

        $forwarded = $_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '';
        if (is_string($forwarded)) {
            return strtolower($forwarded) === 'https';
        }

        return false;
    }

    /** @return array{id: int, email: string, full_name: string, role_id: int, role_name: string}|null */
    public static function user(): ?array
    {
        if (self::$cachedUser !== null) {
            return self::$cachedUser;
        }

        self::boot();

        $stored = $_SESSION[self::USER_KEY] ?? null;
        if (!is_array($stored)) {
            return null;
        }

        $user = [
            'id' => (int) ($stored['id'] ?? 0),
            'email' => (string) ($stored['email'] ?? ''),
            'full_name' => (string) ($stored['full_name'] ?? ''),
            'role_id' => (int) ($stored['role_id'] ?? 0),
            'role_name' => (string) ($stored['role_name'] ?? ''),
        ];

        if ($user['id'] <= 0 || $user['role_name'] === '') {
            return null;
        }

        self::$cachedUser = $user;

        return $user;
    }

    public static function attempt(string $email, string $password): bool
    {
        $row = Database::fetchOne(
            'SELECT u.id, u.email, u.password_hash, u.full_name, u.role_id, r.name AS role_name'
            . ' FROM users u INNER JOIN roles r ON r.id = u.role_id'
            . ' WHERE u.email = ? AND u.is_active = 1 LIMIT 1',
            [$email]
        );

        if ($row === null) {
            return false;
        }

        $hash = $row['password_hash'];
        if (!is_string($hash) || !password_verify($password, $hash)) {
            return false;
        }

        self::boot();
        session_regenerate_id(true);

        $_SESSION[self::USER_KEY] = [
            'id' => (int) $row['id'],
            'email' => (string) $row['email'],
            'full_name' => (string) $row['full_name'],
            'role_id' => (int) $row['role_id'],
            'role_name' => (string) $row['role_name'],
        ];
        self::$cachedUser = null;

        return true;
    }

    public static function check(): bool
    {
        return self::user() !== null;
    }

    /** Yetki kontrolü: rol adı verilen rollerden biriyle eşleşir. */
    public static function can(string ...$roles): bool
    {
        $user = self::user();
        if ($user === null) {
            return false;
        }

        return in_array($user['role_name'], $roles, true);
    }

    public static function logout(): void
    {
        self::boot();

        $_SESSION = [];

        if (ini_get('session.use_cookies') !== false) {
            $params = session_get_cookie_params();
            setcookie(self::SESSION_NAME, '', [
                'expires' => time() - 42000,
                'path' => $params['path'],
                'domain' => $params['domain'],
                'secure' => $params['secure'],
                'httponly' => $params['httponly'],
                'samesite' => $params['samesite'],
            ]);
        }

        session_destroy();
        self::$cachedUser = null;
    }
}
