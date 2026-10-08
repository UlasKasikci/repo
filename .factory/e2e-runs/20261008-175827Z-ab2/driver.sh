#!/usr/bin/env bash
# Faz 1.3 A/B driver — orchestrate --auto deneme döngüsü (CI dışı)
set -u
PROJ="/var/folders/nd/178klgxs675c7ntwdvw3nlyc0000gn/T/opencode/ab2-20261008-175827Z/project"
RUN="/Volumes/SSD/Projeler/Repo/.factory/e2e-runs/20261008-175827Z-ab2"
REPO="/Volumes/SSD/Projeler/Repo"
LOG="$RUN/orchestrate.log"
MAX_ATTEMPTS=6
attempt=0; rc=0
printf 'AB_ARM header: MODEL_P2=%s MODEL_P1=%s launched=%s\n' "${MODEL_P2:-default}" "${MODEL_P1:-default}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
  attempt=$((attempt+1))
  printf '######## attempt %s · %s ########\n' "$attempt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  rc=0
  bash "$REPO/scripts/web/orchestrate.sh" "$PROJ" --auto >> "$LOG" 2>&1 || rc=$?
  printf -- '---- attempt %s rc=%s · %s\n' "$attempt" "$rc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  [ "$rc" -eq 0 ] && break
  [ "$rc" -eq 2 ] && break
  [ "$rc" -eq 143 ] && break
  sleep 30
done
printf 'DRIVER_DONE rc=%s attempts=%s\n' "$rc" "$attempt" >> "$LOG"
printf '%s\n' "$rc" > "$RUN/driver.rc"
