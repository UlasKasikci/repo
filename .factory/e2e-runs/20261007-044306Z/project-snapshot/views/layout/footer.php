<?php

/**
 * App-Fabrika Web Edition — ortak sayfa alt bilgisi (layout/footer).
 *
 * @var array<string, mixed> $data
 */
$data = $data ?? [];
?>
  </main>

  <footer class="site-footer">
    <div class="container site-footer__inner">
      <p class="site-footer__copy">&copy; <?= e(date('Y')) ?> App-Fabrika — Tüm hakları saklıdır.</p>

      <nav class="site-footer__nav" aria-label="Yasal bağlantılar">
        <ul>
          <li><a href="<?= e(url('/yasal/aydinlatma')) ?>">KVKK Aydınlatma Metni</a></li>
          <li><a href="<?= e(url('/yasal/gizlilik')) ?>">Gizlilik Politikası</a></li>
          <li><a href="<?= e(url('/yasal/cerez')) ?>">Çerez Politikası</a></li>
          <li>
            <button type="button" id="cookie-consent-reopen" class="link-button" hidden>Çerez Tercihleri</button>
          </li>
        </ul>
      </nav>
    </div>
  </footer>

  <?php require VIEW_DIR . '/partials/cookie-consent.php'; ?>

  <script src="<?= e(url('/assets/js/cookie-consent.js')) ?>" defer></script>
  <script src="<?= e(url('/assets/js/main.js')) ?>" defer></script>
</body>
</html>
