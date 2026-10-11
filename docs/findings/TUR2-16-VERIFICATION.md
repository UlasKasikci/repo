# TUR 2-16 — Bağımsız Denetim Fix Paketi: Gerçek Ortam Doğrulaması

**Tarih:** 2026-10-11 · **Makine:** macOS (darwin, bash 3.2, zsh) · **Kapsam:** ChatGPT bağımsız denetimi 3 SEV-2 + 3 SEV-3
**Sonuç:** A–E tamam (5 commit) · F.1–F.4 gerçek çıktılar ↓ · self-test **63/63 PASS** · CI yeşil · **TAG YOK** (rc4 kalır)

## Commit zinciri (K7: aşama başına commit, her biri CI yeşil)

| # | Commit | Aşama | CI |
|---|--------|-------|----|
| c1 | `74e959b` | A: qa-gate CSRF/session gerçek doğrulama + negatif fixture | success |
| c2 | `fbb1c88` | B: bootstrap git bütünlüğü (iç/dis hedef, .git, staged) | success |
| c3 | `97bbcb6` | C+D: state advance P1 kapısı (domain-check) + `start --reset` yedeği | success |
| c4 | `45c3eee` | E: README tek kaynak 63/63 + `--reset` recovery notları | success |
| c5 | bu dosya | F: gerçek doğrulama raporu | — |

## F.1 — Bootstrap veri bütünlüğü (B.1/B.2) · 5/5 ✓

| Senaryo | Beklenen | Çıktı |
|---------|----------|-------|
| Hedef = fabrika kökü | rc=1 + "KENDİSİ" | `rc=1 \| fabrika deposunun KENDİSİ — duruldu` |
| Hedef fabrika içi | rc=1 + "İÇİNDE" | `rc=1 \| fabrika deposunun İÇİNDE` |
| Mevcut `.git` + `--yes` | rc=1 + "mevcut git deposu" | `rc=1 \| mevcut git deposu` |
| … + `--allow-existing-git` | rc=0 + commit=1 | `rc=0 · commit=1` |
| Stage edilmiş iş + override | rc=1 + dosya korunur | `rc=1 \| stage edilmiş değişiklikler · wip korundu: evet` |
| Boş hedef `--yes --force` | rc=0 + manifest tracked + özel dosya commit dışı/disk'te | `rc=0 · manifest tracked:1 · NOT commit'te:0 · NOT disk'te:evet` |

## F.2 — State graph invariant (C+D) · 9/9 ✓

| Adım | Beklenen | Çıktı |
|------|----------|-------|
| F2.1 advance, rapor yok | rc=1 + "kapı artefaktı yok" + state P1'de değişmez | `rc=1 · kapı artefaktı yok · durum: P1 in_progress 0` |
| F2.2 advance, bozuk rapor | rc=1 + "advance engellendi" + state değişmez | `rc=1 · advance engellendi · durum: P1 in_progress 0` |
| F2.3 advance, geçerli rapor | rc=0 + P1→P2 | `rc=0 · state: P1 → P2 · durum: P2 in_progress 0` |
| F2.4 mevcut state + reset'siz start | rc=1 + "--reset" ipucu + state korunur | `rc=1 · start --reset · durum: P1…(önceki faz)` |
| F2.5 `start --reset` | rc=0 + yedek + P1 retry=0 | `rc=0 · yedeklendi · yedek=1 · durum: P1 in_progress 0` |
| F2.6 halted advance | rc=2 + `--reset` mesajı | `rc=2 · start --reset` |
| F2.7 HALT → `--reset` kurtarma | rc=0 + P1 | `rc=0 · P1 başladı` |
| F2.8 `status --reset` | rc=1 + "yalnız start" | `rc=1 · yalnız start` |

## F.3 — self-test (tek kaynak: `^step "` sayacı; K5 badge = 63/63)

```
bash scripts/web/self-test.sh   →  rc=0 · 63 senaryo · SELF-TEST: PASS — tüm senaryolar yeşil
```

Yeni senaryolar: 51-52 (A: CSRF/oturum negatif), 53-56 (B: bootstrap bütünlüğü),
57-59 (C: advance kapısı), 60-62 (D: reset koruması + HALT kurtarma zinciri).
C/D taşkınlıkları: seed_domain_report helper (proje-bağımsız evidence — mp23/24/26
gibi SQL'siz köklerde fs doğrulaması geçer), 165/173/247 `--reset`, M28 seed,
senaryo 23 kill yarısı onarımı (`--reset` ile deterministik P3).

## F.4 — qa-gate güvenlik (A) · 3/3 ✓

| Fix | Beklenen | Çıktı |
|-----|----------|-------|
| `bad_csrf.php` (`$_POST`, doğrulama yok) | rc=1 + security_policy=FAIL + mesaj | `rc=1 · result=FAIL security_policy=FAIL · CSRF token doğrulama çağrısı yok: bad_csrf.php` |
| `bad_session.php` + `ini_set`-only | rc=1 + 2 hata | `eksik parametre (HttpOnly + Secure + SameSite zorunlu)` + `session_set_cookie_params() yok (ini_set yetersiz)` |
| Temiz fixture | rc=0 + PASS | `rc=0 · security_policy=PASS` |

## Sapma kaydı (bilinçli)

- **A.4 fixture yeri:** görev `tests/fixtures/web-sample/` içine yazıyordu; web-sample
  ~25 senaryonun ortak PASS fixture'ı olduğu için oraya eklemek hepsini kırardı.
  `tests/fixtures/bad_csrf.php` + `bad_session.php` **kardeş dosya** olarak eklendi.
- **Senaryo 23:** QA yarışı (qa-fail → P4) eski 0.5s poll ile yarışabilirdi; poll
  0.1s + faz dışıysa `--reset` ile deterministik P3 onarımı (guard sözü: advance
  çiftleri tam `[("P1","P2"),("P2","P3")]`).

## K1–K8

K1 hard-kill yok ✓ · K6 set_check 7→7 ✓ (yalnız security_policy içi güçlendirme) ·
K7 aşama başına commit ✓ · K8 silinmedi ✓ · Hybrid P2/asimetrik çekirdek/traceability
ertelenmesi tasarım kararı olarak **dokunulmadı** ✓ · Yeni TAG **yok** (rc4 kalır).
