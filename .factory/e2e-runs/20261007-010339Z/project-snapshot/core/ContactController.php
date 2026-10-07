<?php

declare(strict_types=1);

namespace App;

/**
 * İletişim formu denetleyicisi — POST → messages (PDO prepared statement).
 * Honeypot + IP hash başına saatte 5 gönderim limiti (spam koruması),
 * rıza kaydı (consent_given/consent_at), VALIDATION_FAILED/422 şeması.
 */
final class ContactController
{
    private const RATE_LIMIT = 5;
    private const IP_HASH_SALT_FALLBACK = 'fabrika-web-edition-secret';

    public function show(): void
    {
        echo View::render('contact', [
            'title' => 'İletişim — E2E İletişim',
            'description' => 'Bize ulaşın: KVKK uyumlu iletişim formu. Verileriniz yalnızca talebinize yanıt vermek amacıyla işlenir.',
            'errors' => [],
            'old' => self::emptyOld(),
            'sent' => false,
        ]);
    }

    public function submit(): void
    {
        $post = $_POST;
        $token = Validator::text($post['csrf_token'] ?? null);

        if (!CSRF::validate($token !== '' ? $token : null)) {
            App::fail('CSRF_FAILED', 'Form güvenlik anahtarı geçersiz veya süresi doldu. Sayfayı yenileyin.', 403);

            return;
        }

        // Honeypot: gizli "website" alanı doluysa bot — sessizce kabul edilmiş gibi davran
        if (Validator::text($post['website'] ?? null) !== '') {
            Response::redirect('/iletisim?sent=1');

            return;
        }

        $errors = Validator::validateContact($post);
        $old = [
            'full_name' => Validator::text($post['full_name'] ?? null),
            'email' => Validator::text($post['email'] ?? null),
            'phone' => Validator::text($post['phone'] ?? null),
            'subject' => Validator::text($post['subject'] ?? null),
            'body' => Validator::text($post['body'] ?? null),
        ];

        if ($errors !== []) {
            if (App::wantsJson()) {
                Response::error('VALIDATION_FAILED', 'Form alanlarını kontrol edin.', 422, $errors);

                return;
            }
            http_response_code(422);
            echo View::render('contact', [
                'title' => 'İletişim — E2E İletişim',
                'description' => 'Bize ulaşın: KVKK uyumlu iletişim formu.',
                'errors' => $errors,
                'old' => $old,
                'sent' => false,
            ]);

            return;
        }

        $ipHash = self::ipHash();
        $recent = $ipHash === '' ? null : Database::fetchOne(
            'SELECT COUNT(*) AS total FROM messages WHERE ip_hash = ? AND created_at > (NOW() - INTERVAL 1 HOUR)',
            [$ipHash]
        );

        if ($recent !== null && (int) ($recent['total'] ?? 0) >= self::RATE_LIMIT) {
            App::fail('RATE_LIMITED', 'Çok fazla gönderim yaptınız. Lütfen bir saat sonra tekrar deneyin.', 429);

            return;
        }

        $consent = Validator::text($post['consent'] ?? null) !== '';

        Database::insert(
            'INSERT INTO messages (full_name, email, phone, subject, body, ip_hash, consent_given, consent_at)'
            . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
                $old['full_name'],
                $old['email'],
                $old['phone'] !== '' ? $old['phone'] : null,
                $old['subject'],
                $old['body'],
                $ipHash !== '' ? $ipHash : null,
                $consent ? 1 : 0,
                $consent ? date('Y-m-d H:i:s') : null,
            ]
        );

        if (App::wantsJson()) {
            Response::json([
                'success' => true,
                'data' => ['message' => 'Mesajınız alındı. En kısa sürede size dönüş yapılacaktır.'],
            ], 201);

            return;
        }

        Response::redirect('/iletisim?sent=1');
    }

    private static function ipHash(): string
    {
        $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
        if ($ip === '') {
            return '';
        }

        $secret = (string) (getenv('APP_SECRET') ?: self::IP_HASH_SALT_FALLBACK);

        return hash('sha256', $ip . '|' . $secret);
    }

    /** @return array<string, string> */
    private static function emptyOld(): array
    {
        return [
            'full_name' => '',
            'email' => '',
            'phone' => '',
            'subject' => '',
            'body' => '',
        ];
    }
}
