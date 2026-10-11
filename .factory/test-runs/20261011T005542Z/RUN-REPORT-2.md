# RUN-REPORT-2 — Tur 2-13 · Uçtan Uca Hybrid İş Akışı (E-ticaret)

**Tarih:** 2026-10-11 · **TS:** 20261011T005542Z · **Proje:** `../test-project-2-20261011T005542Z`
**Domain:** E-ticaret / ürün katalog (RBAC, kategori→ürün, sepet/sipariş, ödeme simülasyonu, KVKK, admin)
**Başlangıç:** 00:56:30Z · **Bitiş (DONE):** ~01:23Z · **Toplam:** ~27 dk (2 saat sınırı: ✓)
**Sonuç:** **PASS** — P1 → hybrid P2 (exit 3 + template) → manel simülasyon → P3 (14/14 kanal) → P5 `Yukleme/` → `DONE`

---

## 1. Faz Zamanı

| Faz | İş | Süre | Çıktı |
|-----|-----|------|-------|
| A.0 | Ön koşul (status/origin/CI/self-test) | ~1 dk | self-test **47/47 PASS** |
| A.1 | Bootstrap + `.git` izolasyon | ~1 dk | **1.0 MB gerçek** (du 855M = exFAT blok yuvarlaması — D1.2 tekrarı, python getsize ile doğrulandı) |
| A.2 | `/kur` eşdeğeri + intent | **1 s** | MASTER-PROMPT ✓, `state.sh start`, kasıtlı FAIL (11 hata), intent compliance=kvkk, 8 modül |
| A.3.1 | P1 (`orchestrate.sh --auto`) | **~21 dk** (lat 863 s) | `domain-report.json` 22.355 B ✓ — **ilk denemede PASS** |
| A.3.2 | P2 auto (driver --auto, istemsiz) | 275 s | `out=0` — bilinen duvar, tekrar etmedi |
| A.3.3 | **Hybrid** `P2_HUMAN_ASSIST=true` | <1 s | **exit 3 + 3/3 template kopyası (F4 ✓)** |
| A.3.4 | Manel P2 simülasyonu | ~1 dk | fixture 22 dosya/169 PHP satır + KVKK bloğu + bootstrap.php |
| A.3.5 | `state.sh advance` | <1 s | **F3 genişletilmiş scaffold_ok PASS** → P3 |
| A.4.1 | P3 qa-gate | 4 tur: 9→6→3→**0 hata** (3 s) | **Check: PASS (0/0)** — 14/14 kanal, F10 "Kapsam güvencesi: 1 test" |
| A.4.2 | P5 package | 5 s | **PASS**, `Yukleme/` ağacı §14 uyumlu, smoke WARN (raporlayıcı) |
| A.4.3 | `state.sh advance` | <1 s | **DONE** (`yukleme-verified`) |

## 2. Tur 2-10 vs Tur 2-13 Karşılaştırması

| Metrik | Tur 2-10 (blog) | Tur 2-13 (e-ticaret, hybrid) |
|--------|-----------------|------------------------------|
| P1 modül sayısı | 10 | 8 (rbac/cart/payment/kvkk **present**, seo injected, notification proposed) |
| P1 ilk deneme | FAIL (out=833, fs-kanıt) → 2. deneme 18 dk | **1. deneme PASS** (14.4 dk lat) |
| P2 | 0/3 write (auto, 2 deneme) | auto 0 write (1×) → **hybrid exit 3 + template kopya** |
| P3 | koşulmadı | **PASS 14/14** (F10 kapsam raporlu) |
| P5 | koşulmadı | **PASS `Yukleme/` + packaging-report** |
| LLM denemesi | 5 | **2** (P1 ✓ + P2-auto ✗) |
| Token in/out | 142.104 / 37.131 | **90.048 / 29.945** (−37% / −20%) |
| Toplam süre | ~79 dk | **~27 dk** (−66%) |
| Final state | P2 FAIL | **DONE** |

## 3. Tur 2-12 (F-fix) Saha Doğrulaması

| Fix | Saha kanıtı |
|-----|-------------|
| **F3** genişletilmiş `scaffold_ok()` | config (phpstan.neon.dist/phpunit.xml) + dolu `tests/` **zorunlu** — manel simülasyonda eksiksiz geçti |
| **F4** hybrid template kopyası | `phpstan.neon.dist` + `phpunit.xml` + `.eslintrc.json` **3/3 kopyalandı**; TPL_DIR `../..` düzgün |
| **F10** phpunit kapsam raporu | `Kapsam güvencesi: 1 test` satırı çıktı (0 test WARN kuralı test edilmedi — kapsam >0) |
| **F1** bootstrap denylist | gerçek **1.0 MB** (259 dosya) |
| **F11** kur.md hybrid ipucu | hybrid mesajı `/kur` eşdeğeri akışını doğru gösterdi (`state.sh advance` → `--auto`) |
| kvkk kanalı | ilk koşuda **7 KVKK hatası** yakaladı (legal view + consent + 2 tablo) → sonra PASS |
| sql_dump drift kanalı | `IF NOT EXISTS` append'i **drift olarak yakalandı** → `sql-dump.sh` ile düzeldi |

