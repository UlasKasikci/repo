<?php

use App\CSRF;
use App\View;

/**
 * @var list<array<string, mixed>> $messages
 * @var string $filter
 */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page">
    <h1>Mesajlar</h1>
    <p class="page__lead">İletişim formundan gelen kayıtlar (son 100).</p>

    <nav class="filter" aria-label="Durum filtresi">
        <ul>
            <li><a href="/admin/mesajlar" <?= ($filter ?? '') === '' ? 'aria-current="page"' : '' ?>>Tümü</a></li>
            <li><a href="/admin/mesajlar?status=new" <?= ($filter ?? '') === 'new' ? 'aria-current="page"' : '' ?>>Yeni</a></li>
            <li><a href="/admin/mesajlar?status=read" <?= ($filter ?? '') === 'read' ? 'aria-current="page"' : '' ?>>Okundu</a></li>
            <li><a href="/admin/mesajlar?status=archived" <?= ($filter ?? '') === 'archived' ? 'aria-current="page"' : '' ?>>Arşiv</a></li>
        </ul>
    </nav>

    <?php if (($messages ?? []) === []): ?>
        <p class="empty">Bu filtrede mesaj bulunmuyor.</p>
    <?php else: ?>
        <div class="table-wrap">
            <table class="table">
                <caption>İletişim formu kayıtları</caption>
                <thead>
                <tr>
                    <th scope="col">ID</th>
                    <th scope="col">Ad Soyad</th>
                    <th scope="col">E-posta</th>
                    <th scope="col">Konu</th>
                    <th scope="col">Durum</th>
                    <th scope="col">Rıza</th>
                    <th scope="col">Tarih</th>
                    <th scope="col">İşlem</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($messages as $message): ?>
                    <tr>
                        <td><?= View::e($message['id'] ?? '') ?></td>
                        <td><?= View::e($message['full_name'] ?? '') ?></td>
                        <td><?= View::e($message['email'] ?? '') ?></td>
                        <td><?= View::e($message['subject'] ?? '') ?></td>
                        <td><span class="badge badge--<?= View::e($message['status'] ?? 'new') ?>"><?= View::e($message['status'] ?? '') ?></span></td>
                        <td><?= ((int) ($message['consent_given'] ?? 0)) === 1 ? 'Verildi' : 'Yok' ?></td>
                        <td><?= View::e($message['created_at'] ?? '') ?></td>
                        <td>
                            <form method="post" action="/admin/mesajlar" class="inline-form">
                                <?= View::e(CSRF::field()) ?>
                                <input type="hidden" name="id" value="<?= View::e($message['id'] ?? '') ?>">
                                <label>
                                    <span class="visually-hidden">Yeni durum (mesaj #<?= View::e($message['id'] ?? '') ?>)</span>
                                    <select name="status">
                                        <option value="new" <?= ($message['status'] ?? '') === 'new' ? 'selected' : '' ?>>Yeni</option>
                                        <option value="read" <?= ($message['status'] ?? '') === 'read' ? 'selected' : '' ?>>Okundu</option>
                                        <option value="archived" <?= ($message['status'] ?? '') === 'archived' ? 'selected' : '' ?>>Arşiv</option>
                                    </select>
                                </label>
                                <button type="submit" class="btn btn--small">Kaydet</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
