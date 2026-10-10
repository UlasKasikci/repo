# FINDINGS — Tur 2-8: Plugin Eşik Teşhisi (K1a ihlali → fix) + kimi-k3 Pilotu + CJK CI

**Tarih:** 2026-10-10 · **Pilot:** tur2-7 projesi yeniden (`kimi-20261010T140220Z`, --p2-only)
**K7:** plugin eşiği A'da sabitlendi; B'de yalnız model değişkeni (`MODEL_P2=nvidia/moonshotai/kimi-k3`)
**Self-test:** 40/40 PASS · **CI:** (bu commit sonrası yeşil)

## A — Plugin eşik teşhisi: **K1a İHLALİ tespit edildi → FIX**

**Yöntem (A.1):** yeni koşu yok; Tur 2-7 WITH-PLUGIN (`ses_eda4592abffed2Pv5OuZnC0w26`) ve
NO-PLUGIN (`ses_eda4244c4ffe6P0jX43gBs6b7z`) oturumlarının `opencode.db` `part` tablosu
sorgulandı (time_created/time_updated/data).

**Kanıt — WITH-PLUGIN turn 2 (abort anı 12:13:47.192):**

```
PART reasoning created=12:12:45.957 updated=12:13:47.241 len=5447
```

Turn 2'de **61.2s boyunca AKTİF REASONING** akıyordu (DB'ye 5447 karakter birikmişti;
updated timestamp abort anıyla çakışıyor). Plugin bunu görmedi çünkü `--format json`
stdout'u reasoning part event'lerini basmıyor (yalnız tool/text) → "boş stream" sanıp
abort etti. **K1a: "dolu stream'de kill yasak" — İHLAL.**

**Kanıt — NO-PLUGIN kontrol (turn 1):** reasoning **197.6s / 23831 char** → text+tool →
başarılı kapanış. Uzun reasoning MEŞRU (GLM-5.3 high effort).

**Sonuç:** 61.2s abort "gerçek stall" değildi — yanlış aborttu. Eşik 60→90 **tek başına
yetersiz** (197s reasoning vakası 90s'de de kill edilirdi).

**Fix (`dfd5363` sonrası bu tur):** `nim-stall-retry.js` reasoning-aware:
- `bun:sqlite` readonly ile `SELECT MAX(time_updated) FROM part WHERE session_id=?`
- reasoning/text/tool güncellemesi active map'ini tazeler → dolu stream asla abort edilmez
- gerçek stall = stdout event YOK **+** DB'de update YOK → 90s'te abort (K1b hizalı)
- DB erişilemezse stdout-only eski davranış (fail-open)
- doğrulama: `loaded (stall=90000ms retries=3 db=yes)` + trivial run rc=0 (false-trigger yok)

**B pilotu ikinci doğrulama:** kimi-k3 attempt 1 — 256s dolu (garbage) stream, plugin
**abort ETMEDİ** (DB refresh aktif) → K1a fix'i sahada da doğrulandı.

## B — kimi-k3 izole pilotu: **FAIL (degraded output)**

| Model | Deneme | rc | Süre | out | reas | write | İskelet | Davranış |
|-------|--------|-----|------|-----|------|-------|---------|----------|
| glm-5.3 (Tur 2-7) | 9 | 1×9 | 70-116s | 0-257 | 0-1458 | 0 | 0 | F5 stall → plugin abort (90s öncesi 60s) |
| **kimi-k3** (bu tur) | 2 | 0 + 1 | 256s + 596s | **4802** + 254 | 18 + 852 | **0** | **0** | Turn kapanıyor ama **multilingual halüsinasyon** |

- **Attempt 1:** rc=0, out=4802 — stdout **Çince/Korece/Rusça/İngilizce karışık
  alakasız üretimi** (klasik model degradation); tek tutarlı cümle: "domain-report must
  be read" / "Go read domain report". Orchestrate haklı: "MVC iskeleti eksik" → rc=3.
- **Attempt 2:** rc=1, 596s, out=254 — stall/error döngüsü, write=0. Benim force-stop'um
  rc=143 kill-safe satırı yazdı.

**Karar:** `nvidia/moonshotai/kimi-k3` bu endpoint'te P2 codegen için **kullanılamaz**
(garbage output). glm-5.3 stall duvarına kıyasla farklı bir arıza modu: akış dolu ama
anlamsız. **Kalan hipotez (Tur 2-9 için):** 0/9 yalnız F5 değil — glm-5.3 F5 duvarı +
kimi-k3 degradation → provider/model envanterinde P2'ye uygun model yok; PROMPT/CONTEXT
katmanı Tur 2-9'da test edilmeli (glm-5.3 + kısaltılmış prompt / tek-turn iskelet).

## C — CJK CI adımı (kalıcı koruma)

- `scripts/web/cjk-check.sh` — GNU grep -P + BSD/python3 fallback; yalnız
  sh/md/json/yaml/yml; Türkçe karakterler meşru.
- CI `validate.yml`: "CJK encoding check" adımı (self-test öncesi).
- Self-test senaryo 39: isabet fixture → rc=1 · Türkçe-temiz → rc=0. Badge 39→**40**.
- Repo taraması: FINDINGS'te CJK alıntıları da temizlendi (CI kendi kendini flag'lemesin).

## Kapanmayanlar / Tur 2-9

1. **P2 completion hâlâ 0** — model envanteri yetersiz (glm-5.3 F5, kimi-k3 garbage).
   Sonraki adaylar: `MODEL_P2` env ile envanterden başka modeller (glm-5.3-flash? kimi
   ailesinin diğer versiyonları) veya prompt katmanı deneyi.
2. Plugin `client.app.log` görünürlüğü (cosmetic, Tur 2-7'den açık).
3. Attempt 2 kimi 596s rc=1 — abort/error döngüsünün tam ayrıştırması için DEBUG=1
   log koşusu (NIM_STALL_DEBUG=1) gerekir — opsiyonel.

## Commit'ler

- A: `nim-stall-retry.js` — K1a fix (bun:sqlite DB polling + 90s)
- B: `FINDINGS-TUR2-8.md` (bu dosya)
- C: `cjk-check.sh` + `validate.yml` + self-test senaryo 39 + badge 40/40
