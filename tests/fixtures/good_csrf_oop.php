<?php
declare(strict_types=1);

// v1.2 F2 pozitif fixture: OOP CSRF deseni — gate PASS vermeli.
// helpdesk-app run'ında gate bu deseni kaçırıyordu (CSRF_CALL_RE OOP-blind).
final class Csrf
{
    public static function verify(string $token): bool
    {
        return hash_equals((string) ($_SESSION['csrf_token'] ?? ''), $token);
    }

    public static function requireValid(): void
    {
        if (!self::verify((string) ($_POST['csrf_token'] ?? ''))) {
            http_response_code(403);
            exit;
        }
    }
}

// $_POST kullanılıyor; Csrf::verify( / Csrf::requireValid( çağrısı dosyada MEVCUT.
Csrf::requireValid();
$value = (string) ($_POST['title'] ?? '');
echo htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
