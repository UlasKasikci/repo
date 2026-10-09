#!/usr/bin/env bash
set -u
TARGET="$1"; RUNDIR="$2"; PROJ="$3"
T0=$(date +%s)
while kill -0 "$TARGET" 2>/dev/null; do
  sleep 10
  NOW=$(date +%s); ELAPSED=$((NOW-T0))
  TOKENS=0
  if [[ -f "$PROJ/.factory/metrics.jsonl" ]]; then
    TOKENS=$(python3 -c "
import json,sys
t=0
for l in open('$PROJ/.factory/metrics.jsonl'):
    l=l.strip()
    if not l: continue
    try: t+=int((json.loads(l).get('tokens') or {}).get('total') or 0)
    except: pass
print(t)
" 2>/dev/null || echo 0)
  fi
  if [[ "$ELAPSED" -ge 1800 ]]; then
    echo "PILOT-WATCHDOG: timeout ${ELAPSED}s ≥ 1800s — TERM" > "$RUNDIR/WATCHDOG_KILLED"
    kill -TERM "$TARGET" 2>/dev/null; exit 143
  fi
  if [[ "$TOKENS" -ge 500000 ]]; then
    echo "PILOT-WATCHDOG: token ${TOKENS} ≥ 500000 — TERM" > "$RUNDIR/WATCHDOG_KILLED"
    kill -TERM "$TARGET" 2>/dev/null; exit 143
  fi
done
exit 0
