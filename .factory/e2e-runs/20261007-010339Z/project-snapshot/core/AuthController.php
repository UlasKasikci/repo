<?php

declare(strict_types=1);

namespace App;

/** Giriş/çıkış denetleyicisi — CSRF + Argon2id + session fixation koruması. */
final class AuthController
{
    public function showLogin(): void
    {
        if (Auth::check()) {
            Response::redirect('/admin');

            return;
        }

        echo View::render('login', [
            'title' => 'Giriş — E2E İletişim Yönetim Paneli',
            'description' => 'Yönetim paneli girişi: rol korumalı erişim (admin/moderator).',
            'error' => null,
            'email' => '',
        ]);
    }

    public function login(): void
    {
        $email = Validator::text($_POST['email'] ?? null);
        $password = Validator::text($_POST['password'] ?? null);
        $token = Validator::text($_POST['csrf_token'] ?? null);

        if (!CSRF::validate($token !== '' ? $token : null)) {
            App::fail('CSRF_FAILED', 'Oturum güvenlik anahtarı geçersiz veya süresi doldu. Sayfayı yenileyin.', 403);

            return;
        }

        if ($email === '' || $password === '') {
            $this->renderLogin($email, 'E-posta ve parola zorunludur.');

            return;
        }

        if (!Validator::email($email)) {
            $this->renderLogin($email, 'Geçerli bir e-posta adresi giriniz.');

            return;
        }

        if (!Auth::attempt($email, $password)) {
            $this->renderLogin($email, 'Kimlik doğrulanamadı. Bilgilerinizi kontrol edin.');

            return;
        }

        Response::redirect('/admin');
    }

    public function logoutAction(): void
    {
        $token = Validator::text($_POST['csrf_token'] ?? null);
        if (!CSRF::validate($token !== '' ? $token : null)) {
            App::fail('CSRF_FAILED', 'Oturum güvenlik anahtarı geçersiz. Sayfayı yenileyin.', 403);

            return;
        }

        Auth::logout();
        Response::redirect('/');
    }

    private function renderLogin(string $email, string $error): void
    {
        http_response_code(422);
        echo View::render('login', [
            'title' => 'Giriş — E2E İletişim Yönetim Paneli',
            'description' => 'Yönetim paneli girişi: rol korumalı erişim (admin/moderator).',
            'error' => $error,
            'email' => $email,
        ]);
    }
}
