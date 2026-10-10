# FINDINGS — Tur 2-7: F5 Remedy (nim-stall-retry plugin) + K5 Fix Paketi + Pilot

**Tarih:** 2026-10-10 · **Pilot:** `tur2-7-20261010T115935Z` (--p2-only, gerçek tur2-6 domain-report, 17272 bayt)
**Model:** `nvidia/z-ai/glm-5.3` (P2, K7 — model DEĞİŞTİRİLMEDİ) · **Self-test:** 39/39 PASS

## Sonuç özeti

| Bölüm | Sonuç |
|-------|-------|
| A. Plugin (`nim-stall-retry`) | **SAHA DOĞRULANDI** — 61.2s gerçek stall'da abort; pluginsiz kontrol koşusu aynı noktada 300s timeout |
| A. False-kill | **0** (10 örneklem; her abort'un stall olduğu kontrol koşuluyla ispatlı) |
| A. P2 tamamlanma | **0/9** — provider F5 duvarı bu gün ~%100; remedy döngüyü hızlandırdı, kaliteyi düzeltmedi |
| B. K5 fix paketi | qa-gate phpunit config xml/dist · CI fixture guard (rc=1 one-off kanıtlandı) · sayaç tek kaynak (39) |
| C. A2'' saha doygunluğu | **TETİKLENMEDİ** — hiçbir deneme dosya yazmadan stall'a uğradı (2-5d ile aynı yapısal limit) |

## A — F5 remedy: mekanizma kanıtı

**İzolasyon deneyi (aynı gerçek p2_prompt, iki koşul):**

| Koşul | Turn 2 davranışı | Sonuç |
|-------|------------------|-------|
| plugin VAR | step_start + **61.2s sessizlik** → `session.abort` → `MessageAbortedError` | rc=1, ~30s |
| plugin YOK | step_start + **210.4s sessizlik → stream KENDİ kendine devam etti** (text+tool) → turn 3'te yeniden asıldı | rc=124 (300s timeout) |

- NIM stall'ları kendi kendine iyileşebilir (210s örneği) — 60s abort bu iyileşme şansını feda eder; karşılığında **deterministik 60-100s retry döngüsü** (K1b-2'nin 420s'ine karşı 4-7× hızlı). A2'' continuation ile deneme maliyeti düşük; tercih determinizm.
- `NIM_STALL_MS` env ile ayarlanabilir (default 60000); `NIM_STALL_RETRIES` default 3 — sonrası K1b-2'ye bırakılır (K1 false-kill yasağı korunur).

**Driver koşusu (9 deneme: 3+6):** tümü rc=1 lat=70-116s · `watchdog_kills=0` (plugin her seferinde K1b-2'den önce davrandı) · token'lı denemeler (#4,5,7,9: out=61-257, reas=394-1458) turn 1 tool'ları çalıştırdı, turn 2'de asıldı · write=0.

## Plugin doğrulama notları

1. opencode modüldeki **HER export'u plugin factory olarak dener** — `checkStalls` export'u `failed to load plugin` (undefined 'active') üretti; export kaldırıldı, saf fonksiyon içeri alındı.
2. `client.session.abort({ path: { id: sid } })` SDK kontratı: `POST /session/{id}/abort` (sdk@1.18.35 types).
3. `client.app.log` pilot daemon'unda ana `opencode.log`'a yansımıyor (cosmetic; abort davranışı kontrattır).
4. Python eşlenik sözleşmesi: 4/4 PASS (erken-fire yok · sid bazlı abort · retry sayacı · max-retry devre dışı).

## B — K5 fix paketi (`9b6c0f4`, `fbc6b64`)

- **B.1** `qa-gate.sh`: `--configuration phpunit.xml` sabiti → mevcut config seçilir (`phpunit.xml` → `.dist` fallback). Eski halde `.dist`'li projede phpunit sessiz skip (kapsam kaçışına yol açıyordu).
- **B.2** `self-test.sh`: fixture yok + `CI=true` → **rc=1** (one-off kanıt: mesaj `CI modunda fixture yokluğu FAIL`). Yerel modda SKIP korunur.
- **B.3** Senaryo sayısı `grep -c '^step "'` (tek kaynak) + README badge tutarlılık kontrolü (senaryo 38) — badge 36→**39** (0..38; B.2+B.3+37/38 eklentileri).
- **B.4** `p1-domain-report.schema.json`: `acceptance_criteria` izlenebilirlik notu (traceability: gereksinim→kabul→test; tekil test edilebilir kriter, tekrar/metin-kopya yok).

## Kapanmayanlar / sonraki tur

1. **P2 completion 0** — provider kalitesi sorunu; remedy altyapısı hazır, tekrar denenmeli (farklı gün/model envanteri; `MODEL_P2` env override).
2. **A2'' saha tetiklenmesi** — P2'de ilk başarılı partial-write needed; completion olmadan blok boş kalmaya devam ediyor.
3. Plugin `client.app.log` görünürlüğü — opencode daemon log yolu araştırılabilir (cosmetic).
4. **CPU sampling platform-kırılganlığı (senaryo 34 CI race — bu tur fix'lendi):** CI'da busy-hang yanlışlıkla stream-stall sanılıyordu (marker 'zero-prod' hiç yazılmadan kill). Root cause: **Linux `ps -o cputime` 1s granularity truncate eder** (macOS 0.01s) — %10 duty'de ilk pencerelerde birikmiş CPU 0.6s → Linux `00:00:00` gösterir → cdelta≈0. Fix (kalıcı): `e2e-driver.sh` → `cpu_time_pid()` — Linux'ta `/proc/<pid>/stat` utime+stime (10ms çözünürlük); macOS'ta ps yolu korunur. Prod kazancı: gerçek watchdog'un kısa CPU pencereleri de Linux'ta artık doğru ölçülür.
5. **CJK encoding sızıntısı (bu tur temizlendi + kalıcı koruma notu):** AI edit'leri üç eski dokümanda CJK karakter sızmıştı (`工作中`, `参照` ×2) — repo-wide tarama sonrası düzeltildi (CJK=0). Kalıcı koruma: CI'a opsiyonel CJK-check adımı (yalnız `.sh`/`.md`, Türkçe karakterler meşru) — sonraki tur.

## Commit'ler

- `dfd5363` feat(plugins): nim-stall-retry — F5 mid-turn stall remedy
- `9b6c0f4` fix(qa): K5 — phpunit config, CI fixture guard, sayaç tek kaynak (39/39)
- `fbc6b64` docs(schema): B.4 — acceptance_criteria izlenebilirlik notu
