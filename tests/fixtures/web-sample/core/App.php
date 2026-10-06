<?php
declare(strict_types=1);

final class App
{
    public function run(): void
    {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }

        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
            $this->verifyCsrf((string)($_POST['csrf_token'] ?? ''));
            $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
            if ($email === false || $email === null) {
                http_response_code(422);
                exit('Geçersiz e-posta');
            }

            $password = (string)($_POST['password'] ?? '');
            if (isset($_POST['register'])) {
                if ($password === '') {
                    http_response_code(422);
                    exit('Parola zorunlu');
                }
                $this->registerUser($email, $password);
            } elseif ($password !== '' && !$this->attemptLogin($email, $password)) {
                http_response_code(401);
                exit('E-posta veya parola hatalı');
            }
        }

        $users = $this->listUsers();
        require __DIR__ . '/../views/home.php';
    }

    private function verifyCsrf(string $token): void
    {
        $sessionToken = (string)($_SESSION['csrf_token'] ?? '');
        if ($sessionToken === '' || !hash_equals($sessionToken, $token)) {
            http_response_code(419);
            exit('CSRF doğrulaması başarısız');
        }
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function listUsers(): array
    {
        $stmt = (new Database())->pdo()->prepare('SELECT id, email FROM users ORDER BY id ASC');
        $stmt->execute();

        /** @var array<int, array<string, mixed>> $rows */
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $rows;
    }

    private function attemptLogin(string $email, string $rawPassword): bool
    {
        $stmt = (new Database())->pdo()->prepare('SELECT password_hash FROM users WHERE email = :email LIMIT 1');
        $stmt->execute([':email' => $email]);
        $row = $stmt->fetch();
        if ($row === false) {
            return false;
        }

        return password_verify($rawPassword, (string)$row['password_hash']);
    }

    private function hashPassword(string $rawPassword): string
    {
        return password_hash($rawPassword, PASSWORD_ARGON2ID);
    }

    private function registerUser(string $email, string $rawPassword): void
    {
        $stmt = (new Database())->pdo()->prepare('INSERT INTO users (email, password_hash) VALUES (:email, :password_hash)');
        $stmt->execute([
            ':email' => $email,
            ':password_hash' => $this->hashPassword($rawPassword),
        ]);
    }
}
