<?php
/**
 * GET /kvkk/gizlilik — Gizlilik Politikası.
 * KVKK + GDPR (2016/679) referanslı gerçek politika metni — yer tutucu değil.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow legal">
        <h1 class="page__title">Gizlilik Politikası</h1>
        <p class="legal__meta">Son güncelleme: 01.10.2026 &middot; Metin sürümü: 1.0.0</p>

        <p>
            Bu politika, E2E İletişim tarafından işlenen kişisel verilerin hangi
            ilkelere uygun olarak ele alındığını açıklar. 6698 sayılı KVKK ve
            Avrupa Birliği Genel Veri Koruma Tüzüğü (GDPR — 2016/679) uyumlu
            olarak hazırlanmıştır.
        </p>

        <h2 class="section-title">1. Veri İşleme İlkeleri</h2>
        <ul>
            <li>
                <strong>Hukuka ve dürüstlük kuralına uygunluk (KVKK m.4/1, GDPR Art. 5/1-a):</strong>
                kişisel veriler yalnız yasal sebeplere dayanılarak ve şeffaf biçimde işlenir.
            </li>
            <li>
                <strong>Doğru ve güncel olma (KVKK m.4/2, GDPR Art. 5/1-d):</strong>
                işlenen verilerin doğru ve güncel olmaması halinde düzeltme talepleri
                KVKK m.11 kapsamında karşılanır.
            </li>
            <li>
                <strong>Belirli, açık ve meşru amaç (KVKK m.4/3, GDPR Art. 5/1-b):</strong>
                veriler yalnız bu politika ve Aydınlatma Metni'nde sayılan amaçlar için işlenir.
            </li>
            <li>
                <strong>Veri minimizasyonu (KVKK m.4/3, GDPR Art. 5/1-c):</strong>
                yalnız amacın ifası için gerekli olan veriler toplanır; iletişim
                formu ad, e-posta, konu ve mesaj dışında zorunlu alan istemez.
            </li>
            <li>
                <strong>Saklama sınırlılığı (KVKK m.4/4, GDPR Art. 5/1-e):</strong>
                veriler amacın gerektirdiği süre kadar saklanır; sonrasında anonimleştirilir
                ve işlem anonymization_log iz kaydıyla belgelenir.
            </li>
        </ul>

        <h2 class="section-title">2. Toplanan Veriler ve Kullanım</h2>
        <ul>
            <li><strong>İletişim formu:</strong> ad, e-posta, konu, mesaj — taleplerinize yanıt vermek için.</li>
            <li><strong>İşlem güvenliği:</strong> IP adresi, tarayıcı bilgisi — spam ve kötüye kullanım önleme (dakikada 3 mesaj üstü istekler sınırlandırılır).</li>
            <li><strong>Hesap ve oturum:</strong> e-posta, Argon2id ile şifrelenmiş parola özeti, son giriş zamanı — yönetim paneli erişimi.</li>
            <li><strong>Rıza kayıtları:</strong> çerez tercihi, rıza metni sürümü, IP adresi — KVKK m.5/1 ispat yükümlülüğü.</li>
        </ul>

        <h2 class="section-title">3. Güvenlik Önlemleri (GDPR Art. 32)</h2>
        <ul>
            <li>Tüm veritabanı sorguları parametreli ifadeler (prepared statements) ile çalıştırılır; SQL enjeksiyonuna karşı koruma sağlanır.</li>
            <li>Kullanıcı verisi arayüze yalnız HTML kaçışlama (escaping) ile basılır; XSS saldırılarına karşı koruma sağlanır.</li>
            <li>Parolalar Argon2id algoritmasıyla tek yönlü şifrelenir; düz metin parola hiçbir yerde saklanmaz.</li>
            <li>Oturum çerezleri HttpOnly, Secure ve SameSite=Strict işaretli olarak sunulur; oturum düzeltme (fixation) koruması uygulanır.</li>
            <li>Tüm form ve mutasyon isteklerinde benzersiz CSRF belirteci zorunludur.</li>
        </ul>

        <h2 class="section-title">4. Üçüncü Taraf Paylaşımı</h2>
        <p>
            Kişisel verileriniz pazarlama amacıyla üçüncü taraflara satılmaz veya
            paylaşılmaz. Veriler yalnız barındırma altyapısının çalışması için
            gerekli teknik sağlayıcılarla ve yasal zorunluluk halinde yetkili
            kamu kurum ve kuruluşlarıyla paylaşılabilir.
        </p>

        <h2 class="section-title">5. Haklarınız</h2>
        <p>
            GDPR Art. 15–22 ve KVKK m.11 kapsamındaki haklarınız (erişim,
            düzeltme, silme, işlemeyi kısıtlama, veri taşınabilirliği, itiraz,
            otomatik kararlara itiraz) için
            <a href="<?= e(url('/iletisim')) ?>">iletişim formunu</a>
            kullanabilirsiniz. Talepleriniz en geç otuz gün içinde yanıtlanır.
        </p>

        <h2 class="section-title">6. Çerezler</h2>
        <p>
            Çerez kullanımına ilişkin ayrıntılar için
            <a href="<?= e(url('/kvkk/cerez')) ?>">Çerez Politikası</a>'mıza
            bakabilirsiniz. Analitik çerezler yalnız açık onayınızla yüklenir;
            tercihinizi dilediğiniz zaman değiştirebilirsiniz.
        </p>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
