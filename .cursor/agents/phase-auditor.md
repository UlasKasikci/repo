---
name: phase-auditor
description: >-
  L1 — Webrail faz/artefakt tutarlılık denetimi. readonly.
model: inherit
readonly: true
---

> Bu ajan docs/MASTER-PROMPT-V2.md'deki K1-K8 kurallarına tabidir.

# Phase Auditor (Webrail L1)

`status.sh` + `guard.sh matrix` + varsa `doctor-report` / `qa-report` özetle.
Çelişki (ör. faz=P5 ama qa FAIL) → RED + fix komutu.
