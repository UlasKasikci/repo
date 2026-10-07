<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

/**
 * Flash mesaj kuyruğu birim testleri.
 */
final class FlashTest extends TestCase
{
    protected function setUp(): void
    {
        unset($_SESSION['_flash']);
    }

    public function testSetAndTakeRoundTrip(): void
    {
        Flash::set([
            'errors' => ['name' => 'Hata mesajı'],
            'old' => ['email' => 'ayse@example.com'],
        ]);

        $bag = Flash::take();

        self::assertSame(['name' => 'Hata mesajı'], $bag['errors']);
        self::assertSame(['email' => 'ayse@example.com'], $bag['old']);
    }

    public function testTakeClearsTheBag(): void
    {
        Flash::set(['ok' => 'Tamam']);
        Flash::take();

        self::assertSame([], Flash::take());
    }

    public function testTakeWithoutSetReturnsEmptyArray(): void
    {
        self::assertSame([], Flash::take());
    }

    public function testCorruptedBagFallsBackToEmpty(): void
    {
        $_SESSION['_flash'] = 'not-an-array';

        self::assertSame([], Flash::take());
    }
}
