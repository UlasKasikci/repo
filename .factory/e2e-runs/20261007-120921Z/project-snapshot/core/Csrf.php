<?php

declare(strict_types=1);

namespace App\Core;

/**
 * CSRF belirteç yönetimi.
 *
 * Oturum başına benzersiz 256-bit token; doğrulama hash_equals ile
 * sabit zamanlı karşılaştırma yapar. Tüm POST/PUT/PATCH/DELETE istekleri
 * App::run içinde bu sınıfla doğrulanır.
 */
final class Csrf
{
    private const TOKEN_KEY = 'csrf_token';

    public static function token(): string
    {
        $existing = $_SESSION[self::TOKEN_KEY] ?? null;
        if (is_string($existing) && $existing !== '') {
            return $existing;
        }
        $token = bin2hex(random_bytes(32));
        $_SESSION[self::TOKEN_KEY] = $token;
        return $token;
    }

    public static function validate(?string $token): bool
    {
        if ($token === null || $token === '') {
            return false;
        }
        $expected = $_SESSION[self::TOKEN_KEY] ?? null;
        if (!is_string($expected) || $expected === '') {
            return false;
        }
        return hash_equals($expected, $token);
    }

    /**
     * Formlara gömülen gizli input alanı.
     */
    public static function field(): string
    {
        return '<input type="hidden" name="csrf_token" value="' . e(self::token()) . '">';
    }

    /**
     * İstekten belirteci okur: önce POST alanı, sonra X-CSRF-Token başlığı
     * (fetch API ile gönderilen JSON istekleri için).
     */
    public static function requestToken(): ?string
    {
        $posted = $_POST['csrf_token'] ?? null;
        if (is_string($posted) && $posted !== '') {
            return $posted;
        }
        $header = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? null;
        return is_string($header) && $header !== '' ? $header : null;
    }
}
