# ATIK DENETİMİ (Tur 2) — mevcut loglar, yeni koşu yok

**Kapsam:** 6 koşu (E2E-1..4 + ab1/ab2), 15 metrics satırı, opencode DB tool sayaçları
(12 oturum). **Para birimi: token değil duvar süresi** (tier ücretsiz, `cost_usd=0.0`);
token burada yalnız tekrar-gönderim yükünün ölçütü. Yöntem: `metrics.jsonl` + DB `part`
(tool sayaçları, compaction) + `orchestrate.log`. Yeni E2E çalıştırılmadı.

## 1. Token ekonomisi — üretim ≤ %1.3

Her P2/P4 satırı için pay (`input` = taze girdi, `cache_read` = bağlam tekrar-gönderimi):

| koşu/oturum | steps | toplam | input | cache_read | out+rsn | out+rsn payı | cache hit¹ |
|---|---:|---:|---:|---:|---:|---:|---:|
| E2E-3 P2 att0 (exit-3) | 23 | 1.67M | 85.3% | 11.5% | 53.9k | **3.2%** | 11.9% |
| E2E-3 P2 att1 | 113 | 12.23M | 68.2% | 31.2% | 69.7k | **0.57%** | 31.4% |
| E2E-4 P2 | 74 | 6.83M | 0.68% | 98.0% | 88.5k | **1.30%** | 99.3% |
| ab1 P2 att0 (0-write) | 7 | 247k | 81.0% | 0% | 46.9k | **19.0%** | 0% |
| ab1 P2 att1 | 76 | 8.76M | 59.0% | 39.8% | 104.3k | **1.19%** | 40.3% |
| ab2 P2 att0 (0-write) | 14 | 486k | 8.4% | 82.8% | 43.4k | **8.9%** | 90.8% |
| ab2 P2 att1 | 80 | 11.54M | 0.78% | 98.0% | 135.9k | **1.18%** | 99.2% |
| ab2 P4 | 27 | 841k | 1.8% | 95.8% | 20.0k | **2.4%** | 98.2% |

¹ `cache_read/(cache_read+input)`. Production = `output+reasoning`.

**Sonuç:** tamamlanan oturumlarda üretimin maliyeti **~%1.2**; kalan **%98.8 bağlam
taşıma**dır (sistem promptu + ajan md + araç şeması + adım iskeleti tekrar-gönderimi).
Tool sonuçları DB'de yalnız **121-201k karakter** (~30-50k token) — şişkinlik tool
çıktılarından değil, **adım sayısının her adımda tüm geçmişi yeniden göndermesinden**
gelir: bağlam/adım = ab2 att1 143k · ab1 att1 114k · E2E-3 att1 108k · E2E-4 91k.
**Maliyet fonksiyonu ≈ steps × ort. bağlam.** Compaction: 12 oturumun **12'sinde 0**.

## 2. Atık kategorileri

### A — att0-0-write erken dönüş (en pahalı israf, üç koşuda tekrarlandı)

| koşu | steps | token | duvar | açıklama |
|---|---:|---:|---:|---|
| E2E-3 P2 att0 | 23 | 1.67M | **274.6 dk** | 275 dk keşif → exit-3, tek satır yazmadan |
| ab1 P2 att0 | 7 | 247k | **71.1 dk** | 8 bash + 5 read → 0 write, 609 sn/adım (paralel lansman çekişmesi?) |
| ab2 P2 att0 | 14 | 486k | **26.8 dk** | 16 bash + 7 read → 0 write |
| **toplam** | | **2.40M** | **372 dk (6.2 saat)** | driver her birini tam attempt olarak retry'ledi |

Orkestratör att0'ı `scaffold_ok` ile yakalayıp exit-3 verdi (doğru davranış) — **ama
önce tüm att0'ı harcadı**. att0'ın 0-write olduğu ancak att0 bitince anlaşılabiliyor.

### B — cache-miss → taze-input şişkinliği (provider varyansı)

