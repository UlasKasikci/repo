<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\Core\App;
use PHPUnit\Framework\TestCase;

/**
 * Front-controller rota tablosu birim testi (App::match — saf, DB'siz).
 */
final class AppRoutingTest extends TestCase
{
    public function testHomeRouteMatchesGet(): void
    {
        $route = App::match('GET', '/');

        self::assertNotNull($route);
        self::assertSame([], $route['roles']);
    }

    public function testContactRoutesMatchGetAndPost(): void
    {
        self::assertNotNull(App::match('GET', '/iletisim'));
        self::assertNotNull(App::match('POST', '/iletisim'));
    }

    public function testLoginRouteMatchesPost(): void
    {
        self::assertNotNull(App::match('POST', '/giris'));
    }

    public function testAdminRouteCarriesRoleProtection(): void
    {
        $route = App::match('GET', '/admin');

        self::assertNotNull($route);
        self::assertNotSame([], $route['roles']);
        self::assertContains('Admin', $route['roles']);
    }

    public function testAnonymizeRouteIsAdminOnly(): void
    {
        $route = App::match('POST', '/admin/anonimlestir');

        self::assertNotNull($route);
        self::assertSame(['Admin'], $route['roles']);
    }

    public function testUnknownRouteReturnsNull(): void
    {
        self::assertNull(App::match('GET', '/boyle-bir-rota-yok'));
    }

    public function testWrongMethodReturnsNull(): void
    {
        self::assertNull(App::match('DELETE', '/iletisim'));
    }

    public function testMethodMatchingIsCaseInsensitive(): void
    {
        self::assertNotNull(App::match('get', '/iletisim'));
    }
}
