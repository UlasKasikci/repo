# FINDINGS — Tur 2-5b: F3 Remedy (K1b/K1b-2) + F2 Prompt + Pilot

**Tarih:** 2026-10-10 · **Kapsam:** K1a/b/c genişletmesi, boş-stream kanalı, F2 prompt,
cwd doğrulaması, self-test 31→34, pilot ≤20dk.
**Karar ağacı girdisi:** Tur 2-5a pilot FAIL (F3: provider stream hang, L3 kesmedi).

---

## 1. Teslimatlar

| Çıktı | Durum |
|-------|-------|
| `docs/MASTER-PROMPT-V2.md` — K1a/b/c + K1b-2 tablosu | ✓ |
| `scripts/web/e2e-driver.sh` — K1b stream-stall + K1b-2 zero-prod kanalları | ✓ (bash 3.2: `${var - var}` bad-substitution fix — `$((...))`) |
| F2 prompt (`workdir` yasağı) — `.opencode/agent/` + `.cursor/agents/web-core-engineer.md` | ✓ |
| `orchestrate.sh` cwd doğrulaması | ✓ **zaten correct** — tek `opencode run` invocation'ı `(cd "$PROJECT" && …)`; değişiklik YOK |
| self-test 32 (stream-stall) / 33 (K1a korunması) / 34 (zero-prod) | ✓ **34/34 PASS** |
| README/MASTER-PROMPT sayaç 31→34 | ✓ |

**K1b kanalı (asılı idle stream):** stream sessiz + hedef ağaç CPU <**%0.55**/pencere +
token sabit + opencode/ev mevcut → `STREAM_STALL_MAX` (90s, env) içinde TERM `stream-stall`.
Token kanalı NA (DB yok) → K1b **devre dışı** (false-kill yasak).

**K1b-2 kanalı (busy-hang — pilot bulgusundan doğdu):** stream/token/dosya **üretimi sıfır** +
CPU <%**25**/pencere (ağır reasoning ≈%27 üstü korunur) → `ZERO_PROD_CAP` (420s, env) içinde
TERM `zero-prod`. CPU eşikleri **pencere yüzdesine normalize** (test kısa pencere = prod 90s).

## 2. Pilot (tur2-5b-20261010T003658Z, --p2-only, config fe73e77 + K1b + F2)

Budget: 1200s outer. Sonuç: **write>0 ACHIEVED** (ilk kez), F2 sıfır red, K1b yanlış kesmedi,
ama F3 busy-hang olarak döndü + turn 4 truncation geri döndü.

| Metrik | Değer |
|--------|-------|
| süre | ~22dk (budget TERM driver'ı 00:56:58'de öldürdü; opencode orphan olarak turn'ü 00:59:07'de bitirdi — metrics rc=0) |
| turns / steps | 4 mesaj / 3 step |
| tokenlar (toplam) | in=16733, out=1006, reas=**45107**, cache_read=16320 |
| tools | read×1 ✓, bash×2 ✓, **write×1 ✓** (06_kvkk.sql) — hepsi completed |
| F2 (workdir red) | **0** (Tur 2-5a pilot 1: 1 red → halt) |
| K1b tetiklenmedi | **doğru** (CPU %2-10 strict eşiğin üstü — üretimken reasoning korundu) |
| K1b-2 o zaman YOKTU | busy-hang 17.5dk sürdü; budget kill dışsal kaldı |

### Turn analizi

- **Turn 1-3 (00:37-00:42):** healthy — reasoning 468/…/12639, out 72→1006, write+tool
  dalgası, F2 workdir yasağına uyum. `reasoning_effort=high` erken turn'lerde ETKİLİ.
- **Turn 4 (00:41:54 → 00:59:07, 17.5dk):** **busy-hang + truncation imzası** —
  reas delta = **32000 TAM**, out delta = **0**. NDJSON stream 15+ dk sabit (44706B),
  DB token'ları sabit, dosya yazımı yok, CPU %2-10 (spiky). Opencode çıkmadı; orchestrate
  rc=0 ile "tamam" saydı.
- Bu imza Tur 2-3'ün 32k-cap imzasıyla AYNI — demek ki `limit.output=65536` **telde
  etkisiz** olabilir (veya NIM ~32k'ya klamp'liyor / high effort hâlâ 32k yakabiliyor).

## 3. Hükm brief karar ağacına göre

- **Kabul "write > 0": PASS** (06_kvkk.sql yazıldı — Tur 2-5a'dan ileri).
- **Kabul "stream stall yok / L3 kesti": FAIL** — F3 busy-hang olarak tekrar etti,
  mevcut kanallar kesmedi (K1b-2 bu tur içinde eklendi → tekrar gerekli).
- **Karar ağacı:** "Pilot FAIL (F3 tekrar, L3 kesmedi) → **K1b eşiği sıkılaştır**" →
  K1b-2 zero-prod katmanı **bu turda** eklendi + senaryo 34 ile kanıtlandı (34/34).
- **A2'' eklenmedi** (K7), QA gate/state graph değişmedi (K6).

## 4. Yeni bulgular (sonraki tur girdisi)

1. **F4 (config-on-wire):** `provider.nvidia.models…limit.output=65536` yüklü görünse de
   turn 4'te 32k-reas/0-out truncation geri döndü. Araştırma: opencode ai-sdk max_tokens
   haritası, NIM clamp'i, `reasoning_effort=high`'ın turn-bazlı bütçesi. Alternatif:
   `low` denemesi veya `variants` ile `glm-5.3#low`.
2. **Turn-asılı kalıcı pattern:** truncation'lı turn (out=0) orchestrate'a **rc=0** geliyor —
   P2 "oldu" sanılabiliyor. A2'' (sürdür ve bitir) bu yüzden kritik: tool'suz/boş kapanış
   yasak + devam prompt'u "kaldığın yerden Uygula".
3. **Driver budget kill orphans:** outer budget `kill -TERM $DPID` yalnız driver'ı öldürür —
   orchestrate+opencode orphan kalır (bu pilotda 2dk daha çalıştı). Gelecek tur: budget
   kill → driver TERM trap'i ile kill_tree.
4. **K1b-2 420s marjı:** ölçülen max üretken tek-turn 291s (5b turn 3) → marj 129s. Uzun
   JEV turn'leri için izlenecek (K3: ölç, sonra karar).

## 5. Kabul kriterleri (bu tur)

| Kriter | Sonuç |
|--------|-------|
| K1b stream-stall: stub → 60-120s (testte 3s) kill | **PASS** (senaryo 32) |
| K1a: dolu stream → kill YOK | **PASS** (senaryo 33) |
| K1b-2 zero-prod: %10 CPU busy-hang → kill | **PASS** (senaryo 34, %9.8 ölçüldü) |
| self-test | **34/34 PASS** |
| F2 prompt devrede (pilot: workdir red 0) | **PASS** |
| orchestrate cwd = proje kökü | **PASS** (değişiklik gerekmedi) |
| Pilot write > 0 | **PASS** (1 write) |
| Pilot stream-stall/zero-prod kesme (F3) | **FAIL** (kanal eklendi, pilot tekrarı gerekiyor) |
| A2'' eklenmedi (K7) · QA/state sabit (K6) | **PASS** |

**Sırada (kullanıcı kararı):** K1b-2 devrede tekrar pilot (Tur 2-5c) · F4 config-on-wire
araştırması (turn 4 truncation) · A2'' tasarımı — sıralama.
