<?php declare(strict_types=1); ?>
<aside id="cookie-consent" role="dialog" aria-label="Çerez onayı">
  <p>Deneyimi iyileştirmek için çerez kullanıyoruz.
    <a href="/legal/aydinlatma">Aydınlatma metni</a></p>
  <form method="post" action="/consent/cookies">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(Csrf::token(), ENT_QUOTES, 'UTF-8') ?>">
    <button type="submit" name="granted" value="1">Kabul et</button>
    <button type="submit" name="granted" value="0">Reddet</button>
  </form>
</aside>
