#!/usr/bin/env bash
set -euo pipefail

# Webrail — PHASE-LOG.md oturum kaydı (IDE handoff)
# Kullanım:
#   bash scripts/web/phase-log.sh <proje> "<yapılan>" ["<kalan>"] ["<ide>"]
# Exit: 0

PROJECT="${1:-.}"
DONE="${2:-}"
LEFT="${3:-}"
IDE="${4:-unknown}"

[[ -d "$PROJECT" ]] || { echo "phase-log: dizin yok: $PROJECT" >&2; exit 1; }
[[ -n "$DONE" ]] || { echo "kullanım: phase-log.sh <proje> \"<yapılan>\" [\"<kalan>\"] [\"<ide>\"]" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

LOG="$PROJECT/PHASE-LOG.md"
TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ ! -f "$LOG" ]]; then
  if [[ -f "$TPL_ROOT/docs/templates/PHASE-LOG.md" ]]; then
    cp "$TPL_ROOT/docs/templates/PHASE-LOG.md" "$LOG"
  else
    printf '# PHASE-LOG — oturum günlüğü (Webrail)\n\n## Kayıtlar\n\n' > "$LOG"
  fi
fi

PHASE="—"
ST="$PROJECT/.factory/web-state.json"
if [[ -f "$ST" ]]; then
  PHASE="$(python3 -c "import json;print(json.load(open('$ST')).get('current_phase') or '—')" 2>/dev/null || echo '—')"
fi
TS="$(date '+%Y-%m-%d %H:%M')"

{
  echo ""
  echo "### $TS · $IDE · faz=$PHASE"
  echo "- Yapılan: $DONE"
  [[ -n "$LEFT" ]] && echo "- Kalan: $LEFT"
  echo "- Kanıt: RUN-STATUS.md · .factory/web-state.json"
  echo "- Sonraki: bash scripts/web/status.sh ."
} >> "$LOG"

echo "phase-log: eklendi → $LOG (faz=$PHASE)"
# RUN-STATUS yenile (varsa)
if [[ -f "$TPL_ROOT/scripts/web/run-status.sh" ]]; then
  bash "$TPL_ROOT/scripts/web/run-status.sh" "$PROJECT" >/dev/null 2>&1 || true
fi
