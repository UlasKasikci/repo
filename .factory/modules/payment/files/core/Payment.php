<?php
declare(strict_types=1);

/**
 * Webrail Payment stub — ecommerce arketipi.
 * Gerçek PSP (iyzico/PayTR/Stripe) P2'de provider arayüzüne bağlanır.
 */
final class Payment
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    /** @return array<string, mixed>|null */
    public function find(int $id): ?array
    {
        $st = $this->pdo->prepare('SELECT * FROM payments WHERE id = ? LIMIT 1');
        $st->execute([$id]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    public function recordPending(int $orderId, float $amount, string $currency = 'TRY'): int
    {
        $st = $this->pdo->prepare(
            'INSERT INTO payments (order_id, provider, amount, currency, status) VALUES (?, ?, ?, ?, ?)'
        );
        $st->execute([$orderId, 'manual', $amount, $currency, 'pending']);
        return (int) $this->pdo->lastInsertId();
    }
}
