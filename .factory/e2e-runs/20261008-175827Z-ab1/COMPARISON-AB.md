# Faz 1.3 — A/B DOĞRULAMA: P2 modeli flash vs glm-5.3 (simetrik paralel koşu)

**Run:** `20261008-175827Z-ab1` (flash) + `20261008-175827Z-ab2` (glm-5.3) · bootstrap `@fa2113d`
**Protokol:** aynı commit, aynı intent (sha `2e481696…007`), iki temiz bootstrap proje,
**paralel** başlatma (aynı sağlayıcı penceresi = kontrollü), tek fark `MODEL_P2` env
(ab1=`nvidia/z-ai/glm-5.3-flash`, ab2=`nvidia/z-ai/glm-5.3`); P1/P4 haritaları sabit.
**Başlangıç:** 17:58:48Z · sağlayıcı hatası YOK (pencere içinde `level=ERROR`=0).
**Protokol notu:** watchdog token-cap 15M→30M **her iki kolda simetrik** yükseltildi
(20:29Z; ab2 P4 birikim riski; cap kaçak-koruma ağıdır, ölçüm parametresi değildir —
`PROTOCOL_NOTES`).

## 1. Sonuç tablosu

| Metrik | ab1 — P2=**flash** | ab2 — P2=**glm-5.3** | Δ (flash'a göre) |
|--------|-------------------:|---------------------:|------------------:|
| P1 token / steps / dk | 765,250 / 18 / 64.3 | 762,065 / 13 / 58.1 | +0.4% (tekrar ✓) |
| P2 att1 (erken dönüş, 0 write → exit-3) | 246,866 / 7 / 71.1 | 486,338 / 14 / 26.9 | ortak bulgu ↓ |
| P2 att2 (asıl üretim) | 8,760,571 / 76 / **194.0** | 11,539,813 / 80 / **53.7** | tok −22.4% / süre −72% |
| **P2 toplam (att1+att2)** | **9,007,437 / 83 st / 265 dk** | **12,026,151 / 94 st / 81 dk** | **tok −25.1% · adım −11.7%** |
| P4 (revizyon) | — (qa-fail **0**) | 841,234 / 27 st / 12.2 dk (qa-fail **1**: eslint+phpunit) | glm-5.3 +0.84M |
| **TOP token** | **9,772,687** | **13,629,450** | **−28.3%** |
| Duvar süresi (kol) | **5s30dk39s** | **2s31dk35s** | **glm-5.3 2.2× hızlı** |
| P2 throughput (att2) | ~33k tok/dk | ~144k tok/dk | **glm-5.3 4.4×** |
| QA (final) | PASS 13/13 (ilk geçiş) | PASS 13/13 (P4 sonrası) | berabere |
| Packaging | PASS · 46 dosya | PASS · 56 dosya | — |
| driver attempts / retry | 3 / 0 | 2 / 1 | — |
| write SchemaError | 7/65 = **%10.8** | 4/81 = **%4.9** | P1 flash 7/7 ↓ |
| edit hata | 3/16 = %18.8 | 6/23 = %26.1 | — |
| cost_usd | **0.0** | **0.0** | ücretsiz tier |
| `model_used` (metrics) | flash (tüm fazlar) | P1 flash; **P2+P4 glm-5.3** ✓ | env geçişi doğrulandı |

## 2. Üç soru (ön-kayıtlı)

**S1 — glm-5.3 token/step harcaması flash'a göre yüksek mi? (karar kuralı: >%20 fark)**
Bu A/B'de **flash P2 −25.1% daha az token** harcadı (9.01M vs 12.03M) → kuralın "flash
ucuz" tarafı tetiklendi. **AMA** varyans gölgesi: glm-5.3 solo koşu E2E-4'te P2=**6.83M/74 st**
idi (ab2: 12.03M/94 st — 1.76×); flash E2E-2'de 4.19M/55 st (ab1: 9.01M/83 st — 2.15×).
**Run-to-run varyans (>2×) model etkisinden (%25) büyük** → tekil koşularla model kararı
verilemez; ortalama: flash 6.60M vs glm-5.3 9.43M (flash −30%, n=2, zayıf kanıt).

**S2 — QA FAIL sayısı / kalite?**
ab1 **0** qa-fail (P3 ilk geçişte PASS) · ab2 **1** qa-fail (eslint+phpunit → P4, 0.84M,
12 dk, düzeldi). Final: ikisi de PASS 13/13 + packaging PASS. Kalite kapısı berabere;
glm-5.3'ün ek maliyeti1 P4 döngüsü.

**S3 — Write SchemaError (B2 hibrit hipotezi)?**
ab1 %10.8 vs ab2 %4.9. Kırılım: **P1 (flash) iki kolda 7/7 SchemaError** (json `{`-parse,
darben-sınıfı deterministik); **P2 att2**: flash 3/61 SchemaError (hattrecover ediyor),
glm-5.3 1/76 (SchemaError sınıfı 0 — farklı hata tipi). **P2'de glm-5.3 JSON yazımı daha
temiz; farkı yaratan P1'in flash olması** (P1 haritası iki kolda da sabitti — P1 flash'in
kendi tutarsızlığı). Handoff: **tüm P2 oturumları domain-report'u ilk okudu** (4/4);
P4 oturumu qa-report/debug/HelpersTest'e odaklandı (uygun).

