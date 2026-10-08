# APP-FABRIKA WEB EDITION — Teknik Spesifikasyon

**Sürüm:** 1.0.0 · **Mod:** deterministic · **Stack:** Sade PHP 8.1+ MVC + MySQL 8.0+/MariaDB
**Kapsam:** Yalnızca Web. Mobil (Flutter, Compose, React Native, Gradle, APK) kod üretimi yasaktır.

Bu dosya App-Fabrika Web Edition'in **kanonik** spesifikasyonudur. Tüm IDE/CLI konfigürasyonları
(`.cursorrules`, `CLAUDE.md`, `opencode.json`, `antigravity.yaml`) bu dosyaya bağlanır; çelişen
talimat geçersizdir.

---

## 1. Multi-Agent Roller (5 ajan)

| # | Ajan | Dosya | Sorumluluk |
|---|------|-------|------------|
| 1 | Requirement & Domain Architect | `.cursor/agents/web-domain-architect.md` | İstek ayrıştırma; eksik gereksinim (RBAC, sepet, ödeme, bildirim, SEO, KVKK) proaktif enjeksiyonu |
| 2 | Core Web & Database Engineer | `.cursor/agents/web-core-engineer.md` | PHP 8.1+ MVC çekirdek, PDO şema, FK/index'li normalize SQL |
| 3 | UI/UX & Frontend Specialist | `.cursor/agents/web-frontend-specialist.md` | Semantik HTML5, erişilebilir, SEO dostu, Core Web Vitals 90+ arayüz |
| 4 | QA & Security Gatekeeper | `.cursor/agents/web-qa-gatekeeper.md` | `qa-gate.sh` işletir; `Check: PASS` vermeden faz geçişi yok (`readonly`) |
| 5 | Production Deployment & Packager | `.cursor/agents/web-deploy-packager.md` | Build isolation + `Yukleme/` üretimi |

Tek ajan onayı yasaktır: P1→P2 geçişi yalnız Domain Architect analiz dokümanıyla,
P3→P5 geçişi yalnız QA Gatekeeper `qa-gate.sh` PASS'ıyla mümkündür.

## 2. State Graph

Makine kontratı: `.factory/web-state-graph.json` · Runtime durum: `.factory/web-state.json`

```
START → P1 (Domain & Scope) → P2 (Code Gen) → P3 (QA Pool) ──PASS──→ P5 (Packaging) → DONE
                                                    │
                                                    ├─FAIL (retry 1–3)→ P4 (Revision) → P3
                                                    │
                                                    └─4. FAIL (3 defadan fazla) → HALT + debug_report.json
```

### Geçiş kuralları

1. **P1 → P2:** Tüm iş kuralları (edge case, security context, eksik modül kararı) dondurulmadan
   kod üretimi tetiklenemez. Kapı artefaktı: `<proje>/.factory/domain-report.json`
   (şema: `.factory/contracts/p1-domain-report.schema.json` — `module_matrix` zorunlu;
   `orchestrate.sh` JSON şemasıyla doğrular).
2. **P2 → P3:** Kod yalnızca dosya varlığı ve yapı bütünlüğüyle geçer; asıl kapı P3'tedir.
3. **P3 → P5:** `scripts/web/qa-gate.sh` exit 0 (`0 Error, 0 Warning`) alınmadan `Yukleme/`
   dizini oluşturulamaz.
4. **P3 → P4:** QA fail → `state.sh qa-fail` (retry_count++). Düzelt → tekrar P3.
5. **max_retries: 3** — 3 başarısızlık toleranslıdır (retry 1–3 → P4); **4. başarısızlık
   (3 defadan fazla)** graph'ı **HALT**'a götürür: `debug_report.json` üretilir, mimari
   durur, sonsuz döngü yoktur.
6. **P5 → DONE:** `packaging-report.json` `result=PASS` iken `state.sh advance` ile kapanır
   (`condition: yukleme-verified`).

### Orkestratör (faz sürücüsü)

