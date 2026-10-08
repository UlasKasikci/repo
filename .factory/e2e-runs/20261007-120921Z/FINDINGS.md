# E2E-3 SAHA TATBİKATI — `20261007-120921Z` (WRITE_RULE tek-hipotez testi + sağlayıcı-arızası dayanıklılık)

**Sonuç: `DRIVER_DONE rc=0 attempts=2`, `state=DONE`, `retry=0`, kill YOK, 15M tavanı tuttu**
12:19:35Z → 02:35:49Z (14s16dk — sağlayıcı arızası enflasyonu; temiz koşu ~2.5s sürerdi).
Senaryo RUN1/RUN2 ile **birebir aynı** (`project-intent.json` sha256 `2e481696…007` eşit).
Baz: commit `341b02a` (WRITE_RULE + `--strict` 1×/2× + exFAT fixture prune).

## 1. Kritik olay — sağlayıcı arızası ve kurtarma (B4 gerçek akışta)

- **Sağlayıcı hataları** (`opencode.log`): 18:49Z → ~02:16Z arası `ProviderHeaderTimeoutError:
  Provider response headers timed out after 300000ms` ≈14× + `AI_APICallError: Bad Gateway` 1×.
  Uzun sessizlikler (16–35 dk round-trip) tamamen sağlayıcı kaynaklı.
- **P2 attempt-1** (`ses_ee93e269effe…`): 4s34dk, 1.67M tok, 23 step, sağlayıcı çöküşü → **rc=1**
  → orchestrate exit 3 → `BEKLEME (exit 3): P2: web-core-engineer çalıştırılamadı` →
  driver **attempt-2** (19:00:41Z). `retry_count=0` **korundu** (tasarım gereği kurtarma ✓).
- **Watchdog devirleri** (`pids`, gerekçe: sağlayıcı arızası + tavan sığmaması):
  `10800s/9M → 14400 → 21600 → 36000 → 43200s/12M → 43200s/15M` (son pid 7445).
- **15M kararı belirleyici:** toplam **14,682,011 tok** — 12M tavanı kalsaydı P2-att2 satırı
  yazar yazılmaz kill (12.23M tek satır).
- `STRICT bütçe`/`SERT AŞIM` izi: **0** (driver `--strict` çalıştırmadı; §6 kalibrasyon notu).

## 2. metrics.jsonl (B4 — provider crash satırı dahil, 3 satır)

| phase/agent | rc | token | step | latency | session |
|---|---|---|---|---|---|
| P1 web-domain-architect | 0 | 780,586 | 19 | 2s06dk | `ses_ee9b1f04…` |
| P2 web-core-engineer (att1) | **1** | 1,668,494 | 23 | 4s34dk | `ses_ee93e269…` |
| P2 web-core-engineer (att2) | 0 | **12,232,931** | 113 | 7s31dk | `ses_ee842ba3…` |
| **TOPLAM** | | **14,682,011** | 155 | 14s16dk | |

