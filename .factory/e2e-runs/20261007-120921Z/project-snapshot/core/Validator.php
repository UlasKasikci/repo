<?php

declare(strict_types=1);

namespace App\Core;

/**
 * Sunucu tarafı doğrulama (saf, birim test edilebilir).
 *
 * İletişim formu kuralları (P1 edge case, dondurulmuş): ad/e-posta/konu/mesaj
 * zorunlu; e-posta FILTER_VALIDATE_EMAIL ile doğrulanır; alan uzunluk
 * sınırlarına tabidir. Geçersiz alanlar 422 VALIDATION_FAILED döner.
 */
final class Validator
{
    public const NAME_MAX = 100;
    public const EMAIL_MAX = 190;
    public const SUBJECT_MAX = 200;
    public const MESSAGE_MAX = 5000;

    /**
     * @param array<string, mixed> $input
     * @return array{errors: array<string, string>, data: array<string, string>}
     */
    public static function contact(array $input): array
    {
        $errors = [];
        $data = [];

        $name = self::text($input, 'name');
        if ($name === '') {
            $errors['name'] = 'Ad alanı zorunludur.';
        } elseif (mb_strlen($name) > self::NAME_MAX) {
            $errors['name'] = 'Ad en fazla ' . self::NAME_MAX . ' karakter olabilir.';
        }
        $data['name'] = $name;

        $email = mb_strtolower(self::text($input, 'email'));
        if ($email === '') {
            $errors['email'] = 'E-posta alanı zorunludur.';
        } elseif (mb_strlen($email) > self::EMAIL_MAX) {
            $errors['email'] = 'E-posta en fazla ' . self::EMAIL_MAX . ' karakter olabilir.';
        } elseif (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            $errors['email'] = 'Geçerli bir e-posta adresi girin.';
        }
        $data['email'] = $email;

        $subject = self::text($input, 'subject');
        if ($subject === '') {
            $errors['subject'] = 'Konu alanı zorunludur.';
        } elseif (mb_strlen($subject) > self::SUBJECT_MAX) {
            $errors['subject'] = 'Konu en fazla ' . self::SUBJECT_MAX . ' karakter olabilir.';
        }
        $data['subject'] = $subject;

        $message = self::text($input, 'message');
        if ($message === '') {
            $errors['message'] = 'Mesaj alanı zorunludur.';
        } elseif (mb_strlen($message) > self::MESSAGE_MAX) {
            $errors['message'] = 'Mesaj en fazla ' . self::MESSAGE_MAX . ' karakter olabilir.';
        }
        $data['message'] = $message;

        return ['errors' => $errors, 'data' => $data];
    }

    /**
     * @param array<string, mixed> $input
     */
    private static function text(array $input, string $key): string
    {
        $value = $input[$key] ?? '';
        return is_scalar($value) ? trim((string) $value) : '';
    }
}
