<?php
/**
 * GET / — ana sayfa (kurumsal iletişim vitrini).
 *
 * @var string $title
 * @var string $description
 * @var string $active
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="hero">
    <div class="container">
        <h1 class="hero__title"><?= e($title) ?></h1>
        <p class="hero__lead">
            E2E İletişim, kurumlar ile müşterileri arasındaki iletişimi güvenli ve
            şeffaf bir kanala taşıyan kurumsal iletişim platformudur. Soru, öneri ve
            iş birliği talepleriniz için iletişim formunu kullanabilirsiniz.
        </p>
        <div class="hero__actions">
            <a class="btn btn--primary" href="<?= e(url('/iletisim')) ?>">Bize Yazın</a>
            <a class="btn btn--ghost" href="<?= e(url('/kvkk/aydinlatma')) ?>">KVKK Aydınlatma Metni</a>
        </div>
    </div>
</section>

<section class="features" aria-labelledby="features-title">
    <div class="container">
        <h2 id="features-title" class="section-title">Neden E2E İletişim?</h2>
        <div class="features__grid">
            <article class="card">
                <h3 class="card__title">Güvenli İletişim</h3>
                <p class="card__text">
                    Tüm mesajlar sunucu tarafında doğrulanır; CSRF koruması ve
                    Argon2id parola saklaması ile iletişim güvenli kanaldan geçer.
                </p>
            </article>
            <article class="card">
                <h3 class="card__title">Şeffaf Veri Yönetimi</h3>
                <p class="card__text">
                    Kişisel veriler KVKK kapsamında işlenir; rıza kayıtları ve
                    anonimleştirme izleri şeffaf biçimde tutulur.
                </p>
            </article>
            <article class="card">
                <h3 class="card__title">Hızlı Yanıt</h3>
                <p class="card__text">
                    Mesajlar yönetim paneline düşer; ekibimiz mesajları öncelik
                    sırasına göre en kısa sürede yanıtlar.
                </p>
            </article>
        </div>
    </div>
</section>

<section class="cta" aria-labelledby="cta-title">
    <div class="container">
        <h2 id="cta-title" class="section-title">Görüşmek Üzere</h2>
        <p class="cta__text">
            Sorularınızı iletmek için iletişim formunu doldurmanız yeterli.
            Kayıtlarınızı takip etmek için giriş yapabilirsiniz.
        </p>
        <div class="hero__actions">
            <a class="btn btn--primary" href="<?= e(url('/iletisim')) ?>">İletişim Formu</a>
            <a class="btn btn--ghost" href="<?= e(url('/giris')) ?>">Giriş Yap</a>
        </div>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
