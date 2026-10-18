---
name: error-doctor
description: >-
  Webrail Error Doctor — qa-gate FAIL sonrası hata tespiti, güvenli otomatik
  düzeltme ve token-ucuz FIX-BRIEF. P3/P4 ve /yama öncesi kullan; kör debug skill değil.
category: test
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: P3
version: "1.0.0"
---

# Error Doctor (Webrail)

**Durum:** READY · **Kapı:** `scripts/web/doctor.sh` + `qa-gate.sh` · **Audit:** `doctor-report.json`

## Overview

Kataloglardaki “debugging-methodology” metin skill’lerinden farkı: Webrail **kanıt
dosyasını** (`qa-report.json`) okur, tarif eşler, güvenli olanları **script ile
uygular**, kalanı tek sayfalık `FIX-BRIEF.md` yapar. LLM’e tüm raporu yapıştırmaz.

## When to Use

- `qa-gate` FAIL / `debug_report.json` oluştu
- P4 revision döngüsü
- `/yama` öncesi “ne kırık?” sorusu
- Token bütçesi dar — tam sohbet dump yasak

## Process

1. `bash scripts/web/guard.sh doctor .` — DENY ise fix yolunu izle.
2. `bash scripts/web/doctor.sh . --qa-first` — teşhis + brief.
3. Güvenli otomatik: `bash scripts/web/doctor.sh . --loop` (max 3; sql-dump, fixture, modül kopya).
4. Kalan için **yalnız** `FIX-BRIEF.md` satırlarını uygula (PDO/CSRF/XSS kuralları).
5. `bash scripts/web/qa-gate.sh .` — 0E/0W olmadan PASS iddiası yok.
6. Kanıt: `doctor-report.json` + `qa-report.json`.

## Rationalizations (reddedilen bahaneler)

- “Önce tüm projeyi okuyayım” → hayır; allowlist + FIX-BRIEF.
- “qa-report’u modele yapıştırayım” → hayır; token israfı.
- “Safe apply atlayıp LLM yazsın” → hayır; önce `--loop`.

## Red Flags

- `mode=discovery` iken `--apply` / iskelet yazma
- PASS iddiası `doctor-report` okunmadan
- Fabrika remote’una push ile “düzeltme” (git-push DENY)

## Verification

```bash
bash scripts/web/doctor.sh . --loop
bash scripts/web/qa-gate.sh .
test -f doctor-report.json && test -f FIX-BRIEF.md
bash scripts/web/guard.sh claim-pass .
```
