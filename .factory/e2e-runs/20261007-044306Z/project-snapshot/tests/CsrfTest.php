<?php

declare(strict_types=1);

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * CSRF token üretimi/doğrulaması birim testleri.
 */
final class CsrfTest extends TestCase
{
    public function testTokenIsSixtyFourHexCharacters(): void
    {
        $token = Csrf::token();

        self::assertMatchesRegularExpression('/^[0-9a-f]{64}$/', $token);
    }

    public function testTokenIsStableWithinSession(): void
    {
        $first = Csrf::token();

        self::assertSame($first, Csrf::token());
    }

    public function testValidateAcceptsStoredToken(): void
    {
        self::assertTrue(Csrf::validate(Csrf::token()));
    }

    public function testValidateRejectsForeignToken(): void
    {
        self::assertFalse(Csrf::validate(str_repeat('a', 64)));
    }

    public function testValidateRejectsEmptyToken(): void
    {
        self::assertFalse(Csrf::validate(''));
    }

    public function testValidateRejectsMissingToken(): void
    {
        self::assertFalse(Csrf::validate(null));
    }

    public function testFieldContainsHiddenTokenInput(): void
    {
        $field = Csrf::field();

        self::assertStringContainsString('type="hidden"', $field);
        self::assertStringContainsString('name="csrf_token"', $field);
        self::assertStringContainsString(Csrf::token(), $field);
    }

    public function testTokenFromPostReadsSuperglobalSafely(): void
    {
        $token = Csrf::token();
        $_POST['csrf_token'] = $token;

        self::assertSame($token, Csrf::tokenFromPost());

        $_POST['csrf_token'] = ['nested'];

        self::assertNull(Csrf::tokenFromPost());

        unset($_POST['csrf_token']);

        self::assertNull(Csrf::tokenFromPost());
    }

    /** @return list<array{0: string, 1: bool}> */
    public static function validatePairsProvider(): array
    {
        return [
            ['', false],
            ['0000000000000000000000000000000000000000000000000000000000000000', false],
            ['zzzz', false],
        ];
    }

    #[DataProvider('validatePairsProvider')]
    public function testValidateRejectsPairs(string $token, bool $expected): void
    {
        self::assertSame($expected, Csrf::validate($token));
    }
}
