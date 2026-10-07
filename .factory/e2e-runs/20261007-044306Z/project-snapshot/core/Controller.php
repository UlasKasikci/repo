<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — denetleyici taban sınıfı.
 *
 * Görünüm üretimi, yönlendirme ve hata yanıtları buradan paylaşılır.
 */

abstract class Controller
{
    /**
     * Şablonu üretir. $data şablon kapsamına aktarılır; şablonlar
     * tip güvenli erişimle (arr/e) okur.
     *
     * @param array<string, mixed> $data
     */
    protected function view(string $template, array $data = []): void
    {
        $file = VIEW_DIR . '/' . $template . '.php';
        if (!is_file($file)) {
            ErrorView::render('500');

            return;
        }

        require $file;
    }

    protected function notFound(): void
    {
        ErrorView::render('404');
    }

    protected function forbidden(): void
    {
        ErrorView::render('403');
    }

    protected function redirect(string $path): never
    {
        header('Location: ' . url($path), true, 302);
        exit;
    }

    /**
     * POST isteklerinde CSRF doğrulaması; geçersizse 403 üretir.
     */
    protected function requireCsrf(): void
    {
        if (Csrf::validate(Csrf::tokenFromPost()) === false) {
            $this->forbidden();
        }
    }

    /**
     * Oturum ve rol koruması (RBAC): oturum yoksa girişe, rol uymuyorsa 403'e gider.
     *
     * @param list<int> $roles
     */
    protected function requireRole(array $roles): void
    {
        if (Auth::check() === false) {
            $this->redirect('/giris');
        }

        $roleId = Auth::roleId();
        if ($roleId === null || in_array($roleId, $roles, true) === false) {
            $this->forbidden();
        }
    }
}
