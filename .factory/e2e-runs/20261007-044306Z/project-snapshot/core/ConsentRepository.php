<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — user_consents (açık rıza) erişim katmanı.
 *
 * KVKK/GDPR açık rıza kayıtları: her rıza amacı, sürümü ve IP hash'i ile saklanır.
 */

final class ConsentRepository
{
    /**
     * Rıza kaydı yazar (iletişim formu onayı vb.).
     */
    public static function record(
        string $email,
        string $purpose,
        ?string $ipHash = null,
        string $version = '1.0'
    ): bool {
        $stmt = Database::get()->prepare(
            'INSERT INTO user_consents (email, purpose, consent_version, granted, ip_hash)
             VALUES (:email, :purpose, :consent_version, 1, :ip_hash)'
        );

        return $stmt->execute([
            'email' => $email,
            'purpose' => $purpose,
            'consent_version' => $version,
            'ip_hash' => $ipHash,
        ]);
    }

    /**
     * Bir rıza amacı için güncel rıza kaydını döner.
     *
     * @return array<string, mixed>|null
     */
    public static function latest(string $email, string $purpose): ?array
    {
        $stmt = Database::get()->prepare(
            'SELECT id, email, purpose, consent_version, granted, granted_at, revoked_at
             FROM user_consents
             WHERE email = :email AND purpose = :purpose
             ORDER BY granted_at DESC, id DESC
             LIMIT 1'
        );
        $executed = $stmt->execute(['email' => $email, 'purpose' => $purpose]);
        if ($executed === false) {
            return null;
        }

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) {
            return null;
        }

        /** @var array<string, mixed> $row */
        return $row;
    }
}
