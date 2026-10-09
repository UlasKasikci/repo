# FINDINGS — Tur 2 (A1+A2 temiz E2E, tek kol)

**Koşu:** `20261009-102447Z-tur2` · **Proje:** bootstrap `--yes`, intent "faz14 projesinden birebir kopya" (sha `2e481696…`)
**Başlangıç/bitiş:** 2026-10-09T10:24:48Z → 13:43:50Z (**2s19dk**) · **driver:** max_attempts=6 · idle=900s · L3 P2 · dış bütçe 18000s/15M (launch'tan sonra 5 saate çekildi, unused)
**Driver:** `DRIVER_DONE rc=143 attempts=6 watchdog_kills=6` · outer kill: YOK
**İmza:** A1 (manifest-onaylı whitelist + whitelist_scan) + A2 (spike→write) — `e00054c`
**Model routing (default):** P1 `glm-5.3-flash` · P2/P4 `glm-5.3` · override YOK

## 1. Kabul sonucu

| kriter | hedef | gerçek | sonuc |
|---|---|---|---|
| attempt ≤ 2 | att≤2 | **att=6** (6/6 P2 idle kill) | **FAIL** |
| P2 token ≤ 8.56M (E2E-3×0.7) | ≤8,562,051 | P2 TAMAMLANMADI (kill altı P2 toplam 248,317) | **N/A→FAIL** |
| iskelet tam (core/views/index.php/SQL) | var | **0 dosya** | **FAIL** |

**Sonuç: KABUL YOK.** Kontrollü başarısızlık: run temiz kapandı (HALT yok, outer kill yok), veri tam.

## 2. Satır metrikleri (metrics.jsonl)

| # | phase/agent | rc | token | not |
|---|---|---|---|---|
| 1 | P1 web-domain-architect | **0** | 1,169,393 | 3× B2 SchemaError → leading-newline recovery; domain-report 12,544B yazıldı (11:59Z); 16 step; P1→P2 12:11Z |
| 2 | P2 att1 | 143 | 33,287 | 0 write · ~14dk · L3 idle kill |
| 3 | P2 att2 | 143 | 34,666 | 0 write · bash find(prune)+python domain-report+ls+state status+read · 0 write · kill |
| 4 | P2 att3 | 143 | 62,003 | 0 write (todo aracı 1× kullandı, write YOK) |
| 5 | P2 att4 | 143 | 33,400 | 0 write |
| 6 | P2 att5 | 143 | 51,687 | 0 write (todo 1×) |
| 7 | P2 att6 | 143 | 33,274 | 0 write; kill anı metni: "Domain raporunun tamamını almam gerekiyor (satır kısaltıldı)" |
| | **TOP** | | **1,417,710** | P2 alt-toplam: 248,317 · P1: 1,169,393 |

db otipsi (salt-okunur, `opencode.db`): P2 oturumlarının **6/6'sında write/edit=0**; P1 oturumunda 3 write (B2 retry) ✓. todo aracı 2/6 oturumda 1'er kez çağrıldı — A2 tetikleyicisi tetiklense bile yazma gelmedi.

## 3. Karşılaştırma — E2E-3 (WRITE_RULE) vs Tur2 (A1/A2)

| metrik | E2E-3 (120921Z) | Tur2 | Δ |
|---|---|---|---|
| P1 rc/token | 0 / 780,586 | 0 / **1,169,393** | +50% token (B2 3× retry dahil) |
| P2 deneme | **2** (att1 provider crash 1.67M → att2 SUCCESS) | **6/6 idle kill** | regresyon |
| P2 başarılı token | 12,232,931 (113 step, 7s31dk) | **0** (toplam 248,317 çöp) | regresyon |
| Toplam token | 14,682,011 | 1,417,710 | −90% (ama sonuç boş) |
| İskelet | tam + Yukleme | 0 dosya | regresyon |
| Wall clock | ~16+ saat (tahmini) | 2s19dk | hızlandı (kill döngüsü) |
| Sonuç | DONE | att exhaust, rc=143 | **FAIL** |

## 4. Kök neden (kanıt zinciriyle)

1. **A2 opencode'da yapısal olarak ısırılamıyor (ana neden).** A2'nin ilk tetikleyicisi "todowrite sonrası ≤3 tool çağrısında ilk write" — 6/6 oturumda yazma YOK; 2 oturumda todo çağrılsa dahi model yazmadı. İkinci tetikleyici ("reasoning >20k → next write") pure-text step'leri konsuna çapalı ve model bash-read → uzun reasoning → kill döngüsüne giriyor. E2E-3'ün WRITE_RULE'ü att2'de **erken ilk write** yaptığı için başarılıyordu; A2 bu özelliği kaybetti → **P2 tek-success (E2E-3 att2) → 0/6 (Tur2)**.
2. **L3 idle (900s) ilk-write öncesinde öldürücü.** Watchdog dosya değişikliği sayar; P2'de ilk write hiç gelmediği için her deneme ~15dk'da sigorta ile kesildi. E2E-3'te ilk write dosya-değişikliği sayacı sıfırlıyordu.
3. **Output truncation → "tam dosya" sapması.** att6 son metni: "Domain raporunun tamamını almam gerekiyor (satır kısaltıldı)". Model read tool'unun kırpmasını bash `cat` ile aşabiliyor ama att6'da bunu yapamadan vadesi doldu (12.5KB'lık rapor tek bash çağrısıyla alınabilir — model yapmadı).
4. **B1/B2 harness: P1 kurtardı, P2 hiç denemedi.** P1'de 3× write SchemaError + newline recovery başarılı (domain-report yazıldı). P2'de write çağrısı hiç olmadığı için B2 test edilmedi.
5. **Whitelist/manifest tarafı sessiz ve temiz:** `whitelist WARN=0`, FORBIDDEN ihlali yok, att2 bash `find . -path ./.git -prune -o -path ./scripts -prune` gibi whitelist-dostu okuma yaptı; domain-report'u bash `python3 json.load` ile okudu (bash = izinli araç → tarama dışı; manifest tüketimi OK). QUESTIONS tetiklenmedi (intent eksik modül satırı yok — "birebir kopya" + compliance kvkk domain-report'a dondu ✓).

## 5. İmza değerlendirmesi

- **A1 (manifest-onaylı whitelist):** sorunsuz — 0 yanlış pozitif, 0 FORBIDDEN, manifest 29 dosya, modül matrix 7 (rbac injected, cart missing, seo proposed, kvkk injected…), compliance=kvkk. **Kapandı** (negatif sonuç yok; whitelist taraması P2 kill döngüsüne takılmadan görev yaptı). Not: tarama yalnız read/grep/glob tool'larında — bash okumaları zaten A1'in genişlettiği alan, beklenen davranış.
- **A2 (spike→write):** **KALMADI — tutmadı.** 6/6 0-write. Kural opencode-native bir çapaya (duvar-saati: "ilk write N dk içinde zorunlu" veya WRITE_RULE tarzı mutlak kural) oturtulmadan tekrar test edilmemeli.

## 6. Aday revizyonlar (uygulanmadı — sonraki tur kararı)

1. **A2' → duvar-saati mutlak kural:** "P2 başladıktan sonraki ilk 3 tool çağrısında `edit`/`write` ile en az bir dosya yaz — hangi araç olursa olsun; yoksa sonraki her step'te bu kuralı tekrarla."
2. **İlk write öncesi L3 idle için ayrı eşik** (ör. 600s) veya P2 phase girişinde ilk-write timeout sayacı (ör. 20dk) — ikisi de tek dosyalık orchestrate/ driver değişikliği.
3. **domain-report tam-okuma affordance:** P2 prompt'una "raporu TEK bash `cat` ile al, read tool ile bölme" satırı (att6 sapması için).
4. Tümü yeni imza (v1.x) → **tek kol Tur2-2** koşusu; E2E-3'ün WRITE_RULE başarı koşuluyla karşılaştırmalı. K7 çift-kol bir-kez şartı ayrı E2E'de.

## 7. Teyitler

- Ön koşul audit (a42fbe6): 4+1 tamam — ölü-kural fix (22/25/26/27 globs), `permission.skill` (üst-seviye `skills` anahtarı docs'ta tanınmıyor — doğru şema uygulandı), README 14×5/28×3, `.cursorrules`↔`.mdc` çelişki YOK.
- **K7 tek-değişken:** `.mdc` = Cursor-only (opencode instructions = CLAUDE.md + WEB-EDITION.md); E2E'de A1/A2 dışında fazla değişken yok → Tur2 tek başına A2 regresyonunu izole eder.
- Faz14 dosyaları untracked KALINDI (§17); bu run yalnızca kendi dizinini commit eder.
- State final: P2/in_progress, retry_count=0 (driver retries ≠ state retries) ✓

## 8. Karar bekleyen (kullanıcı)

Tur2 FAIL → seçenekler: (a) v1.x: A2'yi §6.1-6.3'e göre revize et + Tur2-2 tek kol; (b) WRITE_RULE'ü geri alıp A1 ile birleştir; (c) v2 (JEV)ye geçiş ertelenir — v1 %90'da durur. **JEV v2 yeşil ışığı K1 gereği v1 tamamlanmadan YOK.**
