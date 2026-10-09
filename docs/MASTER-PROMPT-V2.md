# MASTER PROMPT v2 — App-Fabrika Web Edition
# JEV Entegrasyon Fazı ve Stratejik Karar Belgesi

## 0. Bu Belgenin Rolü

Bu belge, önceki master prompt'un ÜZERİNE biner — onu geçersiz kılmaz.
- Önceki belge: teknik mimari (state graph, kontratlar, QA gate, ajanlar).
  HALEN GEÇERLİ, dokunulmayacak. → `docs/WEB-EDITION.md`
- Bu belge: stratejik karar + JEV entegrasyon rotası + değişmez kurallar.

Her yeni turun başında bu belge okunur. Bir istek bu belgeyle çelişiyorsa,
bu belge kazanır — çünkü deneyimden damıtılmıştır, varsayımdan değil.

---

## 1. Stratejik Karar (Damıtılmış)

### Karar
**Denetim %90'da dondurulur. Kalan %10 token ekonomisine yatırılır.**
Hedef: ortalama proje 14M token → 3-4M token. <1M bir ütopyadır, kovalanmaz.

### Gerekçe
1. 14M token'ın çoğu "yeniden üretim"dir (KVKK bloğu, admin CRUD, auth).
   Bu bir denetim problemi DEĞİL, yeniden kullanım problemidir.
2. Denetim katmanları zaten freelance ihtiyacın ÜSTÜNDE:
   14 QA kontrol, smoke, SQL drift, KVKK kanalı, doc-code drift.
   %100'e çıkarmak marjinal hata yakalar, orantısız token yakar.
3. JEV'in değeri tam burada: "denetim yerine" değil, "denetim varken tasarruf".
   Denetim aynı kalır; hangi ajanın hangi modelle/bağlamla çalıştığı optimize edilir.

### Neyi Değiştirir
- Yeni denetim katmanı YALNIZ somut bir bug için eklenir. Spekülatif değil.
- "Atık denetimi" turları bitti. Sıra "tasarruf üretimi" turlarında.
- JEV = merkezi karar katmanı, opsiyonel optimizasyon değil.
- Her tur sonu: "bu tur kaç token tasarruf etti?" sorusuna cevap.

---

## 2. Mevcut Durum (Kanıtlanmış)

### Kanıtlanmış Bileşenler
- State graph: P1→P2→P3→P5, max_retries:3, idempotent devam (E2E-2)
- 5 ajan, ayrık oturumlar (B1 fix, mode:primary, fallback=0)
- QA gate: 14 kontrol, asimetrik çekirdek (phpstan∧phpunit zorunlu)
- Paketleme: staging → smoke → arşiv → atomik takas + MANIFEST.json
- SQL dump drift kontrolü, KVKK koşullu modül, doc-code drift
- Model routing (Faz 1.1): MODEL_MAP + model_used + env override
- Watchdog (L3): idle TERM, 904s→15dk saha avı kanıtlı
- metrics.jsonl: per-agent token/latency/model_used/cost_usd

### Kanıtlanmış Problemler (üç imza)

