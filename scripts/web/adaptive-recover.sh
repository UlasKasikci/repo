#!/usr/bin/env bash
set -euo pipefail

# Webrail Adaptive Recovery — sınıflandırılmış FAIL → strateji uygula (swarm değil)
# Kullanım: bash scripts/web/adaptive-recover.sh <proje>
# Önkoşul: failure-report.json (yoksa classify-fail çağırır)
# Exit: 0 strateji uygulandı/plan yazıldı · 1 halt_infra · 2 kullanım

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "adaptive-recover: dizin yok" >&2; exit 2; }
PROJECT="$(cd "$PROJECT" && pwd)"

if [[ ! -f "$PROJECT/failure-report.json" ]]; then
  bash "$ROOT/scripts/web/classify-fail.sh" "$PROJECT" || true
fi
[[ -f "$PROJECT/failure-report.json" ]] || { echo "adaptive-recover: failure-report yok" >&2; exit 1; }

export _AR_PROJECT="$PROJECT" _AR_ROOT="$ROOT"
eval "$(python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ["_AR_PROJECT"])
r = json.loads((p / "failure-report.json").read_text(encoding="utf-8"))
def sh(s):
    return "'" + str(s).replace("'", "'\"'\"'") + "'"
print(f"STRATEGY={sh(r.get('strategy') or 'fix_brief_p4')}")
print(f"REASON={sh(r.get('strategy_reason') or '')}")
print(f"SIG={sh(r.get('signature') or '')}")
print(f"CLASS={sh(r.get('primary_class') or '')}")
PY
)"

echo "==> adaptive-recover · $(basename "$PROJECT") · strategy=$STRATEGY · class=$CLASS · sig=$SIG"
echo "    $REASON"

FAC="$PROJECT/.factory"
mkdir -p "$FAC"
PLAN_OUT="$FAC/adaptive-plan.json"

python3 - <<PY
import json, os
from datetime import datetime, timezone
from pathlib import Path
fac = Path(os.environ["_AR_PROJECT"]) / ".factory"
doc = {
  "schema_version": 1,
  "tool": "adaptive-recover",
  "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "signature": os.environ.get("SIG") or "$SIG",
  "primary_class": os.environ.get("CLASS") or "$CLASS",
  "strategy": os.environ.get("STRATEGY") or "$STRATEGY",
  "strategy_reason": os.environ.get("REASON") or "",
  "actions_taken": [],
}
# bash exports below
PY
# rewrite plan with bash vars
python3 -c "
import json
from datetime import datetime, timezone
from pathlib import Path
fac = Path('$FAC')
doc = {
  'schema_version': 1,
  'tool': 'adaptive-recover',
  'at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
  'signature': '''$SIG''',
  'primary_class': '''$CLASS''',
  'strategy': '''$STRATEGY''',
  'strategy_reason': '''$REASON''',
  'actions_taken': [],
}
fac.mkdir(parents=True, exist_ok=True)
(fac / 'adaptive-plan.json').write_text(json.dumps(doc, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print('    plan:', fac / 'adaptive-plan.json')
"

append_action() {
  local act="$1"
  local detail="$2"
  ACT="$act" DETAIL="$detail" PLAN_OUT="$PLAN_OUT" python3 - <<'PY'
import json, os
from pathlib import Path
path = Path(os.environ["PLAN_OUT"])
doc = json.loads(path.read_text(encoding="utf-8"))
doc.setdefault("actions_taken", []).append({
    "action": os.environ["ACT"],
    "detail": os.environ["DETAIL"],
})
path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

case "$STRATEGY" in
  doctor_loop)
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --loop --qa-first || true
    append_action "doctor_loop" "doctor.sh --loop --qa-first"
    ;;
  fix_brief_p4)
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    append_action "fix_brief_p4" "FIX-BRIEF.md — P4 ajan; aynı yaklaşımı kopyalama"
    if [[ -f "$PROJECT/FIX-BRIEF.md" ]]; then
      cat >> "$PROJECT/FIX-BRIEF.md" <<EOF

## Adaptive Recovery
- signature: \`$SIG\` · class: \`$CLASS\`
- Strateji: FIX-BRIEF uygula; önceki denemeyle aynı yaklaşımı kopyalama
- reason: $REASON
EOF
    fi
    ;;
  module_apply)
    if [[ -f "$PROJECT/.factory/decision.json" ]]; then
      bash "$ROOT/scripts/web/module-apply.sh" "$PROJECT" || true
      append_action "module_apply" "module-apply.sh"
    else
      append_action "module_apply_skipped" "decision.json yok"
    fi
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    ;;
  expand_context)
    append_action "expand_context" "PLAN/gap/allowlist — kör kod tekrarı yok"
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    if [[ -f "$PROJECT/FIX-BRIEF.md" ]]; then
      cat >> "$PROJECT/FIX-BRIEF.md" <<EOF

## Adaptive: expand_context
- FAIL bağlam/gereksinim kaynaklı olabilir. Önce PLAN.md ve gap-report.
- signature=\`$SIG\`
EOF
    fi
    ;;
  alt_model)
    append_action "alt_model" "MODEL_P4/MODEL_P2 alternatif — orchestrate env"
    echo "WEBRAIL_HINT_ALT_MODEL=1" > "$FAC/adaptive-hint.env"
    echo "    ipucu: alternatif MODEL_P4 export edip P4 çalıştır"
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    ;;
  multi_candidate)
    if [[ "${WEBRAIL_MULTI_CANDIDATE:-0}" != "1" ]]; then
      echo "adaptive-recover: multi_candidate kapalı (WEBRAIL_MULTI_CANDIDATE=1)" >&2
      append_action "multi_candidate_denied" "env kapalı"
      exit 1
    fi
    append_action "multi_candidate" "2–3 aday; seçici=qa-gate (ajan self-approve yok)"
    mkdir -p "$FAC/candidates"
    echo "    .factory/candidates/ hazır"
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    ;;
  halt_infra)
    append_action "halt_infra" "altyapı — kod üretme"
    echo "adaptive-recover: HALT_INFRA — üretim durdurulmalı" >&2
    exit 1
    ;;
  *)
    echo "adaptive-recover: bilinmeyen strateji: $STRATEGY — fix_brief_p4 fallback" >&2
    bash "$ROOT/scripts/web/doctor.sh" "$PROJECT" --qa-first || true
    append_action "fallback" "$STRATEGY"
    ;;
esac

echo "==> adaptive-recover: strategy=$STRATEGY uygulandı"
exit 0
