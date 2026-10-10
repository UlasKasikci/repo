# FINDINGS — Tur 2-9 · P2 Prompt Optimizasyonu + /kur + İlk Temiz P2 Pilotu

**Tarih:** 2026-10-10 · **Sonuç:** A+B TAMAM · C = **FAIL** (bilinen kısıt) · D = 41/41 PASS

## A — Prompt optimizasyonu (tamam)

- **A.1 ölçüm:** `.opencode/agent/web-core-engineer.md` = 4909 bayt (~850 token),
  `.cursor/agents/web-core-engineer.md` = 5654 bayt (~980 token). Hedef <8k token
  **aşırı rahat karşılandı** — prompt zaten küçük, kısaltma gerekmedi.
- **A.2 tek-turn iskelet (eklendi, ×2 IDE):** "TEK TURN'DE PARALEL write" + "plan
  todowrite'ta, reasoning'de değil" + "scaffold'ta tekrar okuma YASAK".
  Kanıt: E2E-3 att0 = 21 paralel write; Tur 2-3'te model hiç write'a geçemedi.
- **A.3 context disiplini (orchestrator `p2_prompt`):** TEK-TURN İSKELET bloğu eklendi
  (`orchestrate.sh` p2_prompt; pilot senkronu bu turda).

## B — /kur komutu (tamam)

- `.opencode/command/kur.md` (1726 bayt) + `.cursor/commands/kur.md` (1629 bayt):
  kontrat oku → dizin tara → bootstrap → state start → qa-gate → özet.
- **bootstrap değişikliği gerekmedi:** `COPY_ROOTS` zaten `.opencode`/`.cursor`
  root'unu kopyalıyor; dry-run + gerçek kopya testi ile teyit edildi
  (`/kur kopyalandı ✓`).
- README "Yeni proje" bölümüne `/kur` + terminal eşdeğeri eklendi.

## C — P2 pilotu (glm-5.3, temiz plugin, K1a-fix devrede) — FAIL

**Kurulum:** tur2-7 projesi (gerçek domain-report 17272 bayt, state P2),
güncel `nim-stall-retry.js` (bun:sqlite DB polling, 90s), A.2/A.3 promptları
senkron, `MODEL_P2=nvidia/z-ai/glm-5.3`, driver `--p2-only … 8 900 15`,
durdurma: 4 attempt sonrası (≈33 dk, ≤45 dk bütçe).

| attempt | lat | out tok | reas tok | rc | write |
|---------|-----|---------|----------|----|----|
| 1 | 436s | 62 | 1214 | 1 | 0 |
| 2 | 321s | 0 | 0 | 1 | 0 |
| 3 | 591s | 345 | 3940 | 1 | 0 |
| 4 | 436s | 175 | 1594 | 1 | 0 |

**Toplam (tur2-8+29 birlikte): 7/7 glm-5.3 run rc=1, write=0.** Prompt katmanı
(A.2/A.3) sonucu DEĞİŞTİRMEYDİ — duvar model/sağlayıcı tarafında (F5 stall),
prompt tarafında değil.

**K1a teyidi:** hiçbir attempt'te dolu-stream kill yok; plugin 90s stall'da abort
ediyor, K1a korunuyor. Sorun "abort edilen stream" değil — "reasoning hiç
write'a ulaşmadan stall".

## D — Self-test + teslimat

- Senaryo 40 (`/kur`): iki IDE'de dosya + kontrat/QA referansı + bootstrap
  kopyası. Badge 40/40 → **41/41 PASS** (README + MASTER-PROMPT senkron).
- Ayrı commit'ler: A (prompt) · B (/kur) · D (self-test 41) · C (bu FINDINGS).
- **v1.0-rc2** tag (durma noktası — P2 tamamlanmadan v1.0 final yok).

## Bilinen kısıt (README'ye taşındı)

**P2 kod üretimi glm-5.3'te 0/7.** K1a-fix plugin stream'i koruyor ama model
reasoning aşamasında stall'lanıp hiç dosya yazmıyor. JEV v2 (Faz 2.1 MCP
ensembles) ertelendi; yeni model/sağlayıcı denemelerinde A.2 tek-turn promptu
+ bu plugin hazır zemin olarak kalır.
