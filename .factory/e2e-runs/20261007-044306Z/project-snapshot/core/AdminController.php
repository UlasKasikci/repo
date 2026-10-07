<?php

declare(strict_types=1);

/**
 * App-Fabrika Web Edition — yönetim paneli denetleyicisi (rol korumalı).
 *
 * /admin/mesajlar   → Admin + Moderatör (listeleme, durum güncelleme)
 * /admin/kullanicilar → yalnız Admin (kullanıcı listesi)
 */

final class AdminController extends Controller
{
    public function messages(): void
    {
        $this->requireRole([Auth::ROLE_ADMIN, Auth::ROLE_MODERATOR]);

        $this->view('admin/messages', [
            'pageTitle' => 'Mesajlar · Yönetim',
            'pageDesc' => 'İletişim formundan gelen talepler.',
            'messages' => MessageRepository::recent(200),
        ]);
    }

    public function updateStatus(): void
    {
        $this->requireRole([Auth::ROLE_ADMIN, Auth::ROLE_MODERATOR]);
        $this->requireCsrf();

        $idRaw = $_POST['id'] ?? null;
        $status = $_POST['status'] ?? null;

        if (!is_string($idRaw) || ctype_digit($idRaw) === false) {
            $this->forbidden();
        }
        if (!is_string($status) || in_array($status, ['new', 'read', 'replied'], true) === false) {
            $this->forbidden();
        }

        MessageRepository::updateStatus((int) $idRaw, $status);

        Flash::set(['ok' => 'Mesaj durumu güncellendi.']);
        $this->redirect('/admin/mesajlar');
    }

    public function users(): void
    {
        $this->requireRole([Auth::ROLE_ADMIN]);

        $this->view('admin/users', [
            'pageTitle' => 'Kullanıcılar · Yönetim',
            'pageDesc' => 'Kayıtlı kullanıcılar ve rolleri (RBAC).',
            'users' => UserRepository::all(),
        ]);
    }
}
