# /web-faz — State Graph + status panosu

Salt okunur. Hedef: `$ARGUMENTS` (boşsa `.`).

```bash
bash scripts/web/status.sh $ARGUMENTS
bash scripts/web/state.sh status $ARGUMENTS
bash scripts/web/guard.sh matrix $ARGUMENTS
```

QA FAIL ise:

```bash
bash scripts/web/doctor.sh $ARGUMENTS --loop
```

Kanıt: `qa-report.json`, `doctor-report.json`, `debug_report.json`, `packaging-report.json`.
