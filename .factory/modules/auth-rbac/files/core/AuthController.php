<?php
declare(strict_types=1);

final class AuthController
{
    public static function loginPost(PDO $db): void
    {
        guardPost();
        $email = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');
        if ($email === '' || $password === '' || !Auth::attempt($db, $email, $password)) {
            http_response_code(401);
            exit('Login failed');
        }
        header('Location: /');
        exit;
    }

    public static function registerPost(PDO $db): void
    {
        guardPost();
        $email = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');
        if ($email === '' || strlen($password) < 8) {
            http_response_code(422);
            exit('Invalid input');
        }
        $hash = password_hash($password, PASSWORD_ARGON2ID);
        $stmt = $db->prepare('INSERT INTO users (role_id, email, password_hash) VALUES (3, ?, ?)');
        $stmt->execute([$email, $hash]);
        header('Location: /login');
        exit;
    }
}
