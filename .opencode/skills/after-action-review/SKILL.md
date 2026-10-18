---
name: after-action-review
description: >-
  /cevap — Webrail oturum özeti (DIAGNOSTIC). YAPILACAKLAR yok; P1–P5 + doctor.
category: review
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: ANY
version: "2.0.0"
---

# After Action Review (Webrail)

**Durum:** READY · **Kapı:** dosya değiştirmez

## Process

1. `RUN-STATUS.md` + `PHASE-LOG.md` + son `qa-report` / `doctor-report`
2. Ne yapıldı / ne kaldı / token notu (module-apply tasarrufu)
3. Sonraki IDE için 3 satır handoff (`docs/IDE-HANDOFF.md` formatı)

Android AAR alanları yok.
