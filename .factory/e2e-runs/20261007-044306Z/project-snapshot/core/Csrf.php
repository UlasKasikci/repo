<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — CSRF token üretimi ve doğrulaması.
 *
 * Token oturum bazlıdır; hash_equals ile zaman-güvenli karşılaştırma yapılır.
 * Tüm POST istekleri bu doğrulamadan geçmek zorundadır.
 */

final class Csrf
{
    private const SESSION_KEY = 'csrf_token';

    public static function token(): string
    {
        $stored = $_SESSION[self::SESSION_KEY] ?? null;
        if (!is_string($stored) || $stored === '') {
            $stored = bin2hex(random_bytes(32));
            $_SESSION[self::SESSION_KEY] = $stored;
        }

        return $stored;
    }

    public static function validate(?string $token): bool
    {
        $stored = $_SESSION[self::SESSION_KEY] ?? null;
        if (!is_string($stored) || $stored === '') {
            return false;
        }
        if ($token === null || $token === '') {
            return false;
        }

        return hash_equals($stored, $token);
    }

    /**
     * POST formları için gizli token alanı (değer içeride kaçırılır).
     */
    public static function field(): string
    {
        return '<input type="hidden" name="csrf_token" value="' . e(self::token()) . '">';
    }

    /**
     * Süper globalden token'ı güvenli biçimde okur.
     */
    public static function tokenFromPost(): ?string
    {
        $token = $_POST['csrf_token'] ?? null;

        return is_string($token) && $token !== '' ? $token : null;
    }
}
