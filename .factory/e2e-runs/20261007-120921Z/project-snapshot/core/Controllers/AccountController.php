<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\View;

/**
 * GET /hesabim — kimlikli kullanıcının kendi kayıtları.
 *
 * Rol hiyerarşisi: User yalnız kendi mesajlarını ve kendi rıza kayıtlarını
 * görür (WHERE user_id = oturum sahibi). Admin/Moderator de bu sayfayı
 * görebilir; yönetim işlemleri /admin altındadır.
 */
final class AccountController
{
    public function show(): void
    {
        $userId = Auth::userId();

        $messages = Database::all(
            'SELECT id, subject, body, status, created_at FROM messages'
            . ' WHERE user_id = :user_id ORDER BY created_at DESC LIMIT 20',
            [':user_id' => $userId]
        );

        $consents = Database::all(
            'SELECT purpose, consent_type, consent_text_version, granted, created_at'
            . ' FROM user_consents WHERE user_id = :user_id ORDER BY created_at DESC LIMIT 20',
            [':user_id' => $userId]
        );

        View::render('account', [
            'title' => 'Hesabım — E2E İletişim',
            'description' => 'Hesap özeti: iletişim mesajlarınız ve rıza kayıtlarınız.',
            'active' => 'account',
            'userName' => Auth::userName(),
            'roleName' => Auth::role(),
            'messages' => $messages,
            'consents' => $consents,
            'flash' => flash(),
        ]);
    }
}
