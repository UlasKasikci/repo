/**
 * App-Fabrika Web Edition — çerez onay banner'ı (KVKK m.5/1 açık rıza).
 *
 * Davranış:
 *  - Banner varsayılan gizlidir (hidden); geçerli bir tercih yoksa gösterilir.
 *  - "Kabul Et" / "Reddet": tercih localStorage'da saklanır, POST /api/cerez-riza
 *    ile user_consents tablosuna (CSRF başlığı + metin sürümü + IP) kaydedilir
 *    ve banner kapatılır.
 *  - Tekrar açılma: footer'daki "Çerez Tercihleri" (#cookie-preferences-open)
 *    ve Çerez Politikası sayfasındaki bağlantı banner'ı yeniden açar; kullanıcı
 *    tercihini güncelleyebilir.
 *  - Analitik çerezler yalnız onay sonrası yüklenir: 'cookie-consent:changed'
 *    olayı yayılır (granted=true iken analitik yükleyici tetiklenir).
 */
(function () {
    'use strict';

    var STORAGE_KEY = 'cookie_consent';
    var API_ENDPOINT = '/api/cerez-riza';
    var VALID_CHOICES = ['granted', 'denied'];

    function banner() {
        return document.getElementById('cookie-consent');
    }

    function readPreference() {
        try {
            var stored = window.localStorage.getItem(STORAGE_KEY);
            return VALID_CHOICES.indexOf(stored) !== -1 ? stored : null;
        } catch (err) {
            return null;
        }
    }

    function storePreference(choice) {
        try {
            window.localStorage.setItem(STORAGE_KEY, choice);
        } catch (err) {
            /* yerel depolama kullanılamıyorsa tercih yalnız sunucuya yazılır */
        }
    }

    function show() {
        var el = banner();
        if (!el) {
            return;
        }
        el.hidden = false;
        var primary = el.querySelector('[data-cookie-action="accept"]');
        if (primary && typeof primary.focus === 'function') {
            primary.focus();
        }
    }

    function hide() {
        var el = banner();
        if (el) {
            el.hidden = true;
        }
    }

    function recordOnServer(choice, version) {
        var el = banner();
        var csrf = el ? el.getAttribute('data-csrf') : null;
        if (!csrf || typeof window.fetch !== 'function') {
            return;
        }
        window.fetch(API_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': csrf
            },
            credentials: 'same-origin',
            body: JSON.stringify({
                consent_type: 'cookie_analytics',
                granted: choice === 'granted',
                text_version: version
            })
        }).catch(function () {
            /* bildirim başarısızlığı kullanıcı akışını bloklamaz;
               tercih yerel olarak zaten saklandı */
        });
    }

    function choose(choice) {
        var el = banner();
        var version = el ? el.getAttribute('data-consent-version') : '1.0.0';
        storePreference(choice);
        recordOnServer(choice, version);
        hide();
        document.dispatchEvent(new window.CustomEvent('cookie-consent:changed', {
            detail: { granted: choice === 'granted' }
        }));
    }

    function reopen() {
        show();
    }

    function init() {
        var el = banner();
        if (!el) {
            return;
        }
        var buttons = el.querySelectorAll('[data-cookie-action]');
        Array.prototype.forEach.call(buttons, function (button) {
            button.addEventListener('click', function () {
                var action = button.getAttribute('data-cookie-action');
                choose(action === 'accept' ? 'granted' : 'denied');
            });
        });

        var reopeners = document.querySelectorAll(
            '#cookie-preferences-open, #cookie-preferences-open-legal'
        );
        Array.prototype.forEach.call(reopeners, function (trigger) {
            trigger.addEventListener('click', function (event) {
                event.preventDefault();
                reopen();
            });
        });

        // Açık rıza: geçerli bir tercih yoksa banner gösterilir.
        if (readPreference() === null) {
            show();
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.CookieConsent = {
        show: show,
        hide: hide,
        reopen: reopen,
        readPreference: readPreference
    };
})();
