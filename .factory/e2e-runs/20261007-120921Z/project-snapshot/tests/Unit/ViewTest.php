<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\Core\View;
use PHPUnit\Framework\TestCase;
use RuntimeException;

/**
 * Şablon işleyici birim testi — traversal koruması + HTML çıktısı.
 */
final class ViewTest extends TestCase
{
    public function testTraversalPathIsRejected(): void
    {
        $this->expectException(RuntimeException::class);
        View::render('../core/Database');
    }

    public function testAbsolutePathIsRejected(): void
    {
        $this->expectException(RuntimeException::class);
        View::render('/etc/passwd');
    }

    public function testMissingTemplateThrows(): void
    {
        $this->expectException(RuntimeException::class);
        View::render('boyle-bir-sablon-yok');
    }

    public function testErrorTemplateRendersHtmlDocument(): void
    {
        ob_start();
        View::render('errors/404', [
            'title' => '404',
            'description' => 'Aradığınız sayfa bulunamadı.',
            'active' => '',
            'code' => 'NOT_FOUND',
            'message' => 'Aradığınız sayfa bulunamadı.',
        ]);
        $html = (string) ob_get_clean();

        self::assertStringContainsString('<!DOCTYPE html>', $html);
        self::assertStringContainsString('404', $html);
        self::assertStringContainsString('NOT_FOUND', $html);
    }

    public function testContactTemplateEscapesUserInput(): void
    {
        $raw = chr(60) . 'img src=x onerror=alert(1)' . chr(62);
        ob_start();
        View::render('contact', [
            'title' => 'İletişim',
            'description' => '',
            'active' => 'contact',
            'errors' => ['name' => 'Ad alanı zorunludur.'],
            'old' => ['name' => $raw],
            'flash' => null,
        ]);
        $html = (string) ob_get_clean();

        // Ham girdi çıktıda bulunmaz; e() ile HTML kaçırılmış hali bulunur.
        self::assertStringNotContainsString($raw, $html);
        self::assertStringContainsString(e($raw), $html);
    }
}
