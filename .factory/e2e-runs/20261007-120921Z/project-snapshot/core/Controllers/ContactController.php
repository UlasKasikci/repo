<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Notifier;
use App\Core\Validator;
use App\Core\View;

/**
 * GET /iletisim — iletişim formu · POST /iletisim — form gönderimi.
 *
 * Kurallar (P1 edge case, dondurulmuş):
 *  - Doğrulama Validator::contact (ad/e-posta/konu/mesaj; 422 VALIDATION_FAILED).
 *  - Honeypot ("website") doluysa bot isteği sessizce yutulur.
 *  - Rate limit: aynı IP'den dakikada 3 mesaj üstü → 429.
 *  - Mesaj messages tablosuna PDO prepared statement ile yazılır (status=new).
 *  - Bildirim: yeni mesajda yöneticiye e-posta (başarısızlık akışı bloklamaz).
 */
final class ContactController
{
    private const RATE_LIMIT_PER_MINUTE = 3;

    public function show(): void
    {
        $this->renderForm();
    }

    public function submit(): void
    {
        $wantsJson = self::wantsJson();

        $result = Validator::contact($_POST);
        if ($result['errors'] !== []) {
            if ($wantsJson) {
                json_error(422, 'VALIDATION_FAILED', 'Form doğrulaması başarısız.', array_values($result['errors']));
            }
            $this->renderForm(422, $result['errors'], $result['data']);
        }

        // Honeypot: gizli "website" alanı doluysa bot — sessizce yutulur.
        $honeypot = $_POST['website'] ?? '';
        if (is_scalar($honeypot) && trim((string) $honeypot) !== '') {
            set_flash('success', 'Mesajınız başarıyla alındı. En kısa sürede dönüş yapılacaktır.');
            redirect('/iletisim');
        }

        $data = $result['data'];
        $ip = client_ip();

        $count = Database::one(
            'SELECT COUNT(*) AS total FROM messages'
            . ' WHERE ip_address = :ip AND created_at > (NOW() - INTERVAL 1 MINUTE)',
            [':ip' => $ip]
        );
        if ($count !== null && (int) ($count['total'] ?? 0) >= self::RATE_LIMIT_PER_MINUTE) {
            $message = 'Çok fazla mesaj gönderildi. Lütfen bir dakika sonra tekrar deneyin.';
            if ($wantsJson) {
                json_error(429, 'RATE_LIMITED', $message);
            }
            http_response_code(429);
            View::render('errors/429', [
                'title' => '429',
                'description' => $message,
                'active' => 'contact',
                'code' => 'RATE_LIMITED',
                'message' => $message,
            ]);
        }

        $userAgent = (string) ($_SERVER['HTTP_USER_AGENT'] ?? '');

        Database::run(
            'INSERT INTO messages (user_id, name, email, subject, body, ip_address, user_agent, status)'
            . ' VALUES (:user_id, :name, :email, :subject, :body, :ip, :user_agent, :status)',
            [
                ':user_id' => Auth::check() ? Auth::userId() : null,
                ':name' => $data['name'],
                ':email' => $data['email'],
                ':subject' => $data['subject'],
                ':body' => $data['message'],
                ':ip' => $ip,
                ':user_agent' => $userAgent === '' ? null : mb_substr($userAgent, 0, 255),
                ':status' => 'new',
            ]
        );

        Notifier::newMessage([
            'name' => $data['name'],
            'email' => $data['email'],
            'subject' => $data['subject'],
            'body' => $data['message'],
        ]);

        set_flash('success', 'Mesajınız başarıyla alındı. En kısa sürede dönüş yapılacaktır.');
        redirect('/iletisim');
    }

    /**
     * @param array<string, string> $errors
     * @param array<string, string> $old
     */
    private function renderForm(int $status = 200, array $errors = [], array $old = []): void
    {
        http_response_code($status);
        View::render('contact', [
            'title' => 'İletişim — E2E İletişim',
            'description' => 'Bize soru, öneri veya iş birliği talebinizi iletin; ekibimiz en kısa sürede yanıtlar.',
            'active' => 'contact',
            'errors' => $errors,
            'old' => $old,
            'flash' => flash(),
        ]);
    }

    private static function wantsJson(): bool
    {
        $accept = (string) ($_SERVER['HTTP_ACCEPT'] ?? '');
        $requested = (string) ($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '');
        return str_contains($accept, 'application/json') || $requested === 'XMLHttpRequest';
    }
}
