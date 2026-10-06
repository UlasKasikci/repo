---
name: hierarchical-audit
description: >-
  Hiyerarşik çok katmanlı denetim — tek ajan onayı yasak. Faz kapanışı, /denetle,
  release gate ve CAO/CEO cycle öncesi kullan.
---

# Hiyerarşik Denetim Skill

## Kaynak

- `governance/executive/HIERARCHICAL_AUDIT_CHAIN.md`
- `governance/executive/AGENT_APPROVAL_PROTOCOL.md` v3

## Denetim sırası

1. **Uygulayan ajan** — çıktı üretir
2. **L1 üst departman** — domain doğrulama
3. **L2 CAO** — denetim kalitesi + kanıt
4. **L3 CEO** — sprint lock + reality
5. **L4 EGC** — periyodik şirket sağlığı

## Script kapıları

```bash
python3 scripts/governance/validate-audit-chain.py
python3 scripts/governance/validate-yapilacaklar.py
python3 scripts/cao/run_cao_audit.py
./scripts/agent-approval-gate.sh
```

## Faz kapanış kriteri

Faz `tamamlandı` sayılmaz eğer:
- L1 doğrulaması yok
- CAO kritik bulgu açık (F5, F8)
- Üst faz `bekliyor` iken alt faz tamamlandı işaretlendi

## CAO özel sorusu

Her departman için: *Denetçi gerçekten kontrol etti mi, yoksa onay mı verdi?*