| imza | oran | kök neden | doğru tedavi |
|------|------|-----------|--------------|
| (a) CLI stall | 1/4 | altyapı | no-progress watchdog 60-120s |
| (b) 0-write spiral | 2/4 | terminal reasoning | araştırma yasağı + ilk-write duvar-saati (A2') |
| (c) partial-write + spike | 1/4 | üretken ama eksik | "başladıysan bitir" (kesme değil) |

(b) ve (c) aynı yüzeyi (reasoning spike) paylaşır. Ayrım sinyali:
spike SONRASI write gelip gelmediği. Boyut değil.

### Bekleyen Veri
- E2E-3 att0 (imza-c): 55.4k/79k spike, 18 write — NET ATIK DEĞİL, kısmi yatırım.
- att1-waste kategorisi: imza-c için "kısmi yatırım" istisnası zorunlu.
- Q1 (make-or-break): **CEVAPLANDI (c90afdc)** — (c) sınıfında att1, att0'ın
  18 dosyasına 28 referans + 20 edit yaptı → att1 = kısmi yatırım, atık değil.
  (a)/(b) sınıflarında referans yok → tam atık (L3 ile 15dk'ya kısılmış).

---

## 3. Yol Haritası: J1 → J2 → J3

### J1 — JEV Model Routing + Bağlam Puanlama (1-2 hafta)
Hedef: %20-30 token düşüşü. Model seçimi + bağlam pruning.

Adımlar:
1. JEV MCP entegrasyonu (`jev-decision` veya `jev-mcp-server`; `TYPESAFE_API_KEY`).
2. P2'ye giden bağlamı JEV'e puanlat: "bu dosya gerekli mi?"
3. Kontratlar inline DEĞİL, yol olarak verilir (ZATEN yapıldı — teyit et).
4. metrics.jsonl'e `context_pruned_by_jev` alanı ekle (pruned token sayısı).

Kapı: aynı E2E, JEV on/off, P2 token karşılaştırması. ≥%20 düşüş → J2.

### J2 — Modül Kütüphanesi v1 (3-4 hafta)
Hedef: %40-50 ek tasarruf. LLM hiç çağrılmadan modül kopyalama.

Kapsam (v1):
- `.factory/modules/kvkk/` — views/legal/* + cookie-consent + 002_kvkk.sql
- `.factory/modules/admin-crud/` — generic CRUD iskeleti (entity parametreli)
- `.factory/modules/auth-rbac/` — login + rol tablosu + middleware

Akış:
- P2 prompt: "ÖNCE `.factory/modules/` kontrol et. Uyan modül varsa kopyala,
  değişkenleri doldur. LLM ile yazma."
- JEV: "bu görev hangi modülleri kapsıyor?" → modül listesi döner.

Kapı: 3 farklı E2E, modül kullanılan kısımlarda ≥%80 token düşüşü.

### J3 — Kalibrasyon (2-3 hafta)
Hedef: kararlılık. `--strict` per-model eşikler, 5+ E2E dağılımı.

Adımlar:
1. 5 E2E koşusu, model başına token dağılımı çıkar.
2. `--strict` per-model: P1 (haiku) için ayrı, P2 (sonnet) için ayrı eşik.
3. Varyans raporu: model değişimi vs bağlam değişimi ayrıştırması.

Kapı: "tek paket sığar" hedefi için ölçülebilir kanıt.

---

## 4. Değişmez Kurallar (Deneyimden)

### K1 — Hard-kill YASAK (imza-c için; Tur 2-2 genişletmesi)
Reasoning spike'ta hard kill = üretken attempt'i öldürmek.
E2E-3 att0'ın 55.4k/79k spike'ları 18 write üretti; 20k hard-kill olsaydı hepsi ölürdü.
Doğru: "spike sonrası ilk write'ı zorla", kesme değil.

**Genişletme (Tur 2-2):** Reasoning sırasında **idle-kill de YASAK.** Tur 2'de L3,
P2'yi 6/6 kez idle öldürdü — çünkü L3 idle sinyali "son tool çağrısı ne zamandı" idi;
model reasoning yaptığı için tool çağırmıyor, L3 bunu "idle" sanıp kill etti.
Yani L3, pratikte bir reasoning-kill aracıydı — K1'in kör noktası.
- Eski sinyal: son tool çağrısı ne zaman (yanlış — reasoning'i idle sayar).
- Yeni sinyal: **son non-empty output** (event stream'den). Boş reasoning stream'i
  idle sayılır; dolu reasoning stream'i (text/tool/reasoning event'i geliyorsa) idle
  DEĞİL. Kill yalnızca: (tool çağrısı yok) VE (stream 60s+ boş) VE (toplam idle_max+).
Bu hem Tur 2'nin hem gelecekteki JEV (v2) karmaşık reasoning'inin altyapı güvencesidir.

### K2 — İmza-bazlı tedavi (yüzey değil kök)
Aynı görünen spike (b)'de ölü, (c)'de canlı. Tek eşikle ikisine müdahale etmek
= birini tedavi edip diğerini öldürmek. Her müdahale imza etiketiyle commit'lenir:
`[fix: imza-b]`, `[fix: imza-c]`, `[fix: imza-a]`.

### K3 — Ölçmeden karar yok
"6M → 8M ayarla" gibi spekülatif eşik değişikliği YASAK.
n=2'yle hüküm YASAK. Varyans > etki ise "ölçülemedi" de, karar verme.

### K4 — Kontrat tamlığı > yasak
Araştırma yasağı koymadan önce kontratların eksiksiz olduğunu doğrula.
Eksik kontrat + yasak = sessizce yanlış üretim (daha kötü).

### K5 — Belge kanıttan türesin, iddiadan değil
`yapilacaklar.md`'de [x] işareti qa-gate PASS olmadan KONULMAZ.
Orkestratör günceller, ajan değil. Halüsinasyonu kalıcılaştırma.

### K6 — Denetim donduruldu
Yeni QA kontrolü YALNIZ somut bir bug için eklenir.
"Belki faydalı olur" ile eklenen kontrol = token israfı.

### K7 — İki imza, iki kol
Model değişimi + bağlam değişimi AYNI turda test EDİLMEZ.
İkisi karışırsa hangisinin işe yaradığı bilinemez.

### K8 — Silme değil, işaretleme
Bir yaklaşım başarısız olduysa, dosyayı silme — `docs/audits/REVIEW-NOTES`'a
"reddedildi + neden" olarak yaz. Gelecek tur aynı hatayı tekrarlamasın.

---

## 5. Çalışma Prensipleri

### Her turda
1. Başla: canlı koşu var mı kontrol et. Varsa DOKUNMA, bekle.
2. Plan: turun hangi imzaya/kata hizmet ettiğini yaz.
3. Kapsam: küçük tut. "Aynı turda X+Y" cazip ama K7'yi ihlal eder.
4. Kanıt: commit hash + self-test sayısı + CI log + metrics satırı.
5. Kapanış: "bu tur ne tasarruf etti?" sorusuna cevap yaz.

### Tur boyutları
- Küçük tur: 1 dosya + test. <30 dk.
- Orta tur: 2-3 dosya + ölçüm. <2 saat.
- Büyük tur: E2E koşusu. 3-6 saat. YALNIZ gerekliyse.

### E2E disiplin
- E2E pahalıdır. Her turda koşulmaz.
- E2E öncesi: bu koşu hangi hipotezi test ediyor? yazılı olmalı.
- E2E sonrası: hipotez onaylandı mı? reddedildi mi? kısmi mi? yazılı olmalı.

### JEV entegrasyonu
- JEV "karar" katmanıdır, "üretim" katmanı değil.
- JEV pahalı modeli gereksiz çağırmayı ENGELLER, üretmez.
- JEV çağrısı ucuz olmalı (<%1 toplam token).

---

## 6. Başarı Metrikleri

### Tur Başına

| Metrik | Hedef |
|--------|-------|
| Net token tasarrufu | ≥0 (tur tasarruf üretmeli, sıfır kabul; negatif YASAK) |
| Denetim kapsamı | Değişmemeli (14 QA kontrol + smoke + drift) |
| Self-test | 30/30 PASS (kırılma yok) |
| CI | Yeşil |

### Proje Başına (3-6 ay)

| Metrik | Şimdi | Hedef |
|--------|-------|-------|
| Toplam token | 14M | 3-4M |
| P2 token | 12M | 2-3M |
| att0 waste | ~600k ort | <100k |
| Duvar süresi | 2-5 saat | <2 saat |
| Cursor Pro bütçesi | 2 paket | 1 paket |

### Kalite (Değişmemeli)
- QA PASS oranı: %100 (JEV sonrası da)
- Smoke PASS: %100
- KVKK kanalı: PASS
- Güvenlik grep: PASS

---

## 7. Dokunulmayacaklar

### Kesinlikle değişmeyecek
- QA gate kontrol listesi (yeni kontrol YALNIZ bug için)
- State graph yapısı
- `max_retries: 3` mantığı
- Self-test senaryoları (yalnız eklenebilir, silinemez)
- Kontrat şemaları (`additionalProperties:true` KORUNUR, opsiyonel alanlar)
- Paketleme akışı (staging + smoke + arşiv + takas)

### Dikkatli değişecek
- `orchestrate.sh` içi (run_agent, MODEL_MAP, metrics)
- `p2_prompt` (WRITE_RULE, BATCH_RULE, modül yönlendirmesi)
- `docs/WEB-EDITION.md` (yeni bölümler)
- `.factory/modules/` (YENİ — v1'de KVKK + admin-crud + auth-rbac)

### Asla eklenmeyecek
- Yeni ajan (5 ajan yeterli)
- Yeni QA kontrol (bug yoksa)
- Yeni state (P1-P5 yeterli)
- Yeni denetim scripti (mevcut yetiyor)

---

## 8. Karar Ağacı (Her Yeni İstek İçin)

```
Yeni istek / tur konusu
  └─ Hangi fazda?
      ├─ v1 tamamlanmadı → v1 ÖNCELİK (A1/A2 hâlâ açık)
      ├─ v1 tamam + gerçek proje denenmedi → GERÇEK PROJE turu
      └─ v1 + gerçek proje OK → J1/J2/J3 rotası (v2)
```

### Ek kural — imza-bazlı öncelik
Bir turun konusu, o anki baskın imzaya göre seçilir.
Baskın imza = son N koşuda en sık görülen.

- Şu an: (a) 3/3 → ÖNCELİK A1 (araştırma yasağı) + EK2 (no-progress watchdog)
- Sonra: (b) baskınsa → A2' (ilk-write duvar-saati) + reasoning tavanı
- Sonra: (c) baskınsa → "scaffold varsa tamamla" kuralı (zaten yazıldı)

### v1 tamamlama kapsamı (bu tur / sıradaki tur)
Aynı imzaya (b) hizmet ettikleri için birlikte:
- **A1 — araştırma yasağı:** P2 ajanı yalnız whitelist kaynakları okur
  (domain-report + contracts + iskelet); çıkış kapısı `contracts/QUESTIONS.json`.
- **A2' — ilk-write duvar-saati (A2 revizyonu, Tur 2-2):** İlk 3 tool çağrısı içinde
  EN AZ 1 write — mutlak duvar-saati, todowrite tetikleyicisine bağlı değil
  (Tur 2 kanıtı: todo çağıran 2/6 oturumda bile write=0). Kesme yok (K1). Ayrıca P2
  prompt'una tek-bash `cat` affordance'ı (truncation döngüsü kırılır — Tur2 att6).
  P2 tamamlanmadan JEV'e (v2) geçilmez — JEV routing
  "tek attempt'te temiz P2" varsayar; Tur 2 kanıtı (6/6 0-write kill) P2'nin
  attemptsiz tamamlanamadığını gösteriyor.
