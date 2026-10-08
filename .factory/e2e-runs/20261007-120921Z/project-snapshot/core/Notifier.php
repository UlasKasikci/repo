<?php

declare(strict_types=1);

namespace App\Core;

/**
 * Bildirim modülü (P1 önerisi — onay: "reddedilmedikçe P2'de eklenir").
 *
 * Yeni iletişim mesajı geldiğinde yöneticiye e-posta bildirimi gönderir.
 * Bildirim başarısızlığı akışı bloklamaz; yalnız error_log'a yazılır.
 * Hedef adres AF_NOTIFIER_EMAIL ortam değişkeniyle yapılandırılır.
 */
final class Notifier
{
    private const DEFAULT_EMAIL = 'admin@example.com';

    /**
     * @param array<string, mixed> $message (name, email, subject, body)
     */
    public static function newMessage(array $message): bool
    {
        $to = self::env('AF_NOTIFIER_EMAIL', self::DEFAULT_EMAIL);
        $subject = 'Yeni iletişim mesajı: ' . (string) ($message['subject'] ?? '(konu yok)');
        $body = implode("\r\n", [
            'Yeni bir iletişim mesajı alındı.',
            '',
            'Ad: ' . (string) ($message['name'] ?? ''),
            'E-posta: ' . (string) ($message['email'] ?? ''),
            'Konu: ' . (string) ($message['subject'] ?? ''),
            '',
            (string) ($message['body'] ?? ''),
        ]);
        $headers = implode("\r\n", [
            'From: no-reply@example.com',
            'Content-Type: text/plain; charset=UTF-8',
            'X-Mailer: App-Fabrika-Web-Edition',
        ]);

        $sent = @mail($to, $subject, $body, $headers);
        if (!$sent) {
            error_log('[Notifier] Yeni mesaj bildirimi gönderilemedi: ' . $to);
        }
        return $sent;
    }

    private static function env(string $key, string $default): string
    {
        $value = getenv($key);
        return is_string($value) && $value !== '' ? $value : $default;
    }
}
