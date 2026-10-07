<?php

declare(strict_types=1);

namespace Tests;

use App\CSRF;
use PHPUnit\Framework\TestCase;

/** CSRF token üretimi/doğrulaması birim testleri. */
final class CSRFTest extends TestCase
{
    protected function setUp(): void
    {
        CSRF::ensureSession();
        $_SESSION = [];
    }

    public function testTokenIsSixtyFourHexCharacters(): void
    {
        $token = CSRF::token();

        self::assertMatchesRegularExpression('/^[a-f0-9]{64}$/', $token);
    }

    public function testTokenIsStableWithinSameSession(): void
    {
        $first = CSRF::token();

        self::assertSame($first, CSRF::token());
    }

    public function testValidateRejectsWrongToken(): void
    {
        CSRF::token();

        self::assertFalse(CSRF::validate('gectersiz-token'));
        self::assertFalse(CSRF::validate(null));
        self::assertFalse(CSRF::validate(''));
    }

    public function testValidateAcceptsSessionToken(): void
    {
        $token = CSRF::token();

        self::assertTrue(CSRF::validate($token));
    }

    public function testFieldContainsHiddenInput(): void
    {
        $field = CSRF::field();

        self::assertStringContainsString('type="hidden"', $field);
        self::assertStringContainsString('name="csrf_token"', $field);
    }
}
