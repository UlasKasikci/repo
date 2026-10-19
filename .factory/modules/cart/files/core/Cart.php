<?php
declare(strict_types=1);

/**
 * Webrail Cart stub — ecommerce / catalog_rfq.
 * Sepet oturumu + orders kaydı; ödeme Payment.php ile bağlanır.
 */
final class Cart
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    /** @return list<array<string, mixed>> */
    public function linesForUser(int $userId): array
    {
        $st = $this->pdo->prepare(
            'SELECT oi.*, o.status, o.total AS order_total
             FROM order_items oi
             INNER JOIN orders o ON o.id = oi.order_id
             WHERE o.user_id = ? AND o.status = ?
             ORDER BY oi.id ASC'
        );
        $st->execute([$userId, 'cart']);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        return $rows === false ? [] : $rows;
    }

    public function createPendingOrder(int $userId, float $total, string $currency = 'TRY'): int
    {
        $st = $this->pdo->prepare(
            'INSERT INTO orders (user_id, status, total, currency) VALUES (?, ?, ?, ?)'
        );
        $st->execute([$userId, 'pending', $total, $currency]);
        return (int) $this->pdo->lastInsertId();
    }

    public function addItem(int $orderId, int $productId, int $qty, float $unitPrice): void
    {
        $st = $this->pdo->prepare(
            'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)'
        );
        $st->execute([$orderId, $productId, $qty, $unitPrice]);
    }
}
