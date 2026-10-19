#!/usr/bin/env bash
set -euo pipefail

# Webrail — PLAN.md ↔ web-state.json senkron (checkbox / durum satırı)
# Kullanım: bash scripts/web/plan-sync.sh <proje>
# Exit: 0 OK · 1 hata · 2 PLAN yok (yumuşak atla)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "plan-sync: dizin yok" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
PLAN="$PROJECT/PLAN.md"
STATE="$PROJECT/.factory/web-state.json"

[[ -f "$PLAN" ]] || { echo "plan-sync: PLAN.md yok — atlandı"; exit 2; }

export _PS_PLAN="$PLAN" _PS_STATE="$STATE" _PS_PROJECT="$PROJECT"
python3 - <<'PY'
import json, os, re
from pathlib import Path
from datetime import date

plan_p = Path(os.environ["_PS_PLAN"])
state_p = Path(os.environ["_PS_STATE"])
text = plan_p.read_text(encoding="utf-8")

phase, status, retry = "—", "—", 0
if state_p.is_file():
    try:
        s = json.loads(state_p.read_text(encoding="utf-8"))
        phase = s.get("current_phase") or "—"
        status = s.get("status") or "—"
        retry = int(s.get("retry_count") or 0)
    except Exception:
        pass

# Durum satırını güncelle
durum = {
    "P1": "işleniyor (domain)",
    "P2": "işleniyor (kod)",
    "P3": "işleniyor (QA)",
    "P4": "revision",
    "P5": "paketleniyor",
    "DONE": "tamam",
    "HALT": "HALT",
}.get(phase, "taslak")
if phase == "DONE":
    durum = "tamam"
line = f"**Durum:** {durum} · faz={phase} · status={status} · retry={retry} · sync={date.today().isoformat()}"
if re.search(r'\*\*Durum:\*\*.*', text):
    text = re.sub(r'\*\*Durum:\*\*.*', line, text, count=1)
else:
    text = line + "\n\n" + text

# Faz checkbox: tamamlanan fazları işaretle
order = ["P1", "P2", "P3", "P4", "P5", "DONE"]
idx = order.index(phase) if phase in order else -1
# DONE → hepsi; P3 → P1+P2 işaretli (P3 devam)
done_upto = idx if phase == "DONE" else max(0, idx)

def mark_section(src: str, header: str, checked: bool) -> str:
    # "## P1 — ..." altındaki ilk unchecked/checked satırları toplu değil;
    # başlık sonrası "- [ ]" → "- [x]" yalnız o bölümde, tamamlandıysa.
    parts = re.split(r'(?=^## )', src, flags=re.M)
    out = []
    for part in parts:
        if part.startswith(header):
            if checked:
                part = re.sub(r'^- \[ \] ', '- [x] ', part, flags=re.M)
            out.append(part)
        else:
            out.append(part)
    return "".join(out)

if idx >= 0:
    # P1 tamam = phase P2+; P2 tamam = P3+; P3 tamam = P5/DONE (qa pass sonrası)
    text = mark_section(text, "## P1 —", idx >= 1 or phase == "DONE")
    text = mark_section(text, "## P2 —", idx >= 2 or phase == "DONE")
    text = mark_section(text, "## P3 —", phase in ("P5", "DONE") or (phase == "P3" and status == "passed"))
    text = mark_section(text, "## P5 —", phase == "DONE")
    if phase == "DONE":
        text = mark_section(text, "## P4 —", True)

plan_p.write_text(text, encoding="utf-8")
print(f"plan-sync: {plan_p.name} ← faz={phase} status={status}")
PY

bash "$ROOT/scripts/web/phase-log.sh" "$PROJECT" "PLAN sync (faz=$(python3 -c "import json;print(json.load(open('$STATE')).get('current_phase','—'))" 2>/dev/null || echo —))" "—" "plan-sync" >/dev/null 2>&1 || true
exit 0
