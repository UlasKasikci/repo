<?php

use App\View;

/** @var list<array<string, mixed>> $users */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page">
    <h1>Kullanıcılar</h1>
    <p class="page__lead">Yalnızca admin rolüne açık kullanıcı listesi.</p>

    <?php if (($users ?? []) === []): ?>
        <p class="empty">Kullanıcı bulunmuyor.</p>
    <?php else: ?>
        <div class="table-wrap">
            <table class="table">
                <caption>Panel kullanıcıları</caption>
                <thead>
                <tr>
                    <th scope="col">ID</th>
                    <th scope="col">Ad Soyad</th>
                    <th scope="col">E-posta</th>
                    <th scope="col">Rol</th>
                    <th scope="col">Aktif</th>
                    <th scope="col">Kayıt Tarihi</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($users as $user): ?>
                    <tr>
                        <td><?= View::e($user['id'] ?? '') ?></td>
                        <td><?= View::e($user['full_name'] ?? '') ?></td>
                        <td><?= View::e($user['email'] ?? '') ?></td>
                        <td><span class="badge"><?= View::e($user['role_name'] ?? '') ?></span></td>
                        <td><?= ((int) ($user['is_active'] ?? 0)) === 1 ? 'Evet' : 'Hayır' ?></td>
                        <td><?= View::e($user['created_at'] ?? '') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
