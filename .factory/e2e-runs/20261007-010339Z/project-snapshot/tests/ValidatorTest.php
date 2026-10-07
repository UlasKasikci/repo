<?php

declare(strict_types=1);

namespace Tests;

use App\Validator;
use PHPUnit\Framework\TestCase;

/** İletişim formu doğrulama birim testleri. */
final class ValidatorTest extends TestCase
{
    /** @return array<string, mixed> */
    private function validData(): array
    {
        return [
            'full_name' => 'Ayşe Yılmaz',
            'email' => 'ayse@ornek.com',
            'phone' => '+90 555 123 45 67',
            'subject' => 'Teklif talebi',
            'body' => 'Kurumsal iletişim platformu hakkında bilgi almak istiyorum.',
            'consent' => '1',
        ];
    }

    public function testValidContactHasNoErrors(): void
    {
        self::assertSame([], Validator::validateContact($this->validData()));
    }

    public function testMissingRequiredFieldsProduceErrors(): void
    {
        $errors = Validator::validateContact([]);

        self::assertNotSame([], $errors);
        self::assertCount(5, $errors);
    }

    public function testInvalidEmailIsRejected(): void
    {
        $data = $this->validData();
        $data['email'] = 'gecersiz-eposta';

        self::assertContains('Geçerli bir e-posta adresi giriniz.', Validator::validateContact($data));
    }

    public function testMissingConsentIsRejected(): void
    {
        $data = $this->validData();
        unset($data['consent']);

        self::assertContains('KVKK aydınlatma metnini onaylamanız gerekir.', Validator::validateContact($data));
    }

    public function testTooLongFieldsAreRejected(): void
    {
        $data = $this->validData();
        $data['full_name'] = str_repeat('a', 121);
        $data['subject'] = str_repeat('b', 151);
        $data['phone'] = str_repeat('9', 33);

        $errors = Validator::validateContact($data);

        self::assertCount(3, $errors);
    }

    public function testShortBodyIsRejected(): void
    {
        $data = $this->validData();
        $data['body'] = 'kısa';

        self::assertContains('Mesaj 10-5000 karakter arasında olmalıdır.', Validator::validateContact($data));
    }

    public function testEmailHelper(): void
    {
        self::assertTrue(Validator::email('ayse@ornek.com'));
        self::assertFalse(Validator::email('not-an-email'));
        self::assertFalse(Validator::email(''));
    }

    public function testTextHelperTrimsStringsAndDropsNonScalars(): void
    {
        self::assertSame('deger', Validator::text('  deger  '));
        self::assertSame('', Validator::text(null));
        self::assertSame('', Validator::text(['dizi']));
        self::assertSame('42', Validator::text(42));
    }
}
