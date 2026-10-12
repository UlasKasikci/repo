<?php
declare(strict_types=1);

final class Auth
{
    public static function attempt(PDO $db, string $email, string $password): bool
    {
        $stmt = $db->prepare('SELECT id, role_id, password_hash FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || !password_verify($password, (string) $row['password_hash'])) {
            return false;
        }
        session_regenerate_id(true);
        $_SESSION['user_id'] = (int) $row['id'];
        $_SESSION['role_id'] = (int) $row['role_id'];
        return true;
    }

    public static function logout(): void
    {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'] ?? '', (bool) $p['secure'], (bool) $p['httponly']);
        }
        session_destroy();
    }

    public static function requireLogin(): void
    {
        if (empty($_SESSION['user_id'])) {
            header('Location: /login');
            exit;
        }
    }

    public static function requireRole(int ...$roleIds): void
    {
        self::requireLogin();
        $rid = (int) ($_SESSION['role_id'] ?? 0);
        if (!in_array($rid, $roleIds, true)) {
            http_response_code(403);
            exit('Forbidden');
        }
    }
}
