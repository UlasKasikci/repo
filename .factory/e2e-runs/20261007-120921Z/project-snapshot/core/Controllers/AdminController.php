<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\View;
use Throwable;

/**
 * GET /admin — yönetim paneli (mesaj + kullanıcı listesi) ·
 * POST /admin/mesaj-durum — mesaj durumu değişimi (Admin/Moderator) ·
 * POST /admin/anonimlestir — kullanıcı anonimleştirme (yalnız Admin).
 *
 * Mesaj yaşam döngüsü: new → read → archived. KVKK veri silme: users kaydı
 * fiziksel silinmez; anonymization_log ile iz bırakılarak anonimleştirilir.
 */
final class AdminController
{
    private const MESSAGE_STATUSES = ['new', 'read', 'archived'];

    /**
     * @var array<string, string>
     */
    private const STATUS_LABELS = [
        'new' => 'Yeni',
        'read' => 'Okundu',
        'archived' => 'Arşivlendi',
    ];

    public function dashboard(): void
    {
        // N+1 yasağı: roller tek JOIN ile getirilir.
        $messages = Database::all(
            'SELECT m.id, m.name, m.email, m.subject, m.body, m.status, m.created_at,'
            . ' u.name AS user_name, r.name AS role_name'
            . ' FROM messages AS m'
            . ' LEFT JOIN users AS u ON u.id = m.user_id'
            . ' LEFT JOIN roles AS r ON r.id = u.role_id'
            . ' ORDER BY m.created_at DESC LIMIT 50'
        );

        $users = Database::all(
            'SELECT u.id, u.name, u.email, u.is_active, u.last_login_at, u.created_at, r.name AS role_name'
            . ' FROM users AS u INNER JOIN roles AS r ON r.id = u.role_id'
            . ' ORDER BY u.created_at DESC'
        );

        View::render('admin/dashboard', [
            'title' => 'Yönetim Paneli — E2E İletişim',
            'description' => 'Mesaj ve kullanıcı yönetimi (rol korumalı).',
            'active' => 'admin',
            'messages' => $messages,
            'users' => $users,
            'statusLabels' => self::STATUS_LABELS,
            'canAnonymize' => Auth::isAdmin(),
            'flash' => flash(),
        ]);
    }

    public function updateStatus(): void
    {
        $messageId = (int) ($_POST['message_id'] ?? 0);
        $status = (string) ($_POST['status'] ?? '');

        if ($messageId <= 0 || !in_array($status, self::MESSAGE_STATUSES, true)) {
            set_flash('error', 'Geçersiz mesaj veya durum değeri.');
            redirect('/admin');
        }

        Database::run(
            'UPDATE messages SET status = :status WHERE id = :id',
            [':status' => $status, ':id' => $messageId]
        );

        set_flash('success', 'Mesaj durumu güncellendi: ' . self::STATUS_LABELS[$status]);
        redirect('/admin');
    }

    public function anonymize(): void
    {
        $userId = (int) ($_POST['user_id'] ?? 0);
        $reason = trim((string) ($_POST['reason'] ?? ''));
        if ($reason === '') {
            $reason = 'KVKK m.5/2(e) ve m.11 kapsamında silme (anonimleştirme) talebi';
        }

        $user = Database::one(
            'SELECT id, name, email FROM users WHERE id = :id LIMIT 1',
            [':id' => $userId]
        );
        if ($user === null || $userId === Auth::userId()) {
            set_flash('error', 'Kullanıcı bulunamadı veya kendi hesabınız anonimleştirilemez.');
            redirect('/admin');
        }

        $connection = Database::connection();
        $connection->beginTransaction();
        try {
            // Fiziksel silme yok: kimlik alanları anonimleştirilir, erişim kapatılır.
            $statement = Database::run(
                'UPDATE users SET name = :name, email = :email, password_hash = :password_hash, is_active = 0'
                . ' WHERE id = :id AND is_active = 1',
                [
                    ':name' => 'Anonimleştirilmiş Kullanıcı',
                    ':email' => 'anonim-' . $userId . '@anonim.local',
                    ':password_hash' => bin2hex(random_bytes(16)),
                    ':id' => $userId,
                ]
            );
            if ($statement->rowCount() === 0) {
                $connection->rollBack();
                set_flash('error', 'Bu kullanıcı zaten anonimleştirilmiş.');
                redirect('/admin');
            }
            Database::run(
                'INSERT INTO anonymization_log (entity, entity_id, user_id, action, basis, performed_by, reason)'
                . ' VALUES (:entity, :entity_id, :user_id, :action, :basis, :performed_by, :reason)',
                [
                    ':entity' => 'users',
                    ':entity_id' => $userId,
                    ':user_id' => $userId,
                    ':action' => 'anonymize',
                    ':basis' => 'KVKK m.5/2(e) ve m.11 — ilgili kişinin silme hakkı',
                    ':performed_by' => Auth::userId(),
                    ':reason' => mb_substr($reason, 0, 255),
                ]
            );
            $connection->commit();
        } catch (Throwable $exception) {
            $connection->rollBack();
            throw $exception;
        }

        set_flash('success', 'Kullanıcı anonimleştirildi ve iz kaydı (anonymization_log) oluşturuldu.');
        redirect('/admin');
    }
}
