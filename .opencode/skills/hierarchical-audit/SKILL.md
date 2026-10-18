---
name: hierarchical-audit
description: >-
  Webrail L1 zinciri — tek ajan kendi işini onaylamaz; phase-verifier + qa-gate.
category: review
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: ANY
version: "2.0.0"
---

# Hierarchical Audit (Webrail)

**Durum:** READY · **Kapı:** `qa-gate.sh` · L1 `phase-verifier` / `hallucination-guard`

## Process

1. Üretici ajan işi bitirir → kendi “PASS”i nihai değil
2. L1: `phase-verifier` veya `hallucination-guard` (readonly)
3. P3+: `bash scripts/web/qa-gate.sh .`
4. Paket: yalnız claim-pass ALLOW sonrası `package-yukleme.sh`

Android CAO/CEO zinciri yok — Webrail state graph yeter.
