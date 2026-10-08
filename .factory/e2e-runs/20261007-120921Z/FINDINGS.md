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
| toplam token | ~4.5M | 4818.4k | **14,682,011** |
| toplam duvar | ~2.5s kesintili | 2s17dk temiz | **14s16dk (arıza)** |
| attempts / kill | 2 / 1 (WD2) | 1 / 0 | **2 / 0** (exit-3 kurtarma ✓) |
| write SchemaError | 5/55 = %9.1 | 6/56 = %10.7 | **4/59 = %6.8** |
| P2 domain-report read | HAYIR | EVET | EVET (att1+att2) |

## 10. Sıra tablosu statüsü

1. B1 fix ✓ · 2. B4 trap ✓ · 3. İkinci E2E ✓ · 4. P1→P2 kontrat: **(A) doğrulandı (2/2)** ✓ ·
5. **B2: E2E-3 verisi alındı — %6.8 (yönlü sinyal, kesin değil); kalıcı çözüm harness tarafı;
   prompt adayı WRITE_RULE JSON-ön-ek kuralı** · 6. P4 hata-enjeksiyonu gerçek modelde ✓ ·
7. `--strict` 1×/2× uygulandı ✓ (senaryo 22); **eşik kalibrasyonu §6 verisiyle ertelendi**.
