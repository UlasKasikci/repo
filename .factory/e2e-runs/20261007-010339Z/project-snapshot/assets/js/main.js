/**
 * App-Fabrika Web Edition — arayüz iyileştirmeleri.
 * Zorunlu işlevsellik sunucu tarafında çalışır; bu dosya yalnızca
 * kademeli iyileştirme (progressive enhancement) sağlar.
 */
(function () {
    'use strict';

    function initForms() {
        const form = document.querySelector('form.form[action="/iletisim"]');
        if (form === null) {
            return;
        }
        form.addEventListener('submit', function (event) {
            const consent = form.querySelector('#consent');
            if (consent !== null && !consent.checked) {
                event.preventDefault();
                consent.setAttribute('aria-invalid', 'true');
                consent.focus();
            }
        });
    }

    function initStatusForms() {
        Array.prototype.forEach.call(
            document.querySelectorAll('form[action="/admin/mesajlar"]'),
            function (form) {
                form.addEventListener('submit', function (event) {
                    const select = form.querySelector('select[name="status"]');
                    if (select === null || select.value !== 'archived') {
                        return;
                    }
                    if (!window.confirm('Bu mesajı arşivlemek istediğinize emin misiniz?')) {
                        event.preventDefault();
                    }
                });
            }
        );
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            initForms();
            initStatusForms();
        });
    } else {
        initForms();
        initStatusForms();
    }
})();
