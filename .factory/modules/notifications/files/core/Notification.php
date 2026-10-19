<?php
declare(strict_types=1);

/** Webrail Notification stub — bildirimler (TR-ASCII). */
final class Notification
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function push(int $kullaniciId, string $title, ?string $body = null): int
    {
        $st = $this->pdo->prepare(
            'INSERT INTO bildirimler (kullanici_id, title, body, okundu) VALUES (?, ?, ?, 0)'
        );
        $st->execute([$kullaniciId, $title, $body]);
        return (int) $this->pdo->lastInsertId();
    }

    /** @return list<array<string, mixed>> */
    public function unreadFor(int $kullaniciId, int $limit = 20): array
    {
        $st = $this->pdo->prepare(
            'SELECT * FROM bildirimler WHERE kullanici_id = ? AND okundu = 0 ORDER BY id DESC LIMIT ?'
        );
        $st->bindValue(1, $kullaniciId, PDO::PARAM_INT);
        $st->bindValue(2, $limit, PDO::PARAM_INT);
        $st->execute();
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        return $rows === false ? [] : $rows;
    }
}
