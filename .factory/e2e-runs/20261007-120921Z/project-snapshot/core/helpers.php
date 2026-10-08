<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — global yardımcı fonksiyonlar.
 *
 * Çıktı kuralı: kullanıcı verisi arayüze yalnız e() üzerinden basılır
 * (htmlspecialchars + ENT_QUOTES + UTF-8). Superglobal'lar doğrudan
 * sorguya hiçbir koşulda girmez.
 */

/**
 * XSS kaçışı: tüm HTML çıktısı bu fonksiyondan geçer.
 */
function e(mixed $value): string
{
    return htmlspecialchars((string) ($value ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * Uygulama taban adresi: AF_BASE_URL env varı varsa onu kullanır,
 * aksi halde Host başlığından (karakter beyaz listesiyle temizlenerek) üretir.
 */
function base_url(): string
{
    $configured = getenv('AF_BASE_URL');
    if (is_string($configured) && $configured !== '') {
        return rtrim($configured, '/');
    }
    $isHttps = (!empty($_SERVER['HTTPS']) && (string) $_SERVER['HTTPS'] !== 'off')
        || strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https';
    $host = (string) preg_replace('/[^A-Za-z0-9.\-]/', '', (string) ($_SERVER['HTTP_HOST'] ?? ''));
    return ($isHttps ? 'https' : 'http') . '://' . ($host !== '' ? $host : 'localhost');
}

/**
 * Mutlak adres üretir: url('/iletisim') → https://host/iletisim
 */
function url(string $path = '/', ?string $base = null): string
{
    $prefix = $base ?? base_url();
    return $prefix . '/' . ltrim($path, '/');
}

/**
 * PRG (Post/Redirect/Get) yönlendirmesi.
 */
function redirect(string $path): never
{
    header('Location: ' . url($path), true, 302);
    exit;
}

/**
 * RESTful JSON yanıtı — standart {success, data|error} zarfı.
 *
 * @param array<string, mixed> $payload
 */
function json_response(int $status, array $payload): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Başarılı JSON yanıtı (200/201) — standart zarfın success dalı.
 *
 * @param array<string, mixed> $data
 */
function json_success(int $status, array $data): never
{
    json_response($status, ['success' => true, 'data' => $data]);
}

/**
 * Standart hata şeması:
 * { "success": false, "error": { "code": "...", "message": "...", "details": [] } }
 *
 * @param list<mixed> $details
 */
function json_error(int $status, string $code, string $message, array $details = []): never
{
    json_response($status, [
        'success' => false,
        'error' => [
            'code' => $code,
            'message' => $message,
            'details' => $details,
        ],
    ]);
}

/**
 * İstemci IP'si: proxy arkasında X-Forwarded-For ilk girişi, aksi halde
 * REMOTE_ADDR. Geçersiz değerler "0.0.0.0" döner (KVKK izi tutarlı kalır).
 *
 * @param array<string, mixed>|null $server
 */
function client_ip(?array $server = null): string
{
    $server ??= $_SERVER;
    $forwarded = (string) ($server['HTTP_X_FORWARDED_FOR'] ?? '');
    if ($forwarded !== '') {
        $first = trim(explode(',', $forwarded, 2)[0]);
        if (filter_var($first, FILTER_VALIDATE_IP) !== false) {
            return $first;
        }
    }
    $remote = (string) ($server['REMOTE_ADDR'] ?? '');
    return filter_var($remote, FILTER_VALIDATE_IP) !== false ? $remote : '0.0.0.0';
}

/**
 * Tek seferlik bildirim (flash) yazar.
 */
function set_flash(string $type, string $message): void
{
    $_SESSION['flash'] = ['type' => $type, 'message' => $message];
}

/**
 * Tek seferlik bildirimi okur ve temizler.
 *
 * @return array{type: string, message: string}|null
 */
function flash(): ?array
{
    $flash = $_SESSION['flash'] ?? null;
    if (is_array($flash)) {
        unset($_SESSION['flash']);
        $type = $flash['type'] ?? 'info';
        $message = $flash['message'] ?? '';
        return ['type' => is_string($type) ? $type : 'info', 'message' => is_string($message) ? $message : ''];
    }
    return null;
}
