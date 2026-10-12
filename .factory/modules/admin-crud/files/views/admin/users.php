<?php declare(strict_types=1); ?>
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <title>Admin · Kullanıcılar</title>
</head>
<body>
  <h1>Kullanıcılar</h1>
  <table>
    <thead><tr><th>ID</th><th>E-posta</th><th>Rol</th></tr></thead>
    <tbody>
    <?php foreach (($rows ?? []) as $r): ?>
      <tr>
        <td><?= (int) $r['id'] ?></td>
        <td><?= htmlspecialchars((string) $r['email'], ENT_QUOTES, 'UTF-8') ?></td>
        <td><?= (int) $r['role_id'] ?></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
  <h2>Yeni kullanıcı</h2>
  <form method="post" action="/admin/users">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(Csrf::token(), ENT_QUOTES, 'UTF-8') ?>">
    <input type="email" name="email" required>
    <input type="password" name="password" required minlength="8">
    <input type="number" name="role_id" value="3" min="1" max="3">
    <button type="submit">Ekle</button>
  </form>
</body>
</html>
