<?php

declare(strict_types=1);

namespace App;

/**
 * Yönetim paneli denetleyicisi — rol korumalı (admin/moderator).
 * Oturumsuz erişim 401; user rolü 403. Tüm POST işlemleri CSRF'li.
 */
final class AdminController
{
    public function dashboard(): void
    {
        if (!$this->requireRole(['admin', 'moderator'])) {
            return;
        }

        $newCount = Database::fetchOne(
            "SELECT COUNT(*) AS total FROM messages WHERE status = 'new'",
            []
        );
        $archivedCount = Database::fetchOne(
            "SELECT COUNT(*) AS total FROM messages WHERE status = 'archived'",
            []
        );
        $userCount = Database::fetchOne(
            'SELECT COUNT(*) AS total FROM users',
            []
        );

        echo View::render('admin/dashboard', [
            'title' => 'Yönetim Paneli — E2E İletişim',
            'description' => 'Rol korumalı yönetim paneli: mesaj ve kullanıcı özetleri.',
            'newCount' => (int) ($newCount['total'] ?? 0),
            'archivedCount' => (int) ($archivedCount['total'] ?? 0),
            'userCount' => (int) ($userCount['total'] ?? 0),
        ]);
    }

    public function messages(): void
    {
        if (!$this->requireRole(['admin', 'moderator'])) {
            return;
        }

        $filter = Validator::text($_GET['status'] ?? null);
        $allowed = ['new', 'read', 'archived'];
        if ($filter !== '' && !in_array($filter, $allowed, true)) {
            $filter = '';
        }

        $rows = $filter === ''
            ? Database::fetchAll(
                'SELECT id, full_name, email, phone, subject, body, status, consent_given, created_at'
                . ' FROM messages ORDER BY created_at DESC, id DESC LIMIT 100',
                []
            )
            : Database::fetchAll(
                'SELECT id, full_name, email, phone, subject, body, status, consent_given, created_at'
                . ' FROM messages WHERE status = ? ORDER BY created_at DESC, id DESC LIMIT 100',
                [$filter]
            );

        echo View::render('admin/messages', [
            'title' => 'Mesajlar — E2E İletişim Yönetim Paneli',
            'description' => 'İletişim formundan gelen mesajların listesi.',
            'messages' => $rows,
            'filter' => $filter,
        ]);
    }

    public function updateMessageStatus(): void
    {
        if (!$this->requireRole(['admin', 'moderator'])) {
            return;
        }

        $token = Validator::text($_POST['csrf_token'] ?? null);
        if (!CSRF::validate($token !== '' ? $token : null)) {
            App::fail('CSRF_FAILED', 'Form güvenlik anahtarı geçersiz. Sayfayı yenileyin.', 403);

            return;
        }

        $id = (int) Validator::text($_POST['id'] ?? null);
        $status = Validator::text($_POST['status'] ?? null);
        $allowed = ['new', 'read', 'archived'];

        if ($id <= 0 || !in_array($status, $allowed, true)) {
            App::fail('VALIDATION_FAILED', 'Geçersiz mesaj kimliği veya durum değeri.', 422);

            return;
        }

        Database::execute('UPDATE messages SET status = ? WHERE id = ?', [$status, $id]);
        Response::redirect('/admin/mesajlar');
    }

    public function users(): void
    {
        if (!$this->requireRole(['admin'])) {
            return;
        }

        $rows = Database::fetchAll(
            'SELECT u.id, u.email, u.full_name, u.is_active, u.created_at, r.name AS role_name'
            . ' FROM users u INNER JOIN roles r ON r.id = u.role_id'
            . ' ORDER BY u.created_at DESC, u.id DESC LIMIT 200',
            []
        );

        echo View::render('admin/users', [
            'title' => 'Kullanıcılar — E2E İletişim Yönetim Paneli',
            'description' => 'Yalnızca admin rolüne açık kullanıcı listesi.',
            'users' => $rows,
        ]);
    }

    /**
     * Rol koruması: oturumsuz 401, yetkisiz 403 (user rolü).
     *
     * @param list<string> $roles
     */
    private function requireRole(array $roles): bool
    {
        if (!Auth::check()) {
            App::fail('UNAUTHENTICATED', 'Bu bölüm için oturum açmanız gerekir.', 401);

            return false;
        }

        if (!Auth::can(...$roles)) {
            App::fail('FORBIDDEN', 'Bu bölüm için yetkiniz bulunmuyor.', 403);

            return false;
        }

        return true;
    }
}
