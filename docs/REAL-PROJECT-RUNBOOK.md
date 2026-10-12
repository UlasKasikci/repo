# GERÇEK PROJE KOŞU KILAVUZU — Webrail

Fabrikayı sıfırdan gerçek bir domain'e koymak için adım adım, kopyalanabilir
komutlar. Tüm sözdizimleri betik `usage` satırlarıyla doğrulanmıştır
(`state.sh`/`orchestrate.sh`/`bootstrap-project.sh`/`measure.sh`).
Ölçüm şablonu: `docs/templates/RUN-REPORT-template.md` · Referans koşu:
`.factory/test-runs/20261011T005542Z/RUN-REPORT-2.md` (Tur 2-13, e-ticaret, DONE).

**Çıktı kontratı (exit):** `0` DONE/OK · `1` hata/geçersiz artefakt · `2` HALT ·
`3` bekleme (LLM/manuel adım gerekli — aynı yerden yeniden çalıştır).

---

## 0. Ön hazırlık

```bash
# garantici araçlar (qa-gate zorunlu çekirdeği: phpstan + phpunit FAIL'SE gate FAIL)
composer global require phpstan/phpstan phpunit/phpunit
npm install -g eslint

# exFAT/FAT32: ._ AppleDouble ikizleri betik/komut listesini bozar
find <hedef_dizini> -name '._*' -delete
```

`<hedef_dizini>` = yeni projenin yolu (örn. `../musteri-projesi`). Aşağıdaki tüm
komutlar **fabrika kökünden** çalıştırılır; `<proje>` = `<hedef_dizini>`.

## 1. Bootstrap (dry-run → onay → kopya)

```bash
bash scripts/web/bootstrap-project.sh <proje>            # DRY-RUN: liste+sayı, dokunmaz
bash scripts/web/bootstrap-project.sh <proje> --yes      # kopyala + git init + ilk commit
```

Ölçüm (RUN-REPORT §1): `bash scripts/web/measure.sh <proje> kur_duration_s <saniye>`

## 2. State + P1 (Domain & Scope)

```bash
bash scripts/web/state.sh start <proje>                  # P1, retry=0 (opsiyonel —
                                                         # orchestrate state yoksa otomatik start;
                                                         # mevcut/bozuk state: --reset yedekler + sıfırlar)
bash scripts/web/orchestrate.sh <proje> --auto           # P1 → P2 sürüşü
```

- P1 kapı artefaktı: `<proje>/.factory/domain-report.json` (`module_matrix` ≥4,
  evidence/justification dolu — `domain-check.py` + şema ile doğrulanır).
- `exit 3` = bekleme (ör. `QUESTIONS.json` yanıtsız) → yanıtlamadan devam etme;
  `exit 1` = artefakt/şema hatası → `qa-report.json`/konsoldaki mesajdan düzelt.

## 3. P2 — hybrid mod (önerilen; P2 auto yazım 0/10 gelene kadar resmi yol)

```bash
P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh <proje> --auto
# → Config template'leri kopyalanır (phpstan.neon.dist, phpunit.xml, .eslintrc.json)
# → exit 3 + ilk girişte .factory/hybrid-p2-start marker'ı + phase_human_assist ölçümü
```

Manel iskeleti yaz: `index.php`, `core/`, `views/`, `SQL/migrations/{schema,seed}/`,
`tests/`. Sonra:

```bash
bash scripts/web/state.sh advance <proje>                # P2 → P3
# (marker varsa manual_p2_min ölçüm satırı otomatik yazılır + marker temizlenir)
P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh <proje> --auto   # P3-P5 devam
```

## 4. P3 → P5 — otomatik sürüş

`--auto` altında: `qa-gate --record` FAIL → `qa-fail` (retry++ → P4) → P4 LLM
düzeltme → tekrar gate; PASS → `qa-pass` → P5 `package-yukleme.sh` (içinde smoke)
→ `advance` → `DONE`, **exit 0**.

