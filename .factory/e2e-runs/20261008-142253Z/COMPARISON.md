# E2E-4 — Faz 1.1 ROUTING ÖLÇÜMÜ (Faz 1.2): E2E-3 ile Per-Phase Karşılaştırma

**Run:** `20261008-142253Z` · `DRIVER_DONE rc=0 attempts=1` · `state=DONE retry=0` · kill YOK
**Duvar:** 14:23:08Z → 16:41:57Z = **2s18dk49s** (E2E-3: 14s16dk arıza · E2E-2: 2s17dk temiz)
**Intent:** sha256 `2e481696…007` — E2E-1/2/3 ile birebir aynı senaryo.
**QA:** PASS 0/0 (13 kanal) · **packaging PASS** · `Yukleme/` 33 dosya · `qa-fail` **0**
(history: start→advance→advance→qa-pass→advance — **P4 iki turda da koşmadı**, QA ilk seferde geçti).
**Sağlayıcı arızası:** YOK (bugün `level=ERROR` provider = 0; tek olay 13-15 dk'lık uzun model
adımları — müdahale yok, kendi kendine devam etti). Exit-3 kurtarmaya gerek kalmadı.

## 1. Ana tablo (brief formatı)

| Faz | E2E-3 token | E2E-4 token | Δ% | E2E-3 model | E2E-4 model | E2E-4 cost_usd |
|-----|------------:|------------:|-----|-------------|-------------|----------------|
| P1  | 780,586 \*  | **987,470** | **+26.5%** | glm-5.3-flash † | `glm-5.3-flash` | **0.0** |
| P2  | 12,232,931 ‡ (att2) | **6,825,044** | **−44.2%** | glm-5.3-flash † | `glm-5.3` | **0.0** |
| P4  | — (koşmadı) | — (koşmadı) | — | — | `glm-5.3` (harita) | — |
| TOP | 14,682,011 | **7,812,514** | **−46.8%** | | | **0.0** |

\* Brief taslağında P1=412k yazıyordu — bu **E2E-1**'in P1'idir; E2E-3 P1 = 780,586 (düzeltildi).
† `model_used` alanı E2E-3'te yok (yönlü ölçüm, kabul); kanıt: `opencode.log` ERROR satırı
`modelID=z-ai/glm-5.3-flash session.id=ses_ee842ba38ffe…` = E2E-3 P2 att2 — E2E-3 tüm fazlar
default model (glm-5.3-flash) ile koştu.
‡ E2E-3 P2 = att1 (1,668,494, sağlayıcı çöküşü rc=1) + att2 (12,232,931) = **13,901,425 toplam**;
att2 dahil Δ −44.2%, toplam dahil **Δ −50.9%**.

**cost_usd = 0.0 (uydurma değil):** NVIDIA `/v1/models` fiyat döndürmüyor, opencode event
`cost=0.0`, models.dev glm-5.3/flash için **explicit {input:0, output:0} = ücretsiz NIM tier**
(bilinmeyenler `null` olurdu) → `.factory/model-pricing.json` rate'i 0/0 → `cost_usd` = 0.0
(E2E öncesi commit `3723bbf`). `not_available` yalnız rate/ token yokluğunda devreye girer
(parse_error satırında görüldü).

## 2. Bağlam tablosu (temiz koşu kontrolü — E2E-2, tamamı flash)

| Metrik | E2E-2 (flash, temiz) | E2E-3 (flash, arıza) | E2E-4 (routing, temiz) |
|--------|---------------------:|----------------------:|-----------------------:|
| P1 token / steps / dk | 623,802 / 14 / 24.6 | 780,586 / 19 / 126.5 | 987,470 / 16 / 69.1 |
| P2 token / steps / dk | 4,194,591 / 55 / 112.5 | 12,232,931 / 113 / 451.4 | **6,825,044 / 74 / 69.5** |
| TOP token | 4,818,393 | 14,682,011 | **7,812,514** |
| P2 token/step | 76.3k | 108.3k | **92.2k** |
| P2 cache_read | (alan yok) | 3,818,240 (%31) | **6,690,432 (%98)** |
| QA qa-fail / P4 | 0 / koşmadı | 0 / koşmadı | 0 / koşmadı |
| write SchemaError | 6/56 = %10.7 | 4/59 = %6.8 | **2/50 = %4.0** |
| attempts / kesinti | 1 / 0 | 2 / exit-3 (1.67M çöküş) | **1 / 0** |

## 3. Üç soru

**S1 — P2 adım sayısı (steps) düştü mü?**
**E2E-3'e göre EVET: 113 → 74 = −34.5%** (asıl karşılaştırma buydu — arıza-enflasyonlu baz).
Ancak temiz koşu kontrolü E2E-2'ye (flash) göre **55 → 74 = +%34.5 arttı**; token/step de
76.3k → 92.2k (+%21). Yani: outage yılına göre büyük kazanç, sağlıklı flash bazına göre
**glm-5.3 daha çok adım/token harcıyor** (ama P2 duvar süresi yine düştü: 112.5 → 69.5 dk).

