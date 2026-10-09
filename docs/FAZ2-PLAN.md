# FAZ 2 PLANI — atık kaldıraçları (Faz 1.4) → JEV MCP (Faz 2.1)

**Durum:** onay bekliyor · **Zemin:** FINDINGS §1-15, WASTE-AUDIT.md, commits
`fa2113d` (E2E-4) · `491e3ba` (A/B) · `69024f1` (advance guard) · `3f82c76` (atık denetimi)
**Tek soru:** sıra onayı — **L1-L4 önce, JEV MCP sonra** (aşağıdaki gerekçe).

## 1. Zemin özeti (neden sıra zorunlu)

Faz 1 çıktıları teyitli: E2E-1..4 + A/B koşuları DONE/PASS; glm-5.3 P2/P4 default
(karar §14); manuel model routing (`MODEL_MAP` + `MODEL_P*` env, Faz 1.1); advance-guard
sınıfı kapandı (Tur 1). Atık denetimi (Tur 2) tek bir sayı ile konuşuyor:

> **Maliyet fonksiyonu ≈ steps × ort. bağlam (91-143k/adım); üretim token'ın ~%1.2'si;
> compaction 12/12 oturumda 0; att0-0-write denemeleri tek başına 6.2 saat duvar.**

JEV MCP (çoklu aday/ensemble) bu fonksiyonu **çarpar**: k aday = bağlam taşıma ×k.
Ücretsiz tier'da tek para birimi **duvar süresi** olduğundan, ensemble'ı maliyet
fonksiyonu düzelmeden açmak duvarı k×'e çıkarır — Faz 2.1'in kendisi ancak L1-L4
sonrasında ölçülebilir. Bu nedenle sıra teknik zorunluluktur, tercih değil.

## 2. Faz 1.4 — atık kaldıraçları (önce)

Her kaldıraç **tek diff** + **tek-değişken E2E** ile ölçülür. Kaldıraç başına diff
sınırlı (prompt kuralı / driver satırı / orchestrate bloğu); self-test senaryosu ile
regresyon kilidi zorunlu.

### L1 — batch-yaz kuralı (etki: steps −%45 hedefi)

- **Yer:** `orchestrate.sh` P2 prompt bloğu (WRITE_RULE yanına) +
  `.cursor/agents/web-core-engineer.md` (kalıcı kayıt).
- **Kural:** "Tüm hedef dosyaları mümkünse **tek write dalgasında** yaz (paralel write
  çağrısı); dosyalar arası **sıralı bash keşfi yasak**; doğrulama için en fazla 3 bash
  (php -l / qa-gate); mevcut dosyaları okumadan önce domain-report'tan çalış."
- **Kabul:** sonraki E2E P2 `steps` ≤ 50 (baz 76-80) **ve** P2 token ≤ baz×0.7.
- **Regresyon:** self-test stub'ında batch-write kalıbı korunur (mevcut senaryolar
  dokunulmaz).

### L2 — compaction eşiği (etki: replay −%30, 100+ adım oturumlarında)

- **Görev 1 (araştırma):** DB'de 56 compaction event'i var → platform tetikleyicisi
  ne? (otomatik context-limit / config / slash). `opencode` config + event şemasından
  çıkar; **API uydurma yasak** — yalnız doğrulanabilir mekanizma.
- **Görev 2 (uygulama):** tetik mekanizmasına göre P2'de 100 adım/1M-token eşiğinde
  compaction'ı garantile (config env veya prompt kuralı: "bağlam şişmeden önce dosya-
  yazma dalgası ile özet geç").
- **Kabul:** 100+ adım oturumunda compaction ≥ 1 **veya** medyan bağlam/adım −≥%20.

### L3 — att0-0-write watchdog (etki: kategori-A israfının ≥%80'i)

- **Yer:** E2E driver (`e2e-*.sh`) — orchestrate'a dokunmadan, Tur 1 sınıfı korunur.
- **Kural:** run_agent aktırken $PROJECT altında **X = 15 dk** boyunca yeni dosya/
  değişiklik yoksa (find -newermt) → önce çocuklar (stub/agent), sonra orchestrate
  TERM; driver retry'a say (mevcut att- sayacı).
- **Kabul:** self-test/behavioral — 0-write stub ile watchdog ≤15 dk'da TERM eder,
  driver retry sayacı artar; sahne: ab1-att0 sınıfı 71 dk → ≤15 dk.
- **Not:** Tur 1 guard'ları aynen korunur; watchdog yalnız driver katmanı.

### L4 — read budama kuralı (etki: read 37→≤12/oturum)

- **Yer:** P2 prompt + `web-core-engineer.md`.
- **Kural:** "Büyük dosyaları bütünüyle okuma; `sed`/aralık okuma; tekrar tekrar okuma
  yasak — bir dosya oturum başına en fazla 1 kez."
- **Kabul:** sonraki E2E P2 `read` çağrıları ≤ 12 (baz 37, E2E-3 att1).

### Faz 1.4 ölçüm protokolü (L1-L4 ortak)

- Tek kol (paralel değil — ab1 att0 çekişmesi dersi), aynı intent sha, glm-5.3 default.
- Baz: E2E-4 + ab2 (P2 6.83M/11.54M, 74/80 adım bandı).
- Rapor: `.factory/e2e-runs/<TS>/` + FINDINGS §16-17; metrics.jsonl'a **compaction
  sayacı** ve driver log'una watchdog kararı satırı eklenir.
- Budget: tek E2E 2.5-5.5 saat duvar (ücretsiz token); watchdog L3 ile alt uca kayar.

## 3. Faz 2.1 — JEV MCP (sonra)

- **Ne:** (a) runtime **dinamik model seçimi** — hardcoded `MODEL_MAP` yerine görev
  tipi/rapor boyutu sinyalleriyle P2 model seçimi (env override kalır); (b) **ensemble
  yalnız P4'te** — P3 QA FAIL sonrası düzeltme adayları ×2 + verifikatör (P2'de asla:
  maliyet fonksiyonunu k×'e çıkarır); (c) faz-bazlı **araç seçimi** (MCP tool
  set'i per-phase).
- **Ne değil:** yeni provider (envanter anthropic'siz); cost modeli (0/0 ücretsiz
  tier); P2'de çoklu aday.
- **Önkoşul:** Faz 1.4 kabul kriterleri yeşil (steps ≤50 bandı + att0 watchdog aktif).
- **Kabul (taslak, L1-L4 sonuçlarına göre kesilecek):** metrics.jsonl `model_used` +
  `ensemble` alanı; P4 ensemble medyan token ≤ 2× tek-aday P4 (ab2 P4 baz 841k);
  duvar ≤ 1.5× tek-aday P4.

## 4. Reddedilenler (bağlama kaydı)

- Daha fazla A/B turu (kullanıcı kararı §14; atık denetimi ile değiştirildi).
- Model default'u değişimi (glm-5.3 kalıcı).
- Uydurma cost/rate hesabı (models.dev 0/0 = ücretsiz tier; cost=0.0 doğrulanmış).

## 5. Onay bekleyenler

1. **Sıra:** L1-L4 (Faz 1.4) → ölçüm → JEV MCP (Faz 2.1)? **[öneri: evet]**
2. L1/L4 kalıcı kaydı: `.cursor/agents/web-core-engineer.md` + prompt — evet mi?
3. L3 eşiği 15 dk — yeterli mi, 10 dk'ya insin mi?
4. Faz 2.1 ensemble kapsamı: **P4-only** (öneri) mi, P2 de dahil mi?
