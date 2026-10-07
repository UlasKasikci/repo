<?php

declare(strict_types=1);

namespace App;

/**
 * Girdi doğrulama — UTF-8 temizleme, alan uzunluk sınırları, e-posta formatı,
 * KVKK rıza zorunluluğu. Hata listesi VALIDATION_FAILED/422 şemasıyla döner.
 */
final class Validator
{
    /**
     * @param array<string, mixed> $data
     * @return list<string>
     */
    public static function validateContact(array $data): array
    {
        $errors = [];

        $fullName = self::text($data['full_name'] ?? null);
        $email = self::text($data['email'] ?? null);
        $phone = self::text($data['phone'] ?? null);
        $subject = self::text($data['subject'] ?? null);
        $body = self::text($data['body'] ?? null);

        if (mb_strlen($fullName) < 2 || mb_strlen($fullName) > 120) {
            $errors[] = 'Ad soyad 2-120 karakter arasında olmalıdır.';
        }

        if (!self::email($email)) {
            $errors[] = 'Geçerli bir e-posta adresi giriniz.';
        }

        if ($phone !== '' && (mb_strlen($phone) > 32 || preg_match('/^[0-9+()\s-]{5,32}$/', $phone) !== 1)) {
            $errors[] = 'Telefon en fazla 32 karakter olmalı ve yalnızca rakam, +, -, (, ), boşluk içerebilir.';
        }

        if (mb_strlen($subject) < 3 || mb_strlen($subject) > 150) {
            $errors[] = 'Konu 3-150 karakter arasında olmalıdır.';
        }

        if (mb_strlen($body) < 10 || mb_strlen($body) > 5000) {
            $errors[] = 'Mesaj 10-5000 karakter arasında olmalıdır.';
        }

        if (self::text($data['consent'] ?? null) === '') {
            $errors[] = 'KVKK aydınlatma metnini onaylamanız gerekir.';
        }

        return $errors;
    }

    public static function email(string $value): bool
    {
        return filter_var($value, FILTER_VALIDATE_EMAIL) !== false && mb_strlen($value) <= 190;
    }

    /** Girdiyi UTF-8 güvenli metne indirger; yoksa boş döner. */
    public static function text(mixed $value): string
    {
        if (is_string($value)) {
            return trim($value);
        }

        if (is_int($value) || is_float($value)) {
            return trim((string) $value);
        }

        return '';
    }
}
