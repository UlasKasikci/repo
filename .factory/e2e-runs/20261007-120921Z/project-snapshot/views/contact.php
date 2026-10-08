<?php
/**
 * GET /iletisim — iletişim formu.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 * @var array<string, string> $errors alan bazlı doğrulama hataları
 * @var array<string, string> $old      eski (yeniden doldurulan) değerler
 * @var array{type: string, message: string}|null $flash
 */

use App\Core\Csrf;

$errors = $errors ?? [];
$old = $old ?? [];

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow">
        <h1 class="page__title">İletişim</h1>
        <p class="page__lead">
            Bize soru, öneri veya iş birliği talebinizi iletin; ekibimiz en kısa
            sürede yanıtlar. Zorunlu alanlar yıldız (*) ile işaretlidir.
        </p>

        <?php require APP_ROOT . '/views/partials/flash.php'; ?>

        <form class="form" method="post" action="<?= e(url('/iletisim')) ?>" novalidate>
            <?= Csrf::field() ?>

            <div class="form__field">
                <label for="name">Ad Soyad *</label>
                <input type="text" id="name" name="name" required maxlength="100"
                       value="<?= e($old['name'] ?? '') ?>"
                       aria-describedby="<?= isset($errors['name']) ? 'name-error' : '' ?>">
                <?php if (isset($errors['name'])): ?>
                    <p class="form__error" id="name-error"><?= e($errors['name']) ?></p>
                <?php endif; ?>
            </div>

            <div class="form__field">
                <label for="email">E-posta *</label>
                <input type="email" id="email" name="email" required maxlength="190"
                       value="<?= e($old['email'] ?? '') ?>"
                       aria-describedby="<?= isset($errors['email']) ? 'email-error' : '' ?>">
                <?php if (isset($errors['email'])): ?>
                    <p class="form__error" id="email-error"><?= e($errors['email']) ?></p>
                <?php endif; ?>
            </div>

            <div class="form__field">
                <label for="subject">Konu *</label>
                <input type="text" id="subject" name="subject" required maxlength="200"
                       value="<?= e($old['subject'] ?? '') ?>"
                       aria-describedby="<?= isset($errors['subject']) ? 'subject-error' : '' ?>">
                <?php if (isset($errors['subject'])): ?>
                    <p class="form__error" id="subject-error"><?= e($errors['subject']) ?></p>
                <?php endif; ?>
            </div>

            <div class="form__field">
                <label for="message">Mesajınız *</label>
                <textarea id="message" name="message" rows="7" required maxlength="5000"
                          aria-describedby="<?= isset($errors['message']) ? 'message-error' : '' ?>"><?= e($old['message'] ?? '') ?></textarea>
                <?php if (isset($errors['message'])): ?>
                    <p class="form__error" id="message-error"><?= e($errors['message']) ?></p>
                <?php endif; ?>
            </div>

            <!-- Honeypot: gerçek kullanıcılar bu alanı görmez/doldurmaz; doluysa istek bot'tur. -->
            <div class="form__hp" aria-hidden="true">
                <label for="website">Web sitesi</label>
                <input type="text" id="website" name="website" tabindex="-1" autocomplete="off">
            </div>

            <div class="form__actions">
                <button type="submit" class="btn btn--primary">Mesajı Gönder</button>
            </div>

            <p class="form__note">
                Formu göndererek
                <a href="<?= e(url('/kvkk/aydinlatma')) ?>">KVKK Aydınlatma Metni</a>
                ve
                <a href="<?= e(url('/kvkk/gizlilik')) ?>">Gizlilik Politikası</a>'nı
                okuduğunuzu kabul ettiğinizi belirtirsiniz.
            </p>
        </form>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
