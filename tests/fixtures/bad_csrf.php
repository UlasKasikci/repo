<?php
declare(strict_types=1);

// Tur 2-16 negatif fixture (ChatGPT 2.1): $_POST kullanımı var ama CSRF token
// doğrulama ÇAGRISI yok. qa-gate security_policy bu dosyayı reddetmeli.
// (web-sample yerine ayrı dosya: web-sample PASS fixture'ıdır — bkz. FINDINGS.)
$username = (string)($_POST['username'] ?? '');
echo htmlspecialchars($username, ENT_QUOTES, 'UTF-8');
