# FINDINGS — Tur 2-6: README Hygiene + A2'' (Devam Stratejisi) + P1 Trend Ölçümü

**Tarih:** 2026-10-10 · **HEAD:** `6da7597` (hijyen) → `4203ab7` (A2'') · CI yeşil.
**Koşu:** tur2-6-20261010T101049Z — tam akış, domain-report **pre-seed YOK** (P1 LLM),
intent `2e481696ceeb`, max_attempts=2, 16M/10h bütçe.

---

## B — README Repo Hijyenİ (tamam)

| Kategori | Bulgu | Aksiyon |
|----------|-------|---------|
| (a) yanlış repo | README badge (CI URL) + clone URL → clariongemini/APP-FABRIKA | **UlasKasikci/repo** olarak değiştirildi |
| (a+) ek | self-test badge **31/31** (stale, iki tur önce 34/34 olmuş) | 34/34'e güncellendi |
| (b) korunan | `APP-FABRIKA WEB EDITION` başlığı, `bootstrap from app-fabrika@<hash>` commit izi (self-test kontratı), `app-fabrika.local` $id'ler, graph adı, governance notları, arşiv snapshot'lar | dokunulmadı |
| (c) workflows/opencode.json/package.json | clariongemini referansı YOK | — |
| **APP-FABRIKA arşiv notu** | clariongemini/APP-FABRIKA README'sine `> ⚠️ Bu repo arşivlenmiştir…` eklendi | **push başarılı** (`2f68d49..fa7875d`, FF, force yok) |

Commit: `6da7597 docs: replace APP-FABRIKA references with UlasKasikci/repo…`

## D — A2'' Devam Stratejisi (tamam, self-test 36/36)

- `orchestrate.sh`: **`continuation_block()`** — P2 prompt'unun sonuna, proje kökündeki
  mevcut üretim dosyalarını (core/, views/, assets/, SQL/, index.php, .htaccess,
  phpstan.neon.dist, tests/ …) `find` ile tarayıp gömer: dosya listesi + "KALDIĞIN
  YERDEN DEVAM ET" + "Baştan planlama YAPMA" + "TEKRAR YAZMA, eksikleri tamamla" +
  "ilk iş write/edit". Boş proje → blok YOK (gereksiz gürültü yok).
- Agent dosyaları ×2 (`.opencode/` + `.cursor/`): A2'' davranışı — listedeki dosyaları
  `cat` ile oku, tekrar yazma, ilk 3 çağrıda eksiklere write.
- self-test **34→36**: senaryo 35 (dolu proje → liste + devam metni; boş proje → blok
  yok), 36 (TEKRAR YAZMA + Baştan planlama + write/edit ilk-iş metinleri). **36/36 PASS.**
- Commit: `4203ab7 feat(orchestrate): A2'' continuation block…`

## D3 — P1 Trend Ölçümü (koşu sonucu)

**P1: rc=0, lat=1045s = 17.4 dk** — domain-architect (glm-5.3-flash + F4 fix) başarılı;
`.factory/domain-report.json` **17272 bayt** yazıldı, P1→P2 kapısı geçti.
Tokenlar: in=90373, out=24296, reas=14673, ev=66.

| Run | P1 süresi | Not |
|-----|-----------|-----|
| E2E-3 | ~25.8 dk | 32k cap era |
| Tur 2 | ~49.2 dk | |
| Tur 2-3 | ~93 dk | |
| **Tur 2-6** | **17.4 dk** | F4 + P1 flash model + A2/A1 olgunluğu |

**Trend kırıldı (aşağı yönlü)** — F4'ün P1'e de faydası + domain-architect olgunluğu.

## Koşu geri kalanı (P2 — F5 devam)

| Attempt | P2 lat | Sonuç | A2'' gözlemi |
|---------|--------|-------|--------------|
| 1 | 472s | zero-prod (ev=1, 0 üretim) — F5 turn açılışında | dosya yok → blok yok (doğru) |
| 2 | 739s | zero-prod — model "write dalgası basacağım" dedikten sonra asılma | yine dosya yok → blok yok (doğru; att1 boş bıraktı) |

- **0 üretim dosyası** · kill=2/2 zero-prod (false-kill 0; CPU %9.6-10.5) ·
  driver_rc=143 · orphan yok (budget tetiklenmedi).
- A2'' **saha doygunluğu için att ≥3 + önceki att'ın kısmi write'ı gerekli** — bu koşuda
  att1 P2 hiç dosya yazamadığı için continuation tetiklenmedi (yapısal doğrulama 35/36
  ile yapıldı). att2 modelin "A2' ilk-3-call" niyeti prompt'ta görünür (agent prompt'u
  etkili), F5 kesintisi write öncesi.

## Karar — Tur 2-7 paketi

1. **F5 remedy A/B (kritik yol):** P2'de 5/5 asılma (2-5d 3/3 + bu koşu 2/2), hepsi write
   öncesi — artık tek duvar. A/B: (a) `MODEL_P2=nvidia/moonshotai/kimi-k3` tek koşu,
   (b) `reasoning_effort` high→medium (NIM wire testleri: effort düşükken de clamp yok).
2. **A2'' saha pilotu:** F5 remedy ile birlikte **att ≥3** — biriken write sonrası
   continuation bloğunun prompt'a girdiğini metrics/log'dan doğrula.
3. P1 trend'i izole P1 koşusuyla teyit (opsiyonel; 17.4 dk tekil ölçüm yeterli zemin).
4. v1.0 tag YOK (0-1/3 ✓; F5 duvarı var).

**Kısıtlara uyuldu:** F5 remedy kodu yok · reasoning_effort değişmedi · QA gate/state
graph sabit · v1.0 tag yok · force-push yok.
