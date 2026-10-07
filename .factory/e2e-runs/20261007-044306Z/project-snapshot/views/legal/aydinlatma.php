<?php

/**
 * App-Fabrika Web Edition — KVKK Aydınlatma Metni (6698 sayılı KVKK m.10).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];

require VIEW_DIR . '/layout/header.php';
?>

<section class="page-head">
  <div class="container">
    <h1>KVKK Aydınlatma Metni</h1>
    <p>6698 sayılı Kişisel Verilerin Korunması Kanunu (&ldquo;KVKK&rdquo;) m.10 uyarınca aydınlatma yükümlülüğü.</p>
  </div>
</section>

<article class="legal-doc container">
  <h2>1. Veri Sorumlusu</h2>
  <p>
    Kişisel verileriniz, veri sorumlusu sıfatıyla App-Fabrika (Örnek Mah. Teknoloji Cad. No: 1, 34100
    İstanbul) tarafından aşağıda açıklanan kapsamda işlenmektedir. Sorularınız için:
    <a href="mailto:info@example.com">info@example.com</a>.
  </p>

  <h2>2. İşlenen Kişisel Veriler</h2>
  <ul>
    <li><strong>Kimlik ve iletişim verileri:</strong> iletişim formunda beyan ettiğiniz ad-soyad, e-posta adresi ve (isteğe bağlı) telefon numarası.</li>
    <li><strong>İşlem güvenliği verileri:</strong> isteklerinizle ilişkili IP adresinizin <em>anonimleştirilmiş özeti</em> (tek yönlü karma değeri; gerçek IP adresi saklanmaz).</li>
    <li><strong>Rıza kayıtları:</strong> verdiğiniz açık rızaların amacı, sürümü, tarihi ve IP özeti (rıza ispatı amacıyla).</li>
    <li><strong>Çerez verileri:</strong> tercih ettiğiniz çerez ayarları (tercihinizi hatırlamak amacıyla).</li>
    <li><strong>Yönetim hesapları:</strong> yetkili kullanıcıların ad-soyad, e-posta ve salt-okunur güvenli parola özeti (Argon2id; düz metin parola hiçbir koşulda saklanmaz).</li>
  </ul>

  <h2>3. İşleme Amaçları ve Hukuki Sebepler</h2>
  <ul>
    <li>İletişim taleplerinizin alınması, değerlendirilmesi ve yanıtlanması — KVKK m.5/2(f) <em>meşru menfaat</em> ve m.5/2(c) <em>sözleşmenin kurulması/ifası</em>.</li>
    <li>Zorunlu olmayan çerezlerin kullanımı — KVKK m.5/2(a) <em>açık rıza</em> (Kişisel Verilerin Çerezlerle İşlenmesi Yönetmeliği uyarınca).</li>
    <li>Hukuki yükümlülüklerin yerine getirilmesi ve uyuşmazlıklarda rıza ispatı — KVKK m.5/2(ç) <em>hukuki yükümlülük</em> ve m.5/2(c).</li>
    <li>Veri güvenliğinin sağlanması (erişim kontrolü, oturum yönetimi) — KVKK m.5/2(f) ve m.12.</li>
  </ul>

  <h2>4. Kişisel Verilerin Aktarımı</h2>
  <p>
    Kişisel verileriniz, yurt içinde barındırılan sistemlerde saklanır; talep güvenliği ve hizmet sürekliliği
    için barındırma altyapısı sağlayıcısı dışında üçüncü taraflara paylaşılmaz. Yalnızca yasal mercilerin
    usulüne uygun talepleri ve KVKK m.8 kapsamındaki zorunlu hallerde aktarılabilir.
  </p>

  <h2>5. Saklama Süreleri</h2>
  <ul>
    <li>İletişim mesajları: talebin sonuçlanmasından itibaren en fazla 2 yıl.</li>
    <li>Rıza kayıtları: rızanın çekilmesi veya geçerlilik süresinin bitiminden itibaren ispat amacıyla yasal zamanaşımı sürelerince.</li>
    <li>Yönetim hesapları: hesabın kapatılmasına kadar; kapatma sonrasında anonimleştirme izi haricinde silinir.</li>
  </ul>

  <h2>6. KVKK m.11 Kapsamındaki Haklarınız</h2>
  <ul>
    <li>Kişisel verilerinizin işlenip işlenmediğini öğrenme,</li>
    <li>işlenmişse buna ilişkin bilgi talep etme,</li>
    <li>işlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,</li>
    <li>yurt içinde/yurt dışında aktarıldığı üçüncü kişileri bilme,</li>
    <li>eksik/yanlış işlenmişse düzeltilmesini isteme,</li>
    <li>KVKK m.7 uyarınca silinmesini veya yok edilmesini isteme,</li>
    <li>bu işlemlerin aktarıldığı üçüncü kişilere bildirilmesini isteme,</li>
    <li>münhasıran otomatik sistemlerle analiz edilmesi sonucu aleyhe bir sonuca itiraz etme,</li>
    <li>kanuna aykırı işleme zararı halinde tazminat talep etme.</li>
  </ul>

  <h2>7. Başvuru Yolu</h2>
  <p>
    Taleplerinizi KVKK m.13 uyarınca kimliğinizi tespit edici bilgilerle birlikte
    <a href="mailto:info@example.com">info@example.com</a> adresine iletebilirsiniz. Başvurunuz en geç
    30 gün içinde ücretsiz olarak yanıtlanır.
  </p>

  <p class="legal-doc__meta">Yürürlük tarihi: 2026-10-07</p>
</article>

<?php require VIEW_DIR . '/layout/footer.php'; ?>
