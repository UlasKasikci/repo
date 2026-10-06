<?php /** @var array<int, array<string, mixed>> $users */ ?>
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="App-Fabrika Web Edition örnek proje">
  <title>App-Fabrika Web Edition — Örnek</title>
  <link rel="stylesheet" href="assets/css/app.css">
</head>
<body>
  <main>
    <h1>App-Fabrika Web Edition — Örnek</h1>

    <form method="post" action="">
      <input type="hidden" name="csrf_token" value="<?= htmlspecialchars((string)($_SESSION['csrf_token'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
      <label for="email">E-posta</label>
      <input id="email" type="email" name="email" required>
      <button type="submit">Gönder</button>
    </form>

    <h2>Kayıtlı kullanıcılar</h2>
    <ul>
      <?php foreach ($users as $user): ?>
        <li><?= htmlspecialchars((string)$user['email'], ENT_QUOTES, 'UTF-8') ?></li>
      <?php endforeach; ?>
    </ul>
  </main>
  <script src="assets/js/app.js"></script>
</body>
</html>
