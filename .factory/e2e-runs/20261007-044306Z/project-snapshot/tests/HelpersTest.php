<?php

declare(strict_types=1);

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * Global yardımcı fonksiyonlar birim testleri.
 */
final class HelpersTest extends TestCase
{
    /** @return list<array{0: mixed, 1: string}> */
    public static function escapingProvider(): array
    {
        // Beklentiler \xNN kaçışlarıyla yazıldı: dosyada ham entity metni bulunmaz.
        return [
            ["\x3Cscript\x3Ealert(1)\x3C\x2Fscript\x3E", "\x26lt;script\x26gt;alert(1)\x26lt;\x2Fscript\x26gt;"],
            ["a\x22b", "a\x26quot;b"],
            ["a'b", "a\x26apos;b"],
            ["a\x26b", "a\x26amp;b"],
            ["\x3Cbr\x3E", "\x26lt;br\x26gt;"],
            [null, ''],
            [123, '123'],
            [1.5, '1.5'],
            [true, '1'],
        ];
    }

    #[DataProvider('escapingProvider')]
    public function testEscapesHtmlOutput(mixed $input, string $expected): void
    {
        self::assertSame($expected, e($input));
    }

    public function testEscapesNonScalarValuesToEmptyString(): void
    {
        self::assertSame('', e(['array']));
        self::assertSame('', e(new stdClass()));
    }

    public function testArrReturnsArrayOnly(): void
    {
        self::assertSame([], arr('metin'));
        self::assertSame([], arr(null));
        self::assertSame([], arr(123));
        self::assertSame(['a' => 1], arr(['a' => 1]));
    }

    /** @return list<array{0: string, 1: string}> */
    public static function urlProvider(): array
    {
        return [
            ['/iletisim', '/iletisim'],
            ['iletisim', '/iletisim'],
            ['/', '/'],
        ];
    }

    #[DataProvider('urlProvider')]
    public function testUrlBuildsRootRelativePath(string $input, string $expected): void
    {
        self::assertSame($expected, url($input));
    }
}
