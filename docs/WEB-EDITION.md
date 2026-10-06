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
```

Eksik faz artefaktını (P1 raporu, P2 iskeleti, P4 düzeltmesi) **bekletir**; hazır olanı
işler, HALT'ı aynadan geçirir. Çıktı raporları `.factory/contracts/*.schema.json` ile
doğrulanır (`jsonschema` varsa tam, yoksa zorunlu-alan/const yedeği).

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
(P1 artefaktı varsa: module_matrix ≥4, dolu evidence/justification) · **statik/test
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
| QA kapısı | `/web-denetle` | `bash scripts/web/qa-gate.sh .` | `/web-denetle` |
| Paketle | `/web-yukle` | `bash scripts/web/package-yukleme.sh .` | `/web-yukle` |
| Faz durumu | `/web-faz` | `bash scripts/web/state.sh status` | `/web-faz` |
| Canlı doğrulama (Lighthouse) | — | `bash scripts/web/lighthouse-verify.sh .` | — |

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
- Orkestratör: `bash scripts/web/orchestrate.sh <proje> [--auto]`
- SQL dump üretici: `bash scripts/web/sql-dump.sh <proje> [--output <path>]`
- Lighthouse (raporlayıcı): `bash scripts/web/lighthouse-verify.sh <proje> [--serve] [--strict]`
- Öz-test: `bash scripts/web/self-test.sh` (CI ile aynı sahne; phpstan+phpunit+eslint gerektirir)
- CI: `.github/workflows/validate.yml`
