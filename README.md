# App-Fabrika Web Edition

**Freelance web projesi üretim fabrikası:** deterministik state graph, 5 ajanlı
denetim, IDE-agnostik kontratlar ve 14 kontrollü QA gate ile PHP/MySQL projelerini
tek komutla üretir.

Eksik CRUD, unutulan RBAC, kırık bağımlılık ve token israfı problemlerini çözer:
her proje aynı kapılardan geçer — domain analizi → kod → QA → paketleme.
Üç IDE (Cursor / OpenCode / Claude Code) aynı `.factory/` state'ini okur/yazar.

[![CI](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml/badge.svg)](https://github.com/UlasKasikci/repo/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![self-test](https://img.shields.io/badge/self--test-48%2F48%20PASS-brightgreen.svg)](scripts/web/self-test.sh)

---

## Problem ve Çözüm

| Problem | Çözüm |
|---------|-------|
| Her projeye sıfırdan başlama | `bootstrap-project.sh` + iskelet kopyalama |
| Eksik CRUD / unutulan RBAC / kayıp KVKK | P1 proaktif domain denetimi (module_matrix kapısı) |
| Kırık bağımlılık, sessiz hata | QA gate: 14 kontrol, 0 Error / 0 Warning zorunlu |
| Token israfı (14M/proje) | model routing, batch yazma, watchdog; hedef 3-4M |
| IDE kilitlenmesi | IDE-agnostik kontratlar (`.factory/contracts`) |

---

## Mimari Genel Bakış

### State Graph

```mermaid
flowchart LR
    START --> P1[P1 Domain & Scope]
    P1 --> P2[P2 Code Gen]
    P2 --> P3[P3 QA Pool]
    P3 -->|qa-gate PASS| P5[P5 Packaging]
    P3 -->|FAIL retry 1-3| P4[P4 Revision]
    P4 --> P3
    P3 -->|4. FAIL| HALT[HALT + debug_report]
    P5 -->|yukleme-verified| DONE[DONE]
```

```text
START → P1 → P2 → P3 ──PASS──→ P5 → DONE
                 │
                 ├─FAIL (retry 1-3)→ P4 → P3
                 └─4. FAIL → HALT + debug_report.json
```

- Kapı artefaktları: P1 `domain-report.json` (şema doğrulanır) · P3 `qa-gate.sh`
  exit 0 · P5 `packaging-report.json` result=PASS.
- `max_retries: 3` — 4. başarısızlık HALT; sonsuz döngü yok.
- `additionalProperties: true` şemalar korunur (opsiyonel alan ekleme serbest).

### Ajanlar (5)

| # | Ajan | Dosya | Faz | Sorumluluk |
|---|------|-------|-----|-----------|
| 1 | Requirement & Domain Architect | `.cursor/agents/web-domain-architect.md` | P1 | İstek ayrıştırma; eksik modül (RBAC, sepet, KVKK) proaktif enjeksiyonu |
| 2 | Core Web & Database Engineer | `.cursor/agents/web-core-engineer.md` | P2, P4 | PHP 8.1+ MVC çekirdek, PDO şema, normalize SQL |
| 3 | UI/UX & Frontend Specialist | `.cursor/agents/web-frontend-specialist.md` | P2 | Semantik HTML5, erişilebilir, SEO dostu arayüz |
| 4 | QA & Security Gatekeeper | `.cursor/agents/web-qa-gatekeeper.md` | P3 | `qa-gate.sh` işletir; PASS vermeden faz geçişi yok (`readonly`) |
| 5 | Production Deployment & Packager | `.cursor/agents/web-deploy-packager.md` | P5 | Build isolation + `Yukleme/` üretimi |

Tek ajan onayı yasaktır: P1→P2 yalnız domain raporuyla, P3→P5 yalnız QA PASS'ıyla.

### Katmanlar

```text
┌─ Kontratlar ── .factory/contracts/*.schema.json (P1/P3/P5 artefakt doğrulama)
├─ Ajanlar ───── .cursor/agents/ + .opencode/agent/ + .cursorrules + CLAUDE.md
├─ QA Gate ───── scripts/web/qa-gate.sh (14 kontrol, 0 Error 0 Warning)
└─ Paketleme ─── scripts/web/package-yukleme.sh (staging → smoke → arşiv → takas)
```

---

## Dosya Yapısı

```text
app-fabrika/
├── .cursor/                  # Cursor IDE config
│   ├── rules/                # Proje kuralları
│   └── agents/               # 5 ajan tanımı
├── .opencode/                # OpenCode CLI config
│   ├── agent/                # 5 ajan tanımı (paralel)
│   ├── skills/               # Modül iskeletleri (kvkk-compliance, admin-crud, auth-rbac)
│   └── command/              # Slash komutlar (/web-baslat, /web-denetle, ...)
├── .factory/                 # Runtime state (proje-başına)
│   ├── contracts/            # p1/p3/p5 JSON şemaları
│   ├── web-state-graph.json  # State graph kontratı
│   ├── web-state.example.json
│   ├── model-pricing.json    # Model rate kartları
│   ├── e2e-runs/             # E2E koşu arşivi (yerel, commit dışı — bulgular docs/findings/)
│   └── metrics.jsonl         # Token/latency/model_used (proje-başına)
├── scripts/web/              # Orkestrasyon
│   ├── orchestrate.sh        # Faz sürücüsü (--auto / --strict)
│   ├── state.sh              # State geçişleri (start/advance/qa-pass/qa-fail)
│   ├── qa-gate.sh            # 14 kontrol
│   ├── frontmatter-check.sh  # Frontmatter kontratı (qa-gate 14. kontrol)
│   ├── package-yukleme.sh    # Paketleme (staging → smoke → arşiv → takas)
│   ├── smoke-test.sh         # php -S + curl canlı doğrulama
│   ├── sql-dump.sh           # Deterministik SQL dump (drift'e karşı)
│   ├── bootstrap-project.sh  # Yeni proje başlatma
│   ├── e2e-driver.sh         # E2E driver + idle watchdog (L3)
│   ├── lighthouse-verify.sh  # Lighthouse (raporlayıcı, opsiyonel)
│   └── self-test.sh          # 47 senaryo
├── docs/                     # Kanonik dokümanlar
│   ├── WEB-EDITION.md        # Teknik spesifikasyon
│   ├── MASTER-PROMPT-V2.md   # Stratejik karar + K1-K8
│   ├── FAZ2-PLAN.md          # Token ekonomisi planı
│   ├── audits/               # CONTRACT-AUDIT + REVIEW-NOTES (K8)
│   ├── protocols/            # E2E protokol notları + rapor taslakları
│   └── findings/             # E2E kalıcı bulgular (run dir commit dışı)
├── tests/                    # Fabrika testleri
├── CLAUDE.md                 # Claude Code CLI direktifleri
├── .cursorrules              # Cursor kuralları
├── antigravity.yaml          # Antigravity/Freebuff config
└── opencode.json             # OpenCode config
```

---

## Hızlı Başlangıç

### Gereksinimler

- `bash` · `php` 8.1+ (CLI) · `python3` · `git` · `shasum`
- Opsiyonel: `node`/`npm` (eslint, minify, lighthouse), `composer global`
  (`phpstan/phpunit/phpunit` — qa-gate için zorunlu)

### Kurulum

```bash
git clone https://github.com/UlasKasikci/repo.git && cd repo

# phpstan + phpunit (qa-gate'in asimetrik çekirdeği)
composer global require phpstan/phpstan phpunit/phpunit

# fabrika kendini sınamalı
bash scripts/web/self-test.sh          # hedef: 48/48 PASS
```

### Yeni proje

Tek komut (iki IDE — Cursor `/kur`, opencode `/kur`): kontrat okur, bootstrap eder,
state'i P1'e alır, QA doğrular, özet sunar. IDE yoksa terminal eşdeğeri:

```bash
# dry-run (default) — ne kopyalanacağını gösterir
bash scripts/web/bootstrap-project.sh ../my-project

# uygula
bash scripts/web/bootstrap-project.sh ../my-project --yes

# sonra: state start + qa-gate (veya IDE'de /kur + /web-baslat)
```

Bootstrap ~1.3M (Tur 2-11: denylist `.opencode/{node_modules,sessions,storage,logs,cache}`
+ `.cursor/{snapshots,history,cache}` + `.factory/{e2e-runs,test-runs}` — 7.9G runtime
bloat'ı kopyalanmaz).

### Üretim hattı

```bash
cd ../my-project

bash scripts/web/state.sh start          # P1, retry=0
bash scripts/web/orchestrate.sh . --auto # P1 → P2 → P3 sürüşü (artifact kapıları)
bash scripts/web/qa-gate.sh .            # 0 Error, 0 Warning olmadan P5 yok
bash scripts/web/package-yukleme.sh .    # Yukleme/ (yalnız QA PASS sonrası)
bash scripts/web/state.sh status         # aktif faz
```

Çıkış kodları: `0` OK · `1` FAIL · `2` HALT · `3` orkestratör bekleme (LLM adımı).

### Test projesi temizliği

Saha testleri için bootstrapped izole dizinler `../test-project-<ts>/` altında
yaşar. Silmeden önce raporlar `.factory/test-runs/<ts>/` altına kopyalanır
(zaten oradadır):

```bash
# onay isteyerek (default)
bash scripts/web/test-project-clean.sh ../test-project-20261010T155312Z

# onaysız
bash scripts/web/test-project-clean.sh ../test-project-20261010T155312Z --yes
```

Güvenlik: `.factory/web-state.json` olmayan dizin, ana repo içi dizin ve
kök/home silinemez (RED, exit 1). Log: `.factory/test-runs/cleanup.log`.

### Ortam Değişkenleri

| Değişken | Varsayılan | Ne işe yarar |
|----------|-----------|--------------|
| `MODEL_P1` / `MODEL_P2` / `MODEL_P4` | hardcoded map | Faz bazlı model routing (`provider/model`) |
| `STRICT_TOTAL_TOKENS` | 8.000.000 | `--strict` toplam bütçe eşiği (2× → exit 1) |
| `STRICT_PHASE_TOKENS` | 6.000.000 | P2-P4 tek faz eşiği |
| `STRICT_WALL_MS` | 10.800.000 | Duvar saati bütçesi (3 saat) |
| `SMOKE_PORT` / `SMOKE_PATHS` | 18000+ | Smoke test portu / ek rotalar |
| `LIGHTHOUSE_URL` | — | Tanımlı değilse Lighthouse SKIPPED |
| `E2E_TIMEOUT_SEC` / `E2E_MAX_TOKENS` | 10.800 / 15M | E2E driver dış watchdog bütçesi |
| `P2_HUMAN_ASSIST` | `false` | `true` → P2 hybrid mod (aşağıda) |

### P2 Hybrid Mod — model uyumsuzluğunda manuel üretim

P2 kod üretimi model uyumsuzluğunda (Tur 2-9/2-10: glm-5.3 0/10 write) kullanılır:
otomatik LLM kapalı, iskeleti insan yazar, P3-P5 otomatik devam eder.

```bash
P2_HUMAN_ASSIST=true bash orchestrate.sh --auto   # → "manuel P2 gerekli" + exit 3
# (iskeleti elle yaz)
bash state.sh advance .                            # P2 → P3
bash orchestrate.sh . --auto                       # P3-P5 otomatik
```

Claude 5.5 çıktığında: `MODEL_P2=claude-sonnet-5.5` tek pilotu — PASS ise hybrid
devre dışı (tam otomatik), FAIL ise hybrid kalıcı.

---

## Kullanım — Üç IDE

| IDE | Config | Kullanım |
|-----|--------|----------|
| Cursor | `.cursor/` + `.cursorrules` | Klasörü aç; 5 ajan + kurallar otomatik yüklenir |
| OpenCode | `.opencode/` + `opencode.json` | `opencode run --agent web-core-engineer` · `/web-baslat` |
| Claude Code | `CLAUDE.md` | `claude` CLI repoyu açınca direktifleri otomatik okur |

- Her IDE aynı `.factory/` state'ini okur/yazar; IDE değişimi state kaybı yaratmaz.
- Komut eşlemesi (`docs/WEB-EDITION.md` §10): `/web-baslat` · `/web-denetle` ·
  `/web-yukle` · `/web-faz`.
- ⚠ exFAT/FAT32 hacimlerde `find . -name '._*' -delete` — AppleDouble ikizleri
  komut/ajan listesini bozar.

---

## QA Gate — 14 Kontrol

`bash scripts/web/qa-gate.sh <proje>` → **0 Error, 0 Warning** zorunlu.

| # | Kontrol | Ne yapar | FAIL koşulu |
|---|---------|----------|-------------|
| 1 | `php_lint` | Tüm `.php` dosyalarına `php -l` | Sözdizimi hatası |
| 2 | `structure` | MVC yapısı (`core/`, `views/`, `index.php`) | Dosya eksik |
| 3 | `sql_schema` | FK + index + seed + RBAC + sepet | Eksik CONSTRAINT/INSERT |
| 4 | `security_grep` | OWASP grep: eval, `mysql_*`, ham md5, superglobal-in-query | Eşleşme |
| 5 | `security_policy` | CSRF'siz POST, ham çıktı basımı | Eşleşme |
| 6 | `password_policy` | `PASSWORD_ARGON2ID` / `BCRYPT` cost ≥ 12 | Zayıf hash |
| 7 | `phpstan` | Level 8 statik analiz (zorunlu çekirdek) | Yapılandırma/araç yoksa |
| 8 | `phpunit` | Birim testleri (zorunlu çekirdek) | Yapılandırma/araç yoksa |
| 9 | `eslint` | JS lint | Yapılandırma yoksa SKIPPED (tek tolerans) |
| 10 | `sql_dump` | Üretilen dump = commit'li dump (byte) | Drift |
| 11 | `kvkk` | intent=kvkk\|gdpr → legal view + consent + 2 tablo | Eksik (none → SKIPPED) |
| 12 | `domain_report` | P1 artefaktı: module_matrix ≥4, dolu evidence/justification | Şablon/uydurma kanıt |
| 13 | `static_coverage` | `phpstan ∧ phpunit` | Aksi her koşulda FAIL |
| 14 | `frontmatter` | Fabrika agent/rule/skill frontmatter kontratı (`mode`/`permission`/`globs`/K1-K8 ref) | Ref üstte, dead rule, eksik alan (K6 istisnası — somut regresyon) |

Çıktılar: `qa-report.json` (her koşuda) · `debug_report.json` (yalnız FAIL).

---

## Paketleme — `Yukleme/` Çıktısı

```text
staging (.factory/yukleme-staging)
   → smoke-test.sh (php -l + php -S + curl; FAIL → paket reddedilir)
   → mevcut Yukleme/ arşive taşınır (.factory/yukleme-archive/<ts>-<hash>/)
   → staging atomik takasla Yukleme/ olur
   → packaging-report.json (sha256 manifest)
```

```text
Yukleme/
├── assets/{css,js,images}/
├── core/  ├── views/
├── SQL/veritabani.sql          # CREATE TABLE + FK + seed, UTF-8
├── .htaccess  ├── index.php
├── robots.txt ├── sitemap.xml
```

- **Girmez:** `node_modules/`, `.git/`, `.env` (`.env.example` serbest), testler,
  `.scss`/`.ts` kaynakları, `.factory/`, raporlar.
- `MANIFEST.json` yalnız arşiv/failed içine yazılır; final paket ağacı sabittir.

---

## Yol Haritası

### v1 — Starter Kit (Şimdi)

- Bootstrap + üç IDE config + QA gate (14) + paketleme + self-test (47)
- **Tamamlandı:** A1 okuma yasağı + QUESTIONS kapısı + A2 spike→write + A2' duvar-saati
  + L3 watchdog (idle+stream+CPU+no-write-cap+cpu_time_pid) + frontmatter kontratı
  + manifest-onaylı whitelist + K1a-fix plugin (`nim-stall-retry`, bun:sqlite DB polling)
  + tek-turn iskelet promptu (A.2) + `/kur` komutu (iki IDE) + CJK-check CI
  + F1-F11 (bootstrap denylist / manifest-safe add / scaffold_ok / template kopya /
  docs / traceability / kvkk-regex / P3-P5 / F9 kill_tree / F10 kapsam / F11 kur ipucu)
- **Bilinen kısıt (Tur 2-9/2-10/2-13):** P2 kod üretimi **0/10 write** (glm-5.3 0/7,
  kimi-k3 halüsinasyon). Prompt katmanı sonucu değiştirmedi — duvar model/sağlayıcı
  tarafında. **Hybrid mod** (`P2_HUMAN_ASSIST=true`) Tur 2-13'te uçtan uca
  doğrulandı (exit 3 + template → manel iskelet → P3/P5 → DONE). v1.0 final =
  P2'yi yazabilen model/sağlayıcı çıkana kadar ertelendi (JEV v2 MCP de erteli).

### v2 — Optimize (2-3 ay)

- JEV model routing + bağlam pruning → **hedef %20-30 P2 token düşüşü**
- Modül kütüphanesi (`.factory/modules/`): KVKK, admin-CRUD, auth-RBAC
  → LLM çağırmadan kopyalama
- **Hedef:** 14M → 3-4M token (Cursor Pro tek paket)
- Kapı: JEV on/off E2E karşılaştırması ≥%20 · modül kısımlarında ≥%80 ·
  5+ E2E dağılımı ile per-model `--strict` eşikler

### v3 — Kalibre (6-12 ay)

- Tüm modüller şablonlaşmış; <1M token ütopyası ama istikamet
- Çoklu dil/framework desteği (opsiyonel)

---

## Release

| Sürüm | Durum | Not |
|-------|-------|-----|
| v1.0-rc1 | Release Candidate (2026-10-09) | Starter Kit |
| v1.0-rc2 | Release Candidate (2026-10-10) | /kur + tek-turn prompt + K1a-fix plugin + hybrid mod + CJK CI |
| **v1.0-rc3** | **Release Candidate** (2026-10-11) | Hybrid iş akışı uçtan uca saha PASS (Tur 2-13) — F1-F11 fix + F3/F4/F10 doğrulandı |
| v1.0 | Planlı | P2 model çıkınca final |
| v2 | Planlı | JEV routing + modül kütüphanesi |
| v3 | Vizyon | Şablonlaşma, <1M token istikameti |

rc2, Tur 2-9/2-10 P2 pilotundan **bağımsız**dır: kod tabanı CI yeşil + self-test
43/43 ile donduruldu; P2 model sorunu hybrid mod ile workaround edildi.
rc3, **hybrid akışın** (P1 → `P2_HUMAN_ASSIST` → manel iskelet → P3 → P5 → DONE)
Tur 2-13 e-ticaret projesinde 27 dk'da uçtan uca PASS'ı ile etiketlendi.

## Production Readiness

| Faz | Durum | Kanıt |
|-----|-------|-------|
| P1 (Domain) | ✓ Çalışıyor | 14-22 dk, 7-10 modül; Tur 2-13'te **ilk deneme PASS** (8 modül, kvkk compliance) |
| P2 (Kod) | ⚠ Model sınırı + ✓ hybrid | auto write **0/10** (glm-5.3 0/7, kimi-k3 halüsinasyon); hybrid mod (exit 3 + 3/3 config template) **uygulanıp P3-P5'e geçildi** |
| P3 (QA) | ✓ Çalışıyor | 14/14 kanal PASS (Tur 2-13: 9→6→3→0 hata düzeltme turu) |
| P5 (Paketleme) | ✓ Çalışıyor | staging + smoke + MANIFEST; Tur 2-13'te `Yukleme/` üretilip DONE (`yukleme-verified`) |

**v1.0 final, P2'yi yazabilen model/sağlayıcı çıkınca.** Hybrid mod uzun vadede
**uçtan uca doğrulandı** (Tur 2-13: P1 PASS → hybrid exit 3 → manel iskelet →
P3 14/14 PASS → P5 `Yukleme/` → DONE, 27 dk, 2 LLM denemesi; Tur 2-10'dan
−%37 token / −%66 süre). Kalan: P2 *auto* write hâlâ 0 (B-1 kvkk-regex,
B-2 driver-P2-tetikleme bulguları için RUN-REPORT-2 §6).

---

## Bilinen Sorunlar

- **P2 model hızı:** glm-5.3 pilotda 30dk'da iskeleti tamamlayamadı (kill yok —
  yavaş ama üretken). Tur 2-3 tam bütçeyle ölçüyor; eşik: P2 < 8 saat.
- **B2 write SchemaError ~%6.8:** harness-side NDJSON şema kayması (prompt ile
  çözülemez; schema-recovery devrede — P1'de 3× tetiklendi, kurtarıldı).
- **acceptance_criteria → test eşlemesi henüz enforce edilmiyor (v1.x):**
  `p1-domain-report.schema.json` alanın "traceability" vaadini şimdilik
  "future work" olarak işaretler; qa-gate bu eşlemeyi henüz işletmiyor.

---

## Değişmez Kurallar (K1-K8)

Tam metin: [`docs/MASTER-PROMPT-V2.md`](docs/MASTER-PROMPT-V2.md)

| # | Kural | Tek cümle |
|---|-------|-----------|
| K1 | Hard-kill yasak | Reasoning spike'ta kesme = üretken attempt'i öldürür (imza-c) |
| K2 | İmza-bazlı tedavi | Aynı spike (b)'de ölü, (c)'de canlı; kök nedeni tedavi et |
| K3 | Ölçmeden karar yok | Spekülatif eşik değişikliği ve n=2 hüküm yasak |
| K4 | Kontrat tamlığı > yasak | Eksik kontrat + yasak = sessizce yanlış üretim |
| K5 | Belge kanıttan türesin | `[x]` yalnız qa-gate PASS sonrası; halüsinasyon yasak |
| K6 | Denetim %90'da donduruldu | Yeni QA kontrolü yalnız somut bug için |
| K7 | İki imza, iki kol | Model + bağlam değişimi aynı turda test edilmez |
| K8 | Silme değil işaretleme | Reddedilen yaklaşım `docs/audits/REVIEW-NOTES`'a yazılır |

---

## Katkı

1. Issue aç veya PR gönder — PR'da `bash scripts/web/self-test.sh` **48/48 PASS**
   ve CI yeşil olmalı.
2. Yeni QA kontrolü yalnız somut bir bug raporuyla eklenir (K6).
3. Doküman güncellemeleri kanıttan türetilir (K5).

## Lisans

[MIT](LICENSE) © 2026 UlasKasikci
