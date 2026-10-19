#!/usr/bin/env bash
set -euo pipefail

# Webrail — merkezi denetim (kullanıcı /denetle unutsa bile orchestrate çağırır)
# Kullanım:
#   bash scripts/web/denetle.sh <proje>           # soft: gap + status + doctor teşhis
#   bash scripts/web/denetle.sh <proje> --strict  # + qa-gate (kod varsa)
# Exit: 0 OK/uyarı · 1 blocker veya QA FAIL · 2 kullanım

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
shift || true
STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    *) echo "denetle: bilinmeyen: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$PROJECT" ]] || { echo "denetle: dizin yok" >&2; exit 2; }
PROJECT="$(cd "$PROJECT" && pwd)"

echo "==> denetle · $(basename "$PROJECT")"
bash "$ROOT/scripts/web/status.sh" "$PROJECT" || true
bash "$ROOT/scripts/web/gap-scan.sh" "$PROJECT"
# Kod varsa borç taraması (WARN; blocker üretmez — rapor birleşik bakış)
if [[ -f "$PROJECT/index.php" || -d "$PROJECT/core" ]]; then
  bash "$ROOT/scripts/web/debt-scan.sh" "$PROJECT" || true
fi
# PLAN varsa state ile senkron
if [[ -f "$PROJECT/PLAN.md" && -f "$PROJECT/.factory/web-state.json" ]]; then
  bash "$ROOT/scripts/web/plan-sync.sh" "$PROJECT" >/dev/null 2>&1 || true
fi

BLOCKERS=0
if [[ -f "$PROJECT/gap-report.json" ]]; then
  BLOCKERS="$(python3 -c "import json;print(json.load(open(r'''$PROJECT/gap-report.json''')).get('blocker_count') or 0)")"
fi

# Kod varsa doctor teşhis (apply yok)
if [[ -f "$PROJECT/index.php" || -d "$PROJECT/core" ]]; then
  if [[ ! -f "$PROJECT/qa-report.json" ]]; then
    bash "$ROOT/scripts/web/qa-gate.sh" "$PROJECT" >/dev/null 2>&1 || true
  fi
  bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" >/dev/null 2>&1 || true
  echo "    doctor teşhis: doctor-report.json / FIX-BRIEF.md"
fi

QA_RC=0
if [[ "$STRICT" -eq 1 && ( -f "$PROJECT/index.php" || -d "$PROJECT/core" ) ]]; then
  bash "$ROOT/scripts/web/qa-gate.sh" "$PROJECT" || QA_RC=$?
fi

# DENETIM.md özet (quoted heredoc — bash backtick/brace çakışmasın)
export _D_PROJECT="$PROJECT" _D_STRICT="$STRICT"
python3 - <<'PY'
import json, os
from pathlib import Path
from datetime import datetime, timezone
p = Path(os.environ["_D_PROJECT"])
strict = os.environ.get("_D_STRICT") == "1"
gap = {}
if (p / "gap-report.json").is_file():
    gap = json.loads((p / "gap-report.json").read_text(encoding="utf-8"))
lines = [
    "# DENETIM — Webrail otomatik denetim",
    "",
    f"UTC: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
    f"Strict: {'evet' if strict else 'hayır'}",
    "",
    "## Gap-scan",
    f"- blocker: {gap.get('blocker_count', 0)} · warn: {gap.get('warn_count', 0)}",
    "",
]
for f in gap.get("findings") or []:
    sev = f.get("severity")
    fid = f.get("id")
    title = f.get("title")
    detail = f.get("detail")
    lines.append(f"- **[{sev}]** `{fid}`: {title} — {detail}")
lines += [
    "",
    "## Sonraki",
    "",
    "- Blocker → PLAN.md / P1 domain-report'a ekle veya bilinçli istisna yaz",
    "- Warn → kullanıcıya sor; reddedilmezse enjekte et",
    "- Kod hataları → bash scripts/web/doctor.sh . --loop",
    "- Handoff → phase-log.sh",
    "",
]
(p / "DENETIM.md").write_text("\n".join(lines), encoding="utf-8")
print(f"    ozet: {p / 'DENETIM.md'}")
PY

bash "$ROOT/scripts/web/phase-log.sh" "$PROJECT" "denetle çalıştı (blocker=$BLOCKERS)" "uyarıları PLAN'a işle" "denetle" >/dev/null 2>&1 || true

if [[ "${BLOCKERS:-0}" -gt 0 ]]; then
  echo "==> denetle: BLOCKER var — P1/PLAN güncellemeden P5'e gitme" >&2
  exit 1
fi
[[ "$QA_RC" -eq 0 ]] || exit 1
echo "==> denetle: OK (blocker=0)"
exit 0
