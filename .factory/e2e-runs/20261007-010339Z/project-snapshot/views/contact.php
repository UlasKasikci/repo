<?php

use App\CSRF;
use App\View;

/**
 * @var list<string> $errors
 * @var array{full_name: string, email: string, phone: string, subject: string, body: string} $old
 * @var bool $sent
 */
require BASE_PATH . '/views/layout/header.php';
?>
<section class="page">
    <h1>İletişim</h1>
    <p class="page__lead">
        Formu doldurarak bize ulaşabilirsiniz. Verileriniz
        <a href="/yasal/aydinlatma">KVKK Aydınlatma Metni</a> kapsamında, yalnızca talebinize
        yanıt vermek amacıyla işlenir.
    </p>

    <?php if ($sent ?? false): ?>
        <div class="alert alert--success" role="status">
            <p><strong>Mesajınız alındı.</strong> En kısa sürede size dönüş yapılacaktır.</p>
        </div>
    <?php endif; ?>

    <?php if (($errors ?? []) !== []): ?>
        <div class="alert alert--error" role="alert">
            <p><strong>Form gönderilemedi. Lütfen aşağıdaki alanları kontrol edin:</strong></p>
            <ul>
                <?php foreach ($errors as $error): ?>
                    <li><?= View::e($error) ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>

    <form method="post" action="/iletisim" class="form" novalidate>
        <?= View::e(CSRF::field()) ?>
        <p class="form__honeypot" aria-hidden="true">
            <label for="website">Website</label>
            <input type="text" id="website" name="website" tabindex="-1" autocomplete="off">
        </p>

        <div class="form__field">
            <label for="full_name">Ad Soyad <span aria-hidden="true">*</span></label>
            <input type="text" id="full_name" name="full_name" required maxlength="120"
                   autocomplete="name" value="<?= View::e($old['full_name'] ?? '') ?>">
        </div>

        <div class="form__field">
            <label for="email">E-posta <span aria-hidden="true">*</span></label>
            <input type="email" id="email" name="email" required maxlength="190"
                   autocomplete="email" value="<?= View::e($old['email'] ?? '') ?>">
        </div>

        <div class="form__field">
            <label for="phone">Telefon (isteğe bağlı)</label>
            <input type="tel" id="phone" name="phone" maxlength="32"
                   autocomplete="tel" value="<?= View::e($old['phone'] ?? '') ?>">
        </div>

        <div class="form__field">
            <label for="subject">Konu <span aria-hidden="true">*</span></label>
            <input type="text" id="subject" name="subject" required maxlength="150"
                   value="<?= View::e($old['subject'] ?? '') ?>">
        </div>

        <div class="form__field">
            <label for="body">Mesajınız <span aria-hidden="true">*</span></label>
            <textarea id="body" name="body" rows="6" required maxlength="5000"><?= View::e($old['body'] ?? '') ?></textarea>
        </div>

        <div class="form__field form__field--checkbox">
            <input type="checkbox" id="consent" name="consent" value="1" required>
            <label for="consent">
                <a href="/yasal/aydinlatma">KVKK Aydınlatma Metni</a>'ni okudum; iletişim
                talebimin işlenmesine açık rıza veriyorum.
            </label>
        </div>

        <button type="submit" class="btn btn--primary">Mesajı Gönder</button>
    </form>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
