<?php
/**
 * GET /kvkk/aydinlatma — KVKK Aydınlatma Metni.
 * 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) m.10 uyarınca
 * gerçek yasal metin — yer tutucu değil.
 *
 * @var string $title
 * @var string $description
 * @var string $active
 */

require APP_ROOT . '/views/partials/header.php';
?>

<section class="page">
    <div class="container container--narrow legal">
        <h1 class="page__title">KVKK Aydınlatma Metni</h1>
        <p class="legal__meta">Son güncelleme: 01.10.2026 &middot; Metin sürümü: 1.0.0</p>

        <p>
            6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") m.10 uyarınca
            veri sorumlusu sıfatıyla hareket eden E2E İletişim ("Kurum"), kişisel
            verilerinizin aşağıda açıklanan kapsamda işlenmesi hususunda sizi
            bilgilendirmektedir.
        </p>

        <h2 class="section-title">1. Veri Sorumlusu</h2>
        <p>
            Kişisel verileriniz, veri sorumlusu olarak E2E İletişim tarafından;
            KVKK m.5/2/ç (sözleşmenin kurulması veya ifasıyla doğrudan ilgili
            olması) ve m.5/2/f (ilgili kişinin temel hak ve özgürlüklerine
            zarar vermemek kaydıyla, veri sorumlusunun meşru menfaati) hukuki
            sebeplerine dayanılarak aşağıda sayılan amaçlarla işlenmektedir.
        </p>

        <h2 class="section-title">2. İşlenen Kişisel Veriler</h2>
        <ul>
            <li>
                <strong>Kimlik ve iletişim verileri:</strong> iletişim formunda
                verdiğiniz ad, e-posta adresi ve mesaj içeriğiniz (KVKK m.5/1:
                rızaya dayalı işleme kapsamında da kullanılabilir).
            </li>
            <li>
                <strong>İşlem güvenliği verileri:</strong> istek IP adresiniz ve
                tarayıcı bilgisi (user-agent); kötüye kullanım (spam) önleme,
                istek oranı sınırlama ve KVKK iz tutma amaçlarıyla işlenir.
            </li>
            <li>
                <strong>Oturum verileri:</strong> yönetim paneli girişlerinde
                e-posta adresiniz, parola özetiniz (Argon2id algoritmasıyla
                tek yönlü şifrelenmiş), son giriş zamanınız ve oturum kimliği.
            </li>
            <li>
                <strong>Rıza verileri:</strong> çerez onay tercihleriniz ve yasal
                metin onaylarınız; rıza metni sürümü ve IP adresi ile birlikte
                user_consents kaydı olarak tutulur.
            </li>
        </ul>

        <h2 class="section-title">3. Kişisel Verilerin İşlenme Amaçları</h2>
        <ul>
            <li>İletişim formu aracılığıyla ilettiğiniz talep, soru ve önerilere yanıt verilmesi.</li>
            <li>Hizmet kalitesinin ölçülmesi ve iyileştirilmesi (yalnız açık rızanız halinde analitik çerezlerle).</li>
            <li>Sistem güvenliğinin sağlanması; spam, kötüye kullanım ve saldırı girişimlerinin önlenmesi.</li>
            <li>Yasal yükümlülüklerin (veri izleme, anonimleştirme kaydı) ifası.</li>
        </ul>

        <h2 class="section-title">4. Kişisel Verilerin Aktarımı</h2>
        <p>
            Kişisel verileriniz, yukarıdaki amaçların ifasıyla sınırlı olmak
            kaydıyla ve KVKK m.8/m.9 hükümlerine uygun olarak; barındırma
            (hosting) altyapısı sağlayıcıları dışında üçüncü taraflara
            satılmamakta, pazarlama amacıyla paylaşılmamaktadır. Yurt dışına
            aktarım, yalnız açık rızanız halinde ve KVKK m.9'a uygun olarak
            yapılabilir.
        </p>

        <h2 class="section-title">5. Kişisel Verilerin Saklanması</h2>
        <p>
            Kişisel verileriniz; işlenme amacının gerektirdiği süre boyunca ve
            ilgili mevzuatta öngörülen süreler için saklanır. İletişim mesajları
            ve işlem güvenliği kayıtları, amacın sona ermesi halinde anonimleştirilir:
            kullanıcı kayıtları fiziksel olarak silinmez; kimlik alanları
            anonimleştirilir ve bu işlem anonymization_log tablosunda iz bırakılarak
            kayıt altına alınır (KVKK m.5/1/6 — ilgili mevzuattaki saklama
            yükümlülüklerinin saklı tutulması).
        </p>

        <h2 class="section-title">6. İlgili Kişi Olarak Haklarınız (KVKK m.11)</h2>
        <p>KVKK m.11 uyarınca veri sorumlusuna başvurarak;</p>
        <ul>
            <li>Kişisel verilerinizin işlenip işlenmediğini öğrenme,</li>
            <li>İşlenmişse buna ilişkin bilgi talep etme,</li>
            <li>İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,</li>
            <li>Yurt içinde veya yurt dışında verilerin aktarıldığı üçüncü kişileri bilme,</li>
            <li>Eksik veya yanlış işlenmiş verilerin düzeltilmesini isteme,</li>
            <li>KVKK m.7 uyarınca silinmesini veya yok edilmesini isteme,</li>
            <li>Bu işlemlerin, verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme,</li>
            <li>Münhasıran otomatik sistemlerle analiz edilmesi sonucu aleyhinize bir sonucun ortaya çıkmasına itiraz etme,</li>
            <li>Kanuna aykırı işleme sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme</li>
        </ul>
        <p>haklarına sahipsiniz.</p>

        <h2 class="section-title">7. Başvuru Yolu</h2>
        <p>
            Haklarınıza ilişkin taleplerinizi
            <a href="<?= e(url('/iletisim')) ?>">iletişim formu</a>
            üzerinden iletebilirsiniz. Talebiniz, KVKK m.13 uyarınca en geç
            otuz gün içinde ücretsiz olarak yanıtlanır.
        </p>
    </div>
</section>

<?php require APP_ROOT . '/views/partials/footer.php'; ?>