ab1 att1 **5.17M taze input** (68k/step) vs ab2 att1 **90k toplam taze** (1.1k/step) —
**57× fark**, aynı prompt, tek fark model. Sonuç: ab1 att1 **153 sn/adım**, ab2 att1
**40 sn/adım** — "ucuz" flash bu oturumda glm-5.3'ten **3.8× yavaş** adım attı (cache
miss → her adım büyük yük yeniden gönderiyor). E2E-4 tekilde flash %99.3 hit almıştı
(46k taze, 56 sn/adım) → miss provider/node varyansı, model özelliği değil. Atık
çerçevesi: ab1 att1'de hit oranı glm-5.3 seviyesinde olsaydı taze input ~1M olurdu
(**~4M token + ~2 saat** görünür duvar farkı). Kullanıcıya etkisi: token'sız tier'da
yalnız duvar — A/B'deki −28.3% token farkının büyük kısmı bu tek oturumun cache
performansından, üretim verimliliğinden değil.

### C — adım × bağlam büyüme (compaction yok)

E2E-3 att1: **113 adım, 12.23M token, 7.5 saat, compaction 0** — bugüne kadarki en
pahalı oturum. 80-adımlık oturumlarda bağlam doğrusal büyüyor (base ~35k + steps×~1.4k);
adım 50'de compaction yapılsaydı replay'in ~%30'u kesilirdi. opencode compaction'ı
destekliyor (DB'de 56 compaction event'i var) — ajanlarımız hiç tetiklemedi.

### D — bash/read churn (bağlama giren her çağrı)

tamamlanan att1'lerde araç karışımı: ab1 41 bash + 11 read + 61 write (1.6 araç/adım),
ab2 28 bash + 6 read + 76 write, E2E-3 att0 **37 read + 40 bash + 40 edit** (201k karakter
tool sonucu — en kirli oturum). Her bash/read sonucu + araç-çağrı JSON'u bir sonraki
adımın girdisi. Verim: **tok/write** — ab2 att1 151.8k · ab1 att1 143.6k · E2E-4 142.2k ·
E2E-3 att1 **305.8k** (en kötü: 80 araç çağrısı 40 write'a).

### E — silent-exit (Tur 1'de kapatıldı)

ab1 att2→att3: token israfı **0** (att3 yalnız qa-gate+pkg, 13 sn), tam bir attempt
israfı. `69024f1` advance-guard ile sınıf kapandı; regresyon self-test 23'te kilitli.

### Zemin (atık değil)

P1 tabanı her koşuda **762-987k** (sistem promptu + spec + denetim) — sabit maliyet,
dokunulmaz.

## 3. Öneriler (etki × maliyet sıralı)

1. **L1 — batch-yaz kuralı** (P2 ajan md + WRITE_RULE): "tüm dosyaları tek `write`
   dalgasında yaz; bash ile sırayla deneyimleme; en fazla N bash" → steps doğrusal
   düşer (maliyet fonksiyonunun birinci terimi). Beklenti: 80→~45 adım, P2 token −%40.
2. **L2 — compaction eşiği** (ajan md veya orchestrate yönlendirmesi): bağlam/adım
   büyümesi eşiği aşınca compact → replay −~%30 (özellikle 100+ adım oturumları).
3. **L3 — att0-0-write watchdog** (driver): 15 dk'da 0 write → att0'ı TERM ile kes,
   retry'a say → 6.2 saatlik A kategorisi israfının %80'i kesilir.
4. **L4 — read budama kuralı** (ajan md): "dosyayı bütünüyle okuma; `sed`/aralık;
   domain-report'tan çalış" → E2E-3 sınıfı 37-read oturumları ~10'a.

**Sınırlar:** B (cache miss) provider varyansıdır — L1/L3 onu yalnız duvar üzerinden
dolaylı azaltır (az adım = az maruz). Cost/throughput ölçümleri ücretsiz tier'da
yalnız duvarla yorumlanmalı (§2B dersi).

## 4. Tur 2 sonucu

P2'nin "12M token"ının **%98.8'i bağlam taşıma, %1.2'si üretim**; israfın kaynağı model
seçimi değil: **(A) 0-write att0 denemeleri (6.2 saat), (C) compactionsız 100+ adım
oturumları, (D) araç churn'u**. L1-L4 fabrika katmanında deterministik uygulanabilir;
L1+L3 tek başına sonraki E2E'de duvar −%40-60 hedefler. Faz 2 planının girdisi.