```bash
bash scripts/web/orchestrate.sh <proje_dizini>          # deterministik faz sürüşü
bash scripts/web/orchestrate.sh <proje_dizini> --auto   # eksik LLM adımları opencode run --agent ile
bash scripts/web/orchestrate.sh <proje_dizini> --auto --strict   # + bütçe alarmı (uyarıcı)
```

Eksik faz artefaktını (P1 raporu, P2 iskeleti, P4 düzeltmesi) **bekletir**; hazır olanı
işler, HALT'ı aynadan geçirir. Çıktı raporları `.factory/contracts/*.schema.json` ile
doğrulanır (`jsonschema` varsa tam, yoksa zorunlu-alan/const yedeği).

**Metrik raporlayıcı (`--auto`, reporter-only):** her `opencode run` çağrısı
`--format json` ile NDJSON event akışı (`step_start`/`text`/`step_finish`) olarak
alınır ve agent metni stdout'a basılır; ardından `<proje>/.factory/metrics.jsonl`'a
tek satır eklenir: `ts, phase, agent, rc, latency_ms, event_span_ms, session,
events, steps, tokens{input,output,total,reasoning,cache_*}, text_parts, cost,
parse_error`. Bozuk/boş çıktıda satır `parse_error: true` + `error` ile yazılır
(rc ve latency yine kaydedilir). **Metrik asla exit kodu/QA/state değiştirmez**
(yazım hatası yutulur).

**Bütçe alarmı (`--strict`):** metrics toplamı 1× eşikleri aşarsa
`STRICT bütçe:` uyarısı basılır — **exit/gate değişmez** (reporter-only).
**2× sert katman:** eşiklerin ikikatını aşan durumda `SERT AŞIM` satırı +
**exit 1** (duraklatılmış fazdan `orchestrate.sh` yeniden çalıştırılarak devam).
Varsayılan 1× eşikler n=2 emprik zeminden (E2E-1/2): toplam **8M** / P2-P4 tek faz
**6M** / P1 **1.5M** token, duvar **10800s**; env ile override: `STRICT_TOTAL_TOKENS`,
`STRICT_PHASE_TOKENS`, `STRICT_P1_TOKENS`, `STRICT_WALL_MS`.

### State komutları

```bash
bash scripts/web/state.sh status     # okuma
bash scripts/web/state.sh start      # P1, retry=0
bash scripts/web/state.sh advance    # P1→P2→P3; P5→DONE (yukleme-verified)
bash scripts/web/state.sh qa-pass    # P3/P4 → P5
bash scripts/web/state.sh qa-fail    # retry++ / HALT (retry alias)
bash scripts/web/state.sh halt       # manuel durdurma
```

Exit kodları: `0` OK · `1` geçersiz geçiş/geçersiz artefakt · `2` HALT ·
`3` orkestratör bekleme (LLM adımı gerekli; mimari değil).

## 3. Faz 1 — Proaktif Domain Denetimi (Agent 1)

Şartname onaylanmadan önce **zorunlu** denetimler:

- `users`/`kullanicilar` tablosu tanımlanıyorsa → `role_id` **veya** `permissions` sütunu yoksa
  **FAIL**: Admin/Moderatör/Kullanıcı rol katmanı enjekte edilir.
- Ürün/katalog listesi var (`products`, `urunler`, `catalog`, `katalog`) → sipariş/sepet/teklif
  mekanizması yoksa **FAIL** ve onay beklenir (tablo eklenir veya `--allow-no-cart` ile
  açık istisna kaydedilir).
- Ödeme/bildirim/yorum gibi modüller sektör standartına göre önerilir; kullanıcı reddetmedikçe
  eklenir.

Bu denetimler `scripts/web/qa-gate.sh` içinde deterministik olarak uygulanır.

