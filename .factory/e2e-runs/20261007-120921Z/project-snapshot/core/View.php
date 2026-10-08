<?php

declare(strict_types=1);

namespace App\Core;

use RuntimeException;

/**
 * Şablon işleyici: views/ altındaki .php şablonlarını değişken kapsamıyla
 * dahil eder. Şablon yolu mutlak olmalı ve '..' içeremez (traversal koruması).
 */
final class View
{
    /**
     * @param array<string, mixed> $vars
     */
    public static function render(string $template, array $vars = []): void
    {
        if ($template === '' || str_contains($template, '..') || str_starts_with($template, '/')) {
            throw new RuntimeException('Geçersiz şablon yolu.');
        }
        $file = APP_ROOT . '/views/' . $template . '.php';
        if (!is_file($file)) {
            throw new RuntimeException('Şablon bulunamadı: ' . $template);
        }
        extract($vars, EXTR_SKIP);
        require $file;
    }
}
