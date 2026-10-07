<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — oturum bazlı flash mesaj kuyruğu.
 *
 * Form hataları / başarı bildirimleri bir sonraki istekte tek kullanımlık okunur.
 */

final class Flash
{
    private const SESSION_KEY = '_flash';

    /**
     * @param array<string, mixed> $bag
     */
    public static function set(array $bag): void
    {
        $_SESSION[self::SESSION_KEY] = $bag;
    }

    /**
     * Flash torbasını okur ve temizler (tek kullanımlık).
     *
     * @return array<string, mixed>
     */
    public static function take(): array
    {
        $bag = $_SESSION[self::SESSION_KEY] ?? null;
        unset($_SESSION[self::SESSION_KEY]);

        return is_array($bag) ? $bag : [];
    }
}
