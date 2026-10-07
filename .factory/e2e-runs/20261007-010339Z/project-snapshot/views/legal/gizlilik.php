<?php

use App\View;

require BASE_PATH . '/views/layout/header.php';
?>
<section class="page page--narrow legal">
    <h1>Gizlilik Politikası</h1>
    <p class="legal__updated">Son güncelleme: 07.10.2026</p>

    <p>
        E2E İletişim olarak kişisel verilerinizin güvenliğine önem veriyoruz. Bu politika,
        6698 sayılı KVKK ve GDPR (EU 2016/679) uyumunda verilerinizi nasıl işlediğimizi,
        koruduğumuzu ve haklarınızı açıklar.
    </p>

    <h2>1. Toplanan Veriler</h2>
    <ul>
        <li><strong>İletişim formu:</strong> ad soyad, e-posta, telefon (isteğe bağlı), mesaj
            metni ve konu</li>
        <li><strong>İşlem güvenliği:</strong> IP adresinin SHA-256 özeti (ham IP saklanmaz)</li>
        <li><strong>Panel hesabı:</strong> e-posta, ad soyad, rol (Argon2id ile hash'lenmiş
            parola özeti)</li>
        <li><strong>Rıza kayıtları:</strong> rıza amacı, onay durumu ve tarihi</li>
    </ul>

    <h2>2. Veri Güvenliği Önlemleri (KVKK m.12)</h2>
    <ul>
        <li>Tüm veritabanı sorguları <strong>PDO prepared statement</strong> ile çalışır
            (SQL injection koruması)</li>
        <li>Tüm çıktılar <strong>htmlspecialchars</strong> ile kaçırılır (XSS koruması)</li>
        <li>Form ve yönetim işlemlerinde <strong>CSRF token</strong> doğrulaması zorunludur</li>
        <li>Parolalar <strong>PASSWORD_ARGON2ID</strong> ile hash'lenir; ham parola hiçbir
            yerde saklanmaz</li>
        <li>Oturum çerezleri <strong>HttpOnly, Secure, SameSite</strong> bayraklıdır;
            oturum fixation koruması (session_regenerate_id) uygulanır</li>
        <li>Üretimde hata çıktıları kapatılır; hassas bilgi günlüklenmez</li>
    </ul>

    <h2>3. Veri Paylaşımı</h2>
    <p>
        Kişisel verileriniz, mevzuat gereği açıkça yükümlü olunması hâli dışında üçüncü
        kişilerle paylaşılmaz (KVKK m.8); yurt dışına aktarılmaz (KVKK m.9). Reklam veya
        profil oluşturma amacıyla veri işlenmez.
    </p>

    <h2>4. Haklarınız ve Başvuru</h2>
    <p>
        KVKK m.11 ve GDPR Art. 15-17 kapsamındaki haklarınız için
        <a href="/iletisim">iletişim formunu</a> kullanabilirsiniz. Talepleriniz 30 gün
        içinde yanıtlanır. Rızanızı dilediğiniz zaman geri alabilirsiniz; rıza geri alma,
        rızaya dayalı işlemeyi durdurur (GDPR Art. 7(3)).
    </p>

    <h2>5. Çerezler</h2>
    <p>
        Çerez kullanımına ilişkin ayrıntılar için <a href="/yasal/cerez">Çerez
        Politikamızı</a> inceleyebilirsiniz. Zorunlu olmayan çerezler yalnızca açık rızanız
        ile kullanılır.
    </p>
</section>
<?php require BASE_PATH . '/views/layout/footer.php'; ?>
