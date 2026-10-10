# FINDINGS — Tur 2-5d: Tam E2E (F4 + K1b-2 + F2 + A1) — FAIL (iskelet eksik, F5 sistematik)

**Tarih:** 2026-10-10 · **Kapsam:** P1→P5 tam akış, 3 attempt, 16M/10h budget.
**Başlangıç:** `e0179fd` · **Pilot artefaktları:** intent `2e481696ceeb` (bazlarla birebir),
domain-report (9 modül) pre-seeded → P1 artifact-gate anında PASS (LLM çağrısı yok).
**Sonuç: FAIL** — karar ağacı: **A2'' + F5 remedy turu**.

---

## 1. Koşu özeti (03:26:01Z → 04:35:09Z, ~35dk)

| Attempt | Süre | ev | out | reas (karakter) | Kill | Nerede asıldı |
|---------|------|----|-----|-----------------|------|---------------|
| 1 | 461s | 1 | 0 | 0 | zero-prod | turn açılışında saf asılı (F3 saf hali) |
| 2 | 830s | 4 | 54 | 8839 | zero-prod | ilk reasoning + read/bash sonrası, **write öncesi** |
| 3 | 738s | 5 | 145 | 4390 | zero-prod | "P2'ye başlıyorum…" text + bash sonrası, **write dalgası öncesi** |

`DRIVER_DONE rc=143 attempts=3 watchdog_kills=3` · kill markerları: **3/3 `zero-prod`** ·
CPU bandı kill anında **%7.8-13.4** (K1b strict'in üstü, K1b-2'nin altı — katmanlama doğru).
Toplam token (metrics): in=114, out=199, reas=13229 (char), cache_read=31616, **≈45k**.
Üretim dosyası: **0** (SQL/core/views/assets/index.php yok; yalnız plugin node_modules).
Bütçe aşılmadı · A1 QUESTIONS.json'a düşülmedi · orphan kill yok (budget hiç tetiklenmedi).

## 2. Kabul kriterleri

| Kriter | Sonuç |
|--------|-------|
| att ≤ 3 | 3 kullanıldı — tamamlandı MI? **FAIL** (P2 kapanmadı) |
| iskelet tam (index.php+views/+assets/+SQL/veritabani.sql) | **FAIL — 0 dosya** |
| L3 kill = 0 (gerçek) | **FAIL** — 3 gerçek asılma (hepsi DOĞRU kill; asılma sayısı sorunun kendisi) |
| write > 0 (sürekli) | **FAIL** — 0 write (out=199 yalnız text) |
| reasoning < 32000 (F4) | **PASS** — max ≈2k token; 32k imzası YOK (F4 düzeldi, kalıcı) |
| P2→P3 kapısı | **FAIL** — state: P2 in_progress |

## 3. F5 (NIM mid-turn hang) — dominant.failure mode

Şimdi **nicel**: 3/3 attempt aynı imza — turn açılıyor → kısa reasoning (0-2k token) →
stream komple susuyor, opencode CPU **%7-13** (busy-hang) → K1b-2 420s'de kesiyor.
Asılma konumu şans işi: 5c pilot'ta write'tan SONRA (turn 4), 5d'de write'dan ÖNCE
(turn 2-3) — **F5 stokastik ve sık**; tek seanslıktaki başarı/luck'a bağlı.

- K1b-2 kanalı **3/3 doğru kill** (false-kill yok; üretken olsaydı CPU >%25 veya üretim
  sinyali devam ederdi). Kanal işlevsel; sorun F5'in kendisi.
- K1b-strict kesmedi (CPU %7-13 > %0.55) — ağır-reasoning koruma refleksi doğru çalıştı.

## 4. Karşılaştırma tablosu

| Run | Tarih | Süre | att | write | ~token | gerçek kill | Dominant kök |
|-----|-------|------|-----|-------|--------|-------------|--------------|
| E2E-3 | 10-07 | uzun | ? | ? | **14.68M** | ? | H1 — 32k reasoning cap |
| Tur 2-3 | 10-09 | 5s02dk | 6/6 | **23** | ~M'ler | 0 | H1 (32k cap + A2' devamsızlık) |
| Tur 2-5b | 10-10 | 22dk (budget) | 1 | **1** (06_kvkk.sql) | 45k | 0 (budget TERM) | F3 busy-hang + 32k geri döndü |
| Tur 2-5c | 10-10 | 10.8dk | 1 | **1** (004_kvkk.sql) | ~21k | 1 zero-prod ✓ | F4 çözüldü; F5 yazdan sonra |
| **Tur 2-5d** | 10-10 | **35dk** | **3** | **0** | 45k | **3 zero-prod ✓** | **F5 sistematik (write öncesi)** |

Trend okuması: H1 (32k cap) KAPANDI (5c+5d kanıtı). F3/K1b-2 altyapısı KAPANDI
(kesme sırasında). Geriye kalan tek duvar: **F5 — NIM mid-turn stream stall**, stokastik
frekansta; write'a VARIP-VARMAMASI şans. Devamsızlık (A2'') ile birleşince her asılma
boşuna: attempt'ler birikim yapmıyor (session sıfır, dosya yok).

## 5. Karar: A2'' + F5 remedy turu (Tur 2-6 önerisi)

Brief karar ağacı: **FAIL (iskelet eksik) → A2'' + F5 remedy**. Önerilen paket:

1. **A2'' — sürdür ve bitir (devam stratejisi):** zero-prod/kill sonrası orchestrate
   fresh session yerine **devam prompt'u** ile yeniden tetikler: "Önceki denemede
   <son dosya listesi> yazıldı/yazılmadı; KALDIĞIN YERDEN UYGULA — ilk iş write".
   Böylece hang'den önce üretilen (reasoning planı, yazılmış dosyalar) birikir; her
   attempt sıfırdan başlamaz. driver retry döngüsüne `--continue` deseni.
2. **F5 remedy seçenekleri (sıralı deneme):**
   a. `reasoning_effort` high→**medium** (uzun tek-turn reasoning stall olasılığını düşürür;
      5c/5d arası asılma konumu erkenyse effort ilişkili olabilir),
   b. `MODEL_P2` env ile **farklı model** denemesi (ör. kimi-k3) — A/B tek koşu,
   c. opencode stream heartbeat yoksa driver-side: kill sonrası **aynı projeyle**
      hemen yeniden koş (A2'' ile birlikte) — F5 stokastikse birikimli tekrar kazanır.
3. **Ölçüm:** A2'' devam prompt'u ile 3 attempt'te biriken write sayısı + "hang'den
   önce/sonra write" oranı; F5 başına kurtarma süresi.

## 6. Notlar

- P1 trend'i bu koşuda **atlandı** (domain-report pre-seeded) — P1 LLM süresi trend'i
  bozulmadı (önceki: 25.8 → 49.2 → 93 dk); tam E2E'de P1'i LLM'e koşturmak için
  domain-report'ları KOYMAMAK gerekir (farklı tur).
- Kısıtlara uyuldu: koşu sırasında dosya değişikliği YOK · A2'' eklenmedi · QA gate /
  state graph değişmedi · pilot dışı ek E2E yok.
- Artefaktlar: `/var/folders/.../T/opencode/tur2-5d-20261010T032341Z/` (launch, run,
  metrics.jsonl, .wd-kill.{1,2,3}).
