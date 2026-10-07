<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — global yardımcı fonksiyonlar.
 *
 * Tüm çıktılar htmlspecialchars üzerinden kaçırılır (XSS koruması).
 */

if (!function_exists('e')) {
    /**
     * HTML çıktısı için güvenli kaçış.
     */
    function e(mixed $value): string
    {
        $string = is_scalar($value) || $value === null ? (string) $value : '';

        return htmlspecialchars($string, ENT_QUOTES | ENT_SUBSTITUTE | ENT_HTML5, 'UTF-8');
    }
}

if (!function_exists('url')) {
    /**
     * BASE_URL (varsa) + yol birleştirir. BASE_URL tanımsızsa göreli yol döner.
     */
    function url(string $path = '/'): string
    {
        $base = defined('BASE_URL') ? (string) BASE_URL : '';
        if ($path === '' || $path[0] !== '/') {
            $path = '/' . $path;
        }

        return $base . $path;
    }
}

if (!function_exists('arr')) {
    /**
     * Görünüm şablonlarında tip güvenli dizi erişimi: dizi değilse boş dizi döner.
     *
     * @return array<array-key, mixed>
     */
    function arr(mixed $value): array
    {
        return is_array($value) ? $value : [];
    }
}
