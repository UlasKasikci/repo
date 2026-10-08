<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\View;

/**
 * GET /giris — giriş formu · POST /giris — giriş · POST /cikis — çıkış.
 *
 * Güvenlik: CSRF (App::run merkezli) · Argon2id + password_verify ·
 * giriş başarısında session_regenerate_id(true) · başarısız girişte
 * sabit hata iletisi (kullanıcı keşfi engeli).
 */
final class AuthController
{
    public function showLogin(): void
    {
        if (Auth::check()) {
            redirect(Auth::isModerator() ? '/admin' : '/hesabim');
        }
        $this->renderLogin();
    }

    public function login(): void
    {
        $email = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');

        if ($email === '' || $password === '') {
            $this->renderLogin('E-posta ve parola alanları zorunludur.');
            return;
        }

        if (!Auth::attempt($email, $password)) {
            // Sabit hata iletisi — geçerli e-posta keşfi engellenir.
            $this->renderLogin('E-posta veya parola hatalı.');
            return;
        }

        redirect(Auth::isModerator() ? '/admin' : '/hesabim');
    }

    public function logout(): void
    {
        Auth::logout();
        redirect('/');
    }

    private function renderLogin(string $error = ''): void
    {
        View::render('login', [
            'title' => 'Giriş — E2E İletişim',
            'description' => 'Yönetim paneline giriş yapın.',
            'active' => 'login',
            'error' => $error,
            'oldEmail' => $error === '' ? '' : trim((string) ($_POST['email'] ?? '')),
        ]);
    }
}
