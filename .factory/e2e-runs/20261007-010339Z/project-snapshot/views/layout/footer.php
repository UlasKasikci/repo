<?php

use App\App;
use App\View;

?>
</main>
<footer class="site-footer">
    <div class="site-footer__inner">
        <p>&copy; <?= View::e(date('Y')) ?> E2E İletişim — Tüm hakları saklıdır.</p>
        <ul class="site-footer__links">
            <li><a href="/yasal/aydinlatma">KVKK Aydınlatma Metni</a></li>
            <li><a href="/yasal/gizlilik">Gizlilik Politikası</a></li>
            <li><a href="/yasal/cerez">Çerez Politikası</a></li>
            <li>
                <button type="button" class="link-button" id="cookie-preferences"
                        data-cookie-consent-reopen>Çerez Tercihleri</button>
            </li>
        </ul>
    </div>
</footer>
<?php require BASE_PATH . '/views/partials/cookie-consent.php'; ?>
<script src="<?= View::e(App::baseUrl()) ?>/assets/js/cookie-consent.js" defer></script>
</body>
</html>