**S2 — QA gate FAIL sayısı değişti mi?**
**Hayır — 0 → 0.** Her i turda da P3 ilk koşuda PASS 0/0 (13 kanal), `qa-fail` event'i yok,
P4 koşmadı. (P2 agent'ının kendi iç doğrulaması da temiz: "PHPStan level 8 temiz" ilk geçişte;
güçlü modelin "daha az retry" beklentisi destekleniyor — dış kapıda retry zaten 0'dı, iç döngü
adımları P2'nin kendi seçimidir.)

**S3 — Write SchemaError oranı değişti mi?**
**Evet — %6.8 → %4.0** (4/59 → 2/50). Model kırılımı çarpıcı:
- **P1 (glm-5.3-flash): 2/2 write HATA (%100)** — başa-newline kuralına RAĞMEN harness yine JSON
  parse etti (model kendi kapanış notunda da yazdı: "iki denemede de harness tarafından JSON
  objesi olarak parse edildi"); recovery bash heredoc → dosya byte-düzgün. **B2 = harness-side
  teyidi: prompt seviyesinde ÖNLENEMİYOR.**
- **P2 (glm-5.3): 0/48 write hata (%0)** — model etkisi görünen tek hücre (yalnız n=1 tur).
- edit hata: %25 → %14.3 (2/14; hepsi "No changes to apply" sınıfı, SchemaError 0).

**Ek kanıt (handoff):** P2'nin ilk read'i yine `domain-report.json` (E2E-3 att1+att2 ile 3/3) ✓.

## 4. KARAR NOKTASI verisi (sıradaki tur için)

- **Brief kriteri (E2E-3 baz, P2 12.23M):** Δ −44.2% → **>%20 düşüş → yeşil ışık (Faz 2.1)**.
- **Temiz kontrol (E2E-2 baz, P2 4.19M):** Δ **+62.7%** → ">%20 artış → model seçimi gözden
  geçir" eşiği de karşılanıyor.glm-5.3, flash'a göre belirgin daha pahalı (token bakımından;
  USD değil — NIM ücretsiz). Muhtemel ayar: `MODEL_P2=nvidia/z-ai/glm-5.3-flash` (env ile
  anında denenebilir) veya glm-5.3 medium/variant ayarı.
- Her iki referans da n=1 ve kontrollü değil (brief kabulü: E2E-3'te `model_used` yok, arıza yılı);
  kesin A/B → Faz 1.3'te iki-koşu tekrarı (aynı commit, iki env).
- **P1 notu:** flash→flash aynı model; +%26.5 artış_WRITE_RULE + doğrulama adımlarından
  (steps 19→16 ama adım başı 41.1k→61.7k) — P1 küçük model katmanı zaten flash'tı, ekstra
  kazanım P1'de yok (brief'in "P1 belirgin düşer" beklentisi bu envanterle karşılanmaz).

## 5. Metrik alanları (canlı doğrulama — `metrics.jsonl` satırları)

```json
{"phase":"P1","rc":0,"latency_ms":4145659,"model_used":"nvidia/z-ai/glm-5.3-flash","cost_usd":0.0,"retry_count":0,"parse_error":false,"steps":16,"input_tokens":945960,"output_tokens":11945,"tokens":{...},"total":987470}
{"phase":"P2","rc":0,"latency_ms":4172885,"model_used":"nvidia/z-ai/glm-5.3","cost_usd":0.0,"retry_count":0,"parse_error":false,"steps":74,"input_tokens":46109,"output_tokens":44717,"tokens":{...,"cache_read":6690432},"total":6825044}
```

- `retry_count` = aynı fazdan önce yazılmış satır sayısı (per-phase; her ikisi 0 — attempts=1).
- `input_tokens`/`output_tokens` = `part.tokens.input/output` flatten; **toplam ≠ in+out**,
  fark `tokens.cache_read` (P2'de 6.69M — NIM bağlam cache'i, E2E-3 flash'ın 3 katı oranı).
- append-only: E2E-3 satırları bu alanları taşımaz (alan eklendi, eski alan dokunulmadı).

## 6. Küçük bulgular

1. **driver.sh log hatası (tüm run'lar):** `printf '---- attempt …'` bash printf'ında format
   `--` option sanılıyor → `printf: --: invalid option` (stderr, log'a girmiyor) → `---- attempt
   rc=…` satırı hiç yazılmıyor (RUN2/3/4 hepsinde 0 satır). Kontrol akışı etkilenmiyor
   (`break` orchestrate rc'ye bakıyor). Düzeltme adayı: `printf -- '---- …'` — **bu turda
   dokunulmadı (ayrı tur).**
2. E2E-4 P2'de write hatası 0 — WRITE_RULE + glm-5.3 kombinasyonu P1 flash'ta 2/2 hataya
   rağmen P2'yi temiz tuttu (B2 hibrit sinyali: hem harness-sınıfı hem model-bağımlı).
