<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use Throwable;

/**
 * RESTful JSON API uç noktaları.
 *
 * GET  /api/mesajlar   — mesaj listesi (yalnız Admin/Moderator; App::run RBAC).
 * POST /api/cerez-riza — çerez açık rıza kaydı (user_consents tablosu).
 *
 * Güvenlik: tüm sorgular PDO prepared statement; CSRF doğrulaması App::run
 * içinde merkezi olarak yapılır (POST alanı veya X-CSRF-Token başlığı,
 * hash_equals ile karşılaştırılır). Hata yanıtları standart zarfı kullanır;
 * iç detay (stack/SQL) istemciye sızdırılmaz.
 */
final class ApiController
{
    /**
     * Rıza türleri: çerez onay banner'ı (analitik) + KVKK aydınlatma onayı.
     *
     * @var list<string>
     */
    private const CONSENT_TYPES = ['cookie_analytics', 'kvkk_aydinlatma'];

    /**
     * Rıza metni sürümü: yasal metin güncellendiğinde artırılır; rıza
     * hangi metin sürümüne verildiğini izler (KVKK m.5/1 ispat yükü).
     */
    private const CONSENT_TEXT_VERSION = '1.0.0';

    /**
     * GET /api/mesajlar — mesaj listesi (N+1 yasağı: roller tek JOIN ile).
     */
    public function messages(): void
    {
        $messages = Database::all(
            'SELECT m.id, m.name, m.email, m.subject, m.body, m.status, m.created_at,'
            . ' u.name AS user_name'
            . ' FROM messages AS m'
            . ' LEFT JOIN users AS u ON u.id = m.user_id'
            . ' ORDER BY m.created_at DESC, m.id DESC LIMIT 50'
        );

        json_success(200, [
            'messages' => $messages,
            'count' => count($messages),
        ]);
    }

    /**
     * POST /api/cerez-riza — çerez onay banner'ının açık rıza/red tercihi.
     *
     * Beklenen gövde (JSON veya form):
     *   { "consent_type": "cookie_analytics|kvkk_aydinlatma", "granted": true|false }
     *
     * Rıza user_consents tablosuna user_id (varsa), e-posta, amaç metni,
     * metin sürümü ve IP ile kaydedilir (KVKK izi).
     */
    public function cookieConsent(): void
    {
        $payload = self::requestPayload();

        $consentType = $payload['consent_type'] ?? null;
        $granted = $payload['granted'] ?? null;

        if (!is_string($consentType) || !in_array($consentType, self::CONSENT_TYPES, true) || !is_bool($granted)) {
            // json_error() never döner (exit) — geçersiz istek burada sonlanır.
            json_error(
                422,
                'VALIDATION_FAILED',
                'Geçersiz rıza isteği: consent_type ve granted alanları zorunlu ve geçerli olmalıdır.'
            );
        }

        $loggedIn = Auth::check();
        $email = null;
        if ($loggedIn) {
            $sessionEmail = $_SESSION['user_email'] ?? null;
            $email = is_string($sessionEmail) && $sessionEmail !== '' ? $sessionEmail : null;
        }

        try {
            Database::run(
                'INSERT INTO user_consents'
                . ' (user_id, email, purpose, consent_type, consent_text_version, granted, ip_address)'
                . ' VALUES (:user_id, :email, :purpose, :consent_type, :consent_text_version, :granted, :ip)',
                [
                    ':user_id' => $loggedIn ? Auth::userId() : null,
                    ':email' => $email,
                    ':purpose' => self::purposeText($consentType),
                    ':consent_type' => $consentType,
                    ':consent_text_version' => self::CONSENT_TEXT_VERSION,
                    ':granted' => $granted ? 1 : 0,
                    ':ip' => client_ip(),
                ]
            );
        } catch (Throwable $exception) {
            error_log('[ApiController] Rıza kaydı yazılamadı: ' . $exception->getMessage());
            json_error(500, 'INTERNAL_ERROR', 'Rıza kaydı şu anda oluşturulamadı. Lütfen tekrar deneyin.');
        }

        $id = (int) Database::connection()->lastInsertId();

        json_success(201, [
            'id' => $id,
            'consent_type' => $consentType,
            'granted' => $granted,
            'consent_text_version' => self::CONSENT_TEXT_VERSION,
        ]);
    }

    /**
     * Rıza türünün amaç metni (user_consents.purpose — KVKK izi).
     */
    private static function purposeText(string $consentType): string
    {
        if ($consentType === 'cookie_analytics') {
            return 'Analitik çerezlerin yüklenmesine ilişkin açık rıza (KVKK m.5/1, GDPR Art. 6/1-a)';
        }
        return 'KVKK aydınlatma metninin okunduğu ve kişisel verilerin işlenmesine onay verildiği kaydı';
    }

    /**
     * İstek gövdesini okur: önce JSON (fetch API), yoksa form POST verisi.
     *
     * @return array<string, mixed>
     */
    private static function requestPayload(): array
    {
        $raw = file_get_contents('php://input');
        if (is_string($raw) && $raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                /** @var array<string, mixed> $decoded */
                return $decoded;
            }
        }
        return $_POST;
    }
}
