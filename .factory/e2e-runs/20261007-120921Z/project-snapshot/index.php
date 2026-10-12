<?php

declare(strict_types=1);

/**
 * Webrail — front-controller.
 *
 * Tüm HTTP istekleri (.htaccess rewrite ile) bu dosyaya yönlendirilir.
 * bootstrap.php: otomatik yükleyici + yardımcı fonksiyonlar + güvenli
 * oturum çerez yapılandırması (HttpOnly + Secure + SameSite=Strict).
 * App::run(): rota eşleşmesi + CSRF doğrulaması + RBAC + hata akışı.
 */

require __DIR__ . '/core/bootstrap.php';

App\Core\App::run();
