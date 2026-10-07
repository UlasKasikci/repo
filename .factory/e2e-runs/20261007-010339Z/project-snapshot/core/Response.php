<?php

declare(strict_types=1);

namespace App;

/**
 * Yanıt yardımcıları — HTTP durum kodları (200/201/400/401/403/404/422/500),
 * JSON JSON + standart hata şeması, PRG redirect'leri.
 */
final class Response
{
    /** @param array<string, mixed> $payload */
    public static function json(array $payload, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=UTF-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    }

    /**
     * Standart hata şeması:
     * {"success":false,"error":{"code":"...","message":"...","details":[]}}
     *
     * @param list<string> $details
     */
    public static function error(string $code, string $message, int $status = 400, array $details = []): void
    {
        self::json([
            'success' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
                'details' => $details,
            ],
        ], $status);
    }

    public static function redirect(string $to, int $status = 302): void
    {
        http_response_code($status);
        header('Location: ' . $to);
    }
}
