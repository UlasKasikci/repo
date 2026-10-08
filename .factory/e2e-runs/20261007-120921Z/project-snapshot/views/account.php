<?php
/**
 * GET /hesabim — kimlikli kullanıcının kendi kayıtları.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 * @var string $userName
 * @var string $roleName
 * @var list<array<string, mixed>> $messages kendi iletişim mesajları
 * @var list<array<string, mixed>> $consents kendi rıza kayıtları
 * @var array{type: string, message: string}|null $flash
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container">
        <h1 class="page__title">Hesabım</h1>
        <p class="page__lead">
            Hoş geldiniz, <strong><?= e($userName) ?></strong> (<?= e($roleName) ?>).
            Bu sayfada yalnız kendi kayıtlarınızı görürsünüz.
        </p>

        <?php require APP_ROOT . '/views/partials/flash.php'; ?>

        <section class="panel" aria-labelledby="account-messages-title">
            <h2 id="account-messages-title" class="panel__title">İletişim Mesajlarım</h2>
            <?php if ($messages === []): ?>
                <p class="panel__empty">Henüz bir iletişim mesajı göndermediniz.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="table">
                        <caption class="visually-hidden">Gönderdiğiniz iletişim mesajları</caption>
                        <thead>
                        <tr>
                            <th scope="col">Konu</th>
                            <th scope="col">Durum</th>
                            <th scope="col">Tarih</th>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($messages as $message): ?>
                            <tr>
                                <td data-label="Konu"><?= e((string) ($message['subject'] ?? '')) ?></td>
                                <td data-label="Durum">
                                    <span class="badge badge--<?= e((string) ($message['status'] ?? 'new')) ?>">
                                        <?= e((string) ($message['status'] ?? '')) ?>
                                    </span>
                                </td>
                                <td data-label="Tarih"><?= e((string) ($message['created_at'] ?? '')) ?></td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>

        <section class="panel" aria-labelledby="account-consents-title">
            <h2 id="account-consents-title" class="panel__title">Rıza Kayıtlarım</h2>
            <?php if ($consents === []): ?>
                <p class="panel__empty">Henüz bir rıza kaydınız yok.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="table">
                        <caption class="visually-hidden">Verdiğiniz rıza kayıtları</caption>
                        <thead>
                        <tr>
                            <th scope="col">Tür</th>
                            <th scope="col">Amaç</th>
                            <th scope="col">Onay</th>
                            <th scope="col">Metin Sürümü</th>
                            <th scope="col">Tarih</th>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($consents as $consent): ?>
                            <tr>
                                <td data-label="Tür"><?= e((string) ($consent['consent_type'] ?? '')) ?></td>
                                <td data-label="Amaç"><?= e((string) ($consent['purpose'] ?? '')) ?></td>
                                <td data-label="Onay">
                                    <?php if ((int) ($consent['granted'] ?? 0) === 1): ?>
                                        <span class="badge badge--read">Onaylı</span>
                                    <?php else: ?>
                                        <span class="badge badge--archived">Reddedildi</span>
                                    <?php endif; ?>
                                </td>
                                <td data-label="Metin Sürümü"><?= e((string) ($consent['consent_text_version'] ?? '')) ?></td>
                                <td data-label="Tarih"><?= e((string) ($consent['created_at'] ?? '')) ?></td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
            <p class="panel__note">
                Çerez tercihlerinizi alt bilgideki "Çerez Tercihleri" bağlantısından
                dilediğiniz zaman değiştirebilirsiniz.
            </p>
        </section>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
