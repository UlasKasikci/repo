# /doktor — Webrail Error Doctor

Target: `$ARGUMENTS` (default `.`).

1. `bash scripts/web/guard.sh doctor $ARGUMENTS`
2. `bash scripts/web/doctor.sh $ARGUMENTS --qa-first`
3. `bash scripts/web/doctor.sh $ARGUMENTS --loop` (safe recipes)
4. Apply only `FIX-BRIEF.md` leftovers — do not paste full `qa-report.json` into the model
5. `bash scripts/web/qa-gate.sh $ARGUMENTS` — must be 0E/0W

Evidence: `doctor-report.json` + `FIX-BRIEF.md`.
