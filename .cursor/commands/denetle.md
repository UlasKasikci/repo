# /denetle — Hiyerarşik Denetim

Tek ajan onayı yasak. Skill: `hierarchical-audit`.

## Kapsam

Aktif faz veya son tamamlanan faz — kullanıcı belirtmezse aktif faz.

## Scriptler (sırayla)

```bash
python3 scripts/governance/validate-yapilacaklar.py
python3 scripts/governance/validate-audit-chain.py
python3 scripts/execution/validate_roadmap_consumption.py
./scripts/gradle-build-loop.sh 2>/dev/null || true
./scripts/run-maestro.sh 2>/dev/null || true
python3 scripts/cao/run_cao_audit.py 2>/dev/null || true
./scripts/agent-approval-gate.sh 2>/dev/null || true
```

## Subagent

`@phase-auditor` — L1+L2 bulgu raporu (readonly).

## Rapor formatı

| Katman | Departman | Sonuç | Bulgu |
|--------|-----------|-------|-------|
| L1 | ... | PASS/FAIL | ... |
| L2 CAO | ... | ... | ... |

**CEO sorusu:** Hangi departman doğru çalıştı? Hangi denetim zayıf?

Faz `tamamlandı` işareti ancak L1+L2 PASS ise önerilir.
