<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — hata yanıtı üreticisi (404/403/500).
 *
 * Hata ayrıntısı istemciye sızdırılmaz; yalnız sunucu günlüğüne yazılır.
 */

final class ErrorView
{
    public static function render(string $code): void
    {
        http_response_code((int) $code);

        $view = VIEW_DIR . '/errors/' . $code . '.php';
        if (is_file($view)) {
            require $view;

            return;
        }

        echo e($code) . ' — Bir hata oluştu.';
    }
}
