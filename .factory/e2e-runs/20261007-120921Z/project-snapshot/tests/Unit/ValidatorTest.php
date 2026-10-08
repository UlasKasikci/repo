<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use App\Core\Validator;
use PHPUnit\Framework\TestCase;

/**
 * Validator::contact birim testi — sunucu tarafı doğrulama kuralları (P1 edge case).
 */
final class ValidatorTest extends TestCase
{
    public function testValidInputIsTrimmedAndNormalized(): void
    {
        $result = Validator::contact([
            'name' => '  Ayşe Yılmaz  ',
            'email' => 'Ayse@Example.COM',
            'subject' => ' Teklif talebi ',
            'message' => ' Merhaba, iş birliği hakkında bilgi almak istiyorum. ',
        ]);

        self::assertSame([], $result['errors']);
        self::assertSame('Ayşe Yılmaz', $result['data']['name']);
        self::assertSame('ayse@example.com', $result['data']['email']);
        self::assertSame('Teklif talebi', $result['data']['subject']);
        self::assertSame('Merhaba, iş birliği hakkında bilgi almak istiyorum.', $result['data']['message']);
    }

    public function testMissingFieldsReportErrors(): void
    {
        $result = Validator::contact([]);

        self::assertArrayHasKey('name', $result['errors']);
        self::assertArrayHasKey('email', $result['errors']);
        self::assertArrayHasKey('subject', $result['errors']);
        self::assertArrayHasKey('message', $result['errors']);
    }

    public function testInvalidEmailIsRejected(): void
    {
        $result = Validator::contact([
            'name' => 'Ali Veli',
            'email' => 'gecersiz-eposta',
            'subject' => 'Soru',
            'message' => 'Sorum var.',
        ]);

        self::assertArrayHasKey('email', $result['errors']);
        self::assertArrayNotHasKey('name', $result['errors']);
    }

    public function testOverlongFieldsAreRejected(): void
    {
        $result = Validator::contact([
            'name' => str_repeat('a', Validator::NAME_MAX + 1),
            'email' => str_repeat('a', Validator::EMAIL_MAX - 10) . '@example.com',
            'subject' => str_repeat('k', Validator::SUBJECT_MAX + 1),
            'message' => str_repeat('m', Validator::MESSAGE_MAX + 1),
        ]);

        self::assertArrayHasKey('name', $result['errors']);
        self::assertArrayHasKey('subject', $result['errors']);
        self::assertArrayHasKey('message', $result['errors']);
    }

    public function testNonScalarInputIsTreatedAsEmpty(): void
    {
        $result = Validator::contact([
            'name' => ['dizi'],
            'email' => null,
        ]);

        self::assertArrayHasKey('name', $result['errors']);
        self::assertArrayHasKey('email', $result['errors']);
        self::assertSame('', $result['data']['name']);
    }
}
