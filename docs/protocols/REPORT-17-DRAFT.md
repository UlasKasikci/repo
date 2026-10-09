# §17 (taslak — doldur: koşu bitince) — Faz 1.4-M ölçüm raporu

TS=20261009-005625Z-faz14 · commit e6cfc62 · tek kol · intent 2e481696…
Yorum dili: **sinyal/hipotez onayı** (tek kol, kontrollü A/B değil — REVIEW-NOTES U1).

## 1. Sonuç tablosu (metriklerden doldur)

| metrik | baz (E2E-4 / ab2) | Faz1.4-M | Δ | kriter | verdict |
|---|---|---|---|---|---|
| P2 steps | 74 / 80 | | | ≤50 | |
| P2 token (att toplam) | 6.83M / 11.54M | | | ≤0.7×baz | |
| P2 read-tool calls | 4 / 6 (E2E-4/ab2); 37 (E2E-3 att1 rekor) | | | ≤12 | |
| P2 bash calls | 28 / 28 | | | ≤3 doğrulama | |
| compaction (oturum) | 0 / 0 | | | ≥1 veya −%20 ctx/adım | |
| medyan bağlam/adım | 91k / 143k | | | −≥%20 | |
| att0/WD kill | ab1 71dk, E2E-3 275dk (0-write) | attempt1: 904s WD kill ✓ | | ≤15dk | PASS (L3) |
| **L3 kurtarılan duvar** (ROI, token değil) | eski: outer-timeout'a kadar ölü hava | **~2.75 saat** (904s kill vs 10800s timeout) | | — | L3 ilk avı |
| P1 duvar (AYRI satır — P2'yi maskeler) | 69 / 58 dk; E2E-1 25.8dk (2.15× varyans) | 49.2 dk | | — | gürültü notu |
| tok/write (P2) | 142k / 152k | | | ↓ hedef | |

## 1b. İki-değişkenli atıf çerçevesi (§REVIEW-NOTES)

| katman | beklenen | ayrıştırma aracı |
|---|---|---|
| L1+L4 | token ↓ + step ↓ | steps, read/bash sayaçları (DB), write dalgası zaman çizelgesi |
| L2 | token maliyeti ↑, net belirsiz | §2 compaction muhasebesi |
| L3 | token nötr, duvar ↓ | WATCHDOG satırları + kurtarılan duvar satırı |

att1 paterni (4/4): iki imza — ab: araştırma sarmalı → dev reasoning → 0 write;
faz14: CLI asılma (boş reasoning). Önleyici aday: P2 araştırma yasağı (bkz.
REVIEW-NOTES ATT1 OTOPSİSİ) — sonraki tur, bu koşu bitmeden uygulanmaz.

## 2. Compaction muhasebesi (AYRI SATIR — kullanıcı zorunlu kıldı)

- compaction sayısı + hangi adımda:
- compaction öncesi/sonrası cache_read/adım:
- tahmini net replay tasarrufu (lineer extrapolasyon — TAHMİN etiketi):
- compaction çağrısının kendi token maliyeti (DB message/part):
- **net: tasarruf / maliyet / belirsiz**:

## 3. Kaldıraç ayrıştırması (hangi müdahale ne yaptı)

- L1 batch-yaz: steps? write dalgası gerçekleşti mi (DB araç çağrısı zaman çizelgesi)?
- L2 compaction: tetiklendi mi? yukarıdaki muhasebe.
- L3 watchdog: kaç kill? (attempt1: 1 — 0-write att1 904s) — kategori-A israfı ne kadar kesildi?
- L4 read-budama: read sayısı + toplam okunan karakter (DB tool output chars)?

## 5. Atık sınıfları — §17'ye zorunlu iki ek satır (kullanıcı)

| atık sınıfı | ölçüm | koşular |
|---|---|---|
| **att1 waste** (ayrı kategori) | duvar + token: faz14 904s/15.2k tok; ab1 71dk/247k; ab2 26.8dk/486k; E2E-3 275dk/1.67M | 4/4 koşuda var; att2 başarılı olursa "att1 boşa, att2 yapar" kanıtlanır → eliminasyon ROI'si netleşir. **İSTİSNA — imza-(c):** E2E-3 att0'ın 18 write'ı gerçek üretimdir → **NET ATIK DEĞİL, KISMİ YATIRIM**; bu 275dk/1.67M satırı waste değil "yarı-yazım yatırımı" olarak sayılacak (Q1'e göre ayrıştırılacak) |
| **reasoning explosion** | tek-step reasoning karakteri: ab1 121.8k (40 dk), ab2 91.7k; E2E-3 att0 55.4k+79k (CANLI — sonrası write var); imza-(b) koşularında terminal ≈106.8k ort. | tedavi: **spike-sonrası-write zorlaması** (EK1 revize — hard-kill REDDEDİLDİ: E2E-3 üretken spike'ları 20k kill'de ölürdü) |

