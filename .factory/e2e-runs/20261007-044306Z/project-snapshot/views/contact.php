<?php

/**
 * App-Fabrika Web Edition — iletişim formu.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

$flash = arr($data['flash'] ?? null);
$errors = arr($flash['errors'] ?? null);
$old = arr($flash['old'] ?? null);
$ok = $flash['ok'] ?? null;

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>İletişim</h1>
    <p>Bize yazın — talebinizi en kısa sürede değerlendirip dönüş yapalım.</p>
  </div>
</section>

<section class="contact">
  <div class="container contact__grid">
    <div class="contact__info">
      <h2>İletişim Bilgileri</h2>
      <address>
        <p>App-Fabrika<br>Örnek Mah. Teknoloji Cad. No: 1<br>34100 İstanbul</p>
        <p><a href="mailto:info@example.com">info@example.com</a></p>
      </address>
      <h3>Kişisel Verileriniz</h3>
      <p>
        Formu gönderdiğinizde ad-soyad, e-posta, telefon (isteğe bağlı) ve mesaj içeriğiniz;
        <a href="<?= e(url('/yasal/aydinlatma')) ?>">KVKK Aydınlatma Metni</a> kapsamında
        yalnızca talebinizin yönetimi amacıyla işlenir. IP adresiniz anonimleştirilmiş özetle saklanır.
      </p>
    </div>

    <div class="contact__form-wrap">
      <?php if (is_string($ok) && $ok !== '') : ?>
      <p class="alert alert--success" role="status"><?= e($ok) ?></p>
      <?php endif; ?>

      <?php if ($errors !== []) : ?>
      <p class="alert alert--error" role="alert">Lütfen aşağıdaki hataları düzeltin.</p>
      <?php endif; ?>

      <form class="contact-form" method="post" action="<?= e(url('/iletisim')) ?>" novalidate>
        <?= Csrf::field() ?>

        <div class="form-field">
          <label for="cf-name">Ad Soyad <span aria-hidden="true">*</span></label>
          <input id="cf-name" name="name" type="text" maxlength="120" required
                 value="<?= e($old['name'] ?? '') ?>"
                 aria-describedby="<?= isset($errors['name']) ? 'cf-name-error' : '' ?>">
          <?php if (isset($errors['name'])) : ?>
          <p class="form-error" id="cf-name-error"><?= e($errors['name']) ?></p>
          <?php endif; ?>
        </div>

        <div class="form-field">
          <label for="cf-email">E-posta <span aria-hidden="true">*</span></label>
          <input id="cf-email" name="email" type="email" maxlength="190" required
                 value="<?= e($old['email'] ?? '') ?>"
                 aria-describedby="<?= isset($errors['email']) ? 'cf-email-error' : '' ?>">
          <?php if (isset($errors['email'])) : ?>
          <p class="form-error" id="cf-email-error"><?= e($errors['email']) ?></p>
          <?php endif; ?>
        </div>

        <div class="form-field">
          <label for="cf-phone">Telefon (isteğe bağlı)</label>
          <input id="cf-phone" name="phone" type="tel" maxlength="32"
                 value="<?= e($old['phone'] ?? '') ?>"
                 aria-describedby="<?= isset($errors['phone']) ? 'cf-phone-error' : '' ?>">
          <?php if (isset($errors['phone'])) : ?>
          <p class="form-error" id="cf-phone-error"><?= e($errors['phone']) ?></p>
          <?php endif; ?>
        </div>

        <div class="form-field">
          <label for="cf-subject">Konu <span aria-hidden="true">*</span></label>
          <input id="cf-subject" name="subject" type="text" maxlength="190" required
                 value="<?= e($old['subject'] ?? '') ?>"
                 aria-describedby="<?= isset($errors['subject']) ? 'cf-subject-error' : '' ?>">
          <?php if (isset($errors['subject'])) : ?>
          <p class="form-error" id="cf-subject-error"><?= e($errors['subject']) ?></p>
          <?php endif; ?>
        </div>

        <div class="form-field">
          <label for="cf-body">Mesajınız <span aria-hidden="true">*</span></label>
          <textarea id="cf-body" name="body" rows="6" maxlength="5000" required
                    aria-describedby="<?= isset($errors['body']) ? 'cf-body-error' : '' ?>"><?= e($old['body'] ?? '') ?></textarea>
          <?php if (isset($errors['body'])) : ?>
          <p class="form-error" id="cf-body-error"><?= e($errors['body']) ?></p>
          <?php endif; ?>
        </div>

        <div class="form-field form-field--checkbox">
          <input id="cf-consent" name="kvkk_consent" type="checkbox" value="1"
                 aria-describedby="<?= isset($errors['kvkk_consent']) ? 'cf-consent-error' : '' ?>">
          <label for="cf-consent">
            <a href="<?= e(url('/yasal/aydinlatma')) ?>">KVKK Aydınlatma Metni</a>'ni okudum;
            verilerimin talebimin yönetimi amacıyla işlenmesine onay veriyorum. <span aria-hidden="true">*</span>
          </label>
          <?php if (isset($errors['kvkk_consent'])) : ?>
          <p class="form-error" id="cf-consent-error"><?= e($errors['kvkk_consent']) ?></p>
          <?php endif; ?>
        </div>

        <button class="btn btn--primary" type="submit">Mesajı Gönder</button>
      </form>
    </div>
  </div>
</section>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
