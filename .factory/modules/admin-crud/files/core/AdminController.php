<?php
declare(strict_types=1);

final class AdminController
{
    public static function index(PDO $db): void
    {
        Auth::requireRole(1, 2);
        $stmt = $db->query('SELECT id, email, role_id, created_at FROM users ORDER BY id DESC LIMIT 100');
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        require __DIR__ . '/../views/admin/users.php';
    }

    public static function createPost(PDO $db): void
    {
        guardPost();
        Auth::requireRole(1);
        $email = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');
        $roleId = (int) ($_POST['role_id'] ?? 3);
        if ($email === '' || strlen($password) < 8) {
            http_response_code(422);
            exit('Invalid input');
        }
        $hash = password_hash($password, PASSWORD_ARGON2ID);
        $stmt = $db->prepare('INSERT INTO users (role_id, email, password_hash) VALUES (?, ?, ?)');
        $stmt->execute([$roleId, $email, $hash]);
        header('Location: /admin/users');
        exit;
    }
}
