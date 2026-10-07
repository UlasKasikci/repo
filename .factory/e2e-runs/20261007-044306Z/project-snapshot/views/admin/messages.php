<?php

/**
 * App-Fabrika Web Edition — yönetim: iletişim mesajları (Admin + Moderatör).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

$flash = arr($data['flash'] ?? null);
$messages = arr($data['messages'] ?? null);
$ok = $flash['ok'] ?? null;

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>Mesajlar</h1>
    <p>İletişim formundan gelen talepler — toplam <?= e(count($messages)) ?> kayıt listeleniyor.</p>
  </div>
</section>

<section class="admin">
  <div class="container">
    <?php if (is_string($ok) && $ok !== '') : ?>
    <p class="alert alert--success" role="status"><?= e($ok) ?></p>
    <?php endif; ?>

    <?php if ($messages === []) : ?>
    <p class="empty-state">Henüz mesaj bulunmuyor.</p>
    <?php else : ?>
    <div class="table-wrap" role="region" aria-label="Mesaj listesi" tabindex="0">
      <table class="data-table">
        <caption class="visually-hidden">İletişim formundan gelen mesajlar</caption>
        <thead>
          <tr>
            <th scope="col">#</th>
            <th scope="col">Ad Soyad</th>
            <th scope="col">E-posta</th>
            <th scope="col">Konu</th>
            <th scope="col">Mesaj</th>
            <th scope="col">Durum</th>
            <th scope="col">Tarih</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($messages as $m) : ?>
          <?php
              $row = arr($m);
              $status = (string) ($row['status'] ?? '');
          ?>
          <tr>
            <td><?= e($row['id'] ?? '') ?></td>
            <td><?= e($row['name'] ?? '') ?></td>
            <td><?= e($row['email'] ?? '') ?></td>
            <td><?= e($row['subject'] ?? '') ?></td>
            <td class="cell-body"><?= e(mb_substr((string) ($row['body'] ?? ''), 0, 140)) ?></td>
            <td>
              <form class="status-form" method="post" action="<?= e(url('/admin/mesajlar/durum')) ?>">
                <?= Csrf::field() ?>
                <input type="hidden" name="id" value="<?= e($row['id'] ?? '') ?>">
                <label class="visually-hidden" for="status-<?= e($row['id'] ?? '') ?>">Durum</label>
                <select id="status-<?= e($row['id'] ?? '') ?>" name="status">
                  <option value="new"<?= $status === 'new' ? ' selected' : '' ?>>Yeni</option>
                  <option value="read"<?= $status === 'read' ? ' selected' : '' ?>>Okundu</option>
                  <option value="replied"<?= $status === 'replied' ? ' selected' : '' ?>>Yanıtlandı</option>
                </select>
                <button class="btn btn--small btn--primary" type="submit">Kaydet</button>
              </form>
            </td>
            <td><?= e($row['created_at'] ?? '') ?></td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
    <?php endif; ?>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
