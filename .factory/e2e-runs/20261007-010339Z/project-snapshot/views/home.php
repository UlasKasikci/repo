<?php

use App\View;

require BASE_PATH . '/views/layout/header.php';
?>
<section class="hero">
    <h1>Kurumsal iletişim, KVKK uyumlu altyapıyla.</h1>
    <p class="hero__lead">
        E2E İletişim; ziyaretçi taleplerini güvenli biçimde toplayan, rol korumalı yönetim
        paneliyle işleyen ve veri işleme süreçlerini şeffaf kılan kurumsal bir iletişim
        platformudur.
    </p>
    <p class="hero__actions">
        <a class="btn btn--primary" href="/iletisim">Bize Ulaşın</a>
        <a class="btn btn--ghost" href="/yasal/aydinlatma">Veri Politikamızı Okuyun</a>
    </p>
</section>

<section class="features" aria-labelledby="features-title">
    <h2 id="features-title">Neler sunuyoruz?</h2>
    <div class="features__grid">
        <article class="card">
            <h3>Güvenli İletişim Formu</h3>
            <p>Form verileri PDO prepared statement ile korunur; spam koruması ve rıza kaydı
                varsayılan olarak etkilidir.</p>
        </article>
        <article class="card">
            <h3>Rol Korumalı Panel</h3>
            <p>Mesaj ve kullanıcı yönetimi admin/moderator rolleriyle sınırlandırılır;
                yetkisiz erişim 401/403 ile engellenir.</p>
        </article>
        <article class="card">
            <h3>KVKK Uyumlu Veri İşleme</h3>
            <p>Ham IP saklanmaz (SHA-256 özeti), açık rıza kaydı tutulur ve yasal metinler
                şeffaf biçimde sunulur.</p>
        </article>
    </div>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
