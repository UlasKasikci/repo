<?php
declare(strict_types=1);
/** @var list<array<string, mixed>> $reviews */
$reviews = $reviews ?? [];
?>
<section class="product-reviews" aria-label="Ürün yorumları">
  <h2>Yorumlar</h2>
  <?php if ($reviews === []): ?>
    <p>Henüz yorum yok.</p>
  <?php else: ?>
    <ul>
      <?php foreach ($reviews as $r): ?>
        <li>
          <strong><?= htmlspecialchars((string) ($r['rating'] ?? ''), ENT_QUOTES, 'UTF-8') ?>/5</strong>
          <?= htmlspecialchars((string) ($r['body'] ?? ''), ENT_QUOTES, 'UTF-8') ?>
        </li>
      <?php endforeach; ?>
    </ul>
  <?php endif; ?>
</section>
