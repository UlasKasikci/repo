# FINDINGS — Tur 2-2 Pilot (K1 genişletmesi + A2' revizyonu doğrulama)

**Tarih:** 2026-10-09 · **Kapsam:** Tur 2 FAIL sonrası K1 kör noktası düzeltmesi + A2' pilotu
**Commit:** `fa45b28` (K1 stream+CPU sinyali, A2' duvar-saati, cat affordance, --p2-only, self-test 29/29)

## 1. Pilot 1 — stream sinyali YETERSİZ (kanıt)

**Koşu:** `20261009T143119Z-tur2pilot` · att1 · idle_max=900s · stream-only sinyal

- **Sonuç:** L3 watchdog 900s idle'da **KILL** etti (`WATCHDOG: P2 idle 900s ≥ 900s`)
- **Kanıt:** ev file 36KB'da 900s SABİT (stream growth=0) AMA opencode **27.4% CPU**
  ile çalışıyordu; son text: *"tek dalgada tüm iskeleti yazıyorum"* (üretken reasoning)
- **Kök neden:** `opencode run --format json` NDJSON stream'i **reasoning sırasında sessiz
  kalır** — step-start → step-finish arası HİÇBİR event yazılmaz. Stream-growth sinyali
  "dolu reasoning" ile "ölü idle"ı AYIRAMAZ.
- **Token:** 37,771 (att1, kill-safe metrics)

**Ders:** K1 genişletmesinin stream-growth sinyali tek başına YETERSİZ. CPU kanalı zorunlu.

## 2. Pilot 2 — CPU sinyali ÇALIŞIYOR (doğrulama)

**Koşu:** `20261009T145339Z-tur2pilot2` · att1 · idle_max=900s · stream+CPU sinyali · dış bütçe 1800s/500k

| metrik | değer | yorum |
|---|---|---|
| L3 iç watchdog kill | **YOK** (27 dk) | **K1 doğrulandı** — reasoning sırasında idle-kill olmadı |
| CPU sinyali | cputime 0:33 → 3:16 (+163s) | kanal (c) aktif, idle sıfırlandı |
| Stream sinyali | ev 12KB→55KB (23. dk'da büyüdü) | kanal (b) ara sıra tetiklendi |
| A2' duvar-saati | **3. tool call = write** ✓ | read→bash→**write**(phpstan.neon.dist, 73B)→bash |
| Model metni | "Duvar-saati kuralı gereği ö..." | kuralı AÇIKÇA telaffuz etti |
| İskelet (index.php/core/views/SQL) | **0 dosya** | skeleton yazılmadı |
| Dış budget | 1803s ≥ 1800s → TERM | 30dk'da skeleton tamamlanamadı |
| Token | metrics kill-safe boş (TERM driver'a gitti) | ~en az 31.5k (step-2 finish) |

## 3. Değerlendirme

| hedef | sonuç |
|---|---|
| K1: reasoning idle-kill yasak (CPU sinyali) | **PASS** — 27 dk L3 kill yok |
| A2': 3. call'da write | **PASS** — write geldi (config dosyası) |
| Pilot: write >0 | **PASS** — phpstan.neon.dist yazıldı |
| Pilot: L3 kill yok | **PASS** |
| Pilot: ≤15 dk skeleton tam | **FAIL** — 30 dk'da skeleton yok (glm-5.3 yavaş) |
| Pilot: ≤500k token | bilinmiyor (metrics boş) |

## 4. Kök neden — glm-5.3 hız sorunu (watchdog DEĞİL)

Model 15 dakika saf reasoning yapıp sonra config dosyası yazdı; skeleton dalgası
30 dk'da gelmedi. Bu **watchdog sorunu değil, model-hız/verimlilik sorunu**:
- K1 fix sayesinde model öldürülmedi (eski L3 900s'te öldürürdü)
- A2' kuralı model tarafından telaffuz edildi ve kısmen uygulandı
- Ama glm-5.3'ün reasoning→write gecikmesi pilot bütçesini aştı

## 5. Karar seçenekleri

1. **K1 fix'i koru, tam E2E'ye geç** — K1 doğrulandı; glm-5.3 yavaş ama üretebilir
   (E2E-3'te att2 12.2M token/7.5saatte tamamladı). Pilot bütçesi (15dk) glm-5.3 için
   gerçekçi değildi; tam E2E'de L3 kill yok → modelin zamanı olur.
2. **A2' iterasyonu** — prompt'a daha agresif erken-write baskısı (ör. "İLK tool call'da
   config değil, İLK SKELETON dosyasını yaz").
3. **Model değişikliği** — P2 için daha hızlı model (ör. glm-5.3-flash) dene.

**Öneri:** (1) — K1 fix ana hedefi karşıladı; tam E2E'de glm-5.3'ün üretebilirliği
kanıtlanmış (E2E-3). Pilot bütçesi gerçekçi değildi, watchdog artık kill yapmıyor.

## 6. Karar: (1) tam E2E — üç hazırlıkla (kullanıcı onayı)

Kullanıcı seçimi: **(1) tam E2E'ye geç**. Gerekçe: K1 27dk kill-yok ile doğrulandı;
A2' 3. call=write ile tuttu; (2)/(3) için veri yok; K7 asimetri ihlali olurdu.

Üç hazırlık (Tur 2-3 öncesi, zorunlu):

1. **CPU kanalı kör noktası testi (no-write-cap):** busy-loop (CPU yakan ama dosya
   yazmayan) süresiz kill'siz kalırdı — CPU kanalı idle'ı sıfırlarken no-write
   sayacını da atlıyordu (`continue` bug'ı). Düzeltme: iki kademeli kill —
   `idle_max` (üç kanal sessiz) + `no_write_cap` (NO_WRITE_CAP env, default 7200s;
   dosya yoksa CPU/stream aktif olsa bile kill). self-test senaryo 30A/30B.
2. **Gerçekçi kabul kriterleri (Tur 2-3):** att ≤ 3 · P2 süre < 8 saat ·
   P2 token < 12.23M (E2E-3 att2 bazı) · write > 0 · **L3 kill = 0** (K1 doğrulaması).
3. **Karşılaştırma baz notu:** E2E-3 (WRITE_RULE) → Tur2-3 arasında **ÜÇ değişken**
   (A1 + K1 CPU/no-write + A2') — izolasyon mümkün değil; sonuç yalnızca
   "sistem çalışıyor mu" sorusunu yanıtlar, "A2' tek başına işe yaradı mı" yanıtlamaz.

Tur 2-3 koşusu: tam E2E (P1→P2→P3→P5), intent 2e4816… (bazlarla birebir),
kill → otomatik retry, koşu sırasında dosya değişikliği yok.
