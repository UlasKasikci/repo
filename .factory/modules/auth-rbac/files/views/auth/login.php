<?php declare(strict_types=1); ?>
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <title>Giriş</title>
</head>
<body>
  <h1>Giriş</h1>
  <form method="post" action="/login">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(Csrf::token(), ENT_QUOTES, 'UTF-8') ?>">
    <label>E-posta <input type="email" name="email" required></label>
    <label>Parola <input type="password" name="password" required></label>
    <button type="submit">Giriş</button>
  </form>
</body>
</html>
