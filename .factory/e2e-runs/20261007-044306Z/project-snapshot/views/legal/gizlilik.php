<?php

/**
 * App-Fabrika Web Edition — Gizlilik Politikası.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>Gizlilik Politikası</h1>
    <p>Kişisel verilerinizin güvenliği, işlenmesi ve korunmasına ilişkin ilkelerimiz.</p>
  </div>
</section>

<article class="legal-doc container">
  <h2>1. Kapsam</h2>
  <p>
    Bu politika; App-Fabrika web sitesi ve iletişim kanalları üzerinden işlenen kişisel verilerin
    6698 sayılı KVKK ve, yürürlükte olduğu ölçüde, 2016/679 sayılı GDPR (AB Genel Veri Koruma
    Tüzüğü) ile uyumlu biçimde işlenmesini kapsar. Ayrıntılı aydınlatma için
    <a href="<?= e(url('/yasal/aydinlatma')) ?>">KVKK Aydınlatma Metni</a>ne bakınız.
  </p>

  <h2>2. Veri Minimizasyonu ve Amaç Sınırlılığı</h2>
  <p>
    Yalnızca amacımız için gerekli olan veriler toplanır: iletişim talepleri için ad-soyad, e-posta,
    (isteğe bağlı) telefon ve mesaj içeriği; güvenlik için anonimleştirilmiş IP özeti; rıza ispatı
    için rıza kaydı. Toplanan hiçbir veri pazarlama profili oluşturmak için kullanılmaz ve satılmaz.
  </p>

  <h2>3. Veri Güvenliği Önlemleri (KVKK m.12 · GDPR Art. 32)</h2>
  <ul>
    <li>Tüm veritabanı sorguları parametrelendirilmiş ifadelerle yürütülür (enjeksiyon koruması).</li>
    <li>Parolalar salt-okunur, tek yönlü ve <em>tuzlanmış</em> Argon2id özetiyle saklanır.</li>
    <li>Oturum çerezleri HttpOnly, (TLS altında) Secure ve SameSite bayraklarıyla taşınır; oturum sabitlemesine karşı kimlik yenilenir.</li>
    <li>Form istekleri siteler arası istek sahteciliğine (CSRF) karşı zaman-güvenli token ile doğrulanır.</li>
    <li>Çıktı kaçırma (XSS koruması) tüm arayüz katmanında uygulanır.</li>
    <li>Yetkilendirme rol bazlıdır (RBAC); yönetim işlemleri minimum yetki ilkesine tabidir.</li>
    <li>Anonimleştirme ve küçültme işlemleri <em>anonymization_log</em> tablosunda denetlenebilir izle kayıt altına alınır.</li>
  </ul>

  <h2>4. Çerezler</h2>
  <p>
    Zorunlu çerezler (oturum, güvenlik) açık rıza gerektirmez; tercihi çerezler yalnızca açık rızanız
    alınarak kullanılır. Tercihinizi dilediğiniz zaman sayfa altındaki
    <a href="<?= e(url('/yasal/cerez')) ?>">Çerez Politikası</a> bağlantısındaki
    &ldquo;Çerez Tercihleri&rdquo; düğmesinden değiştirebilirsiniz.
  </p>

  <h2>5. Üçüncü Taraf Paylaşımı</h2>
  <p>
    Kişisel verileriniz yalnızca yasal zorunluluk hallerinde ve usulüne uygun taleplerle paylaşılır;
    reklam/analitik ağlarına aktarılmaz.
  </p>

  <h2>6. Haklarınız ve Başvuru</h2>
  <p>
    KVKK m.11 kapsamındaki haklarınız için <a href="mailto:info@example.com">info@example.com</a>
    adresine başvurabilirsiniz; talepler en geç 30 gün içinde yanıtlanır.
  </p>

  <p class="legal-doc__meta">Yürürlük tarihi: 2026-10-07</p>
</article>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
