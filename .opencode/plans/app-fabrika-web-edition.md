# Plan: App-Fabrika Web Edition — Tam Sistem Uygulaması

## Bağlam & Kararlar

Repo şu an HEAD'de Android fabrikası (v3.1.0, FROZEN); çalışma ağacında `AGENTS.md`, `README.md`, `docs/`, `scripts/`, `templates/`, `governance/`, `APP-FABRIKASI/` dahil **588 takip edilen dosya diskten silinmiş** (commit edilmemiş).

Kullanıcı kararları:
1. **Kapsam:** Tam sistem — 4 IDE/CLI config matrisi + `.cursor/` State Graph governance (kural/ajan/komut) + çalıştırılabilir QA & paketleme scriptleri.
2. **Silinmiş 588 dosyaya dokunma** — Web Edition silik ağaç üzerine inşa edilir, geri yükleme yok.
3. **Stack:** Sade PHP 8.1+ MVC + MySQL (framework'süz, `core/ views/ index.php .htaccess` — §14 yapısına birebir).
4. **CI:** Mevcut `validate.yml` web doğrulamasına çevrilecek (Android adımları çıkar).
5. **Minify:** terser/csso kurulu ise çalışır; yoksa kopyalanır + rapora `minified: skipped` uyarısı → paketleme yine PASS.

Repo konvansiyonları: Türkçe içerik, `.mdc` frontmatter (`description`, `alwaysApply`), bash `set -euo pipefail` + `echo "==> ..."` stili, `.factory/` config + gitignore'lu runtime dosya + `*.example.json` şablonu.

## Teslimatlar (dosya listesi)

### A. Configuration Matrix (§15)

| Dosya | İçerik |
|---|---|
| `.cursorrules` (yeniden yazılır) | Web Edition anayasası: web-only (mobil/Flutter/Compose yasak), proaktif denetçi modu (eksik RBAC/sepet/ödeme/bildirim enjeksiyonu), test odaklı tamamlama (`php -l`/QA PASS olmadan "hazır" yok), `Yukleme/` paketleme kuralı, State Graph 5 faz + `max_retries: 3`, departman haritası → web kuralları (24–27). Eski Android içeriği git history'de korunur. |
| `CLAUDE.md` (yeni) | §15.B direktifleri + repo gerçek yolları: `scripts/web/qa-gate.sh`, `scripts/web/package-yukleme.sh`, `docs/WEB-EDITION.md`, gate semantiği (PASS/FAIL/HALT). |
| `opencode.json` (yeni) | Geçerli opencode şeması: `$schema: https://opencode.ai/config.json`, `instructions: ["CLAUDE.md", "docs/WEB-EDITION.md"]` (§15.C `system_instruction` buraya taşınır; `execution_mode: deterministic` ↔ düşük temperature politikası agent dosyasında). Schema key'leri skill'e göre — sahte key (`system_instruction` vb.) kullanılmaz. |
| `antigravity.yaml` (yeni) | §15.D direktifleri + gerçek script yolları (Web-Only-Production, lint-before-build, Yukleme pipeline, dev-dependency sızıntısı yasağı). |

### B. State Graph Governance (`.cursor/` + `docs/` + `.factory/`)

- `docs/WEB-EDITION.md` — kanonik spec: 5 faz (Analiz→Kod→QA→Revision→Paketleme), geçiş kuralları, 5 ajan rolü, QA kabul kriterleri (0 Error/0 Warning), `Yukleme/` ağaç kontratı, API hata şeması (§10), OWASP/KVKK checklist, `debug_report.json` şeması.
- `.factory/web-state-graph.json` — statik makine kontratı: fazlar, gate'ler, `max_retries: 3`, artifact yolları.
- `.factory/web-state.example.json` — runtime durum şablonu (`current_phase`, `retry_count`, `last_error`, `history`). Gerçek `web-state.json` gitignore'lu.
- **Rules** (mevcut 00–23'e devam; mevcut Android rule'lara dokunulmaz, `.cursorrules` web-only override eder):
  - `24-web-edition-core.mdc` — `alwaysApply: true`: web-only + faz geçişleri + retry kuralı + zero-hallucination referansı
  - `25-web-domain-architect.mdc` — `alwaysApply: false`: Agent 1 proaktif eksiklik denetimi (kullanıcı tablosu → `role_id/permissions` zorunlu, katalog → sepet/sipariş/teklif önerisi, onaysız geçiş yok)
  - `26-web-qa-gate.mdc` — `alwaysApply: false`: Agent 4 gate — `qa-gate.sh` PASS olmadan faz geçişi yasak, 3 fail → HALT + `debug_report.json`
  - `27-web-packaging.mdc` — `alwaysApply: false`: Agent 5 — build isolation denylist, §14 ağaç, SQL dump zorunluluğu
- **Agents** (5, `.cursor/agents/`): `web-domain-architect.md`, `web-core-engineer.md`, `web-frontend-specialist.md`, `web-qa-gatekeeper.md` (`readonly: true`), `web-deploy-packager.md` — mevcut `phase-verifier.md` frontmatter stili.
- **Commands** (`.cursor/commands/`): `/web-baslat` (P1 + intent gate), `/web-denetle` (qa-gate + rapor), `/web-yukle` (paketleme + manifest), `/web-faz` (state okuma). Mevcut komut dosyası formatı (`# /ad — Başlık` + script blokları).

### C. opencode dosyaları

- `.opencode/command/web-baslat.md`, `web-denetle.md`, `web-yukle.md`
- `.opencode/agent/web-qa-gatekeeper.md` (`mode: subagent`, `temperature: 0.1`, `permission: {edit: deny}`)

### D. Çalıştırılabilir scriptler (`scripts/web/`)

1. `scripts/web/state.sh` — state graph kontrolcüsü: `status | advance | retry | halt`; `.factory/web-state.json` üzerinde; `retry` 3'ü aşınca `halt` → exit 2.
2. `scripts/web/qa-gate.sh <proje_dizini>` — Phase 3/4 kapısı:
   - `php -l` tüm `*.php` (php yoksa net ERROR)
   - Structural: `index.php`, `.htaccess`, `robots.txt`, `sitemap.xml`, SQL dump varlığı
   - OWASP grep'leri: `mysql_*`, `mysqli_query` doğrudan, `eval(`, `md5(` şifre, prepared statement'siz açık desenler
   - Proaktif şema denetimi (SQL dump üzerinde): `users` tablosu varsa `role_id`/`permissions`; ürün/katalog varsa sepet/sipariş/teklif tablosu → eksikse FAIL
   - Çıktı: `qa-report.json`; FAIL ise `debug_report.json` + `state.sh retry`; 3. fail → `state.sh halt` (exit 2)
3. `scripts/web/package-yukleme.sh <proje_dizini>` — Phase 5:
   - Whitelist kopya: `index.php`, `.htaccess`, `robots.txt`, `sitemap.xml`, `core/`, `views/`, `assets/{css,js,images}`, config (secret hariç), `SQL/veritabani.sql`
   - Hard denylist: `node_modules/`, `.git/`, `.env` (`.env.example` serbest), test dosyaları, `.scss`/`.ts` kaynakları, `*.md` dev dokümanları
   - Minify: `npx --no-install terser/csso` varsa uygula, yoksa `minified: skipped` uyarısı (PASS)
   - SQL doğrulama (UTF-8, `CREATE TABLE`, FK/index, seed `INSERT`) → `Yukleme/SQL/veritabani.sql`
   - §14 ağaçı doğrula (eksik zorunlu dosya → FAIL); rapor `packaging-report.json` (repo kökü — `Yukleme/` içine ek dosya konmaz)
4. `scripts/web/self-test.sh` — deterministik öz-test: `tests/fixtures/web-sample/` → mktemp'e kopya, junk üret (`node_modules/`, `.env`, `src.scss`, `*_test.php`), qa-gate PASS + retry/halt senaryosu + paketleme ağaç/exclusion assertion'ları. CI bunu koşar.

### E. Fixture

- `tests/fixtures/web-sample/` — minimal PHP MVC: `index.php`, `.htaccess`, `core/`, `views/`, `assets/css+js`, `robots.txt`, `sitemap.xml`, `SQL/veritabani.sql` (users+role_id, products, orders, seed). (`.env`/junk commit edilmez — gitignore'da; self-test runtime üretir.)

### F. CI & Gitignore

- `.github/workflows/validate.yml` → **Web CI'ye çevrilir**: `bash -n scripts/web/*.sh`, JSON/YAML lint, `shivammathur/setup-php@v2` (8.1), `scripts/web/self-test.sh` (QA + paketleme dry-run assertion dahil).
- `.gitignore` yeni bölüm: `Yukleme/`, `.factory/web-state.json`, `debug_report.json`, `qa-report.json`, `packaging-report.json`.

## Sıra

1. Spec + state kontratı (`docs/WEB-EDITION.md`, `.factory/web-state-graph.json`, `web-state.example.json`)
2. Scriptler (`state.sh` → `qa-gate.sh` → `package-yukleme.sh` → `self-test.sh`) + fixture
3. Script doğrulaması: `bash -n` + self-test (pozitif, retry/halt negatif, exclusion assertion)
4. Config matrisi (`.cursorrules`, `CLAUDE.md`, `opencode.json`, `antigravity.yaml`)
5. Governance (4 rule, 5 agent, 4 command) + `.opencode/` (3 command, 1 agent)
6. CI çevirisi + `.gitignore`
7. Final doğrulama + `git status` gözden geçirme (commit YOK — kullanıcı istemedi)

## Doğrulama

- `bash -n scripts/web/*.sh`; `python3 -m json.tool` tüm JSON; YAML parse (PyYAML varsa)
- `scripts/web/self-test.sh` → tüm assertion'lar PASS; negatif senaryoda exit 2 + `debug_report.json` üretimi
- `opencode.json`: JSON parse + şema doğrulaması (`https://opencode.ai/config.json` çekilip alan adları kontrol; `opencode` CLI kuruluysa açılış testi) — **kullanıcıya opencode'ı yeniden başlatma hatırlatması**
- Mevcut silinmiş 588 dosyaya ve mevcut Android rule/ajranlara dokunulmadığı `git status` ile teyit

## Riskler / Notlar

- `validate.yml` dönüşümü Android CI'yi kaldırır (onaylandı).
- `AGENTS.md` oluşturulmaz (silinmiş takip edilen dosya yolu — yeni içerik "dokunma" kararını ihlal eder); araçlar `instructions`/`.cursorrules` üzerinden bağlanır.
- `Yukleme/` ve state dosyaları gitignore'lu (build artifact).
- Repoda hâlâ `03-android-elite.mdc` vb. mevcut; web-onlylik `.cursorrules` + `24-web-edition-core.mdc` ile sağlanır.
