<?php
declare(strict_types=1);

/**
 * Webrail Cart stub — siparisler / siparis_kalemleri (TR-ASCII).
 */
final class Cart
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    /** @return list<array<string, mixed>> */
    public function linesForUser(int $kullaniciId): array
    {
        $st = $this->pdo->prepare(
            'SELECT k.*, s.status, s.total AS order_total
             FROM siparis_kalemleri k
             INNER JOIN siparisler s ON s.id = k.siparis_id
             WHERE s.kullanici_id = ? AND s.status = ?
             ORDER BY k.id ASC'
        );
        $st->execute([$kullaniciId, 'cart']);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        return $rows === false ? [] : $rows;
    }

    public function createPendingOrder(int $kullaniciId, float $total, string $currency = 'TRY'): int
    {
        $st = $this->pdo->prepare(
            'INSERT INTO siparisler (kullanici_id, status, total, currency) VALUES (?, ?, ?, ?)'
        );
        $st->execute([$kullaniciId, 'pending', $total, $currency]);
        return (int) $this->pdo->lastInsertId();
    }

    public function addItem(int $siparisId, int $urunId, int $qty, float $unitPrice): void
    {
        $st = $this->pdo->prepare(
            'INSERT INTO siparis_kalemleri (siparis_id, urun_id, quantity, unit_price) VALUES (?, ?, ?, ?)'
        );
        $st->execute([$siparisId, $urunId, $qty, $unitPrice]);
    }
}
