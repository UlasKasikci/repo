#!/usr/bin/env bash
set -euo pipefail

# Webrail — tek ekran durum panosu
# Kullanım: bash scripts/web/status.sh [proje_dizini]
# Exit: 0

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "status: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

python3 - "$PROJECT" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
fac = p / ".factory"
mode = "factory (mode.json yok)"
mode_path = fac / "mode.json"
if mode_path.is_file():
    try:
        mode = json.loads(mode_path.read_text(encoding="utf-8")).get("mode") or "?"
    except Exception as e:
        mode = f"bozuk ({e})"

phase = retry = status = "—"
state_path = fac / "web-state.json"
if state_path.is_file():
    try:
        s = json.loads(state_path.read_text(encoding="utf-8"))
        phase = s.get("current_phase") or "—"
        retry = f"{s.get('retry_count', 0)}/{s.get('max_retries', 3)}"
        status = s.get("status") or "—"
    except Exception:
        phase = "bozuk"

qa = "—"
qa_path = p / "qa-report.json"
if not qa_path.is_file():
    qa_path = fac / "qa-report.json"
if qa_path.is_file():
    try:
        q = json.loads(qa_path.read_text(encoding="utf-8"))
        err = q.get("errors", q.get("error_count", "?"))
        warn = q.get("warnings", q.get("warning_count", "?"))
        res = q.get("result") or q.get("status") or "?"
        qa = f"{res} (E={err} W={warn})"
    except Exception:
        qa = "bozuk"

decision = "yok"
dec_path = fac / "decision.json"
if dec_path.is_file():
    try:
        d = json.loads(dec_path.read_text(encoding="utf-8"))
        mods = d.get("modules_to_apply") or []
        names = [m.get("module") for m in mods if isinstance(m, dict)]
        decision = d.get("result", "OK") + (f" · {','.join(names)}" if names else "")
    except Exception:
        decision = "bozuk"

disc = "var" if (p / "DISCOVERY.md").is_file() else "yok"

# Sonraki komut
if mode == "discovery":
    nxt = "bash scripts/web/mode.sh from-brief . \"<brief>\"   # veya /kesfet → promote"
elif phase in ("—", None) or not state_path.is_file():
    nxt = "bash scripts/web/state.sh start ."
elif phase == "P1":
    nxt = "/web-baslat → domain-report + bash scripts/web/decide.sh ."
elif phase == "P2":
    nxt = "P2_HUMAN_ASSIST=true … veya module-apply + state advance"
elif phase == "P3":
    nxt = "bash scripts/web/qa-gate.sh .   # /web-denetle · FAIL → doctor.sh --loop"
elif phase == "P4":
    nxt = "bash scripts/web/doctor.sh . --loop → FIX-BRIEF → qa-gate → state qa-pass/fail"
elif phase == "P5":
    nxt = "bash scripts/web/package-yukleme.sh .   # /web-yukle"
elif phase == "DONE":
    nxt = "/yama (küçük düzeltme) veya yeni brief"
else:
    nxt = "bash scripts/web/state.sh status ."

# QA FAIL ise doctor öner
if isinstance(qa, str) and qa.upper().startswith("FAIL"):
    nxt = "bash scripts/web/doctor.sh . --loop   # /doktor → sonra qa-gate"

# Son guard DENY (audit)
guard_last = "—"
glog = fac / "guard-log.jsonl"
if glog.is_file():
    try:
        lines = [ln for ln in glog.read_text(encoding="utf-8").splitlines() if ln.strip()]
        for ln in reversed(lines):
            g = json.loads(ln)
            if g.get("allow") is False and g.get("op") != "matrix":
                guard_last = f"DENY {g.get('op')}: {g.get('reason')} → {g.get('fix')}"
                break
    except Exception:
        guard_last = "bozuk"

doctor = "—"
dr = p / "doctor-report.json"
if not dr.is_file():
    dr = fac / "doctor-report.json"
if dr.is_file():
    try:
        d = json.loads(dr.read_text(encoding="utf-8"))
        rem = d.get("remaining_errors") or []
        doctor = f"{d.get('result', '?')} · kalan={len(rem)}"
        if (p / "FIX-BRIEF.md").is_file():
            doctor += " · FIX-BRIEF.md"
    except Exception:
        doctor = "bozuk"

print(f"==> Webrail status · {p.name}")
print(f"  mode     : {mode}")
print(f"  discovery: {disc}")
print(f"  phase    : {phase}  status={status}  retry={retry}")
print(f"  qa       : {qa}")
print(f"  decision : {decision}")
print(f"  doctor   : {doctor}")
print(f"  next     : {nxt}")
print(f"  guard    : {guard_last}")
print(f"  tip      : bash scripts/web/guard.sh matrix .   # işlem öncesi ALLOW/DENY")
PY
