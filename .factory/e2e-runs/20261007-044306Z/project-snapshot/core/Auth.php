<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — oturum kimlik doğrulama ve RBAC katmanı.
 *
 * Parola doğrulaması password_verify (Argon2id hash) ile; oturum fixation
 * koruması için giriş başarısında session_regenerate_id(true) çağrılır.
 */

final class Auth
{
    public const ROLE_ADMIN = 1;
    public const ROLE_MODERATOR = 2;

    public static function attempt(string $email, string $password): bool
    {
        $user = UserRepository::findByEmail($email);
        if ($user === null) {
            return false;
        }

        $hash = $user['password_hash'] ?? null;
        if (!is_string($hash) || $hash === '') {
            return false;
        }

        if (!password_verify($password, $hash)) {
            return false;
        }

        if ((int) ($user['is_active'] ?? 0) !== 1) {
            return false;
        }

        session_regenerate_id(true);

        $_SESSION['user_id'] = (int) ($user['id'] ?? 0);
        $_SESSION['role_id'] = (int) ($user['role_id'] ?? 0);
        $_SESSION['role_name'] = (string) ($user['role_name'] ?? '');

        return true;
    }

    public static function check(): bool
    {
        return self::userId() !== null;
    }

    public static function userId(): ?int
    {
        $id = $_SESSION['user_id'] ?? null;

        return is_int($id) && $id > 0 ? $id : null;
    }

    public static function roleId(): ?int
    {
        $id = $_SESSION['role_id'] ?? null;

        return is_int($id) && $id > 0 ? $id : null;
    }

    public static function isAdmin(): bool
    {
        return self::roleId() === self::ROLE_ADMIN;
    }

    public static function canModerate(): bool
    {
        $roleId = self::roleId();

        return $roleId === self::ROLE_ADMIN || $roleId === self::ROLE_MODERATOR;
    }

    public static function logout(): void
    {
        $_SESSION = [];

        $params = session_get_cookie_params();
        $name = session_name();
        if (is_string($name)) {
            setcookie($name, '', [
                'expires' => time() - 42000,
                'path' => $params['path'],
                'domain' => $params['domain'],
                'secure' => $params['secure'],
                'httponly' => $params['httponly'],
                'samesite' => $params['samesite'],
            ]);
        }

        session_destroy();
    }
}
