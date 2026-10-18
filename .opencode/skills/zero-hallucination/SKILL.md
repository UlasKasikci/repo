---
name: zero-hallucination
description: >-
  Webrail kanıt protokolü — dosya/API uydurma yasak; RUN-STATUS ve .factory zorunlu.
category: think
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: ANY
version: "2.0.0"
---

# Zero Hallucination (Webrail)

**Durum:** READY · **Kapı:** `status.sh` · `guard.sh` · okuma kanıtı

## When to Use

Her IMPLEMENTATION oturumu başı; IDE el değiştirme; “tamamlandı” iddiası öncesi.

## Process

1. `bash scripts/web/status.sh .`
2. Oku: `RUN-STATUS.md`, `PHASE-LOG.md` (varsa), ilgili `.factory/*.json`
3. Referans vereceğin her path’i oku/grep et
4. QA/PASS → `qa-report.json` + `guard.sh claim-pass`
5. Eksik iş → `doctor.sh` veya ilgili faza dön

## Red Flags

- YAPILACAKLAR / Gradle / Compose / Android planı
- Okunmamış dosyaya atıf
- Sohbet hafızasına güvenerek devam

## Verification

`status.sh` ile faz uyumu; iddia edilen dosya diskte var.
