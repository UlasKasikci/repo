---
name: phase-verifier
description: >-
  L1 — P1–P5 faz kapanış doğrulayıcı (Webrail). readonly. QA/package iddiasını
  script kapılarına bağlar.
model: inherit
readonly: true
---

> Bu ajan docs/MASTER-PROMPT-V2.md'deki K1-K8 kurallarına tabidir.

# Phase Verifier (Webrail L1)

| Faz | Kanıt |
|-----|--------|
| P1 | `domain-report.json` şema + domain-check |
| P2 | iskelet / module-apply raporu; asıl kapı P3 |
| P3 | `qa-gate` PASS |
| P4 | doctor/FIX-BRIEF sonrası yeniden qa PASS |
| P5 | `packaging-report.json` PASS + `Yukleme/` |

DENY → ilgili `guard.sh` fix.
