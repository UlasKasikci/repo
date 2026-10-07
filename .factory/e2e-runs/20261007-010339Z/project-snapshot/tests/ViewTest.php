<?php

declare(strict_types=1);

namespace Tests;

use App\View;
use PHPUnit\Framework\TestCase;

/** View katmanı birim testleri — XSS çıkış kaçırma + KVKK view render'ı. */
final class ViewTest extends TestCase
{
    public function testEscapesHtmlSpecialCharacters(): void
    {
        self::assertSame(
            '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;',
            View::e('<script>alert("x")</script>')
        );
    }

    public function testEscapesSingleQuotesWithEntQuotes(): void
    {
        self::assertSame('&#039;', View::e("'"));
    }

    public function testHandlesNullAndArrays(): void
    {
        self::assertSame('', View::e(null));
        self::assertSame('', View::e(['dizi']));
        self::assertSame('42', View::e(42));
    }

    public function testMissingTemplateThrows(): void
    {
        $this->expectException(\RuntimeException::class);

        View::render('olmayan-template');
    }

    public function testRendersKvkkCookiePolicyPage(): void
    {
        $html = View::render('legal/cerez', [
            'title' => 'Çerez Politikası — Test',
            'description' => 'Test açıklaması',
        ]);

        self::assertStringContainsString('<!DOCTYPE html>', $html);
        self::assertStringContainsString('Çerez Tercihleri', $html);
        self::assertStringContainsString('cookie-consent', $html);
    }

    public function testCookieConsentPartialHasConsentAndRejectButtons(): void
    {
        $html = View::render('partials/cookie-consent');

        self::assertStringContainsString('id="cookie-consent-accept"', $html);
        self::assertStringContainsString('id="cookie-consent-reject"', $html);
        self::assertStringContainsString('aria-labelledby="cookie-consent-title"', $html);
    }
}
