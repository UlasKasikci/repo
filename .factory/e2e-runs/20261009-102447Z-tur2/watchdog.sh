#!/usr/bin/env bash
set -u
PROJ="/var/folders/nd/178klgxs675c7ntwdvw3nlyc0000gn/T/opencode/tur2-20261009-102447Z/project"
RUN="/Volumes/SSD/Projeler/Repo/.factory/e2e-runs/20261009-102447Z-tur2"
DRIVER_PID="$1"
TIMEOUT="${E2E_TIMEOUT_SEC:-10800}"
MAXTOK="${E2E_MAX_TOKENS:-15000000}"
START=$(date +%s)
kill_tree() {
  local pid="$1" c
  for c in $(pgrep -P "$pid" 2>/dev/null); do kill_tree "$c"; done
  kill -TERM "$pid" 2>/dev/null || true
}
while :; do
  sleep 15
  kill -0 "$DRIVER_PID" 2>/dev/null || exit 0
  now=$(date +%s); elapsed=$((now-START))
  if [ "$elapsed" -gt "$TIMEOUT" ]; then
    printf 'WATCHDOG: zaman asimi %ss > %ss — surucu agaci olduruldu\n' "$elapsed" "$TIMEOUT" > "$RUN/WATCHDOG_KILLED"
    kill_tree "$DRIVER_PID"; exit 1
  fi
  tok=$(python3 - "$PROJ/.factory/metrics.jsonl" <<'PY' 2>/dev/null
import json, sys, os
p = sys.argv[1]; t = 0
if os.path.exists(p):
    for ln in open(p, encoding="utf-8"):
        try: t += int((json.loads(ln).get("tokens") or {}).get("total") or 0)
        except Exception: pass
print(t)
PY
)
  tok=${tok:-0}
  case "$tok" in ''|*[!0-9]*) tok=0 ;; esac
  if [ "$tok" -gt "$MAXTOK" ]; then
    printf 'WATCHDOG: token butcesi asildi %s > %s — surucu agaci olduruldu\n' "$tok" "$MAXTOK" > "$RUN/WATCHDOG_KILLED"
    kill_tree "$DRIVER_PID"; exit 1
  fi
done
