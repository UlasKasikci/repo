<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — iletişim formu denetleyicisi.
 *
 * POST akışı: CSRF doğrulaması → doğrulama → mesaj kaydı (PDO prepared)
 * → açık rıza kaydı (user_consents) → flash ile yönlendirme.
 */

final class ContactController extends Controller
{
    private const CONSENT_PURPOSE = 'contact_form';

    public function form(): void
    {
        $this->view('contact', [
            'pageTitle' => 'İletişim · App-Fabrika',
            'pageDesc' => 'Bize yazın — talebinizi en kısa sürede değerlendirip dönüş yapalım.',
            'flash' => Flash::take(),
        ]);
    }

    public function submit(): void
    {
        $this->requireCsrf();

        $input = [
            'name' => $_POST['name'] ?? null,
            'email' => $_POST['email'] ?? null,
            'phone' => $_POST['phone'] ?? null,
            'subject' => $_POST['subject'] ?? null,
            'body' => $_POST['body'] ?? null,
            'kvkk_consent' => $_POST['kvkk_consent'] ?? null,
        ];

        $errors = Validator::contact($input);
        if ($errors !== []) {
            Flash::set([
                'errors' => $errors,
                'old' => [
                    'name' => self::text($input, 'name'),
                    'email' => self::text($input, 'email'),
                    'phone' => self::text($input, 'phone'),
                    'subject' => self::text($input, 'subject'),
                    'body' => self::text($input, 'body'),
                ],
            ]);
            $this->redirect('/iletisim');
        }

        $ipHash = self::ipHash();
        $email = self::text($input, 'email');

        MessageRepository::create([
            'name' => self::text($input, 'name'),
            'email' => $email,
            'phone' => self::text($input, 'phone'),
            'subject' => self::text($input, 'subject'),
            'body' => self::text($input, 'body'),
            'ip_hash' => $ipHash,
        ]);

        ConsentRepository::record($email, self::CONSENT_PURPOSE, $ipHash);

        Flash::set([
            'ok' => 'Mesajınız alındı. En kısa sürede dönüş yapacağız.',
        ]);
        $this->redirect('/iletisim');
    }

    /**
     * Giriş dizisinden temizlenmiş metin okur.
     *
     * @param array<string, mixed> $input
     */
    private static function text(array $input, string $key): string
    {
        $value = $input[$key] ?? null;

        return is_string($value) ? trim($value) : '';
    }

    /**
     * İstemci IP'sini anahtar türevli özetle saklar (KVKK veri minimizasyonu).
     */
    private static function ipHash(): ?string
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '';
        if (!is_string($ip) || $ip === '') {
            return null;
        }

        return hash('sha256', $ip . '|appfabrika-contact');
    }
}