```bash
bash scripts/web/qa-gate.sh <proje>                      # manel kapı (opsiyonel; --record yazmaz)
bash scripts/web/package-yukleme.sh <proje>              # manel paketleme (QA PASS sonrası!)
```

- **QA FAIL düzeltme döngüsü:** hataları `<proje>/qa-report.json` → `checks` →
  dosyayı düzelt → yeniden `orchestrate.sh <proje> --auto`. 3 başarısızlık
  toleranslıdır; **4. → HALT (exit 2)** + `debug_report.json` — sonsuz döngü yok.
- SQL: `bash scripts/web/sql-dump.sh <proje>` (migrations varsa; drift QA'da
  byte-compare ile FAIL verir — dump'ı elle değil betikle üret).

## 5. Durum / hata ayıklama

```bash
bash scripts/web/state.sh status <proje>                 # faz, retry, history
cat <proje>/debug_report.json                            # yalnız HALT'ta
```

| Exit | Anlam | Eylem |
|------|-------|-------|
| 3 | bekleme (LLM/manuel adım) | adımı yap, aynı komutu tekrar çalıştır |
| 1 | artefakt/şema/bütçe hatası | mesajı düzelt, yeniden çalıştır |
| 2 | HALT (retry > 3) | `debug_report.json` → kök neden → `state.sh start <proje> --reset` (mevcut state yedeklenir) |
| 0 | DONE | §6 doğrulama |

`--strict`: bütçe 1× aşımlarını uyarır; 2× → SERT AŞIM (exit 1, aynı yerden devam).

## 6. Bitti mi? (zorunlu doğrulama)

```bash
bash scripts/web/state.sh status <proje> | grep -E 'current_phase|"status"'  # DONE / done
python3 -c "import json;print(json.load(open('<proje>/packaging-report.json'))['result'])"
bash scripts/web/qa-gate.sh <proje>                      # son kez: Check: PASS (0 Error 0 Warning)
ls <proje>/Yukleme/                                      # §14 ağacı: assets/ core/ views/
                                                         # SQL/veritabani.sql index.php .htaccess …
```

Not: `MANIFEST.json` **`Yukleme/`'de değildir** — yalnızca `.factory/yukleme-archive/`
(geri alınabilir arşiv) ve `yukleme-failed/` içine yazılır. Kalıcı kanıt
`<proje>/packaging-report.json` (sha256 manifest + skipped/nots).

## 7. Ölçüm + RUN-REPORT

`.factory/metrics.jsonl` iki satır tipi taşır: **agent** satırları
(`rc, latency_ms, tokens, retry_count, model_used` — otomatik) ve **`kind: measure`**
satırları (insan ölçümü):

```bash
bash scripts/web/measure.sh <proje> kur_duration_s 42        # §1: /kur süresi (manuel)
# otomatik: phase_human_assist=true  → hybrid girişinde (orchestrate)
# otomatik: manual_p2_min            → advance P2→P3'te marker'dan (state.sh)
```

RUN-REPORT: `cp docs/templates/RUN-REPORT-template.md <proje>/.factory/test-runs/$(date -u +%Y%m%dT%H%M%SZ)/RUN-REPORT.md`
→ doldur (§1-§4 tabloları, §2 sıfırdan karşılaştırma = metric'ler; §6 öneriler).
Alan adları kendiliğinden kabul edilir (`measure.sh` serbest alan yazar).

## 8. Yayına hazırlık (opsiyonel)

```bash
bash scripts/web/lighthouse-verify.sh <proje> --serve     # raporlayıcı faz (state graph'a girmez)
git -C <proje> add -A && git -C <proje> commit -m "feat: web edition bootstrap + DONE"
# push/CI: fabrika deposunda — gh run watch <id> -R UlasKasikci/repo --exit-status
```

---

**Kısıtlar (K1-K8):** K6 QA gate 0/0 olmadan `Yukleme/` yasak · K7 model izole ·
state graph `docs/WEB-EDITION.md` §2 (bu kılavuz onu DEĞİŞTİRMEZ) ·
`Yukleme/` commit edilmez · TAG yalnız denetim/CI sonrası.
