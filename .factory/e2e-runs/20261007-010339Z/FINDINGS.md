# E2E SAHA TATBİKATI — `20261007-010339Z`

**Sonuç: `DRIVER_DONE rc=0`, `state=DONE done`, `retry=0`** — 2026-10-07 01:04Z → 03:34Z
(~2.5 saat, 2 gerçek LLM çağrısı + 1 watchdog kesintisi + idempotent kurtarma).
Proje: minimal kurumsal iletişim sitesi (contact form + admin paneli, RBAC, `intent.compliance=kvkk`).

## 1. Kabul kriterleri

| Kriter | Sonuç | Kanıt |
|---|---|---|
| qa-gate PASS | **PASS 0/0 — 13/13 kanal** | `qa-report.json`: domain_report, kvkk, sql_dump, sql_schema, php_lint, phpstan, phpunit, eslint, security_grep, security_policy, password_policy, static_coverage, structure |
| `Yukleme/` üretildi | **EVET — 192K, §14 sadık** | `yukleme-tree.txt`: index.php, core/, views/, assets/, SQL/, robots.txt, sitemap.xml, .htaccess |
| smoke | **PASS — 0 hata, 0 ihlal** | `smoke-report.factory.json`: php_lint, server_start, root_transport, content_signature, html_marker, robots_txt, sitemap_xml; tek not `.htaccess` rewrite (tasarım gereği) |
| `MANIFEST.json` | **YOK — beklenen** | İlk pakette arşiv adımı yok; MANIFEST yalnız 2.+ paketlerde `.factory/yukleme-archive/<ts>/` içinde oluşur |
| Paket sızıntısı | **YOK** | `packaging-report.json` `skipped`: `.opencode, .cursor, docs, scripts, CLAUDE.md, .git, tests, .factory, …` |

## 2. Kullanıcı tahminleri — doğrulama

1. **P1→P2 `module_matrix` drift — KISMEN (tasarımsal açık, davranışta örtüştü).**
   P2 prompt'unda domain-report'a referans **yok**; ama çıktı P1 raporuyla birebir:
   entities `roles, users, messages, user_consents, anonymization_log` ↔ SQL `CREATE TABLE` **5/5**;
   modül→view eşlemesi tam (`contact`, `admin/{dashboard,messages,users}`, `legal/*` ×3,
   `sitemap/robots`; `sepet-siparis: missing` → katalog views yok). Ortak kanal: her iki ajanın
   da okuduğu `.factory/project-intent.json` **notes** — prompt'ta garanti edilmeyen, keşfe
   dayalı **stokastik** kanal. P2'nin ayrıca domain-report'u okuduğuna dair doğrudan kanıt yok
   (event dosyası `run_agent` sonunda siliniyor).
2. **`max_retries: 3` / P4 hata beslemesi — İNCONCLUSIVE.** QA ilk turda geçti
   (`retry_count=0`); `p4_prompt` hiç çalışmadı. Doğrulama için bilinçli hata enjeksiyonu gerekir
   (ayrı, küçük bir tur).
3. **KVKK kanalı — TAM ÇALIŞTI.** intent `kvkk` → P1 `compliance: kvkk` + matrix `kvkk: injected`
   → P2 `views/legal/{aydinlatma,gizlilik,cerez}.php` + `partials/cookie-consent.php` +
   `assets/js/cookie-consent.js` + `SQL/migrations/schema/002_kvkk.sql` (`user_consents`,
   `anonymization_log`) → qa `kvkk: PASS`.
4. **Smoke gerçek `index.php` — PASS.** `/` 200 + HTML imzası, robots/sitemap 200;
   DB bağımlılığı PHP fatal üretmedi (`php_lint` + `content_signature` PASS).
5. **`--auto` zinciri — KIRILMADI.** `web-state.history`:
   `start P1 (01:04:04) → advance P2 (01:29:52) → advance P3 (03:33:49) →
   qa-pass P3→P5 (03:33:53) → advance DONE (03:34:01, condition yukleme-verified)`.

## 3. Tahmin listesi dışındaki bulgular

