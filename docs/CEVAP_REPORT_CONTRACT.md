# /cevap — After Action rapor kontratı

**Mod:** DIAGNOSTIC · dosya değiştirmez · faz ilerletmez · push yok  
**Skill:** `.cursor/skills/after-action-review/SKILL.md` · Komut: `/cevap`

## Zorunlu bölümler

```markdown
# CEVAP REVIEW REPORT

## Oturum
- Proje / faz / mode (status.sh)
- Kanıt dosyaları: RUN-STATUS.md · PHASE-LOG.md · qa-report / doctor-report (varsa)

## Yapılan
- 3–7 madde (yalnız diskte kanıtlanan)

## Kalan
- Blocker / WARN / FIX-BRIEF maddeleri

## Handoff (sonraki IDE)
1. …
2. …
3. …
```

## Yasak

- Android / YAPILACAKLAR / Gradle dili  
- Kanıtsız “PASS / bitti”  
- Remediation veya commit önerme (DIAGNOSTIC)

Kanon handoff: [`docs/IDE-HANDOFF.md`](IDE-HANDOFF.md)
