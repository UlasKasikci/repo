<?php

use App\View;

require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow legal">
    <h1>Çerez Politikası</h1>
    <p class="legal__updated">Son güncelleme: 07.10.2026</p>

    <p>
        Bu politika, web sitemizde kullanılan çerezleri ve çerez tercihlerinizi nasıl
        yönetebileceğinizi açıklar. Çerezler; KVKK m.5/1 (açık rıza), m.6/2-a ve 6698 sayılı
        Kanun'un <strong>Kişisel Verilerin Korunması Kurulu'nun 2018/10 sayılı kararı</strong>
        ile GDPR <strong>Art. 6(1)(a)</strong> ve <strong>Art. 7</strong> çerçevesinde yönetilir.
    </p>

    <h2>1. Çerez Türleri</h2>
    <table class="table table--legal">
        <caption>Sitede kullanılan çerezler</caption>
        <thead>
        <tr>
            <th scope="col">Çerez</th>
            <th scope="col">Tür</th>
            <th scope="col">Amaç</th>
            <th scope="col">Rıza</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td><code>FABRIKASESS</code></td>
            <td>Zorunlu (oturum)</td>
            <td>Giriş oturumunun ve CSRF korumasının çalışması</td>
            <td>Gerekli — rıza aranmaz</td>
        </tr>
        <tr>
            <td><code>cookie_consent</code></td>
            <td>Zorunlu (yerel depolama)</td>
            <td>Çerez tercihinin (onay/red) saklanması</td>
            <td>Gerekli — tercihinizi hatırlamak için</td>
        </tr>
        <tr>
            <td>Üçüncü taraf / analitik</td>
            <td>İsteğe bağlı</td>
            <td>Kullanılmıyor — rıza verilmedikçe yüklenmez</td>
            <td>Açık rıza gerekir</td>
        </tr>
        </tbody>
    </table>

    <h2>2. Açık Rıza ve Tercih Yönetimi</h2>
    <p>
        Sitemizi ilk ziyaretinizde çerez onay banner'ı gösterilir. <strong>"Tümüne izin
        ver"</strong> seçeneği isteğe bağlı çerezleri de etkinleştirir; <strong>"Yalnızca
        zorunlu çerezler"</strong> seçeneği ise yalnızca oturum ve tercih çerezini bırakır.
        Zorunlu olmayan hiçbir çerez, açık rızanız alınmadan yüklenmez (GDPR Art. 7;
        ePrivacy Direktifi 2002/58/EC m.5/3).
    </p>

    <h2>3. Tercihinizi Değiştirme</h2>
    <p>
        Çerez tercihiniz tarayıcınızın yerel depolamasında saklanır ve sonraki ziyaretlerde
        hatırlanır. Dilediğiniz zaman sayfanın altındaki <strong>"Çerez Tercihleri"</strong>
        bağlantısına tıklayarak banner'ı yeniden açabilir ve tercihinizi değiştirebilirsiniz.
        Tercihinizi değiştirdiğinizde yeni seçim anında uygulanır ve kaydedilir.
    </p>

    <h2>4. Tarayıcı Ayarları</h2>
    <p>
        Ayrıca tarayıcı ayarlarınızdan tüm çerezleri silebilir veya engelleyebilirsiniz.
        Zorunlu oturum çerezini engellemek, yönetim paneline girişi engeller.
    </p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
