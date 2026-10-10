# FINDINGS — Tur 2-5c: F4 Config-On-Wire Fix + On-Wire Kanıt + Pilot (K1b-2 İlk Real Kill)

**Tarih:** 2026-10-10 · **Kapsam:** F4 (opencode gizli 32K cap) düzeltmesi, NIM on-wire
clamp araştırması, --p2-only pilot tekrarı (F4 fix + K1b-2 devrede).
**Karar ağacı girdisi:** Tur 2-5b pilot FAIL (F3 busy-hang tekrar + 32k truncation geri döndü).

---

## 1. F4 kök neden + fix

**Kök neden (kanıtlandı):** opencode gizli output cap'i — `max_tokens = min(limit.output,
OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX, 32000)`. Env set edilmedikçe NIM'e **32000**
gidiyor; model 32k'yı reasoning'e yakıp `out=0` + `finish_reason=length` üretiyor
(5b pilot turn 4: reas delta = 32000 TAM). `opencode.json` `limit.output=65536` bu cap'i
eşitlemiyor.

**Fix (Tur 2-5c):** `scripts/web/orchestrate.sh` — tüm `opencode run` çağrılarında
`OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072` (inline env, satır 525). Nihai wire
max_tokens = min(65536, 131072) = **65536**. `reasoning_effort=high` + `limit.output=65536`
korundu (değişiklik YOK).

## 2. NIM on-wire clamp araştırması (E2E ÖNCESİ, curl/stream)

| Probe | max_tokens | effort | Sonuç |
|-------|-----------|--------|-------|
| big domain prompt (stream) | 131072 | high | HTTP 200 — NIM 131072'yi **kabul etti**; ~25k token sonra `finish=stop` (model doğal durdu) |
| big domain retry (stream) | 131072 | high | `usage.completion_tokens=24928, reasoning_tokens=1360, finish=stop` — dürüst usage, 32k yuvarlama YOK |
| never-finish probe | 40000 | high | model öz-durdu (~25k, finish=stop) |
| **count/copy probe (force-limit)** | **40000** | **low** | **`finish=length`, `completion_tokens=40000` TAM** → **NIM clamp YOK** (40000 > 32000 üretildi) |

**Hüküm:** NIM tarafında 32K clamp **YOK**; 5b'deki 32k imzası %100 opencode gizli cap
kaynaklıydı. `reasoning_effort=low` denemesine gerek kalmadı (clamp yok).

## 3. Pilot (tur2-5c-20261010T025050Z, --p2-only, 1200s budget)

F4 fix + K1b-2 + F2 prompt devrede. Session `ses_edc4792f9ffe` (P2, glm-5.3, 646s).

| Turn | İçerik | reas (karakter) | Kapanış |
|------|--------|-----------------|---------|
| 1 | read domain-report + bash | 3137 | tool'lu ✓ |
| 2 | text + **write → `SQL/migrations/schema/004_kvkk.sql`** (1982 karakter, disk'te) | 7949 | tool'lu + patch ✓ |
| 3 | text + bash (keşif) | 1679 | tool'lu ✓ |
| 4 | reasoning **len=0** — sessiz asılı | 0 | **K1b-2 zero-prod kill** (482s, CPU %5.5) |

Session toplam: in=16816, **out=1196, reas=3195** (token; ≈ turn reas toplamı/4 ✓).

### Kabul kriterleri

| Kriter | Sonuç |
|--------|-------|
| reasoning < 32000 (cap kırıldı) | **PASS** — max turn ~2k token; 32k imzası YOK |
| write > 0 | **PASS** — 1 dosya (004_kvkk.sql) |
| turn tool'lu kapanış | **PASS** — 3/3 tamamlandı |
| K1b-2 busy-hang kesme | **PASS** — 482s'te `zero-prod` marker'lı kill (ilk real-world kill) |
| F2 (workdir red) | **PASS** — 0 red |

**Pilot: PASS** → karar ağacı: **tam E2E (Tur 2-5d)**.

## 4. K1b-2 katmanlama kanıtı (bonus)

Turn 4 hang'i CPU **%5.5** üretti — K1b strict (<%0.55) kesmezdi (doğru: ağır reasoning
korunurdu), K1b-2 (<%25 + 420s sıfır üretim) kesti. 2-5b'de aynı imza 17.5dk asılı
kalmıştı (budget dışsal kill); bu kez **420s'de otomatik kesildi**. Katman ayrımı sahada
doğrulandı.

## 5. Notlar / sonraki tur

- **Budget kill orphans (fix YOK, A2'' turuna):** launch.sh `( sleep 1200; kill -TERM $DPID )`
  driver'ı kill_tree'siz öldürür → orchestrate+opencode orphan kalabilir. Bu pilotda budget
  hiç tetiklenmedi (zero-prod önce kesti) — risk devam ediyor.
- **Turn-4 hang deseni (yeni F5 adayı):** model turn açıyor (step-start + reasoning part)
  sonra stream komple susuyor (reasoning len=0, token yok). NIM tarafında asılı HTTP olabilir.
  A2'' devam prompt'u bu turn'leri kurtarabilir; K1b-2 zarar vermeden kesiyor.
- **Tur 2-5d (tam E2E):** F4+K1b-2+F2+A1 whitelist ile tam akış (P1→P5); başarı = qa-report
  PASS veya en azından P2 iskeleti + P3'e geçiş + tekrar eden hang yok.
- Wire probe çıktıları: `/var/folders/.../T/opencode/nim-wire-*.ndjson` (bu oturumda).

## 6. Değişiklik listesi

| Dosya | Değişiklik |
|-------|-----------|
| `scripts/web/orchestrate.sh` | `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=131072` inline env (satır 525) |
| `docs/findings/FINDINGS-TUR2-5c.md` | bu dosya |

self-test: **34/34 PASS** (orchestrate değişikliği sonrası). A2'' eklenmedi (K7) ·
QA gate/state graph değişmedi (K6) · pilot dışı E2E koşulmadı.
