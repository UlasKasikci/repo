<?php

declare(strict_types=1);

namespace App;

/**
 * CSRF token üretimi/doğrulaması — tüm POST/PUT/DELETE isteklerinde zorunlu.
 * Token: bin2hex(random_bytes(32)), hash_equals ile sabit-zamanlı karşılaştırma.
 */
final class CSRF
{
    private const SESSION_KEY = 'csrf_token';

    public static function ensureSession(): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            Auth::boot();
        }
    }

    public static function token(): string
    {
        self::ensureSession();

        $stored = $_SESSION[self::SESSION_KEY] ?? null;
        if (is_string($stored) && $stored !== '') {
            return $stored;
        }

        $token = bin2hex(random_bytes(32));
        $_SESSION[self::SESSION_KEY] = $token;

        return $token;
    }

    public static function validate(?string $token): bool
    {
        self::ensureSession();

        $stored = $_SESSION[self::SESSION_KEY] ?? null;
        if (!is_string($stored) || !is_string($token) || $token === '') {
            return false;
        }

        return hash_equals($stored, $token);
    }

    public static function field(): string
    {
        return '<input type="hidden" name="csrf_token" value="' . self::token() . '">';
    }
}