## 5b. Spike-sonrası davranış tablosu (şablon — koşu bitince doldurulacak)

Ayrım sinyali: spike sonrasında write gelip gelmediği. Bu tablo olmadan (b) vs (c)
ayrımı kâğıt üzerinde kalır.

| koşu/oturum | spike boyutu | konum (msg#/step#) | sonrası write? | kaç write | imza |
|---|---|---|---|---|---|
| ab1 att0 | 121.8k | msg7 (todowrite sonrası) | HAYIR | 0 | (b) terminal |
| ab2 att0 | 91.7k | msg13 (harness-okuma sonrası) | HAYIR | 0 | (b) terminal |
| E2E-3 att0 | 55.4k | msg5 | EVET | 18 (toplam) | (c) canlı |
| E2E-3 att0 | 79.0k | msg9 | EVET | (aynı oturum) | (c) canlı |
| faz14 att1 | 0 (boş reasoning[0ch]) | msg3 (step1 sonrası) | HAYIR | 0 | (a) CLI stall |
| faz14 att2 | (doldur) | | | | |
| *diğer spike'lar (varsa)* | | | | | |

## 6. Karar (senaryo A/B/C) + sonraki tur önceliği

- senaryo: (A/B/C — kriter tablosuna göre)
- **öncelik sırası (EK1 revizyonuyla — REVIEW-NOTES):** 1 kontrat tamlığı →
  2 araştırma yasağı+QUESTIONS.json → **3 spike-sonrası-write zorlaması +
  "başladıysan bitir"** (hard-kill değil) → 4 todowrite→3→write → 5 no-progress
  watchdog → 6 write post-process. **Faz 2.1 (JEV) ERTELENDİ** — ve design'i
  revize: tek-attempt varsayımı → "araştır+yaz / devam et" iki-attempt modeline
  bağlanacak (bkz. hazırlık-turu revizyonu, §6b).

## 6b. Hazırlık-turu çerçevesi REVİZYONU + Q1

- ESKİ (yanlış): "att0=hazırlık (keşif+plan), att1=yazma" — iki temiz faz.
  İmza-(c) bu modeli inkâr eder (E2E-3 att0 zaten 18 write yaptı).
- YENİ (doğru): "att0=**araştır+yaz** (tek faz, sıkı bütçe), att1=**devam et**
  (sıfırdan değil)".
- **Q1 (HAYATİ — att2 bitince İLK iş):** att2 transcript'inde att1'e referans
  var mı? (domain-report / todowrite / yazılmış dosya adları / "önceki deneme")
  - YOK → att1 tamamen atık → tek-attempt sıkı bütçe yeterli.
  - VAR → att1 kısmi yatırım → iki-attempt "devam" modeli meşru.
  Bu arama yapılmadan "att1 gereksiz" hükmü kesinleşmez; sonuç §17'de tek satır.

## 7. Sapmalar / ilginç bulgular

- P1 write-JSON-parse (B2, 3. tekrar) — ajan bash-heredoc recovery ile kurtardı;
  WRITE_RULE prevention değil recovery olarak çalıştı.
- L3 ilk saha avı:904s TERM (imza-faz14 CLI stall — boş reasoning[0ch]).
- att2: 02:01:45Z start; P2 hâlâ aktif (izleme sürüyor).

## 6c. Q1 CEVABI (make-or-break — dolduruldu)

| sınıf | attN→attN+1 referans? | kanıt | hüküm |
|---|---|---|---|
| (c) E2E-3 | **VAR** | att1: att0 dosyalarına 28 ref + 20 edit (8 dosya) | att1 = **kısmi yatırım**; "devam et" modeli meşru |
| (a) faz14 | YOK (trivial) | att1 0 çıktı; att2 3 araç = P1 artifactsı | att1 = tam atık (L3 ile 15dk'ya kısılmış) |
| (b) ab1/ab2 | YOK | att0 0 write | att0 = tam atık |

Tasarım sonucu: "scaffold varsa sıfırdan yazma, tamamla" kuralı evrensel
yazılabilir — (c)'yi korur, (a)/(b)'de bedavi.
