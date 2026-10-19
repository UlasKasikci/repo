# AGENT-CONTRACT — faz başına görev / kanıt / teslim

> Kopyala → proje kökü veya `.factory/AGENT-CONTRACT.md`.  
> Ajan iş bitince kanıtı yazar; L1 denetçi (`phase-verifier` / `denetle`) doğrular.  
> Tek ajan kendi işini onaylamaz.

**Proje:** _(ad)_  
**Güncelleme:** `phase-log.sh` + bu dosya checkbox

---

## P1 — web-domain-architect

| | |
|--|--|
| **Yazar** | `.factory/domain-report.json` · gap uyarıları → PLAN |
| **Yasak** | `core/` `views/` ürün kodu |
| **Kanıt** | şema PASS (`domain-check.py`) + `decide.sh` |
| **Teslim** | hallucination-guard → P2 |
| **Durum** | [ ] |

## P2 — web-core-engineer (+ frontend)

| | |
|--|--|
| **Yazar** | `index.php` · `core/` · `views/` · `SQL/` · module-apply çıktısı |
| **Yasak** | QA PASS iddiası; `Yukleme/` |
| **Kanıt** | `p2-checklist.sh` · scaffold_ok |
| **Teslim** | phase-verifier → P3 |
| **Durum** | [ ] |

## P3 — web-qa-gatekeeper (readonly)

| | |
|--|--|
| **Yazar** | yalnız `qa-report.json` (kod yazmaz) |
| **Kapı** | `qa-gate.sh` 0 Error / 0 Warning |
| **Kanıt** | `guard.sh claim-pass` |
| **Teslim** | PASS → P5 · FAIL → P4 + FIX-BRIEF |
| **Durum** | [ ] |

## P4 — web-core-engineer (revision)

| | |
|--|--|
| **Yazar** | yalnız `FIX-BRIEF.md` maddeleri |
| **Kanıt** | `doctor-report.json` · qa yeniden PASS |
| **Teslim** | phase-auditor → P3 |
| **Durum** | [ ] _(gerekirse)_ |

## P5 — web-deploy-packager

| | |
|--|--|
| **Yazar** | `Yukleme/` · `packaging-report.json` |
| **Önkoşul** | denetle blocker=0 · QA PASS |
| **Kanıt** | sha256 manifest · smoke |
| **Teslim** | DONE + FTP notu |
| **Durum** | [ ] |

---

## L1 zincir (zorunlu)

1. Üretim ajanı işi bitirir → PLAN / phase-log günceller  
2. `denetle.sh` veya `phase-verifier` kanıtı okur  
3. Uyuşmazlık → WARN/BLOCKER; PASS iddiası yok  

Otomatik tetik: `.factory/auto-hooks.json`
