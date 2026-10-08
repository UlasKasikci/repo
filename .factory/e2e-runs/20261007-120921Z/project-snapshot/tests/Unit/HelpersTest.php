<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use PHPUnit\Framework\TestCase;

/**
 * Global yardımcı fonksiyonlar birim testi — e() XSS kaçışı, url(), client_ip().
 */
final class HelpersTest extends TestCase
{
    public function testEEscapesHtmlSpecialChars(): void
    {
        $raw = '<script>"x"&\'y\'';
        $escaped = e($raw);

        // Oracle: e() htmlspecialchars ile birebir aynı sonucu üretmeli.
        self::assertSame(htmlspecialchars($raw, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'), $escaped);
        // Ham etiket çıktıda bulunmamalı (kaçırılmış olmalı).
        self::assertStringNotContainsString('<script>', $escaped);
        // Tek tırnak da kaçırılmalı (ENT_QUOTES).
        self::assertSame(htmlspecialchars("'", ENT_QUOTES, 'UTF-8'), e("'"));
    }

    public function testENullBecomesEmptyString(): void
    {
        self::assertSame('', e(null));
    }

    public function testEIntegerBecomesString(): void
    {
        self::assertSame('42', e(42));
    }

    public function testUrlConcatenatesBaseAndPath(): void
    {
        self::assertSame('https://example.test/iletisim', url('/iletisim', 'https://example.test'));
        self::assertSame('https://example.test/', url('/', 'https://example.test'));
    }

    public function testUrlTrimsLeadingSlash(): void
    {
        self::assertSame('https://example.test/iletisim', url('iletisim', 'https://example.test'));
    }

    public function testClientIpPrefersValidForwardedFor(): void
    {
        $server = [
            'HTTP_X_FORWARDED_FOR' => '203.0.113.7, 70.41.3.18',
            'REMOTE_ADDR' => '10.0.0.1',
        ];

        self::assertSame('203.0.113.7', client_ip($server));
    }

    public function testClientIpFallsBackToRemoteAddr(): void
    {
        self::assertSame('10.0.0.1', client_ip(['REMOTE_ADDR' => '10.0.0.1']));
    }

    public function testClientIpInvalidValueBecomesZeroAddress(): void
    {
        self::assertSame('0.0.0.0', client_ip(['REMOTE_ADDR' => 'gecersiz-ip']));
        self::assertSame('0.0.0.0', client_ip(['HTTP_X_FORWARDED_FOR' => 'yok', 'REMOTE_ADDR' => '']));
    }
}