B4 kanıtı: rc=13/143 benzeri anormal bitişlerde dahi satır **sonuçlandı ve yazıldı**
(önceki P4 mini'de 600s kill → rc=143 satırı; burada sağlayıcı çöküşü → rc=1 satırı).
Anormallikler metrics satırını değiştirmez; sağlayıcı hatası model çıktısı değil transport.

## 3. B2 — WRITE_RULE write SchemaError oranı (ana hipotez)

| tur | write hata/çalışma | oran | not |
|---|---|---|---|
| E2E-1 | 5/55 | %9.1 | P1 2/2 + P2 3/53 |
| E2E-2 | 6/56 | %10.7 | P1 2/2 + P2 4/54 — **FINDINGS2'deki "5" yanlıştı (P1=2)** |
| **E2E-3 (WRITE_RULE)** | **4/59** | **%6.8** | P1 1/1 + P2-att1 0/18 + P2-att2 3/40 |

- **Hepsi aynı harness sınıfı:** content `{` ile başlayınca opencode JSON objesi parse edip
  `SchemaError: Expected string, got {"schema_version"…}` üretir — **prompt kuralı bu parse'ı
  engelleyemez**; WRITE_RULE kurtarmayı hızlandırıyor (aynı step'te newline → bash heredoc;
  P1'de `python3 json.dump` fallback). E2E-1/2'deki "çift hata + kaçış" deseni görülmedi.
- **Sonuç: yönlü/olumlu sinyal (%9-11 → %6.8, ~%30-36 göreli düşüş) ama n=4 hata ile
  kesin değil.** Kök neden = harness davranışı → kalıcı çözüm harness/değil prompt'ta.
- **Aday iyileştirme:** WRITE_RULE'e "JSON dosyalarında content'e başa `\n` koy; kabul
  edilmezse bash heredoc ile yaz" ekleme (tüm write JSON şablonlarında baştaki `{` tetikliyor).
- Yan sınıf (B2 dışı): **edit 10/40 = %25** (hepsi att2): "No changes to apply" (entity-escape
  thrash) + filePath eksik SchemaError — ayrı hipotez, ayrıca izlenecek.

## 4. P1→P2 handoff okuma disiplini (mekanizma (A))

| tur | P2 domain-report okudu mu? |
|---|---|
| E2E-1 (kontrat satırı YOK) | **HAYIR** (keşifle buldu, sonra) |
| E2E-2 (kontrat satırı VAR) | **EVET** |
| E2E-3 (kontrat satırı VAR) | **EVET — att1 ve att2 ikisi de ilk read = `domain-report.json`** |

3/3 oturum `domain-report.json` okudu (P1 kendi çıktısını verify'de okuyor).
**Kontrat satırı 2/2 run'da çalıştı** → mekanizma (A) doğrulandı; (B) inline kararı gerekmedi.

## 5. Kabul kriterleri (RUN3)

| Kriter | Sonuç |
|---|---|
| qa-gate (P3) | **PASS 0/0** (report `qa-report.json`) |
| packaging | **PASS** — `Yukleme/` 42 dosya, `yukleme-tree.txt` §14 uyumlu |
| smoke | `smoke-report.factory.json` PASS |
| state | `start→advance→advance→qa-pass→advance` = DONE, retry=0 |
| intent eşitliği | sha256 `2e481696…007` — RUN1/RUN2 ile birebir |
| driver/watchdog | driver 26826 → `DRIVER_DONE rc=0 attempts=2`; WD normal çıkış (driver ölümünde WD ölür) |
| contamination | `project-snapshot` (71 dosya, 21MB) — `.opencode`/`.cursor` hariç (dev tooling) |

## 6. `--strict` kalibrasyon verisi (n=3 zemin)

- **E2E-3 driver'ı `--strict` çalıştırmadı** (RUN2'den sed'lenen driver bayraksız) →
  strict burada koşulmadı; eşik davranışı `self-test.sh` senaryo 22'de (1× WARN exit 0 +
  2× SERT AŞIM exit 1) yeşil (commit `341b02a`).
- **Kalibrasyon uyarısı:** P2-att2 tek satırı **12,232,931 tok = 2× faz eşiğinin (12M) üzerinde**
  → bugün `--strict` olsaydı **SERT AŞIM** çıkardı. Sebep sağlayıcı-arızası enflasyonu
  (retry'lar + 4.5s/7.5s fazlar), koşan model kaçak değil. Aday revizyon: P2/P4 faz eşiği
  6M → 8M (2×=16M) veya arıza-durumunda wall-clock'a dayalı muafiyet — **n=4 beklenmeden
  dokunulmayacak** (2× katmanı tasarımı gereği "uyarıcı + sert" çift; ilk eşik ihlali veri).
- **Strict kalibrasyonu JEV routing sonrasına ertelendi. E2E-1 P2: 3.1M, E2E-3 P2: 12.23M —
  varyans 4×, threshold tek nokta değil dağılım gerektirir.** (Kapanış C, JEV Faz 1.1 —
  eşik bu turda DEĞİŞTİRİLMEDİ.)

## 7. P4 gerçek-model mini (tamamlandı — RUN3 dışı, `p4-mini/`)

- Kurgu: `eval($_GET["q"])` enjeksiyonu → P3 qa-gate **FAIL** → P4 revision → PASS.
- Sonuç: `state=DONE`, `retry=1`, history `…qa-fail→qa-pass→advance`, qa **PASS 0/0**,
  packaging PASS. **Agent enjeksiyonu bulup temizledi** (eval → htmlspecialchars akışı).
- metrics (2 satır): `P4 rc=143 16,125 tok 2 step` (**600s manuel timeout kill — kill-safe
  metrics gerçek akışta**) + `P4 rc=0 214,960 tok 20 step` (attempt-2, orchestrate `--auto --strict`).
- İlk deneme 600s'te rc=143 ile kesilmesine rağmen state bozulmadı; qa-fail retry sayacı
  hilesiz ilerledi. P1/P2 satırları yok — fixture hazırlığı manuel adımlardı.

## 8. Yeni bulgular / düzeltmeler

1. **bash `$()` + heredoc apostrof tuzağı (DÜZELTİ, `341b02a`):** `$( … <<'PY' … )` gövdesindeki
   `1'e` gibi kesme işaretleri `$()` lexeri tarafından kaçırılıp quote dengesini bozuyor →
   orchestrate syntax hatası. Çözüm: python gövdesi ayrı top-level `budget_lines()` fonksiyonu
   (comment içinde bile `'` yok). `bash -n` + self-test 22/22 + CI yeşil.
2. **FINDINGS2 düzeltmesi:** E2E-2 write SchemaError toplamı **6** (P1=2), "5" değil — §3 tablosu
   kesin oranları veriyor (DB'den `part` tablosu, salt-okunur).
3. **opencode runtime `.opencode/node_modules` üretimi (bootstrap hatası DEĞİL):** proje dizinine
   ilk çalıştırmadan ~3 sn sonra `node_modules` (61M, `effect` 46M) + `package.json` iniyor
   (mtime 12:19:40Z vs P1 başlangıç 12:19:37Z). Bootstrap dry-run **temiz** (83 dosya/256KB,
   prune'lar çalışıyor: `node_modules`/`package.json`/`.opencode/plans`). QA/packaging
   `.opencode`'ü zaten denylist'te — üretim etkisi yok; yalnızca yerel alan/boyut.
4. **`.factory/e2e-runs` bootstrap prune** (FINDINGS2 madde 4'teki aday): `PRUNE_REL_DIRS`
   içinde artık ✓ (`context`, `e2e-runs`, `yukleme-*`, `.cursor/{skills,snapshots}`, `.github`, `tests`).
5. **P4 prompt adayı:** gerçek P4 run'da agent `qa-gate.sh`'i proje cwd'den bulamadı
   ("sistemde mevcut değil") — kendi manuel kontrolleri + orchestrate gate'i ile kurtardı.
   `p4_prompt`'a mutlak yol/`bash scripts/web/qa-gate.sh .` açıklığı eklenebilir.

## 9. Metrik karşılaştırması (n=3)

| | E2E-1 | E2E-2 | E2E-3 |
|---|---|---|---|
| P1 token / süre | 412.5k / 25dk | 623.8k / 24.6dk | 780.6k / 2s06dk |
| P2 token / süre | ≥3.1M (WD kill) | 4194.6k / 112.5dk | 1.67M+12.23M / 12s05dk (att1 çöküş + att2) |
| toplam token | ~3.5M (P2 satırı WD kill ile kayıp: P1 412.5k + P2 ≥3.1M oturum verisi) | 4818.4k | **14,682,011** |
| toplam duvar | ~2.5s kesintili | 2s17dk temiz | **14s16dk (arıza)** |
| attempts / kill | 2 / 1 (WD2) | 1 / 0 | **2 / 0** (exit-3 kurtarma ✓) |
| write SchemaError | 5/55 = %9.1 | 6/56 = %10.7 | **4/59 = %6.8** |
| P2 domain-report read | HAYIR | EVET | EVET (att1+att2) |

## 10. Sıra tablosu statüsü

1. B1 fix ✓ · 2. B4 trap ✓ · 3. İkinci E2E ✓ · 4. P1→P2 kontrat: **(A) doğrulandı (2/2)** ✓ ·
5. **B2: E2E-3 verisi alındı — %6.8 (yönlü sinyal, kesin değil); kalıcı çözüm harness tarafı;
   prompt adayı WRITE_RULE JSON-ön-ek kuralı → uygulandı (§11 ③-A), ölçüm Faz 1.2'de** ✓ ·
6. P4 hata-enjeksiyonu gerçek modelde ✓ ·
7. `--strict` 1×/2× uygulandı ✓ (senaryo 22); **eşik kalibrasyonu §6'daki notla ertelendi
   (JEV routing sonrasına — eşik DEĞİŞMEDİ)** ✓.

## 11. JEV Faz 1.1 — Model Katmanlama + 3 küçük kapanış (aynı commit)

① **Routing (`--model`):** `run_agent` içinde `MODEL_MAP` + `resolve_model()` —
P1 `nvidia/z-ai/glm-5.3-flash` (en ucuz yetenekli), P2/P4 `nvidia/z-ai/glm-5.3` (güçlü),
diğer fazlar mevcut opencode varsayılanı (dokunma). Env override: `MODEL_P1`/`MODEL_P2`/
`MODEL_P4`. claude-* bu ortamda yok (`opencode auth list` → 0 credential) → brief'in
"veya mevcut en ucuz yetenekli/en güçlü" yetkisiyle envanterden substitüte (docs §9);
claude eklenince env override yeterli. `--model` prompt'tan ÖNCE (self-test stub son
argümanı prompt sayar), boşta hiç verilmez. Log: `[model=…]`.

② **Metrics `model_used`:** append-only — mevcut alanlar korunur, `model_used` eklendi;
`parse_error` fallback satırında DA yazılır; kill-safe rc=143 satırı `CURRENT_MODEL` taşır.
Örnek satır (gerçek `record_agent_metrics` ile üretildi):
`{"ts":"…","phase":"P2","agent":"web-core-engineer","rc":0,"latency_ms":1500,"model_used":"nvidia/z-ai/glm-5.3","parse_error":false,…}`.

③ **Üç kapanış:**
- **(A) WRITE_RULE:** p1/p2/p4 prompt'larına JSON content **leading-newline** kuralı eklendi
  (ilk karakter `{` değil, JSON ikinci satırdan) — **recovery speedup, prevention değil;
  B2 harness-side, bkz. bu dosya §3** (yorum satırı `orchestrate.sh` WRITE_RULE üstünde).
- **(B) P4 qa-gate yolu:** `bash scripts/web/qa-gate.sh` → **mutlak**
  `bash $ROOT/scripts/web/qa-gate.sh .` (E2E-3 P4 mini'deki göreli-yol bulgusu §8 madde 5).
- **(C) Strict eşiği DEĞİŞTİRİLMEDİ** — erteleme notu §6'ya eklendi (varyans 4×, dağılım
  gerektirir; routing sonrası Faz 1.2 verisiyle yeniden değerlendirilecek).

**Doğrulama (bu turda E2E YOK — token ölçümü Faz 1.2):** `bash -n` OK · self-test **22/22
PASS** (yeni senaryo yok — ayrı tur) · metrics örnek satırı `model_used` görünür ·
`grep MODEL_MAP|--model|model_used` konumları raporlandı · docs §9 eklendi (Route→§10,
Referanslar→§11).

## 12. Faz 1.1 routing sonrası ölçüm — E2E-4 (`20261008-142253Z`, Faz 1.2)

**Tam tablo + 3 soru:** `.factory/e2e-runs/20261008-142253Z/COMPARISON.md` (bu bölüm özet).

- **Koşu:** `rc=0 attempts=1`, `DONE retry=0`, **2s18dk** (E2E-3: 14s16dk arıza), sağlayıcı
  arızası YOK, qa-fail 0 (P4 yine koşmadı), qa PASS 0/0 · intent sha birebir.
- **Token:** P1 780,586→**987,470** (+26.5%) · P2 12,232,931→**6,825,044** (**−44.2%**;
  crash-att1 dahil bazda −50.9%) · TOP 14,682,011→**7,812,514** (**−46.8%**).
  Brief'in P1=412k taslağı E2E-1'e ait — düzeltildi; E2E-3 modelleri `opencode.log`
  `modelID=z-ai/glm-5.3-flash` kanıtıyla dolduruldu (`model_used` yoktu, yönlü ölçüm).
- **Temiz kontrol (E2E-2, flash):** P2 4,194,591/55 adım → 6,825,044/74 adım = **+%62.7 /
  +%34.5 adım** — glm-5.3 flash'a göre daha çok harcıyor; P2 duvar süresi ise 112.5→69.5 dk.
  KARAR verisi iki参照 ile raporlandı (brief kriteri: −44% → yeşil ışık; kontrol: +63% →
  model seçimi gözden geçirme eşiği de tetikleniyor — karar kullanıcı/Faz 1.3, n=1).
- **S1 steps:** E2E-3'e göre 113→74 (−34.5% ✓) · E2E-2'ye göre 55→74 (arttı).
- **S2 QA FAIL:** 0 → 0 değişmedi (ilk geçişte PASS, her i turda).
- **S3 Write SchemaError:** **%6.8 → %4.0** (4/59→2/50); kırılım: P1 flash **2/2 hata**
  (leading-newline'a rağmen harness parse → **B2 prevention'sız teyidi**), P2 glm-5.3
  **0/48**; edit %25→%14.3. Handoff: P2 ilk read = domain-report (3/3).
- **Yeni alanlar canlı:** `model_used`, `cost_usd` (0.0 — models.dev explicit 0/0 ücretsiz
  NIM tier; `not_available` fallback parse_error satırında doğrulandı, uydurma rate yok),
  `input_tokens`/`output_tokens` (P2 cache_read 6.69M = bağlamın %98'i), `retry_count` (0/0).
- **Küçük bulgu:** driver.sh `printf '---- attempt…'` bash printf option-tuzzağı → rc satırı
  tüm run'larda eksik (kozmetik; `printf --` düzeltme adayı, ayrı tur).

## 13. Faz 1.3 A/B doğrulama — P2 flash vs glm-5.3 (`20261008-175827Z-ab1/ab2`)

**Tam tablo:** `.factory/e2e-runs/20261008-175827Z-ab1/COMPARISON-AB.md` (ab2'de kopya).

- **Protokol:** aynı commit `@fa2113d`, aynı intent, iki temiz bootstrap, **paralel**
  (aynı sağlayıcı penceresi), tek fark `MODEL_P2` env (ab1=flash, ab2=glm-5.3); P1/P4
  sabit (flash/glm-5.3). Sağlayıcı hatası 0. Watchdog cap 15M→30M simetrik yükseltildi
  (ab2 P4 riski; `PROTOCOL_NOTES`; hiçbir kol 15M'yi geçmedi).
- **Sonuç:** P2 toplam **flash 9,007,437/83 st** vs **glm-5.3 12,026,151/94 st**
  (**flash −25.1%**; TOP −28.3%) · P4: ab1 yok (qa-fail 0), ab2 841,234 (qa-fail 1,
  eslint+phpunit → düzeldi) · final ikisi de QA PASS 13/13 + pkg PASS · duvar:
  ab1 **5s30dk** vs ab2 **2s31dk** (glm-5.3 **2.2×** hızlı; P2 throughput 4.4×) ·
  cost_usd 0.0/0.0 · model_used alanları env geçişini doğruladı.
- **Varyans uyarısı (ana bulgu):** glm-5.3 P2 n=2 = [6.83M (E2E4), 12.03M] **1.76×**;
  flash n=2 = [4.19M (E2E2), 9.01M] **2.15×** → **run varyansı model etkisinden büyük**;
  ortalama flash −30% ama n=2 zayıf kanıt. Karar veri seti §4 (öneri: glm-5.3 kalsın —
  hız kesin, token ücretsiz tier'da ikincil, instabilite prompt/parallel tarafında).
- **Ortak konfördanç:** paralel koşuda **her iki kolun P2 att1'i de 0-write erken-döndü**
  (exit-3 → retry; token israfı ortak/küçük). E2E-4 tekil değildi → parallel ilk-deneme
  güvenilirliğini düşürüyor.
- **Yeni harness bulgusu (ab1 att2 rc=1, token'sız):** P2 agent'ı kendi oturumundan
  `state.sh advance` (P2→P3) çalıştırdı → orchestrate P2-branch `advance` geçersiz-faz
  rc=1 (`>/dev/null` stdout yuttu, `set -e` sessiz exit) → driver att3 yalnız qa+pkg
  (~13 sn) bitirdi. Düzeltme adayları (ayrı tur): advance'ı idempotent yap veya agent'a
  state-yazma yasağı prompt'ta.
- **B2/handoff:** P1 flash write SchemaError **7/7** (iki kol toplamı — deterministik);
  P2 att2: flash 3/61, glm-5.3 1/76 (glm-5.3 JSON yazımı daha temiz). Handoff: **4/4 P2
  oturumu domain-report'u ilk okudu**; P4 odakları uygun (qa-report/debug/HelpersTest).
- driver `printf --` düzeltmesi bu A/B'nin kendi driver'larına uygulandı (rc satırları
  artık log'da — E2E-4'teki kozmetik eksiklik kapandı).

## 14. Karar + Tur 1: ajan self-advance toleransı (advance guard)

**Model kararı (kullanıcı onayı):** **(a) glm-5.3 P2 varsayılanı KORUNDU** — hız (2.2×
duvar / 4.4× throughput) ve kalite (13/13; ek maliyet tek P4) birincil; token ücretsiz
NIM tier'da ikincil; A/B'deki "−25.1%" varyans (flash 2.15×, glm-5.3 1.76×) nedeniyle
sinyal sayılmadı. (c) "daha fazla A/B" olarak REDDEDİLDİ; **atık denetimi** (Tur 2) olarak
yeniden çerçevelendi — P2'nin ~12M token'ının att1/retry/input-context/output kırılımı
yeni koşusuz, mevcut loglardan.

**Tur 1 — kök neden (kanıt):** ab1 att2'de P2 agent'ı bash #39 ile `state.sh advance`
(P2→P3) çalıştırdı → orchestrate P2-branch `advance` geçersiz-faz `die("P3 → P5 yalnız
qa-pass ile")` (log satır 137, stderr) → rc=1 + `set -e` → orkestratör sessiz exit →
driver att3 (yalnız qa+pkg, token'sız ama tam bir attempt israfı). E2E-4'te P2 agent'ı
ilmeleri bu yola girmeden geçti — şans işi.

**Düzeltme (sınıf, satır değil):** `orchestrate.sh` → `state_phase()` helper + **P1/P2/P5
üç advance guard'ı**: yalnız hâlâ o fazdaysa `advance`, aksi halde ajanın koyduğu fazla
devam. `state.sh`'a dokunulmadı (hatalar zaten stderr'de).

**Regresyon kilidi:** self-test **adım 23** — davranışsal (stub: yan-etki `advance` +
iskelet üretimi; "P2 → P3 (code-complete)" basılır, "P3 → P5 yalnız" basılmaz, durak
P3'te kalır) + `state.sh` kanal kontratı (geçersiz advance → **rc=1, stdout boş, stderr
mesaj, state değişmez**). Self-test **23/23 PASS** (`bash -n` OK).

**Tur 2 sıradaki (atık denetimi):** E2E-3/E2E-4/ab1/ab2 metrik+loglarından P2 token
kategorizasyonu — tahmin: att1 erken-dönüş ~0.25-0.5M israf/tur, input-context ~%50+,
gerçek output ~%10; kaldıraç model seçiminde değil bağlam şişkinliğinde.
