<?php

declare(strict_types=1);

namespace App;

/**
 * View katmanı — semantik HTML5 şablon render'ı + XSS çıkış kaçırma.
 * e(): htmlspecialchars($v, ENT_QUOTES, 'UTF-8') — kullanıcı girdisi ham basılmaz.
 */
final class View
{
    /**
     * @param array<string, mixed> $data
     */
    public static function render(string $template, array $data = []): string
    {
        $safe = str_replace(['..', "\0"], '', $template);
        $file = BASE_PATH . '/views/' . $safe . '.php';

        if (!is_file($file)) {
            throw new \RuntimeException(sprintf('View bulunamadı: %s', $template));
        }

        extract($data, EXTR_SKIP);

        ob_start();

        try {
            include $file;
        } finally {
            $content = (string) ob_get_clean();
        }

        return $content;
    }

    public static function e(mixed $value): string
    {
        if (is_array($value) || (is_object($value) && !method_exists($value, '__toString'))) {
            return '';
        }

        return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
    }
}
