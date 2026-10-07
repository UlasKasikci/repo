<?php

declare(strict_types=1);

namespace App;

/**
 * Front controller — tek giriş noktası (index.php → App::run()).
 * Durum kodları: 200/201 ok · 400/422 doğrulama · 401 oturumsuz ·
 * 403 yetkisiz/CSRF · 404 rota · 429 hız sınırı · 500 sunucu.
 */
final class App
{
    public static function run(): void
    {
        self::sendSecurityHeaders();
        Auth::boot();

        $path = self::currentPath();
        $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

        try {
            self::dispatch($path, $method);
        } catch (\PDOException) {
            if (self::wantsJson()) {
                Response::error('INTERNAL_ERROR', 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.', 500);

                return;
            }
            http_response_code(500);
            echo View::render('error/500');
        }
    }

    private static function dispatch(string $path, string $method): void
    {
        $home = new HomeController();
        $legal = new LegalController();
        $auth = new AuthController();
        $contact = new ContactController();
        $admin = new AdminController();

        if ($path === '/' && $method === 'GET') {
            $home->index();

            return;
        }
        if ($path === '/iletisim' && $method === 'GET') {
            $contact->show();

            return;
        }
        if ($path === '/iletisim' && $method === 'POST') {
            $contact->submit();

            return;
        }
        if ($path === '/giris' && $method === 'GET') {
            $auth->showLogin();

            return;
        }
        if ($path === '/giris' && $method === 'POST') {
            $auth->login();

            return;
        }
        if ($path === '/cikis' && $method === 'POST') {
            $auth->logoutAction();

            return;
        }
        if ($path === '/admin' && $method === 'GET') {
            $admin->dashboard();

            return;
        }
        if ($path === '/admin/mesajlar' && $method === 'GET') {
            $admin->messages();

            return;
        }
        if ($path === '/admin/mesajlar' && $method === 'POST') {
            $admin->updateMessageStatus();

            return;
        }
        if ($path === '/admin/kullanicilar' && $method === 'GET') {
            $admin->users();

            return;
        }
        if ($path === '/yasal/aydinlatma' && $method === 'GET') {
            $legal->aydinlatma();

            return;
        }
        if ($path === '/yasal/gizlilik' && $method === 'GET') {
            $legal->gizlilik();

            return;
        }
        if ($path === '/yasal/cerez' && $method === 'GET') {
            $legal->cerez();

            return;
        }
        if ($path === '/api/health' && $method === 'GET') {
            Response::json(['success' => true, 'data' => ['status' => 'ok']]);

            return;
        }

        if (self::wantsJson()) {
            Response::error('NOT_FOUND', 'İstenen kaynak bulunamadı.', 404);

            return;
        }
        http_response_code(404);
        echo View::render('error/404');
    }

    public static function currentPath(): string
    {
        $uri = (string) ($_SERVER['REQUEST_URI'] ?? '/');
        $parsed = parse_url($uri, PHP_URL_PATH);
        $path = is_string($parsed) && $parsed !== '' ? $parsed : '/';
        $path = urldecode($path);

        $script = (string) ($_SERVER['SCRIPT_NAME'] ?? '/');
        $base = rtrim(str_replace('\\', '/', $script), '/');
        if ($base !== '' && $base !== '/' && str_starts_with($path, $base)) {
            $path = substr($path, strlen($base));
        }

        if ($path === '') {
            $path = '/';
        }

        return '/' . trim($path, '/');
    }

    public static function wantsJson(): bool
    {
        $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

        return (is_string($accept) && str_contains($accept, 'application/json'))
            || (is_string($contentType) && str_contains($contentType, 'application/json'));
    }

    /**
     * Hata çıkışı: JSON istemciye standart şema, HTML istemciye durum kodlu hata view'ı.
     */
    public static function fail(string $code, string $message, int $status): void
    {
        if (self::wantsJson()) {
            Response::error($code, $message, $status);

            return;
        }
        http_response_code($status);
        echo View::render('error/' . $status, ['code' => $code, 'message' => $message]);
    }

    public static function baseUrl(): string
    {
        $configured = getenv('APP_URL');
        if (is_string($configured) && $configured !== '') {
            return rtrim($configured, '/');
        }

        $scheme = Auth::isHttps() ? 'https' : 'http';
        $host = (string) ($_SERVER['HTTP_HOST'] ?? 'localhost');

        return $scheme . '://' . $host;
    }

    private static function sendSecurityHeaders(): void
    {
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('Referrer-Policy: strict-origin-when-cross-origin');
    }
}
