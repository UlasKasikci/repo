<?php
/**
 * GET /admin — yönetim paneli (mesaj + kullanıcı listesi).
 * POST /admin/mesaj-durum — mesaj durumu değişimi (Admin/Moderator).
 * POST /admin/anonimlestir — kullanıcı anonimleştirme (yalnız Admin).
 *
 * @var string $title
 * @var string $description
 * @var string $active
 * @var list<array<string, mixed>> $messages
 * @var list<array<string, mixed>> $users
 * @var array<string, string> $statusLabels
 * @var bool $canAnonymize
 * @var array{type: string, message: string}|null $flash
 */

use App\Core\Auth;
use App\Core\Csrf;

$canAnonymize = $canAnonymize ?? false;

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container">
        <h1 class="page__title">Yönetim Paneli</h1>
        <p class="page__lead">
            Mesaj yaşam döngüsü: Yeni &rarr; Okundu &rarr; Arşivlendi.
            <?= $canAnonymize ? 'Admin rolü kullanıcı anonimleştirebilir (KVKK m.11).' : 'Anonimleştirme yalnız Admin rolündedir.' ?>
        </p>

        <?php require APP_ROOT . '/views/partials/flash.php'; ?>

        <section class="panel" aria-labelledby="admin-messages-title">
            <h2 id="admin-messages-title" class="panel__title">Mesajlar</h2>
            <?php if ($messages === []): ?>
                <p class="panel__empty">Henüz mesaj yok.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="table">
                        <caption class="visually-hidden">İletişim mesajları ve durum yönetimi</caption>
                        <thead>
                        <tr>
                            <th scope="col">#</th>
                            <th scope="col">Ad</th>
                            <th scope="col">E-posta</th>
                            <th scope="col">Konu</th>
                            <th scope="col">Durum</th>
                            <th scope="col">Tarih</th>
                            <th scope="col">Durum Değiştir</th>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($messages as $message): ?>
                            <tr>
                                <td data-label="#"><?= e((string) ($message['id'] ?? '')) ?></td>
                                <td data-label="Ad"><?= e((string) ($message['name'] ?? '')) ?></td>
                                <td data-label="E-posta"><?= e((string) ($message['email'] ?? '')) ?></td>
                                <td data-label="Konu"><?= e((string) ($message['subject'] ?? '')) ?></td>
                                <td data-label="Durum">
                                    <span class="badge badge--<?= e((string) ($message['status'] ?? 'new')) ?>">
                                        <?= e($statusLabels[(string) ($message['status'] ?? '')] ?? (string) ($message['status'] ?? '')) ?>
                                    </span>
                                </td>
                                <td data-label="Tarih"><?= e((string) ($message['created_at'] ?? '')) ?></td>
                                <td data-label="Durum Değiştir">
                                    <form class="inline-form" method="post" action="<?= e(url('/admin/mesaj-durum')) ?>">
                                        <?= Csrf::field() ?>
                                        <input type="hidden" name="message_id" value="<?= e((string) ($message['id'] ?? '')) ?>">
                                        <label class="visually-hidden" for="status-<?= e((string) ($message['id'] ?? '')) ?>">Yeni durum</label>
                                        <select id="status-<?= e((string) ($message['id'] ?? '')) ?>" name="status" class="input--small">
                                            <?php foreach ($statusLabels as $value => $label): ?>
                                                <option value="<?= e($value) ?>"<?= (string) ($message['status'] ?? '') === $value ? ' selected' : '' ?>><?= e($label) ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                        <button type="submit" class="btn btn--ghost btn--small">Kaydet</button>
                                    </form>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>

        <section class="panel" aria-labelledby="admin-users-title">
            <h2 id="admin-users-title" class="panel__title">Kullanıcılar</h2>
            <?php if ($users === []): ?>
                <p class="panel__empty">Kullanıcı yok.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="table">
                        <caption class="visually-hidden">Sistem kullanıcıları</caption>
                        <thead>
                        <tr>
                            <th scope="col">#</th>
                            <th scope="col">Ad</th>
                            <th scope="col">E-posta</th>
                            <th scope="col">Rol</th>
                            <th scope="col">Durum</th>
                            <th scope="col">Son Giriş</th>
                            <?php if ($canAnonymize): ?>
                                <th scope="col">KVKK Anonimleştirme</th>
                            <?php endif; ?>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($users as $user): ?>
                            <tr>
                                <td data-label="#"><?= e((string) ($user['id'] ?? '')) ?></td>
                                <td data-label="Ad"><?= e((string) ($user['name'] ?? '')) ?></td>
                                <td data-label="E-posta"><?= e((string) ($user['email'] ?? '')) ?></td>
                                <td data-label="Rol"><?= e((string) ($user['role_name'] ?? '')) ?></td>
                                <td data-label="Durum">
                                    <?php if ((int) ($user['is_active'] ?? 0) === 1): ?>
                                        <span class="badge badge--read">Aktif</span>
                                    <?php else: ?>
                                        <span class="badge badge--archived">Kapalı</span>
                                    <?php endif; ?>
                                </td>
                                <td data-label="Son Giriş"><?= e((string) ($user['last_login_at'] ?? '—')) ?></td>
                                <?php if ($canAnonymize): ?>
                                    <td data-label="KVKK Anonimleştirme">
                                        <?php if ((int) ($user['id'] ?? 0) === Auth::userId()): ?>
                                            <span class="panel__note">(kendi hesabınız)</span>
                                        <?php elseif ((int) ($user['is_active'] ?? 0) !== 1): ?>
                                            <span class="panel__note">(anonimleştirilmiş)</span>
                                        <?php else: ?>
                                            <form class="inline-form" method="post" action="<?= e(url('/admin/anonimlestir')) ?>">
                                                <?= Csrf::field() ?>
                                                <input type="hidden" name="user_id" value="<?= e((string) ($user['id'] ?? '')) ?>">
                                                <button type="submit" class="btn btn--danger btn--small"
                                                        data-confirm="Bu kullanıcı anonimleştirilecek. Onaylıyor musunuz?">
                                                    Anonimleştir
                                                </button>
                                            </form>
                                        <?php endif; ?>
                                    </td>
                                <?php endif; ?>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
