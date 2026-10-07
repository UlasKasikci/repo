<?php

declare(strict_types=1);

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * İletişim formu doğrulama kuralları birim testleri.
 */
final class ValidatorTest extends TestCase
{
    /** @return array<string, mixed> */
    private static function validInput(): array
    {
        return [
            'name' => 'Ayşe Yılmaz',
            'email' => 'ayse@example.com',
            'phone' => '+90 532 000 00 00',
            'subject' => 'Teklif talebi',
            'body' => 'Bu mesaj on karakterden uzun bir deneme metnidir.',
            'kvkk_consent' => '1',
        ];
    }

    public function testValidInputPassesWithoutErrors(): void
    {
        self::assertSame([], Validator::contact(self::validInput()));
    }

    public function testConsentAcceptsIntegerAndBoolean(): void
    {
        $input = self::validInput();
        $input['kvkk_consent'] = 1;

        self::assertSame([], Validator::contact($input));

        $input['kvkk_consent'] = true;

        self::assertSame([], Validator::contact($input));
    }

    public function testMissingConsentFails(): void
    {
        $input = self::validInput();
        unset($input['kvkk_consent']);

        $errors = Validator::contact($input);

        self::assertArrayHasKey('kvkk_consent', $errors);
    }

    public function testEmptyNameFails(): void
    {
        $input = self::validInput();
        $input['name'] = '   ';

        $errors = Validator::contact($input);

        self::assertArrayHasKey('name', $errors);
    }

    public function testTooLongNameFails(): void
    {
        $input = self::validInput();
        $input['name'] = str_repeat('a', 121);

        $errors = Validator::contact($input);

        self::assertArrayHasKey('name', $errors);
    }

    /** @return list<array{0: string}> */
    public static function invalidEmailsProvider(): array
    {
        return [
            ['not-an-email'],
            ['missing@tld'],
            ['@example.com'],
            ['a b@example.com'],
        ];
    }

    #[DataProvider('invalidEmailsProvider')]
    public function testInvalidEmailFails(string $email): void
    {
        $input = self::validInput();
        $input['email'] = $email;

        $errors = Validator::contact($input);

        self::assertArrayHasKey('email', $errors);
    }

    public function testEmptyBodyFails(): void
    {
        $input = self::validInput();
        $input['body'] = '';

        $errors = Validator::contact($input);

        self::assertArrayHasKey('body', $errors);
    }

    public function testTooShortBodyFails(): void
    {
        $input = self::validInput();
        $input['body'] = 'kısa';

        $errors = Validator::contact($input);

        self::assertArrayHasKey('body', $errors);
    }

    public function testInvalidPhoneFails(): void
    {
        $input = self::validInput();
        $input['phone'] = 'abc!def';

        $errors = Validator::contact($input);

        self::assertArrayHasKey('phone', $errors);
    }

    public function testEmptyPhoneIsOptional(): void
    {
        $input = self::validInput();
        $input['phone'] = '';

        self::assertSame([], Validator::contact($input));
    }

    public function testMissingFieldsAreTreatedAsEmpty(): void
    {
        $errors = Validator::contact([]);

        self::assertArrayHasKey('name', $errors);
        self::assertArrayHasKey('email', $errors);
        self::assertArrayHasKey('subject', $errors);
        self::assertArrayHasKey('body', $errors);
        self::assertArrayHasKey('kvkk_consent', $errors);
        self::assertArrayNotHasKey('phone', $errors);
    }
}
