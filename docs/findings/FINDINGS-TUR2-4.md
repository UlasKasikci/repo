# FINDINGS-TUR2-4 — Erken Turn-Close Teşhisi (Kök Neden Raporu)

**Tarih:** 2026-10-09 · **Kaynak koşu:** `.factory/e2e-runs/20261009T154922Z-tur2-3/`
**Veri kaynağı:** `opencode.db` oturum deposu (kopya: run-eleme, salt-okunur) — silinen
NDJSON ev dosyaları yerine mesaj/part/token tabloları.
**Kapsam:** teşhis + reporting fix. **A2' metni değişmedi, yeni E2E koşulmadı (K3/K7).**

## Sonuç (tek cümle)

**Ana kök neden H1'in fiziksel varyantı: glm-5.3, son step'i reasoning içinde
32.000-token cap'e çarparak bitiriyor (output=0 → tool call yok → opencode oturumu
"tamamlandı" sayıyor, rc=0).** 6 P2 oturumun **4'ünde** son mesaj `reasoning=32000,
output=0`; kalan 2'sinde cap altında reasoning + uzun DUYURU metni, yine tool call'sız.

## Hipotez hükmü

| Hipotez | Hükm | Kanıt |
|---------|------|-------|
| **H1** — erken turn-close (tool'suz kapanış) | **DESTEKLENDİ (ana neden)** | 6/6 oturumun son step'i `step-start → REASONING → step-finish` — tek bir tool call yok. 4/6 son mesaj: `reasoning=32000` (tam cap), `output=0`. |
| **H2** — B2 SchemaError write kaybı | **ELENDİ** | 6 oturumda **0 hatalı tool** (`write:completed` ×23, hepsi `completed`). P1'deki 2 SchemaError P2'ye taşınmamış. |
| **H3** — A2' minimumu maksimum sanma | **KATKICI (ikincil)** | 2/6 oturumda tek write (sitemap.xml / robots.txt) + dur; birinde 21 write yapıp sözleşme-özeti metniyle kapandı. Minimum kural bazı oturumlarda "yeterli" hissi veriyor; ama asıl kesici cap. |

## Oturum kanıtları (6 P2, kronolojik)

| # | Oturum | Tools / Write | Son step reasoning | Son output | Son davranış |
|---|--------|---------------|--------------------|------------|--------------|
| 1 | 1bwTCV 17:24→18:01 | 1 / 0 | **32000** | **0** | Cap — read/bash sonrası plan, kesildi |
| 2 | HWUSQ8 18:02→19:11 | 7 / 1 (sitemap.xml) | 31523 | 477 | "Tüm çekirdek API'ler netleşti…" duyurusu, tool'suz kapandı |
| 3 | XYwVZT 19:12→19:33 | 2 / 0 | **32000** | **0** | Cap — domain-report truncation planı yarıda |
| 4 | Uxh4mD 19:33→19:56 | 5 / 1 (robots.txt) | **32000** | **0** | Cap — "tamamlama modeli… tamamlayacağım" |
| 5 | BFny19 19:57→20:34 | 24 / **21** | 28243 | 3757 | **En verimli:** core/9 + SQL/migrations/5 + configs + .htaccess + tests/3 tek dalgada; sonra uzun sözleşme özeti, tool'suz kapandı. **index.php + views/ + assets/ dalga dışı kaldı** |
| 6 | sNWHrf 20:34→20:54 | 1 / 0 | **32000** | **0** | Cap — "hemen yazma dalgasına geçeceğim" |

Ortak desen: her oturum **"sıradaki dalga" metniyle** dönüyor; opencode için
tool'suz assistant message = oturum tamam (rc=0). Model "devam edeceğim" diyor,
opencode "bitti" anlıyor.

## Mekanizma (M1 vs M2)

- **M1 — reasoning-cap truncation (4/6):** reasoning tam 32.000'de kesiliyor,
  output hiç üretilmiyor. Planlama reasoning bütçesini tüketiyor; tool call'a
  sıra gelmiyor. `opencode.json`'da token/effort ayarı **yok** — cap provider
  default'u (nvidia/z-ai/glm-5.3).
- **M2 — "kontrat anlaşıldı = kilometre" (2/6):** cap altında reasoning + uzun
  özet metni (output 477 / 3757 token) tool call'sız. H3'ün davranışsal çekirdeği.

Ek bulgu: BFny19 tek step'te **21 paralel write** basabildi — model ACT ettiğinde
kapasitesi var; darboğaz act'e GEÇİŞ, kapasite değil.

## Reporting fix (bu turda yapılan tek kod değişikliği)

`scripts/web/e2e-driver.sh`: `watchdog_kills` sahte sayımı düzeltildi — Tur 2-3'te
`watchdog_kills=6` göründü ama **gerçek kill=0** (driver, rc=3 çıkışında kendi
watchdog'unu TERM edip wrc=143'ü kill sayıyordu).

- Watchdog artık kill anında `E2E_WD_KILL_MARK` dosyasına nedeni yazar
  (`idle` / `no-write`).
- Driver: doğal çıkış için ≤12s poll; sayım **yalnız marker dosyasıyla**
  (`-s "$WD_MARK"`). Eşik aşılmışsa TERM yine yapılıyor ama sayılmıyor.
- self-test: senaryo 30A marker assertion'ı + **senaryo 31** (doğal çıkış →
  rc=0 + marker yok). 31/31.

## ÖNERİLER (sonraki tur için — bu turda FIX YOK, K3)

Sıralama, kanıt ağırlığına göre:

1. **M1 için — reasoning-cap araştırması (önce ucuz olan):**
   glm-5.3'ün 32k reasoning cap'i provider default'u. opencode model options'ta
   effort/thinking-budget yükseltilebilir mi? (opencode.json `models` bloğu /
   provider param). Kaldırılamıyorsa → 2 numara zorunlu.
2. **A2'' — "sürdür ve bitir" (M1+M2 ortak ilacı):** son mesajın tool'suz
   kapanışı yasak; "plan metni yazma, AYNI step'te ilk tool call'ı üret";
   "dalga duyurusu = dalga IÇINDE tool call". A2' (başlatma) korunur, sonuna
   sürdürme bağlanır. Prompt-side, K6'ya aykırı değil (A2' metni zaten karar
   bekliyor).
3. **Devam stratejisi:** orchestrate, `reasoning=32000 & output=0` oturumunu
   "yarım iş" sınıflandırıp retry prompt'una **önceki planın özetini + "plan
   tekrarlama, UYGULA"** enjekte edebilir (yeniden-planlama israfı bitsin —
   her retry sıfırdan planlayıp cap'e çarpıyordu). opencode session-devam
   (parent_id) destekleniyor mu araştırılmalı.
4. **H3 için opsiyonel:** A2''ye "1 write değil, manifest-ex gap kapanana kadar
   devam" eklenebilir — ama M1 çözülmeden H3 fix'i tek başına yeter değil (K7:
   tek kol).

## Kabul kriterleri mirası (Tur 2-3 → Tur 2-5)

- L3 kill=0 ✓ (K1 zinciri 5 saatte kusursuz — no-write-cap hiç tetiklenmedi,
  0 sahte kill message)
- write>0 ✓ (Tur 2: 0/6 → Tur 2-3: 3/6 oturumda yazım, 23 write toplam)
- Kalan boşluk: **tamamlanabilirlik** — iskelet %~70 (core+SQL var; index/views/
  assets/veritabani.sql yok). Tur 2-5 hedefi: tek oturumda iskelet 100%.
