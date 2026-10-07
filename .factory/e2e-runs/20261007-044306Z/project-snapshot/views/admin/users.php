<?php

/**
 * App-Fabrika Web Edition — yönetim: kullanıcılar (yalnız Admin, RBAC).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

$users = arr($data['users'] ?? null);

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>Kullanıcılar</h1>
    <p>Kayıtlı kullanıcılar ve rolleri — toplam <?= e(count($users)) ?> kayıt.</p>
  </div>
</section>

<section class="admin">
  <div class="container">
    <div class="table-wrap" role="region" aria-label="Kullanıcı listesi" tabindex="0">
      <table class="data-table">
        <caption class="visually-hidden">Kayıtlı kullanıcılar ve rolleri</caption>
        <thead>
          <tr>
            <th scope="col">#</th>
            <th scope="col">Ad Soyad</th>
            <th scope="col">E-posta</th>
            <th scope="col">Rol</th>
            <th scope="col">Durum</th>
            <th scope="col">Kayıt Tarihi</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($users as $u) : ?>
          <?php
              $row = arr($u);
              $active = (int) ($row['is_active'] ?? 0) === 1;
          ?>
          <tr>
            <td><?= e($row['id'] ?? '') ?></td>
            <td><?= e($row['name'] ?? '') ?></td>
            <td><?= e($row['email'] ?? '') ?></td>
            <td><?= e($row['role_name'] ?? '') ?></td>
            <td><?= $active ? 'Aktif' : 'Devre dışı' ?></td>
            <td><?= e($row['created_at'] ?? '') ?></td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
