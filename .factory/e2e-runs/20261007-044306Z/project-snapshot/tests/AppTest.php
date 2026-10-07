<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

/**
 * App router (yol normalizasyonu + eşleşme) birim testleri.
 */
final class AppTest extends TestCase
{
    public function testNormalizesTrailingSlash(): void
    {
        $app = new App();

        self::assertSame('/iletisim', $app->normalize('/iletisim/'));
        self::assertSame('/', $app->normalize('/'));
        self::assertSame('/', $app->normalize(''));
        self::assertSame('/', $app->normalize('iletisim'));
    }

    public function testNormalizesUrlEncodedPath(): void
    {
        $app = new App();

        self::assertSame('/iletisim', $app->normalize('/%69letisim'));
    }

    public function testMatchesRegisteredRoute(): void
    {
        $app = new App();
        $called = false;
        $app->get('/test', static function () use (&$called): void {
            $called = true;
        });

        $handler = $app->match('GET', '/test');

        self::assertNotNull($handler);
        $handler();
        self::assertTrue($called);
    }

    public function testTrailingSlashStillMatches(): void
    {
        $app = new App();
        $app->get('/test', static function (): void {
        });

        self::assertNotNull($app->match('GET', '/test/'));
    }

    public function testUnknownRouteReturnsNull(): void
    {
        $app = new App();

        self::assertNull($app->match('GET', '/yok'));
    }

    public function testMethodsAreIsolated(): void
    {
        $app = new App();
        $app->post('/test', static function (): void {
        });

        self::assertNull($app->match('GET', '/test'));
        self::assertNotNull($app->match('POST', '/test'));
    }

    public function testHeadFallsBackToGet(): void
    {
        $app = new App();
        $app->get('/test', static function (): void {
        });

        self::assertNotNull($app->match('HEAD', '/test'));
    }

    public function testPostRouteDoesNotMatchGet(): void
    {
        $app = new App();
        $app->post('/giris', static function (): void {
        });

        self::assertNull($app->match('GET', '/giris'));
        self::assertNotNull($app->match('POST', '/giris'));
    }
}
