<?php

declare(strict_types=1);

namespace App\Core;

use App\Controllers\AccountController;
use App\Controllers\AdminController;
use App\Controllers\ApiController;
use App\Controllers\AuthController;
use App\Controllers\ContactController;
use App\Controllers\HomeController;
use App\Controllers\PageController;
use Closure;
use Throwable;

/**
 * Front-controller yönlendirici.
 *
 * - Rota tablosu: "METHOD /yol" → handler kapanışı + RBAC rol listesi.
 * - CSRF: tüm POST/PUT/PATCH/DELETE istekleri merkezi olarak doğrulanır.
 * - RBAC: rol listesi boş olmayan rotalar 401 (kimliksiz) / 403 (yetkisiz)
 *   ayrımıyla korunur; API yolları JSON hata şeması döner, web yolları
 *   giriş yönlendirmesi veya hata sayfası üretir.
 * - 404/405 ve yakalanan tüm Throwable'lar standart hata akışına gider;
 *   iç detay (stack/SQL) istemciye sızdırılmaz.
 */
final class App
{
    /**
     * Rota tablosu (tembel kurulum — closure'lar const ifade olamaz).
     *
     * @var array<string, array{handler: Closure(): void, roles: list<string>}>|null
     */
    private static ?array $routes = null;

    public static function run(): void
    {
        $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
        if ($method === 'HEAD') {
            $method = 'GET';
        }
        $path = self::currentPath();

        $route = self::match($method, $path);
        if ($route === null) {
            if (self::hasPathWithOtherMethod($method, $path)) {
                self::reject($path, 405, 'METHOD_NOT_ALLOWED', 'Bu istek yöntemi bu adres için desteklenmiyor.');
                return;
            }
            self::reject($path, 404, 'NOT_FOUND', 'Aradığınız sayfa bulunamadı.');
            return;
        }

        // CSRF: tüm mutasyon isteklerinde benzersiz oturum belirteci zorunlu.
        if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'], true)
            && !Csrf::validate(Csrf::requestToken())) {
            self::reject($path, 403, 'CSRF_TOKEN_INVALID', 'Oturum güvenlik belirteci geçersiz veya eksik.');
            return;
        }

        // RBAC: kimliksiz → 401 (web'de giriş sayfasına yönlendirme),
        // yetkisiz rol → 403.
        $roles = $route['roles'];
        if ($roles !== []) {
            Auth::enforceTimeout();
            if (!Auth::check()) {
                if (self::isApiPath($path)) {
                    self::reject($path, 401, 'UNAUTHENTICATED', 'Bu uç nokta kimlik doğrulaması gerektiriyor.');
                    return;
                }
                redirect('/giris');
            }
            if (!in_array(Auth::role(), $roles, true)) {
                self::reject($path, 403, 'FORBIDDEN', 'Bu işlem için yetkiniz yok.');
                return;
            }
        }

