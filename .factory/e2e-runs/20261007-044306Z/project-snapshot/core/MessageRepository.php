<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — messages tablosu erişim katmanı.
 *
 * Tüm sorgular PDO prepared statement; N+1 yok (tek sorgu, listeleme sınırlı).
 */

final class MessageRepository
{
    /**
     * Yeni iletişim mesajı kaydeder; yeni kaydın kimliğini döner.
     *
     * @param array<string, mixed> $row
     */
    public static function create(array $row): int
    {
        $stmt = Database::get()->prepare(
            'INSERT INTO messages (name, email, phone, subject, body, ip_hash, status)
             VALUES (:name, :email, :phone, :subject, :body, :ip_hash, :status)'
        );

        $phone = $row['phone'] ?? null;
        $ipHash = $row['ip_hash'] ?? null;

        $executed = $stmt->execute([
            'name' => (string) ($row['name'] ?? ''),
            'email' => (string) ($row['email'] ?? ''),
            'phone' => is_string($phone) && $phone !== '' ? $phone : null,
            'subject' => (string) ($row['subject'] ?? ''),
            'body' => (string) ($row['body'] ?? ''),
            'ip_hash' => is_string($ipHash) && $ipHash !== '' ? $ipHash : null,
            'status' => 'new',
        ]);

        if ($executed === false) {
            throw new RuntimeException('Mesaj kaydı yazılamadı.');
        }

        return (int) Database::get()->lastInsertId();
    }

    /**
     * En yeni mesajları listeler (satır sınırlı tek sorgu).
     *
     * @return list<array<string, mixed>>
     */
    public static function recent(int $limit = 200): array
    {
        $limit = max(1, min(500, $limit));

        $stmt = Database::get()->prepare(
            'SELECT id, name, email, phone, subject, body, status, created_at
             FROM messages
             ORDER BY created_at DESC, id DESC
             LIMIT :limit'
        );
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $executed = $stmt->execute();
        if ($executed === false) {
            return [];
        }

        /** @var list<array<string, mixed>> $rows */
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $rows;
    }

    /**
     * Mesaj durumunu günceller.
     */
    public static function updateStatus(int $id, string $status): bool
    {
        if (!in_array($status, ['new', 'read', 'replied'], true)) {
            return false;
        }

        $stmt = Database::get()->prepare(
            'UPDATE messages SET status = :status WHERE id = :id'
        );

        return $stmt->execute([
            'status' => $status,
            'id' => $id,
        ]);
    }
}
