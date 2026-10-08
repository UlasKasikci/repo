<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\Core\Csrf;
use PHPUnit\Framework\TestCase;

/**
 * Csrf belirteç yönetimi birim testi — per-session token + hash_equals.
 */
final class CsrfTest extends TestCase
{
    protected function setUp(): void
    {
        unset($_SESSION['csrf_token']);
    }

    public function testTokenIsSixtyFourHexChars(): void
    {
        $token = Csrf::token();

        self::assertSame(64, strlen($token));
        self::assertMatchesRegularExpression('/^[0-9a-f]{64}$/', $token);
    }

    public function testTokenIsStableWithinSession(): void
    {
        $first = Csrf::token();
        $second = Csrf::token();

        self::assertSame($first, $second);
    }

    public function testValidateAcceptsMatchingToken(): void
    {
        $token = Csrf::token();

        self::assertTrue(Csrf::validate($token));
    }

    public function testValidateRejectsMismatchedToken(): void
    {
        Csrf::token();

        self::assertFalse(Csrf::validate(str_repeat('0', 64)));
    }

    public function testValidateRejectsNullAndEmptyTokens(): void
    {
        Csrf::token();

        self::assertFalse(Csrf::validate(null));
        self::assertFalse(Csrf::validate(''));
    }

    public function testValidateWithoutSessionTokenFails(): void
    {
        self::assertFalse(Csrf::validate('herhangibir-deger'));
    }
}