**P1 artefaktı (zorunlu):** Domain Architect denetim sonucunu
`<proje>/.factory/domain-report.json` dosyasına UTF-8 JSON olarak yazar
(şema: `.factory/contracts/p1-domain-report.schema.json`). `module_matrix` ≥4 modül;
her hücrede `status ∈ present|missing|injected|proposed` **zorunlu** olmanın yanında
`evidence` (≥10 karakter, kaynak referansı: dosya/satır veya tablo kanıtı) ve
`justification` (≥20 karakter, gerçek gerekçe) dolu olmalıdır — şablon/boş/tekrar
değerler semantik olarak reddedilir. **`evidence` filesystem doğrulanır:** metinde
geçen dosya adları (uzantı whitelist'i) proje kökünde gerçekten var olmalı; uydurma
kaynak referansı FAIL. Denetim iki katmanda uygulanır: `orchestrate.sh` P1'de şema +
`scripts/web/domain-check.py` (semantik + fs), `qa-gate.sh` `domain_report`
kontrolünde aynı tek doğruluk kaynağı (hollow/uydurma matrix → FAIL). Bu dosya yoksa
veya uymuyorsa `orchestrate.sh` P2'ye geçmez (exit 1/3); `state.sh advance` P1→P2'yi
yalnız geçiş anında hücresel olarak değil, artefakt varlığını orkestratör katmanında
doğrular.

**Compliance (KVKK/GDPR) — koşullu modül (#9):** tek doğruluk kaynağı
`<proje>/.factory/project-intent.json` → `compliance ∈ {kvkk, gdpr, none}`
(alan yoksa/bozuksa `none`; example'da `null`). Seçim:
- **`kvkk|gdpr`:** P1 prompt'u `compliance` alanını domain-report'a dondurur (şemada
  **opsiyonel** — `additionalProperties: true`, `schema_version` 1'de kalır, majör bump
  yok). P2 prompt'u KVKK bloğunu **zorunlu** kılar: `views/legal/{aydinlatma,gizlilik,
  cerez}.php` (gerçek yasal metin), `views/partials/cookie-consent.php` +
  `assets/js/cookie-consent.js` (açık rıza banner'ı), `SQL/migrations/schema/*_kvkk.sql`
  → `user_consents` + `anonymization_log` (boş şema, seed değil) ve dump yeniden üretimi.
  `qa-gate.sh` `kvkk` kanalı bunları + iki tabloyu denetler → eksik FAIL.
- **`none`/alan yok:** P2 prompt'u bloğu yazmaz, `kvkk` kanalı **SKIPPED** kalır
  (ayrı kanal — SKIPPED bütçesine girmez, PASS'i etkilemez; iç panel/B2B intranet muaf).

## 4. Faz 2/3 — Mimari & Kod Standartları

- **Backend:** Sade PHP 8.1+, MVC (`core/`, `views/`, `index.php` front-controller), stateless,
  `declare(strict_types=1)`.
- **Veritabanı:** MySQL 8.0+/MariaDB; FK kısıtlamaları + cascade kuralları; B-Tree index;
  N+1 sorgu yasağı; seed verileri `SQL/veritabani.sql` içinde. Şema/seed kaynağı
  `SQL/migrations/{schema,seed}/*.sql` altında tutulur; `SQL/veritabani.sql`
  `bash scripts/web/sql-dump.sh <proje>` ile **deterministik** üretilir (LC_ALL=C sıralama,
  saat damgası yok — aynı kaynak = byte-identical; tarih yorumu opsiyonel
  `SQL/migrations/SURUM` dosyasından; başlıkta `Kaynak Hash` sürümü). qa-gate `sql_dump`
  kontrolü üretim ile commit'li dump'ı byte-karşılaştırır, **drift → FAIL**.
- **API:** RESTful, JSON, HTTP durum kodu (200/201/400/401/403/404/422/500), standart hata şeması:

```json
{ "success": false, "error": { "code": "VALIDATION_FAILED", "message": "Açıklayıcı hata metni", "details": [] } }
```

- **Frontend:** Semantik HTML5, mobil uyumlu, Lighthouse 90+; `.scss`/`.ts` kaynak dosyaları
  üretime girmez (derlenmiş çıktı girer).

## 5. Güvenlik (OWASP Top 10 · KVKK/GDPR)

| Kontrol | Zorunluluk |
|---------|-----------|
| SQL Injection | Tüm sorgular PDO Prepared Statement (`prepare`/`execute`) — doğrudan string birleştirme yasak |
| XSS | Çıktıda `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`; kullanıcı girdisi arayüze ham basılmaz |
| CSRF | Tüm POST/PUT/DELETE isteklerinde benzersiz token doğrulaması |
| Şifre | `PASSWORD_ARGON2ID` veya `PASSWORD_BCRYPT` (Cost ≥ 12); `password_verify` |
| Oturum | `HttpOnly`, `Secure`, `SameSite=Strict/Lax` çerezler; session fixation koruması |
| Gizlilik | KVKK/GDPR aydınlatma metni + çerez onay mekanizması |

`qa-gate.sh` bu kontrollerin statik karşılıklarını (eval, `mysql_*`, superglobal-in-query,
ham md5, CSRF'siz POST) **FAIL** ile denetler.

## 6. QA Kapısı (Phase 3/4)

```bash
bash scripts/web/qa-gate.sh <proje_dizini>
```

Kontroller: `php -l` (tüm PHP dosyaları) · yapısal dosya denetimi · SQL şema denetimi
(FK/index/seed/RBAC/sepet) · OWASP grep'leri · **`domain_report` semantik denetimi**
(P1 artefaktı varsa: module_matrix ≥4, dolu evidence/justification) · **`kvkk`
kanalı** (intent.compliance=kvkk|gdpr → legal view + consent bileşeni + `user_consents`
/`anonymization_log`; none/yok → SKIPPED, ayrı kanal) · **statik/test
üçlüsü** · raporlar.

- Çıktılar: `qa-report.json` (her koşuda), `debug_report.json` (yalnız FAIL).
- `0 Error, 0 Warning` → `Check: PASS` → yalnız o zaman P5.
- **Statik garantici çekirdek (asimetrik):** `phpstan` ve `phpunit` **zorunludur** —
  yapılandırması yoksa o kontrol doğrudan **FAIL**; yapılandırma var ama araç kurulu
  değilse de FAIL. Yalnız `eslint` SKIPPED olabilir (ör. JS'siz proje).
  `static_coverage` = `phpstan=PASS ∧ phpunit=PASS`; aksi her koşulda FAIL.
- **SKIPPED bütçesi yerine kanal-bazlı çekirdekler:** genel "≥2 SKIPPED" sayacı yoktur;
  her SKIPPED kanalın kendi zorunlu karşılığı vardır. `sql_dump` SKIPPED olsa bile
  `sql_schema` **koşulsuz** çalışır (migrations yoksa eski tip `SQL/veritabani.sql`
  zorunlu — UTF-8/FK/INSERT/RBAC/sepet denetimi); `domain_report` yalnız P1 artefaktı
  hiç yoksa SKIPPED olabilir (fabrika akışında P1'i `orchestrate.sh`/`state.sh` zorlar).
- **max_retries: 3** — 3 başarısızlık P4'e döner; **4. başarısızlıkta** `state.sh` HALT
  (exit 2) + `debug_report.json`.

## 7. Paketleme — `Yukleme/` Kontratı (Phase 5)

```bash
bash scripts/web/package-yukleme.sh <proje_dizini>
```

Zorunlu çıktı ağacı:

```
Yukleme/
├── assets/css/  ├── assets/js/  ├── assets/images/
├── core/
├── views/
├── SQL/veritabani.sql
├── .htaccess
├── index.php
├── robots.txt
└── sitemap.xml
```

**Build isolation (denylist — asla pakete girmez):** `node_modules/`, `.git/`, `.env`
(`.env.example` serbest), test dosyaları (`*_test.php`, `tests/`), `.scss`/`.ts` kaynakları,
`.factory/`, `qa-report.json`, `debug_report.json`, `packaging-report.json`, dev dokümanları.

- CSS/JS minify: `terser`/`csso` mevcutsa uygulanır; yoksa dosya aynen kopyalanır ve rapora
  `minify: skipped` **notu** düşülür (QA gate'in 0-warning kuralını bozmaz).
- SQL: `Yukleme/SQL/veritabani.sql` UTF-8, `CREATE TABLE` + `FOREIGN KEY` + seed `INSERT`
  içermek zorundadır; eksikse paketleme FAIL. Dosya doğrudan üretilmiş dump olur —
  `SQL/migrations/` klasörü pakete **girmez** (senkronluk QA'da `sql_dump` ile garantidir).
- Rapor: `<proje>/packaging-report.json` (sha256 manifest + skipped/nots listesi).
  `Yukleme/` içine ek dosya konmaz — ağaç §14'e birebir sadık kalır.

**Staging + smoke + arşiv/geri alma (P5 iç akışı):** build `.factory/yukleme-staging`'e
yapılır; `bash scripts/web/smoke-test.sh <dizin>` lokal modda **katmanlı** kapı işletir —
*blocker* (FAIL → paket reddedilir): tüm `.php` dosyalarına `php -l`, `php -S` ayağa kalkması
(port adayları `SMOKE_PORT`/`18000+RANDOM`, süreç ölürse sonraki port, yanıt-tekrar-dene
15×200ms — sabit uyku yok), `GET /` transport yanıtı, `/robots.txt` + `/sitemap.xml` 200;
*raporlayıcı* (yalnız WARN/not): `/` durum kodu, `<html>` marker'ı, PHP Fatal/Parse/Uncaught
imzası, `SMOKE_PATHS` ek rotaları. `--url <canlı>` canlı mod = aynı raporlayıcı katman
(`--strict` ile WARN → exit 1). Rapor `.factory/smoke-report.json`'a (`SMOKE_REPORT`
yönlendirir; **asla** paket dizinine yazılmaz). Geçiş: rapor yazıldıktan sonra **PASS** →
mevcut `Yukleme/` `.factory/yukleme-archive/<UTCts>-<hash12>`'ye taşınır (yanına
`MANIFEST.json`: `source_hash`, `sql_dump_hash`, `built_at`, `smoke_result`; son
`YUKLEME_ARCHIVE_KEEP` (varsayılan 3) paket tutulur), staging **atomik takas** ile
`Yukleme/` olur; **FAIL** → staging `.factory/yukleme-failed`'a (+ FAIL `MANIFEST.json`)
taşınır, mevcut `Yukleme/` dokunulmadan korunur (geri alma = eski paket yerinde durur).
`php -S` `.htaccess` rewrite'larını uygulamaz — rewrite bağımlı rotalar canlıda (`--url`)
doğrulanır (yalnızca rapor notu). Arşiv/staging/failed dizinleri `qa-gate` taramasından ve
bootstrap kopyasından muaftır; final paketin §14 ağacı değişmez (`MANIFEST.json` yalnız
arşiv/failed içine yazılır).

## 8. Ortam & Araç Sırası

| Adım | Araç | Yoksa |
|------|------|-------|
| Syntax | `php -l` | QA FAIL (php-cli zorunlu) |
| Statik analiz | `phpstan` (Level 8) | yapılandırma/araç yoksa **FAIL** (zorunlu çekirdek) |
| Birim test | `phpunit` (`phpunit.xml`) | yapılandırma/araç yoksa **FAIL** (zorunlu çekirdek) |
| Frontend lint | `eslint` | yapılandırma yoksa SKIPPED (tek tolerans); varsa araç zorunlu |
| Statik eşik | `static_coverage` = phpstan ∧ phpunit PASS | aksi **FAIL** (§6) |
| Paketleme | `bash`, `python3`, `shasum` | zorunlu |
| Kontrat doğrulama | `python3 -m pip install jsonschema` | yoksa zorunlu-alan/const yedeği |
| SQL dump | `sql-dump.sh` (python3) | migrations yoksa `sql_dump` SKIPPED; varsa drift **FAIL** |
| Lighthouse | `lighthouse` (npm) + `LIGHTHOUSE_URL` | env/araç yoksa SKIPPED — **raporlayıcı faz** (§9) |
| Smoke test | `php -S` + `curl` (+ `php -l`) | araç yoksa paketleme **FAIL** (paket doğrulanamaz — zorunlu) |
| Minify | `npx --no-install terser/csso` | `minify: skipped` notu |

Araç kurulumu (garantici teslimat):

```bash
composer global require phpstan/phpstan phpunit/phpunit
npm install -g eslint
```

`qa-gate.sh`/`self-test.sh` composer global bin dizinlerini (`~/.composer/vendor/bin`,
`~/.config/composer/vendor/bin`) PATH'e otomatik ekler.

## 9. Route / Komut Eşlemesi

| İşlem | Cursor | Claude Code | opencode |
|-------|--------|-------------|----------|
| Başlat (P1 + intent) | `/web-baslat` | `bash scripts/web/state.sh start` | `/web-baslat` |
| Orkestratör (faz sürücüsü) | `/web-baslat` | `bash scripts/web/orchestrate.sh .` | `/web-baslat` |
| — (`--auto` metrikleri) | — | `<proje>/.factory/metrics.jsonl` (reporter-only) | — |
| QA kapısı | `/web-denetle` | `bash scripts/web/qa-gate.sh .` | `/web-denetle` |
| Paketle | `/web-yukle` | `bash scripts/web/package-yukleme.sh .` | `/web-yukle` |
| Faz durumu | `/web-faz` | `bash scripts/web/state.sh status` | `/web-faz` |
| Canlı doğrulama (Lighthouse) | — | `bash scripts/web/lighthouse-verify.sh .` | — |
| Temiz bootstrap (yeni proje) | — | `bash scripts/web/bootstrap-project.sh <hedef> [--yes] [--force]` | — |

**Lighthouse faz yerleşimi (v1 kararı):** P5 **sonrası bağımsız, raporlayıcı** bir fazdır —
state graph'a girmez, `qa-gate.sh`'yi ağırlaştırmaz (çalışan sunucu + Chrome gerekir;
gate "hızlı ve deterministik" kalır). Sonuç `.factory/lighthouse-report.json`'a yazılır;
`LIGHTHOUSE_URL` tanımlı değilse veya `lighthouse` kurulu değilse **SKIPPED** (exit 0).
Eşikler (kategori ≥90, LCP <2.5s, CLS <0.1) ilk sürümde **bloklayıcı değildir** —
altında kalınırsa `result: WARN` + exit 0; sıkılaştırmak istenirse `--strict` ile
WARN → exit 1. `--serve` geçici `php -S` ile URL türetir. Paketlemeye girmez
(`.factory/` denylist'tedir).

**Operasyon notu (opencode):** `.opencode/agent/*` ve `.opencode/command/*` değişiklikleri
yalnız opencode **yeniden başlatıldığında** yüklenir; `opencode debug config` ile doğrula.
exFAT/FAT32 hacimlerde `._*` AppleDouble ikizleri komut/ajan listesini bozar — paketleme
ve `debug config` öncesi `find . -name '._*' -delete` ile temizle.

## 10. Referanslar

- State kontratı: `.factory/web-state-graph.json`
- Artefakt şemaları: `.factory/contracts/{p1-domain-report,p3-qa-report,p5-packaging-report}.schema.json`
- Örnek state: `.factory/web-state.example.json`
- Orkestratör: `bash scripts/web/orchestrate.sh <proje> [--auto] [--strict]`
- Agent metrikleri: `<proje>/.factory/metrics.jsonl` (`--auto` reporter-only; parse
  edilemezse `parse_error: true` — gate/exit kodu değişmez)
- SQL dump üretici: `bash scripts/web/sql-dump.sh <proje> [--output <path>]`
- Lighthouse (raporlayıcı): `bash scripts/web/lighthouse-verify.sh <proje> [--serve] [--strict]`
- Temiz bootstrap: `bash scripts/web/bootstrap-project.sh <hedef> [--yes] [--force]`
  (dry-run default; kopya/hariç listesi betiğin baş yorumunda; ilk commit
  `bootstrap from app-fabrika@<12-hex>` — fabrika sürümü izlenebilir)
- Smoke test: `bash scripts/web/smoke-test.sh <dizin> | --url <canlı> [--strict]`
  (`SMOKE_PORT`/`SMOKE_PATHS`/`SMOKE_REPORT` env; paketleme içinde otomatik çağrılır)
- Öz-test: `bash scripts/web/self-test.sh` (CI ile aynı sahne; phpstan+phpunit+eslint gerektirir)
- CI: `.github/workflows/validate.yml`
