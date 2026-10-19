<?php
declare(strict_types=1);

/**
 * Webrail Payment stub — odemeler tablosu (TR-ASCII).
 * Gerçek PSP (iyzico/PayTR/Stripe) P2'de bağlanır.
 */
final class Payment
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    /** @return array<string, mixed>|null */
    public function find(int $id): ?array
    {
        $st = $this->pdo->prepare('SELECT * FROM odemeler WHERE id = ? LIMIT 1');
        $st->execute([$id]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function recordPending(int $siparisId, float $amount, string $currency = 'TRY'): int
    {
        $st = $this->pdo->prepare(
            'INSERT INTO odemeler (siparis_id, provider, amount, currency, status) VALUES (?, ?, ?, ?, ?)'
        );
        $st->execute([$siparisId, 'manual', $amount, $currency, 'pending']);
        return (int) $this->pdo->lastInsertId();
    }
}
