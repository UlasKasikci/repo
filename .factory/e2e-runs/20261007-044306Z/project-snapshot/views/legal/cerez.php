<?php

/**
 * App-Fabrika Web Edition — Çerez Politikası.
 *
 * Kişisel Verilerin Çerezlerle İşlenmesi Yönetmeliği (RG 11.03.2022/31782) uyarınca.
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>Çerez Politikası</h1>
    <p>Çerez kullanımı, açık rıza ve tercih yönetimi hakkında bilgilendirme.</p>
  </div>
</section>

<article class="legal-doc container">
  <h2>1. Çerez Nedir?</h2>
  <p>
    Çerezler, ziyaret ettiğiniz web sitesi tarafından tarayıcınıza kaydedilen küçük metin
    dosyalarıdır. Oturum çerezleri tarayıcı kapatıldığında silinir; kalıcı çerezler belirli
    bir süre cihazınızda kalabilir.
  </p>

  <h2>2. Kullanılan Çerezler</h2>
  <div class="table-wrap" role="region" aria-label="Çerez listesi" tabindex="0">
    <table class="data-table">
      <caption class="visually-hidden">Sitede kullanılan çerezler</caption>
      <thead>
        <tr>
          <th scope="col">Çerez</th>
          <th scope="col">Tür</th>
          <th scope="col">Amaç</th>
          <th scope="col">Süre</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>PHPSESSID</td>
          <td>Zorunlu</td>
          <td>Oturumun çalışması (yönetim paneli erişimi, form güvenliği)</td>
          <td>Oturum boyunca</td>
        </tr>
        <tr>
          <td>cookie_consent</td>
          <td>Zorunlu</td>
          <td>Çerez tercihinin hatırlanması (rıza durumu sunucuya bildirilir)</td>
          <td>12 ay</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    Bu sitede zorunlu çerezler dışında üçüncü taraf analitik/reklam çerezi <strong>kullanılmaz</strong>;
    ileride zorunlu olmayan bir çerez kategorisi eklenecekse açık rızanız bu sayfa ve onay
    bileşeni üzerinden tekrar alınacaktır.
  </p>

  <h2>3. Açık Rıza (KVKK m.5/2(a) · GDPR Art. 4(11), Art. 7)</h2>
  <p>
    Kişisel Verilerin Çerezlerle İşlenmesi Yönetmeliği (Resmî Gazete 11.03.2022/31782) uyarınca;
    zorunlu olmayan çerezler yalnızca <strong>açık rızanız</strong> alınarak kullanılabilir.
    Ziyaretinizde karşınıza çıkan onay bileşeni ile:
  </p>
  <ul>
    <li><strong>Tümünü Kabul Et</strong> seçeneğiyle rıza verebilir,</li>
    <li><strong>Yalnızca Zorunlu Çerezler</strong> seçeneğiyle rızanızı <em>reddedebilirsiniz</em> — reddetmek sitede gezinmenizi engellemez,</li>
    <li>tercihiniz tarayıcı kaydında ve çerezte saklanır ve onay bileşeni tekrar gösterilmez.</li>
  </ul>

  <h2>4. Tercihinizi Değiştirme</h2>
  <p>
    Tercihinizi dilediğiniz zaman geri alabilir veya değiştirebilirsiniz: sayfa altındaki
    <strong>Çerez Tercihleri</strong> düğmesine tıklayarak onay bileşenini yeniden açabilir,
    tarayıcı ayarlarınızdan çerezleri silebilirsiniz. Çerezler silindiğinde onay bileşeni
    bir sonraki ziyarette yeniden sunulur.
  </p>

  <h2>5. Daha Fazla Bilgi</h2>
  <p>
    Kişisel verilerinizin işlenmesine ilişkin ayrıntılar için
    <a href="<?= e(url('/yasal/aydinlatma')) ?>">KVKK Aydınlatma Metni</a>ni ve
    <a href="<?= e(url('/yasal/gizlilik')) ?>">Gizlilik Politikası</a>nı inceleyebilirsiniz.
  </p>

  <p class="legal-doc__meta">Yürürlük tarihi: 2026-10-07</p>
</article>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
