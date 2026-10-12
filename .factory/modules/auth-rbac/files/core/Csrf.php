<?php
declare(strict_types=1);

final class Csrf
{
    public static function token(): string
    {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return (string) $_SESSION['csrf_token'];
    }

    public static function verify(string $token): bool
    {
        return hash_equals((string) ($_SESSION['csrf_token'] ?? ''), $token);
    }

    public static function requireValid(): void
    {
        $token = (string) ($_POST['csrf_token'] ?? '');
        if (!self::verify($token)) {
            http_response_code(403);
            exit('CSRF validation failed');
        }
    }
}

function guardPost(): void
{
    Csrf::requireValid();
}
