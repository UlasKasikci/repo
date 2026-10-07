#!/usr/bin/env bash
# E2E driver — orchestrate --auto deneme döngüsü (saat tatbikati, CI DIŞI)
set -u
PROJ="/var/folders/nd/178klgxs675c7ntwdvw3nlyc0000gn/T/opencode/e2e-20261007-010339Z/project"
RUN="/Volumes/SSD/Projeler/Repo/.factory/e2e-runs/20261007-010339Z"
REPO="/Volumes/SSD/Projeler/Repo"
LOG="$RUN/orchestrate.log"
MAX_ATTEMPTS=6
attempt=0; rc=0
while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
  attempt=$((attempt+1))
  printf '######## attempt %s · %s ########\n' "$attempt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  rc=0
  bash "$REPO/scripts/web/orchestrate.sh" "$PROJ" --auto >> "$LOG" 2>&1 || rc=$?
  printf '---- attempt %s rc=%s · %s\n' "$attempt" "$rc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  [ "$rc" -eq 0 ] && break   # DONE
  [ "$rc" -eq 2 ] && break   # HALT
done
printf 'DRIVER_DONE rc=%s attempts=%s\n' "$rc" "$attempt" >> "$LOG"
printf '%s\n' "$rc" > "$RUN/driver.rc"