## 3. Konfördançlar ve olaylar

1. **Ortak erken-dönüş (parallel etkisi):** her iki kolun P2 att1'i de **0-write, salt-keşif**
   oturumuyla erken döndü (exit-3 kapısı yakaladı, driver retry att2'yi üretti). E2E-4
   (tekil glm-5.3) böyle değildi → **paralel iki `opencode run` ilk-deneme güvenilirliğini
   düşürüyor** (iki modelde de). Token israfı ortak ve küçük (0.25M / 0.49M).
2. **ab1 att2 rc=1 (sessiz, token'sız):** P2 agent'ı kendi oturumundan `state.sh advance`
   çalıştırdı (P2→P3, 23:22:39 history) → orchestrate'in P2-branch `advance`'ı geçersiz-faz
   rc=1 verdi (`>/dev/null` stdout yuttu; `set -e` sessiz exit) → driver att3 → yalnız
   qa-gate+packaging (~13 sn) → DONE. **Token etkisi yok**; harness etkileşim bulgusu
   (agent self-advance + silent advance). Düzeltme adayları ayrı tur.
3. **Watchdog cap yükseltmesi** (§ protokol notu): simetrik, belgeli, ölçümü etkilemedi
   (hiçbir kol 15M'yi geçmedi: max birikim ab2'de P4 öncesi 12.79M idi — P4 sonrası 13.63M).
4. **Yukleme dosya sayısı** 46 vs 56 (aynı intent/kvkk; farklı uygulama içeriği — paketleme
   gate'i ikisinde de PASS).

## 4. KARAR VERİSİ (kullanıcı için)

| Kriter | Kazanan | Marj | Güven |
|--------|---------|------|-------|
| P2 token (bu A/B) | **flash** | −25.1% (TOP −28.3%) | orta (varyans > etki) |
| P2 token (ortalama n=2/kol) | flash | −30% (6.60M vs 9.43M) | zayıf (n=2, 2× spread) |
| Duvar süresi / throughput | **glm-5.3** | 2.2× / 4.4× | **yüksek** |
| Kalite (QA final) | berabere | 13/13 vs 13/13; glm53 1×P4 | orta |
| USD maliyet | berabere | 0.0 vs 0.0 (NIM free) | yüksek |
| İlk-deneme güvenilirliği | berabere | iki kolda da att1 erken-dönüş (parallel) | — |

**Öneri seçenekleri:**
- **(a) glm-5.3 kalsın (önerilen):** hız üstünlüğü kesin, token ortalaması yüksek ama
  ücretsiz tier'da öncelikli değil; E2E-4 solo kanıtı (6.83M) glm-5.3'ün düşük-token
  modunu gösterdi; instabilite (att1 erken-dönüş + att2 varyansı) prompt/parallel
  tarafında giderilebilir.
- **(b) flash'e çevir:** token-lean profilde −25…−30% token, ama 2.2× yavaş P2 ve
  flash'in yüksek `{`-parse yazım hatası (B2) kalır. `MODEL_P2=nvidia/z-ai/glm-5.3-flash`
  env ile anında uygulanır.
- **(c) yetersiz veri:** n=2 + 2× varyans → kesin A/B için 3-5 koşu/ kol (Faz 1.4) veya
  parallel'siz (seri) koşu protokolü.