        $handler = $route['handler'];
        try {
            $handler();
        } catch (Throwable $exception) {
            error_log('[App] ' . $exception->getMessage()
                . ' @ ' . $exception->getFile() . ':' . $exception->getLine());
            self::reject($path, 500, 'INTERNAL_ERROR', 'Beklenmeyen bir sunucu hatası oluştu.');
        }
    }

    /**
     * Rota tablosunu üretir (tembel; bir kez kurulur).
     *
     * @return array<string, array{handler: Closure(): void, roles: list<string>}>
     */
    public static function routes(): array
    {
        if (self::$routes !== null) {
            return self::$routes;
        }

        self::$routes = [
            'GET /' => [
                'handler' => static function (): void {
                    (new HomeController())->index();
                },
                'roles' => [],
            ],
            'GET /iletisim' => [
                'handler' => static function (): void {
                    (new ContactController())->show();
                },
                'roles' => [],
            ],
            'POST /iletisim' => [
                'handler' => static function (): void {
                    (new ContactController())->submit();
                },
                'roles' => [],
            ],
            'GET /giris' => [
                'handler' => static function (): void {
                    (new AuthController())->showLogin();
                },
                'roles' => [],
            ],
            'POST /giris' => [
                'handler' => static function (): void {
                    (new AuthController())->login();
                },
                'roles' => [],
            ],
            'POST /cikis' => [
                'handler' => static function (): void {
                    (new AuthController())->logout();
                },
                'roles' => [],
            ],
            'GET /hesabim' => [
                'handler' => static function (): void {
                    (new AccountController())->show();
                },
                // Tüm kimlikli roller: User yalnız kendi kayıtlarını görür.
                'roles' => ['Admin', 'Moderator', 'User'],
            ],
            'GET /admin' => [
                'handler' => static function (): void {
                    (new AdminController())->dashboard();
                },
                'roles' => ['Admin', 'Moderator'],
            ],
            'POST /admin/mesaj-durum' => [
                'handler' => static function (): void {
                    (new AdminController())->updateStatus();
                },
                'roles' => ['Admin', 'Moderator'],
            ],
            'POST /admin/anonimlestir' => [
                'handler' => static function (): void {
                    (new AdminController())->anonymize();
                },
                'roles' => ['Admin'],
            ],
            'GET /kvkk/aydinlatma' => [
                'handler' => static function (): void {
                    (new PageController())->aydinlatma();
                },
                'roles' => [],
            ],
            'GET /kvkk/gizlilik' => [
                'handler' => static function (): void {
                    (new PageController())->gizlilik();
                },
                'roles' => [],
            ],
            'GET /kvkk/cerez' => [
                'handler' => static function (): void {
                    (new PageController())->cerez();
                },
                'roles' => [],
            ],
            'GET /api/mesajlar' => [
                'handler' => static function (): void {
                    (new ApiController())->messages();
                },
                'roles' => ['Admin', 'Moderator'],
            ],
            'POST /api/cerez-riza' => [
                'handler' => static function (): void {
                    (new ApiController())->cookieConsent();
                },
                'roles' => [],
            ],
        ];

        return self::$routes;
    }

    /**
     * Rota eşleşmesi (saf, birim test edilebilir).
     *
     * @return array{handler: Closure(): void, roles: list<string>}|null
     */
    public static function match(string $method, string $path): ?array
    {
        $route = self::routes()[strtoupper($method) . ' ' . $path] ?? null;
        return is_array($route) ? $route : null;
    }

    private static function currentPath(): string
    {
        $uri = (string) ($_SERVER['REQUEST_URI'] ?? '/');
        $path = parse_url($uri, PHP_URL_PATH);
        if (!is_string($path) || $path === '') {
            return '/';
        }
        $trimmed = trim(rawurldecode($path), '/');
        return $trimmed === '' ? '/' : '/' . $trimmed;
    }

    private static function hasPathWithOtherMethod(string $method, string $path): bool
    {
        foreach (array_keys(self::routes()) as $key) {
            $key = (string) $key;
            $parts = explode(' ', $key, 2);
            if (count($parts) !== 2) {
                continue;
            }
            [$routeMethod, $routePath] = $parts;
            if ($routePath === $path && $routeMethod !== $method) {
                return true;
            }
        }
        return false;
    }

    private static function isApiPath(string $path): bool
    {
        return str_starts_with($path, '/api/');
    }

    /**
     * API yollarında standart JSON hata zarfı; web yollarında hata sayfası.
     */
    private static function reject(string $path, int $status, string $code, string $message): void
    {
        if (self::isApiPath($path)) {
            // json_error() never döner (exit) — API dalı burada sonlanır.
            json_error($status, $code, $message);
        }
        http_response_code($status);
        View::render('errors/' . (string) $status, [
            'title' => (string) $status,
            'description' => $message,
            'active' => '',
            'code' => $code,
            'message' => $message,
        ]);
    }
}