## 4. P3 Düzeltme Yolculuğu (QA gate gerçek davranışı)

1. **9 hata:** KVKK eksik (7) + exFAT `._*Test.php` phpunit'i bozma + static_coverage
2. **6 hata:** `._*` temizlendi + KVKK yazıldı → **regex bug ortaya çıktı** (aşağıda B-1) + sql drift + eslint boş catch + phpunit bootstrap
3. **3 hata:** migrations → `sql-dump.sh` (drift ✓), eslint fix, `tests/bootstrap.php`
4. **0 hata → PASS:** `OK (1 test, 1 assertion)`, 14/14 kanal PASS

> Not: QA gate **hiçbir turda tolere etmedi**; her hata somut, aksiyonel mesaj verdi (K6 davranışı).

## 5. Hybrid Akış (F4 çekirdeği)

```
$ P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh . --auto
==> P2 HYBRID (P2_HUMAN_ASSIST=true): otomatik kod üretimi kapalı.
    template kopyalandı: phpstan.neon.dist / phpunit.xml / .eslintrc.json
    Manuel P2 gerekli: iskeleti elle yaz ...
    Sonra: state.sh advance → orchestrate.sh --auto   # P3-P5 otomatik devam
rc=3   ← doğru bekleme kodu (mimari değil, LLM adımı)
```

Manel simülasyon **fixture kopyası** ile yapıldı (raporda açıkça simülasyon); KVKK bloğu +
`tests/bootstrap.php` elle tamamlandı (fixture'da yoktu — gerçek kullanıcının işi).

## 6. Yeni Bulgular (FINDINGS-TUR2-13)

- **B-1 (SEV-4):** qa-gate kvkk regex'i `CREATE TABLE[[:space:]]+`?tablo`` — `CREATE TABLE IF NOT EXISTS tablo`
  yazan dump'ı **yakalamaz** (test'te `sql-dump.sh` IF NOT EXISTS üretmediği için kurtardı;
  elle IF NOT EXISTS yazsaydık hatalı FAIL olurdu). Fix: regex'e `(IF NOT EXISTS )?` opsiyoneli.
- **B-2 (SEV-4):** `saha-driver.sh` tam `--auto` çalıştırır → P1 bitince **P2 auto'yu da tetikler**
  (kısıt "P2 auto denemesi YOK" ihlal edildi — 275 s, out=0, K7 tekrarı). Fix: driver `--until-p1`
  veya `P2_HUMAN_ASSIST` passthrough.
- **B-3 (bilgi):** exFAT `._*` ikizleri `.opencode/node_modules/` içinde PHPUnit'u bozuyor;
  qa-gate doğru teşhis ediyor ama otomatik temizlemiyor (manuel `find -name '._*' -delete` +
  phpunit rerun gerekti). Alternatif: phpunit.xml'de `._*` exclude.
- **B-4 (bilgi):** bootstrap sonrası `du -sh` exFAT'te **800× şişirilmiş** (855M vs 1.0M) —
  raporlarda gerçek boyut `python3 os.path.getsize` ile alınmalı (D1.2 tekrarı).

## 7. Karar Ağacı Karşılaştırması (Tur 2-10 planı)

| Öngörülen | Gerçek |
|-----------|--------|
| P1 PASS + hybrid PASS + P3/P5 koşulmadı → KISMİ | **P1 PASS + hybrid PASS + P3 PASS + P5 PASS → TAM PASS** |
| tag: v1.0-rc3 + P3 fix turu | tag **v1.0-rc3** (P3 fix turu gerekmedi — B-1/B-2 sonraki tur için) |

## 8. Sonuç

- **İş akışı uçtan uca kapandı:** START → P1 → (hybrid bekleme) → manel P2 → P3 → P5 → **DONE**.
- Hybrid workaround **ilk kez tam pipeline'da doğrulandı**; Tur 2-10'un P2 duvarı artık
  kaybı durduran değil, **dokümanlı geçiş kapısı**.
- Token/ süre Tur 2-10'a göre sırasıyla **−37% / −66%**; LLM denemesi **5 → 2**.
- Kalan iş: B-1 (kvkk regex), B-2 (driver P2 tetikleme) — P2 gerçek write'ı hâlâ 0/10
  (model duvarı, K7 korunuyor); `--auto` yalnız P1/P3/P5 akışında güvenli.

**PASS koşulları:** [x] P1 PASS [x] hybrid exit 3 + 3/3 template [x] manel simülasyon + F3
[x] P3 14/14 [x] P5 `Yukleme/` [x] DONE [x] 2 saat sınırı [x] model değişmedi
[x] RUN-REPORT-2 kayıtları bu dizinde.
