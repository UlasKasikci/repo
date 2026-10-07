/**
 * App-Fabrika Web Edition — KVKK çerez onay bileşeni (açık rıza).
 *
 * Davranış:
 *  - Tercih yoksa onay banner'ı gösterilir (açık rıza).
 *  - "Tümünü Kabul Et" / "Yalnızca Zorunlu Çerezler" tercihini kaydeder
 *    (localStorage + çerez yansıması, 12 ay).
 *  - Tercih kayıtlıysa banner gizlenir; sayfa altındaki "Çerez Tercihleri"
 *    düğmesi bileşeni yeniden açar (tercih yönetimi).
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'cookie-consent-v1';
  var COOKIE_NAME = 'cookie_consent';
  var COOKIE_MAX_AGE = 60 * 60 * 24 * 365; // 12 ay

  var VALID = { all: true, essential: true };

  function readPreference() {
    try {
      var raw = window.localStorage.getItem(STORAGE_KEY);
      if (raw !== null && Object.prototype.hasOwnProperty.call(VALID, raw)) {
        return raw;
      }
    } catch (err) {
      // localStorage erişilemez (gizli mod vb.) — çerez yansımasına düş
    }
    var cookie = readCookie(COOKIE_NAME);
    if (cookie !== null && Object.prototype.hasOwnProperty.call(VALID, cookie)) {
      return cookie;
    }
    return null;
  }

  function readCookie(name) {
    var parts = document.cookie ? document.cookie.split(';') : [];
    for (var i = 0; i < parts.length; i += 1) {
      var pair = parts[i].split('=');
      var key = pair[0].trim();
      if (key === name && pair.length > 1) {
        return pair.slice(1).join('=').trim();
      }
    }
    return null;
  }

  function writeCookie(name, value) {
    document.cookie = name + '=' + encodeURIComponent(value) +
      '; max-age=' + COOKIE_MAX_AGE + '; path=/; SameSite=Lax';
  }

  function savePreference(preference) {
    try {
      window.localStorage.setItem(STORAGE_KEY, preference);
    } catch (err) {
      // localStorage yazılamadı — çerez yansıması yeterli
    }
    writeCookie(COOKIE_NAME, preference);
  }

  function consentBanner() {
    return document.getElementById('cookie-consent');
  }

  function reopenButton() {
    return document.getElementById('cookie-consent-reopen');
  }

  function openBanner() {
    var banner = consentBanner();
    var reopen = reopenButton();
    if (banner !== null) {
      banner.hidden = false;
    }
    if (reopen !== null) {
      reopen.hidden = true;
    }
    var accept = document.getElementById('cookie-consent-accept');
    if (accept !== null) {
      accept.focus();
    }
  }

  function closeBanner() {
    var banner = consentBanner();
    var reopen = reopenButton();
    if (banner !== null) {
      banner.hidden = true;
    }
    if (reopen !== null) {
      reopen.hidden = false;
    }
  }

  function choose(preference) {
    savePreference(preference);
    closeBanner();
  }

  function bind() {
    var accept = document.getElementById('cookie-consent-accept');
    var reject = document.getElementById('cookie-consent-reject');
    var reopen = reopenButton();

    if (accept !== null) {
      accept.addEventListener('click', function () {
        choose('all');
      });
    }
    if (reject !== null) {
      reject.addEventListener('click', function () {
        choose('essential');
      });
    }
    if (reopen !== null) {
      reopen.addEventListener('click', function () {
        openBanner();
      });
    }

    if (readPreference() === null) {
      openBanner();
    } else {
      closeBanner();
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bind);
  } else {
    bind();
  }

  // Sunucu/arayüz entegrasyonu için açık API
  window.CookieConsent = {
    get: readPreference,
    set: choose,
    reopen: openBanner
  };
})();
