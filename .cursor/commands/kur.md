# /kur — App-Fabrika İlk Kurulum (tek komut, iki IDE)

Hedef dizin: `$ARGUMENTS` (boşsa `.`).

Tek komutta ilk kurulum — sırayı DEĞİŞTİRME:

1. **Kontratı oku:** `docs/MASTER-PROMPT-V2.md` (K1-K8; K1a dolu-stream kill yasak,
   K6 QA gate 0 Error/0 Warning, K7 model izole test). `.factory/web-state-graph.json`
   faz akışını (P1→P2→P3→P5) gözden geçir.
2. **Dizini tara:** `$ARGUMENTS` içinde `index.php`, `core/`, `views/`, `SQL/`,
   `.factory/` var mı? Bootstrapped değilse (index.php yok) → adıma 3. Boş değilse
   (mevcut proje) → `bash scripts/web/state.sh status $ARGUMENTS` + adıma 5.
3. **Bootstrap:** `bash scripts/web/bootstrap-project.sh $ARGUMENTS` — önce DRY-RUN
   çıktısını göster (kopya/hariç listesi), onaylanınca `--yes` ile kopyala + git init
   + ilk commit (`bootstrap from app-fabrika@<12-hex>`). exFAT uyarısı: `._*` ikizleri
   betikçe temizlenir.
4. **State başlat:** `bash scripts/web/state.sh start $ARGUMENTS` (P1, retry=0).
5. **QA doğrula:** `bash scripts/web/qa-gate.sh $ARGUMENTS` — bootstrapped boş projede
   ilk çalıştırma P2 öncesi kasıtlı FAIL verir (iskelet + phpstan/phpunit zorunlu);
   mevcut projede 0 Error / 0 Warning hedeflenir. `qa-report.json`'ı özetle.
6. **Özet sun:** phase, retry, QA hata/uyarı sayısı, sonraki adım
   (`/web-baslat` → P1 domain analizi · `/web-denetle` → QA · `/web-yukle` → paketle).
   Asla "hazır" deme — qa-gate PASS olmadıysa beklemede olduğunu söyle.

Kısıtlar: model DEĞİŞTİRME (K7) · `Yukleme/` paketleme öncesi oluşturma (K6) ·
TAG yok (denetim öncesi).