- **B1 — `mode: subagent` → default agent fallback.** `opencode run --agent web-domain-architect`
  → *"is a subagent, not a primary agent. Falling back to default agent"*. Beş ajan mimarisi
  (P1→P2 geçiş kilidi, readonly QA vb.) **CLI seviyesinde fiilen devre dışı**; tüm E2E'yi default
  agent çalıştırdı. Düzeltme adayı: `.opencode/agent/*.md` frontmatter `mode: primary`
  (`opencode run` subagent'ı başlatamıyor; subagent'lar inline çağrı zincirine ait).
- **B2 — write tool `SchemaError(Expected string, got {…})`.** Model `content` alanına obje verdi:
  P1'de 2 hata → ajan bash ile yazdı; P2'de 3 hata (`.eslintrc.json` dahil) → yine bash refleksi.
  Bugün döndü ama **dosya üretimi LLM'in bash workaround'una bağlı — kırılgan**.
- **B3 — watchdog kill yarışı + idempotent kurtarma (kanıtlandı).** Genişletme çağrısında eski
  WD2 `kill`'i etkisiz kaldı; WD2 7200s'de P2'yi öldürdü (`WATCHDOG_KILLED`). Kurtarma temiz:
  state `P2`'de kaldı; driver yeniden başlatılınca orchestrate `scaffold_ok` ile P2'yi geçip
  kaldığı yerden QA→P5'e gitti. Ders: WD değişiminde `kill -0` doğrulaması; tek WD tutulmalı.
- **B4 — kill durumunda metrik kaybı.** `record_agent_metrics` yalnız doğal bitişte çalışıyor;
  kill edilen P2 için `metrics.jsonl`'da satır yok. Watchdog kill'i bile olsa ts/rc/latency satırı
  düşmeli.
- **B5 — (ÇÜRÜTÜLDÜ) `.opencode` paket sızıntısı.** Ön-taramada denylist `find` satırlarında
  `.opencode` görünmüyordu; gerçek paketleme `skipped` listesine alıyor — **sızıntı yok**
  (yalnızca `find` prune satırına bakmak yanıltıcı; copy aşaması ayrı katman).

## 4. Gerçek metrikler (`--strict` bütçe alarmı için zemin)

| Çağrı | latency | tokens (in/out/cache_read) | diğer |
|---|---|---|---|
| P1 `web-domain-architect` | 1548s (25.8 dk) | 412.5k (234k/9k/154k), cost 0 | 11 step, 44 event, session `ses_eec1c67…` |
| P2 `web-core-engineer` (kill öncesi) | ~120 dk | ≥3.1M (event 182KB ölçümü) | 49+ step, 89 tool_use; metrics satırı yok (B4) |
| QA (resmi P3) | 4 sn | — | 13/13 PASS |
| Packaging + smoke | 8 sn | — | PASS |

Tek P1 örneği eşik koymaya yeterli değil — tekrarlı E2E ile dağılım gerekli.
Bugünkü tavanlar: `E2E_TIMEOUT_SEC=10800`, `E2E_MAX_TOKENS=9000000`.

## 5. Metodoloji (tekrarlanabilirlik)

- Bootstrap proje (kendi git snapshot'ı `91f5c1a`) → `.factory/project-intent.json`
  (kvkk + brief) → `driver.sh` (≤6 attempt; rc0/rc2 durdurur, rc1/rc3 tekrar) → `watchdog.sh`
  (duvar saati + metrics token toplamı, `kill_tree` recursive).
- Tek atışlık, CI dışı. Geçici proje: `/var/folders/…/T/opencode/e2e-20261007-010339Z/project`.
- Bu dizindeki kanıtlar: `orchestrate.log`, `qa-report.json`, `packaging-report.json`,
  `smoke-report.factory.json`, `metrics.jsonl`, `domain-report.json`, `web-state.json`,
  `yukleme-tree.txt`, `project-snapshot/` (120 dosya, ~370KB), `driver.sh`, `watchdog.sh`.

## 6. Önerilen sıradaki hamleler

1. **B1 düzeltmesi** — ajan ayrımı olmadan 5 ajan vaadi kâğıtta kalıyor (en yüksek etki).
2. **P4/`max_retries` bilinçli test** — tek dosyalık hata enjeksiyonu ile retry→HALT zinciri.
3. **B2/B4 için prompt/ölüm-koruma notları**, sonra tekrar E2E ile **empirik `--strict` eşiği**.
