<?php

declare(strict_types=1);

/**
 * Webrail — oturum açma/kapama denetleyicisi.
 */

final class AuthController extends Controller
{
    public function form(): void
    {
        if (Auth::check()) {
            $this->redirect('/admin/mesajlar');
        }

        $this->view('login', [
            'pageTitle' => 'Yönetim Girişi · Webrail',
            'pageDesc' => 'Yönetim paneli erişimi yetkili kullanıcılar içindir.',
            'flash' => Flash::take(),
        ]);
    }

    public function login(): void
    {
        $this->requireCsrf();

        $email = $_POST['email'] ?? null;
        $password = $_POST['password'] ?? null;
        $email = is_string($email) ? trim($email) : '';
        $password = is_string($password) ? $password : '';

        if ($email === '' || $password === '') {
            Flash::set([
                'errors' => ['form' => 'E-posta ve şifre zorunludur.'],
                'old' => ['email' => $email],
            ]);
            $this->redirect('/giris');
        }

        if (Auth::attempt($email, $password)) {
            $this->redirect('/admin/mesajlar');
        }

        Flash::set([
            'errors' => ['form' => 'E-posta veya şifre hatalı.'],
            'old' => ['email' => $email],
        ]);
        $this->redirect('/giris');
    }

    public function logout(): void
    {
        $this->requireCsrf();

        Auth::logout();
        $this->redirect('/');
    }
}
