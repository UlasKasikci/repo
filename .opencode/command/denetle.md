# /denetle — Webrail audit (auto-invoked by orchestrate)

```bash
bash scripts/web/denetle.sh $ARGUMENTS
bash scripts/web/denetle.sh $ARGUMENTS --strict   # + qa-gate
```

Reads PLAN/DISCOVERY + SQL/views; writes `gap-report.json` + `DENETIM.md`.
Blockers must be resolved before packaging.
