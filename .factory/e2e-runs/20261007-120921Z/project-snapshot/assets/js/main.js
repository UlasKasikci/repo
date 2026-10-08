/**
 * App-Fabrika Web Edition — sayfa betiği.
 * Tek seferlik bildirim (flash) bloklarını birkaç saniye sonra yumuşakça kapatır.
 */
(function () {
    'use strict';

    var AUTO_DISMISS_MS = 6000;

    function dismissFlash() {
        var flashes = document.querySelectorAll('.flash[data-auto-dismiss="true"]');
        Array.prototype.forEach.call(flashes, function (flash) {
            window.setTimeout(function () {
                flash.classList.add('flash--fading');
                window.setTimeout(function () {
                    if (flash.parentNode) {
                        flash.parentNode.removeChild(flash);
                    }
                }, 400);
            }, AUTO_DISMISS_MS);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', dismissFlash);
    } else {
        dismissFlash();
    }
})();
