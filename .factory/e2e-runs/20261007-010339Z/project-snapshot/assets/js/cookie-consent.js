/**
 * App-Fabrika Web Edition — Çerez Onay Bileşeni (açık rıza banner'ı)
 *
 * Rıza modeli: KVKK m.5/1 (açık rıza) + GDPR Art. 6(1)(a)/Art. 7 +
 * ePrivacy Direktifi 2002/58/EC m.5/3. Zorunlu olmayan hiçbir çerez,
 * kullanıcı açık rıza vermeden yüklenmez.
 *
 * Tercih saklama: localStorage "cookie_consent" anahtarı (JSON: choice/at/version).
 * Tekrar açılma: [data-cookie-consent-reopen] veya window.CookieConsent.reopen().
 */
(function () {
    'use strict';

    const STORAGE_KEY = 'cookie_consent';
    const SCHEMA_VERSION = 1;

    let banner = null;

    function readConsent() {
        try {
            const raw = window.localStorage.getItem(STORAGE_KEY);
            if (raw === null) {
                return null;
            }
            const parsed = JSON.parse(raw);
            if (parsed === null || typeof parsed !== 'object' || typeof parsed.choice !== 'string') {
                return null;
            }
            if (parsed.choice !== 'granted' && parsed.choice !== 'rejected') {
                return null;
            }
            return parsed;
        } catch (error) {
            return null;
        }
    }

    function writeConsent(choice) {
        const record = {
            choice: choice,
            at: new Date().toISOString(),
            version: SCHEMA_VERSION
        };
        try {
            window.localStorage.setItem(STORAGE_KEY, JSON.stringify(record));
        } catch (error) {
            /* yerel depolama kullanılamıyorsa tercih yalnız oturum boyunca geçerli */
        }
        return record;
    }

    function announce(choice) {
        try {
            window.dispatchEvent(new CustomEvent('cookie-consent', {
                detail: { choice: choice }
            }));
        } catch (error) {
            /* CustomEvent desteklenmiyorsa sessiz geç */
        }
    }

    function choose(choice) {
        writeConsent(choice);
        hideBanner();
        announce(choice);
    }

    function showBanner() {
        if (banner !== null) {
            banner.hidden = false;
            const accept = document.getElementById('cookie-consent-accept');
            if (accept !== null) {
                accept.focus();
            }
        }
    }

    function hideBanner() {
        if (banner !== null) {
            banner.hidden = true;
        }
    }

    function init() {
        banner = document.getElementById('cookie-consent');
        if (banner === null) {
            return;
        }

        const stored = readConsent();
        if (stored === null) {
            showBanner();
        }

        const accept = document.getElementById('cookie-consent-accept');
        const reject = document.getElementById('cookie-consent-reject');

        if (accept !== null) {
            accept.addEventListener('click', function () {
                choose('granted');
            });
        }
        if (reject !== null) {
            reject.addEventListener('click', function () {
                choose('rejected');
            });
        }

        Array.prototype.forEach.call(
            document.querySelectorAll('[data-cookie-consent-reopen]'),
            function (trigger) {
                trigger.addEventListener('click', function () {
                    showBanner();
                });
            }
        );
    }

    window.CookieConsent = {
        init: init,
        reopen: showBanner,
        decide: choose,
        decision: function () {
            const stored = readConsent();
            return stored === null ? null : stored.choice;
        }
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
