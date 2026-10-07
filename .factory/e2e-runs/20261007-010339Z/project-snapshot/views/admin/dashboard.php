<?php

use App\View;

/**
 * @var int $newCount
 * @var int $archivedCount
 * @var int $userCount
 */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page">
    <h1>Yönetim Paneli</h1>
    <p class="page__lead">Mesaj ve kullanıcı özetleri — rol korumalı bölüm.</p>

    <div class="stats">
        <article class="card card--stat">
            <h2>Yeni Mesaj</h2>
            <p class="stats__value"><?= View::e($newCount ?? 0) ?></p>
            <a href="/admin/mesajlar?status=new">Listele</a>
        </article>
        <article class="card card--stat">
            <h2>Arşivlenen</h2>
            <p class="stats__value"><?= View::e($archivedCount ?? 0) ?></p>
            <a href="/admin/mesajlar?status=archived">Listele</a>
        </article>
        <article class="card card--stat">
            <h2>Kullanıcı</h2>
            <p class="stats__value"><?= View::e($userCount ?? 0) ?></p>
            <a href="/admin/kullanicilar">Listele</a>
        </article>
    </div>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
