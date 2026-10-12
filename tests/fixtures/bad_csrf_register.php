<?php
declare(strict_types=1);

// v1.2 F2 negatif fixture (gerçek helpdesk-app /register açığının birebir kopyası):
// POST handler $_POST okuyor, CSRF doğrulama ÇAĞRISI hiç yok. Gate REDDETmeli.
// helpdesk-app run'ında bu desen gate'ten KAÇMIŞTI (regex OOP-blind'dı).
$email = filter_var((string) ($_POST['email'] ?? ''), FILTER_VALIDATE_EMAIL);
$password = (string) ($_POST['password'] ?? '');
if ($email === false || $password === '') {
    http_response_code(422);
    exit;
}
// kayıt işlemi...
echo 'registered: ' . htmlspecialchars($email, ENT_QUOTES, 'UTF-8');
