<?php
/**
 * Ortak sayfa alt bilgisi + çerez onay banner'ı + betikler.
 */
?>
</main>

<footer class="site-footer">
    <div class="container site-footer__inner">
        <p class="site-footer__copy">&copy; <?= e((string) date('Y')) ?> E2E İletişim — Tüm hakları saklıdır.</p>
        <nav aria-label="Yasal bağlantılar">
            <ul class="site-footer__links">
                <li><a href="<?= e(url('/kvkk/aydinlatma')) ?>">KVKK Aydınlatma Metni</a></li>
                <li><a href="<?= e(url('/kvkk/gizlilik')) ?>">Gizlilik Politikası</a></li>
                <li><a href="<?= e(url('/kvkk/cerez')) ?>">Çerez Politikası</a></li>
                <li>
                    <button type="button" id="cookie-preferences-open" class="btn btn--link">
                        Çerez Tercihleri
                    </button>
                </li>
            </ul>
        </nav>
    </div>
</footer>

<?php require APP_ROOT . '/views/partials/cookie-consent.php'; ?>

<script src="<?= e(url('assets/js/main.js')) ?>" defer></script>
<script src="<?= e(url('assets/js/cookie-consent.js')) ?>" defer></script>
</body>
</html>
