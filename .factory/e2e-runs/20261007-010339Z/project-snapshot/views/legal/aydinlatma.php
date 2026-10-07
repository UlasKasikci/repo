<?php

use App\View;

require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow legal">
    <h1>KVKK Aydınlatma Metni</h1>
    <p class="legal__updated">Son güncelleme: 07.10.2026</p>

    <p>
        6698 sayılı <strong>Kişisel Verilerin Korunması Kanunu</strong> ("KVKK") uyarınca,
        veri sorumlusu <strong>E2E İletişim</strong> ("Şirket") olarak kişisel verilerinizi
        aşağıda açıklanan kapsamda işlemekteyiz. Bu aydınlatma metni, KVKK m.10 ve m.11
        ile <strong>Kişisel Verilerin Korunması Kurulu'nun 10.03.2018 tarihli ve 2018/10
        sayılı Aydınlatma Yükümlülüğü Kararı</strong> uyarınca düzenlenmiştir.
    </p>

    <h2>1. Veri Sorumlusu</h2>
    <p>
        Kişisel verileriniz, veri sorumlusu sıfatıyla E2E İletişim tarafından
        <a href="/iletisim">iletişim formu</a> üzerinden toplanmakta ve işlenmektedir.
        Veri sorumlusuna ilişkin taleplerinizi <a href="/iletisim">iletişim formunu</a>
        doldurarak iletebilirsiniz.
    </p>

    <h2>2. İşlenen Kişisel Veriler ve İşleme Amaçları</h2>
    <p>
        İletişim formu aracılığıyla aşağıdaki kişisel veriler işlenmektedir:
    </p>
    <ul>
        <li><strong>Kimlik verileri:</strong> ad, soyad</li>
        <li><strong>İletişim verileri:</strong> e-posta adresi, telefon numarası (isteğe bağlı)</li>
        <li><strong>İşlem güvenliği verileri:</strong> IP adresinizin SHA-256 özeti —
            ham IP adresiniz KVKK gereği saklanmaz, yalnızca spam koruması için tek yönlü
            özeti tutulur</li>
    </ul>
    <p>
        Kişisel verileriniz, <strong>KVKK m.5/2-a</strong> (kanunda öngörülen haller),
        <strong>m.5/2-c</strong> (bir sözleşmenin kurulması/ifası) ve
        <strong>m.6/2-a</strong> (aşikâr biçimde açıklanmış olma) istisnaları ile verdiğiniz
        <strong>açık rıza (KVKK m.5/1)</strong> kapsamında; talebinize yanıt verilmesi,
        taleplerin doğrulanması ve kötüye kullanımın önlenmesi amaçlarıyla işlenir.
        Yurt dışına aktarım yapılmaz (KVKK m.9); otomatik sistemlerle profil oluşturulmaz.
    </p>

    <h2>3. Kişisel Verilerin Toplanma Yöntemi ve Hukuki Sebebi</h2>
    <p>
        Verileriniz, web sitemizdeki iletişim formu aracılığıyla <strong>elektronik ortamda</strong>,
        sizin beyanınız ile toplanır. Toplama hukuki sebepleri yukarıda 2. maddede belirtilmiştir.
        Formu göndermek için aydınlatma metnini onaylamanız (açık rıza) gerekir; rıza tercihiniz
        <code>user_consents</code> kayıtlarında amaç bazlı olarak tutulur.
    </p>

    <h2>4. Kişisel Verilerin Saklanma Süresi</h2>
    <p>
        İletişim talebinize ilişkin veriler, talebin sonuçlandırılmasından ve yasal zamanaşımı
        sürelerinin dolmasından sonra <strong>silinir, yok edilir veya anonimleştirilir</strong>
        (KVKK m.7). Anonimleştirme eylemleri <code>anonymization_log</code> kayıtlarında izlenir;
        log satırlarında kimlik bilgisi bağlantısı tutulmaz.
    </p>

    <h2>5. KVKK m.11 — İlgili Kişi Hakları</h2>
    <p>
        KVKK m.11 uyarınca veri sorumlusuna başvurarak;
    </p>
    <ul>
        <li>kişisel verilerinizin işlenip işlenmediğini öğrenme,</li>
        <li>işlenmişse buna ilişkin bilgi talep etme,</li>
        <li>işlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,</li>
        <li>yurt içinde/yurt dışında aktarıldığı üçüncü kişileri bilme,</li>
        <li>eksik/yanlış işlenmişse düzeltilmesini isteme,</li>
        <li>KVKK m.7 uyarınca silinmesini veya yok edilmesini isteme,</li>
        <li>bütnbu işlemlerin üçüncü kişilere bildirilmesini isteme,</li>
        <li>münhasıran otomatik sistemlerle analiz edilmesi sonucu aleyhe sonuç doğmasına itiraz etme,</li>
        <li>kanuna aykırı işleme nedeniyle zarara uğramanız hâlinde zararın giderilmesini talep etme</li>
    </ul>
    <p>
        haklarına sahipsiniz. Başvurunuz en geç <strong>30 gün</strong> içinde yanıtlanır
        (KVKK m.13/2).
    </p>

    <h2>6. GDPR Hakkında</h2>
    <p>
        Avrupa Birliği vatandaşlarının verileri için <strong>GDPR (EU 2016/679)</strong> aynı
        prensiplerle uygulanır: işleme hukuki dayanağı <strong>Art. 6(1)(a)</strong> (açık rıza),
        rıza yönetimi <strong>Art. 7</strong>, aydınlatma yükümlülüğü <strong>Art. 13</strong>,
        erişim/silme hakları <strong>Art. 15-17</strong> kapsamında güvence altındadır.
    </p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
