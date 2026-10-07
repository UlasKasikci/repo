<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — uygulama çekirdeği (router + dispatch).
 *
 * Yol normalizasyonu (sondaki eğik çizgi, url-decode) ve HTTP durum kodları
 * buradan yönetilir; 404 fallback tek noktadan üretilir.
 */

final class App
{
    /** @var array<string, array<string, callable>> */
    private array $routes = ['GET' => [], 'POST' => []];

    public function get(string $path, callable $handler): void
    {
        $this->routes['GET'][$this->normalize($path)] = $handler;
    }

    public function post(string $path, callable $handler): void
    {
        $this->routes['POST'][$this->normalize($path)] = $handler;
    }

    /**
     * İstek yolunu normalize eder: url-decode + sondaki eğik çizgi temizliği.
     */
    public function normalize(string $path): string
    {
        $path = rawurldecode($path);
        if ($path === '' || $path[0] !== '/') {
            return '/';
        }
        if ($path !== '/') {
            $trimmed = rtrim($path, '/');
            $path = $trimmed === '' ? '/' : $trimmed;
        }

        return $path;
    }

    /**
     * Yöntem + yol eşleşmesini çözer; eşleşme yoksa null döner.
     */
    public function match(string $method, string $path): ?callable
    {
        $method = strtoupper($method);
        if ($method === 'HEAD') {
            $method = 'GET';
        }

        return $this->routes[$method][$this->normalize($path)] ?? null;
    }

    public function dispatch(): void
    {
        $handler = $this->match(self::serverMethod(), self::serverPath());
        if ($handler === null) {
            ErrorView::render('404');

            return;
        }

        $handler();
    }

    private static function serverMethod(): string
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if (!is_string($method) || $method === '') {
            return 'GET';
        }

        return strtoupper($method);
    }

    private static function serverPath(): string
    {
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $parsed = is_string($uri) && $uri !== '' ? parse_url($uri, PHP_URL_PATH) : false;
        if (!is_string($parsed) || $parsed === '') {
            return '/';
        }

        return $parsed;
    }
}
