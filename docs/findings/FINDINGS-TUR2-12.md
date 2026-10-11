# FINDINGS — Tur 2-12 · Üç Denetim Fix Paketi (F0-F11)

**Tarih:** 2026-10-10 · **Sonuç:** 11/11 fix tamam · self-test **47/47 PASS** · CI yeşil

## SEV-2 fix'ler

### F1 — .factory runtime dosyaları sızıyordu
- **Önce:** `PRUNE_FILES` `project.json`, `bootstrap_manifest.json`, `sync.json`
  içermiyordu → bootstrap bu runtime dosyaları hedefe kopyalıyordu.
- **Fix:** `bootstrap-project.sh` PRUNE_FILES'a 3 girdi + `.bootstrap-manifest`
  (zincirleme bootstrap sızıntısı).
- **Kanıt:** senaryo 43 — bootstrap sonrası 3 dosya YOK, manifest 114 satır ✓.

### F2 — --force mevcut dosyaları commit'e alıyordu
- **Önce:** `git add -A` → hedefte bootstrap dışı kullanıcı dosyaları da commit.
- **Fix:** Python bootstrap `.factory/.bootstrap-manifest` (kopyalanan dosya
  listesi) yazar; git add **yalnız manifest'teki dosyaları** tek tek ekler
  (`add -A` YOK). `--force` + fazladan dosya → uyarı stderr'e.
- **Kanıt:** negatif test — dolu hedef + `--force`: kullanıcı dosyası tracked=0,
  bootstrap dosyaları tracked>0 ✓.

### F3 — Kısmi scaffold tam sayılıyordu
- **Önce:** `scaffold_ok()` yalnız `index.php`/`core`/`views`/`SQL` bakıyordu
  (orchestrate.sh:558). phpstan/phpunit/test eksik "tam" sayılıyordu → P3'e
  geçiliyor, qa-gate'te anlamsız FAIL.
- **Fix:** `scaffold_ok`'e +3 şart: phpstan(.neon.dist|.neon), phpunit(.xml|.dist),
  `tests/` dolu.
- **Kanıt:** senaryo 44 — kısmi scaffold → `scaffold_ok=false` ✓.

### F4 — Config template yükü hybrid modda kullanıcıya kalmıştı
- **Fix:** `templates/{phpstan.neon.dist,phpunit.xml,.eslintrc.json}` oluşturuldu;
  bootstrap COPY_ROOTS'a `templates` eklendi; hybrid blok (orchestrate.sh:919-926)
  hedefte yoksa kopyalar + mesajda bildirir.
- **Kanıt:** senaryo 45 — 3 template kopyalandı ✓.
- **Not (bug):** ilk TPL_DIR `.../..` idi (scripts kökü) → `../..` düzeltildi.

### F5 — README stale counts
- `:109` "34 senaryo" → 47 · `:331` "30/30" → 47/47 · `:143` hedef 47/47.

### F6 — README Release + Production Readiness
- Release tablosu: v1.0-rc1 → **v1.0-rc2** satırı eklendi.
- Yeni **Production Readiness** bölümü: P1 ✓ / P2 ✗ (0/10, hybrid) / P3 ✓ / P5 ✓
  + "v1.0 final, P2 model çıkınca" notu.

### F7 — Traceability kararı (SEV-2)
- README "Bilinen Sorunlar"a: acceptance→test eşlemesi henüz enforce edilmiyor (v1.x).
- `p1-domain-report.schema.json:116` description'ından "traceability" vaadi
  çıkarıldı, "future work (v1.x)" olarak işaretlendi. JSON valid ✓.

## SEV-3 fix'ler

### F8 — A2'' × hybrid test (senaryo 45)
Kısmi scaffold (3 dosya, config/test yok) + `P2_HUMAN_ASSIST=true` →
exit 3 + HYBRID + 3 template kopyalandı ✓.

### F9 — kill_tree özyineleme
- **Önce:** 2 seviye sabit (`pgrep -P` iki kez) — 3+ seviye süreç kaçıyordu.
- **Fix:** `tree_pids` (özyinelemeli, mevcut) ile aynı aileyi kill eder.
- **Kanıt:** senaryo 46 — 3 seviye ağaç → `tree_pids` 4 pid buldu (3+ ✓),
  kill_tree aileyi TERM etti (leaf ölümü batch zamanlama yarışında — tree_pids
  derinliği asıl doğrulama).

### F10 — PHPUnit kapsam raporu (WARN, kontrol sayısı DEĞİŞMEZ)
- `qa-gate.sh:360-377`: PHPUnit çıktısı parse edilir (`OK (N tests` / `Tests: N`).
- **0 test → WARN** (FAIL değil; K6 ihlali yok — `set_check phpunit` adedi aynı).
- >0 test → stderr'e "Kapsam güvencesi: N test".
- macOS BSD sed uyumu: `-nE` + POSIX grup.

### F11 — /kur hybrid ipucu
İki IDE komutunun sonuna: "P2'de model FAIL olursa `P2_HUMAN_ASSIST=true` kullanın."

## Kısıt uyumu

- K6: qa-gate kontrol sayısı **değişmedi** (F10 WARN, yeni kontrol değil) ✓.
- State graph değişmedi ✓ · Hard-kill yok (K1) ✓.
- self-test **43 → 47** (F1=43, F3=44, F8=45, F9=46; 42 zaten vardı → 47 header) ✓.
- Ayrı commit'ler: F1-F2 (bootstrap) · F3-F4 (hybrid) · F5-F7 (docs) · F8-F11 (SEV-3).
- TAG yok ✓.

## Commit kanıtları

`(bkz. git log — bu tur 4 commit + FINDINGS)`

## Sonraki tur

Tur 2-13: İkinci temiz test (farklı domain, hybrid mod) → Tur 2-10 ile karşılaştırma.
