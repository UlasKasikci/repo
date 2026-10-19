#!/usr/bin/env bash
set -euo pipefail

# Webrail Reality Checker (L1) — ajan "bitti" demez; kanıt dosyası şart
# Kullanım:
#   bash scripts/web/reality-check.sh <proje> P1|P3|P5
# Exit: 0 PASS · 1 FAIL (kanıt yok/geçersiz)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
GATE="${2:-}"
[[ -d "$PROJECT" ]] || { echo "reality-check: dizin yok" >&2; exit 1; }
[[ -n "$GATE" ]] || { echo "kullanım: reality-check.sh <proje> P1|P3|P5" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

export _RC_PROJECT="$PROJECT" _RC_GATE="$GATE" _RC_ROOT="$ROOT"
python3 - <<'PY'
import json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(os.environ["_RC_PROJECT"])
gate = os.environ["_RC_GATE"].upper()
root = Path(os.environ["_RC_ROOT"])
fac = p / ".factory"
fac.mkdir(parents=True, exist_ok=True)
findings = []
ok = True

def fail(msg):
    global ok
    ok = False
    findings.append({"severity": "fail", "detail": msg})

def note(msg):
    findings.append({"severity": "ok", "detail": msg})

if gate == "P1":
    rep = fac / "domain-report.json"
    if not rep.is_file():
        fail("domain-report.json yok")
    else:
        chk = root / "scripts" / "web" / "domain-check.py"
        if chk.is_file():
            rc = subprocess.call(
                [sys.executable, str(chk), str(rep), str(p)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if rc != 0:
                fail("domain-check.py PASS değil")
            else:
                note("domain-report + domain-check OK")
        else:
            note("domain-report var (domain-check yok)")
    dec = fac / "decision.json"
    if not dec.is_file():
        fail("decision.json yok — decide.sh çalıştır")
    else:
        note("decision.json var")

elif gate == "P3":
    qa = p / "qa-report.json"
    if not qa.is_file():
        fail("qa-report.json yok")
    else:
        try:
            doc = json.loads(qa.read_text(encoding="utf-8"))
        except Exception as e:
            fail(f"qa-report okunamadı: {e}")
            doc = {}
        if doc.get("result") != "PASS":
            fail(f"qa result={doc.get('result')} (PASS değil)")
        elif doc.get("errors"):
            fail("qa-report errors dolu")
        else:
            note("qa-report PASS · 0 error")

elif gate == "P5":
    pkg = p / "packaging-report.json"
    if not pkg.is_file():
        fail("packaging-report.json yok")
    else:
        try:
            doc = json.loads(pkg.read_text(encoding="utf-8"))
        except Exception as e:
            fail(f"packaging-report okunamadı: {e}")
            doc = {}
        res = doc.get("result") or doc.get("status")
        if str(res).upper() not in ("PASS", "OK", "SUCCESS"):
            # bazı raporlar result alanı farklı
            if not (p / "Yukleme" / "index.php").is_file():
                fail(f"packaging result={res} ve Yukleme/index.php yok")
            else:
                note("Yukleme/index.php var")
        else:
            note("packaging-report PASS")
    if not (p / "Yukleme" / "index.php").is_file():
        fail("Yukleme/index.php yok")

else:
    fail(f"bilinmeyen gate: {gate}")
    print(json.dumps({"ok": False, "gate": gate, "findings": findings}))
    sys.exit(1)

report = {
    "schema_version": 1,
    "tool": "reality-check",
    "gate": gate,
    "project": str(p),
    "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "result": "PASS" if ok else "FAIL",
    "findings": findings,
}
out = fac / "reality-check.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(p / "reality-check.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")

print(f"==> reality-check · {p.name} · {gate} · {report['result']}")
for f in findings:
    print(f"    [{f['severity'].upper()}] {f['detail']}")
print(f"    rapor: {out}")
sys.exit(0 if ok else 1)
PY
