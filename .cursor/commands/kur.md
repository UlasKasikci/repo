# /kur — Webrail İlk Kurulum (tek komut, iki IDE)

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
   + ilk commit (`bootstrap from webrail@<12-hex>`). exFAT uyarısı: `._*` ikizleri
   betikçe temizlenir.
4. **Keşif (Şerit A):** Bootstrap `mode=discovery` bırakır. `DISCOVERY.md` doldur
   (`/kesfet`) — kod yazma. Sonra `bash scripts/web/mode.sh promote $ARGUMENTS`.
5. **State başlat:** `bash scripts/web/state.sh start $ARGUMENTS` (P1; **factory** kilidi).
   State zaten varsa (HALT/önceki tur) `--reset` gerekir — önceki durum
   `.factory/web-state.backup-<ts>.json`a yedeklenir (veri kaybı yok).
6. **QA doğrula:** `bash scripts/web/qa-gate.sh $ARGUMENTS` — bootstrapped boş projede
   ilk çalıştırma P2 öncesi kasıtlı FAIL verir (iskelet + phpstan/phpunit zorunlu);
   mevcut projede 0 Error / 0 Warning hedeflenir. `qa-report.json`'ı özetle.
7. **Özet sun:** mode, phase, retry, QA, sonraki adım
   (`/kesfet` → promote · `/web-baslat` → P1 · P2 hybrid `P2_HUMAN_ASSIST=true`).
   Asla "hazır" deme — qa-gate PASS olmadıysa beklemede olduğunu söyle.

Kısıtlar: model DEĞİŞTİRME (K7) · `Yukleme/` paketleme öncesi oluşturma (K6) ·
TAG yok (denetim öncesi).

Not: P2'de model FAIL olursa `P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh $ARGUMENTS --auto` kullanın (hybrid mod — iskeleti siz yazarsınız, `state.sh advance $ARGUMENTS` sonrası P3-P5 otomatik devam eder; tam akış: `docs/REAL-PROJECT-RUNBOOK.md`).
