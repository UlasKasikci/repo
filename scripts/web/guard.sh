#!/usr/bin/env bash
set -euo pipefail

# Webrail — merkezi işlem kapısı (yanlış işlem → RED + düzeltme yolu + audit log)
# Kullanım:
#   bash scripts/web/guard.sh <op> [proje]
#   bash scripts/web/guard.sh matrix [proje]
#
# Ops: write-code | promote | decide | advance | module-apply | qa | package | claim-pass | orchestrate
# Exit: 0 ALLOW · 1 DENY/hata
#
# Skill metni değil — deterministik denetim. Mevcut mode/state/qa kurallarını
# tek sorguda birleştirir; DENY satırları .factory/guard-log.jsonl'e yazılır.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OP="${1:-}"
PROJECT="${2:-.}"

usage() {
  echo "kullanım: guard.sh <write-code|promote|decide|advance|module-apply|qa|package|claim-pass|orchestrate|matrix> [proje]" >&2
  exit 1
}

[[ -n "$OP" ]] || usage
[[ -d "$PROJECT" ]] || { echo "guard: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
FAC="$PROJECT/.factory"
LOG="$FAC/guard-log.jsonl"
mkdir -p "$FAC"

export _G_PROJECT="$PROJECT" _G_OP="$OP" _G_LOG="$LOG"

python3 - <<'PY'
import json, os, sys
from datetime import datetime, timezone
from pathlib import Path

project = Path(os.environ["_G_PROJECT"])
op = os.environ["_G_OP"]
log_path = Path(os.environ["_G_LOG"])
fac = project / ".factory"

OPS = {
    "write-code", "promote", "decide", "advance", "module-apply",
    "qa", "package", "claim-pass", "orchestrate", "matrix",
}
if op not in OPS:
    print(f"guard: bilinmeyen op: {op}", file=sys.stderr)
    sys.exit(1)


def read_json(p: Path):
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def mode_of() -> str:
    m = read_json(fac / "mode.json")
    if m is None:
        return "factory"
    return str(m.get("mode") or "discovery")


def qa_pass() -> tuple[bool, str]:
    for cand in (project / "qa-report.json", fac / "qa-report.json"):
        q = read_json(cand)
        if not q:
            continue
        err = q.get("error_count", q.get("errors"))
        warn = q.get("warning_count", q.get("warnings"))
        if isinstance(err, list):
            err = len(err)
        if isinstance(warn, list):
            warn = len(warn)
        result = str(q.get("result") or q.get("status") or "").upper()
        try:
            e = int(err) if err is not None else -1
            w = int(warn) if warn is not None else -1
        except (TypeError, ValueError):
            e, w = -1, -1
        rel = str(cand.relative_to(project))
        if e == 0 and w == 0 and result not in ("FAIL", "ERROR"):
            return True, rel
        return False, f"{cand.name}: result={result} E={err} W={warn}"
    return False, "qa-report.json yok"


def discovery_filled() -> bool:
    d = project / "DISCOVERY.md"
    if not d.is_file():
        return False
    text = d.read_text(encoding="utf-8", errors="replace")
    # şablon: **Proje adı:** _(buraya yaz — …)_
    if "buraya yaz" in text.lower():
        return False
    for line in text.splitlines():
        if line.startswith("**Proje adı:**"):
            rest = line.split(":", 1)[-1].strip()
            if rest and not rest.startswith("_") and "buraya" not in rest.lower():
                return True
    return False


mode = mode_of()
st = read_json(fac / "web-state.json") or {}
phase = st.get("current_phase") or "—"
status = st.get("status") or "—"
halted = status == "halted" or phase == "HALT"


def row(name: str, allow: bool, reason: str, fix: str) -> dict:
    return {
        "op": name,
        "allow": allow,
        "reason": reason,
        "fix": fix,
        "mode": mode,
        "phase": phase,
        "status": status,
    }


def eval_op(name: str) -> dict:
    if halted and name not in ("qa", "claim-pass", "matrix"):
        return row(
            name,
            False,
            "HALT — geçişler kapalı",
            "cat debug_report.json; bash scripts/web/state.sh start . --reset",
        )

    if name == "write-code":
        if mode != "factory":
            return row(
                name, False,
                f"mode={mode} — keşifte üretim kodu yasak",
                'bash scripts/web/mode.sh from-brief . "<brief>"',
            )
        if not (fac / "web-state.json").is_file():
            return row(name, False, "state yok", "bash scripts/web/state.sh start .")
        if phase == "P1":
            return row(
                name, False,
                "faz=P1 — kod yok; domain dondur",
                "bash scripts/web/orchestrate.sh .  # /web-baslat",
            )
        return row(name, True, f"mode=factory phase={phase}", "module-apply → iskelet → qa-gate")

    if name == "promote":
        if mode == "factory":
            return row(name, True, "zaten factory", "bash scripts/web/state.sh start .")
        if not discovery_filled():
            return row(
                name, False,
                "DISCOVERY.md eksik veya yer tutucu",
                'bash scripts/web/mode.sh from-brief . "<brief>"',
            )
        return row(name, True, "DISCOVERY dolu", "bash scripts/web/mode.sh promote .")

    if name == "decide":
        if mode != "factory":
            return row(name, False, "mode≠factory", "from-brief / promote")
        if not (fac / "domain-report.json").is_file():
            return row(name, False, "domain-report.json yok", "/web-baslat → domain-report")
        return row(name, True, "domain-report var", "bash scripts/web/decide.sh .")

    if name == "advance":
        if mode != "factory":
            return row(name, False, "mode≠factory", "promote")
        if not (fac / "web-state.json").is_file():
            return row(name, False, "state yok", "state.sh start .")
        if phase == "P1" and not (fac / "domain-report.json").is_file():
            return row(name, False, "P1→P2 için domain-report yok", "domain-report yaz")
        if phase == "P3":
            return row(name, False, "P3→P5 yalnız qa-pass", "qa-gate.sh . --record")
        return row(name, True, f"phase={phase}", "bash scripts/web/state.sh advance .")

    if name == "module-apply":
        if mode != "factory":
            return row(name, False, "mode≠factory", "promote")
        if not (fac / "decision.json").is_file():
            return row(name, False, "decision.json yok", "bash scripts/web/decide.sh .")
        return row(name, True, "decision.json var", "bash scripts/web/module-apply.sh .")

    if name == "qa":
        if mode != "factory":
            return row(name, False, "mode≠factory", "promote")
        return row(name, True, "qa-gate çalıştırılabilir", "bash scripts/web/qa-gate.sh .")

    if name == "package":
        if mode != "factory":
            return row(name, False, "mode≠factory", "promote")
        ok, detail = qa_pass()
        if not ok:
            return row(name, False, f"QA PASS değil ({detail})", "bash scripts/web/qa-gate.sh .")
        return row(name, True, f"QA PASS ({detail})", "bash scripts/web/package-yukleme.sh .")

    if name == "claim-pass":
        ok, detail = qa_pass()
        if not ok:
            return row(
                name, False,
                f"PASS iddiası geçersiz ({detail})",
                "bash scripts/web/qa-gate.sh . && cat qa-report.json",
            )
        return row(name, True, f"kanıt var ({detail})", "paketleme / teslim")

    if name == "orchestrate":
        if mode != "factory":
            return row(name, False, "mode≠factory", "from-brief / promote")
        return row(name, True, f"phase={phase}", "bash scripts/web/orchestrate.sh . --auto")

    return row(name, False, "op tanımsız", "guard.sh matrix .")


def log_entry(r: dict) -> None:
    r = dict(r)
    r["ts"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    r["project"] = str(project)
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(r, ensure_ascii=False) + "\n")


NAMES = (
    "write-code", "promote", "decide", "advance", "module-apply",
    "qa", "package", "claim-pass", "orchestrate",
)

if op == "matrix":
    print(f"==> guard matrix · {project.name} · mode={mode} phase={phase} status={status}")
    for name in NAMES:
        r = eval_op(name)
        mark = "ALLOW" if r["allow"] else "DENY "
        print(f"  {mark}  {name:14}  {r['reason']}")
        if not r["allow"]:
            print(f"         fix: {r['fix']}")
    log_entry(row("matrix", True, "matrix dump", "guard.sh <op> ."))
    sys.exit(0)

r = eval_op(op)
log_entry(r)
if r["allow"]:
    print(f"guard: ALLOW {op}")
    print(f"  reason: {r['reason']}")
    print(f"  next  : {r['fix']}")
    sys.exit(0)

print(f"guard: DENY  {op}", file=sys.stderr)
print(f"  reason: {r['reason']}", file=sys.stderr)
print(f"  fix   : {r['fix']}", file=sys.stderr)
print(f"  state : mode={mode} phase={phase} status={status}", file=sys.stderr)
print(f"  audit : {log_path}", file=sys.stderr)
sys.exit(1)
PY
