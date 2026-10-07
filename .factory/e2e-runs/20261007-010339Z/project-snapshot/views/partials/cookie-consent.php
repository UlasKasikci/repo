<?php

use App\View;

?>
<div id="cookie-consent" class="cookie-consent" role="dialog" aria-modal="false"
     aria-labelledby="cookie-consent-title" aria-describedby="cookie-consent-desc" hidden>
    <div class="cookie-consent__inner">
        <div class="cookie-consent__text">
            <h2 id="cookie-consent-title">Çerez Tercihleri</h2>
            <p id="cookie-consent-desc">
                Sitemizde zorunlu oturum çerezleri dışında yalnızca açık rızanız ile çerez
                kullanılır. Tercihiniz
                <a href="/yasal/cerez">Çerez Politikamız</a> kapsamında yerel depolamada
                saklanır; dilediğiniz zaman sayfanın altındaki "Çerez Tercihleri"
                bağlantısıyla yeniden açabilirsiniz.
            </p>
        </div>
        <div class="cookie-consent__actions">
            <button type="button" class="btn btn--primary" id="cookie-consent-accept"
                    data-cookie-consent-accept>Tümüne izin ver</button>
            <button type="button" class="btn btn--ghost" id="cookie-consent-reject"
                    data-cookie-consent-reject>Yalnızca zorunlu çerezler</button>
        </div>
    </div>
</div>
