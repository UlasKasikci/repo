<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — girdi doğrulama kuralları (birim test edilebilir).
 */

final class Validator
{
    /**
     * İletişim formu doğrulaması. Hata anahtarları alan adlarına eşlenir.
     *
     * @param array<string, mixed> $input
     *
     * @return array<string, string>
     */
    public static function contact(array $input): array
    {
        $errors = [];

        $name = self::text($input, 'name');
        if ($name === '') {
            $errors['name'] = 'Ad Soyad alanı zorunludur.';
        } elseif (mb_strlen($name) > 120) {
            $errors['name'] = 'Ad Soyad en fazla 120 karakter olabilir.';
        }

        $email = self::text($input, 'email');
        if ($email === '') {
            $errors['email'] = 'E-posta alanı zorunludur.';
        } elseif (mb_strlen($email) > 190) {
            $errors['email'] = 'E-posta en fazla 190 karakter olabilir.';
        } elseif (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            $errors['email'] = 'Geçerli bir e-posta adresi giriniz.';
        }

        $phone = self::text($input, 'phone');
        if ($phone !== '' && preg_match('/^[0-9+()\-\s]{7,32}$/', $phone) !== 1) {
            $errors['phone'] = 'Telefon 7-32 karakter olmalı ve yalnızca rakam, +, -, (, ), boşluk içerebilir.';
        }

        $subject = self::text($input, 'subject');
        if ($subject === '') {
            $errors['subject'] = 'Konu alanı zorunludur.';
        } elseif (mb_strlen($subject) > 190) {
            $errors['subject'] = 'Konu en fazla 190 karakter olabilir.';
        }

        $body = self::text($input, 'body');
        if ($body === '') {
            $errors['body'] = 'Mesaj alanı zorunludur.';
        } elseif (mb_strlen($body) < 10) {
            $errors['body'] = 'Mesaj en az 10 karakter olmalıdır.';
        } elseif (mb_strlen($body) > 5000) {
            $errors['body'] = 'Mesaj en fazla 5000 karakter olabilir.';
        }

        $consent = $input['kvkk_consent'] ?? null;
        if ($consent !== '1' && $consent !== 1 && $consent !== true) {
            $errors['kvkk_consent'] = 'Devam etmek için aydınlatma metnini onaylamanız gerekir.';
        }

        return $errors;
    }

    /**
     * Giriş dizisinden temizlenmiş metin okur.
     */
    /**
     * Giriş dizisinden temizlenmiş metin okur.
     *
     * @param array<string, mixed> $input
     */
    private static function text(array $input, string $key): string
    {
        $value = $input[$key] ?? null;
        if (!is_string($value)) {
            return '';
        }

        return trim($value);
    }
}
