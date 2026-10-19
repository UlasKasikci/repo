#!/usr/bin/env bash
set -euo pipefail

# Webrail — sistem borcu taraması (TODO/FIXME, boş stub, kaba CSRF boşluğu)
# Kullanım: bash scripts/web/debt-scan.sh <proje>
# Exit: 0 her zaman (rapor); blocker varsa stdout BLOCKER (denetle birleştirebilir)

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "debt-scan: dizin yok" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

export _DS_PROJECT="$PROJECT"
python3 - <<'PY'
import json, re, os
from pathlib import Path
from datetime import datetime, timezone

p = Path(os.environ["_DS_PROJECT"])
findings = []

def add(fid, title, detail, severity="warn"):
    findings.append({"id": fid, "title": title, "detail": detail, "severity": severity, "source": "debt-scan"})

# PHP / JS / MD (core, views, scripts proje-içi)
roots = [p / "core", p / "views", p / "assets" / "js", p / "index.php"]
files = []
for r in roots:
    if r.is_file():
        files.append(r)
    elif r.is_dir():
        files.extend(r.rglob("*.php"))
        files.extend(r.rglob("*.js"))

todo_n = 0
stub_n = 0
for f in files[:200]:
    try:
        t = f.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    rel = str(f.relative_to(p))
    for m in re.finditer(r'(TODO|FIXME|XXX|HACK)\b[^\n]{0,80}', t):
        todo_n += 1
        if todo_n <= 12:
            add("todo_mark", f"İşaret: {m.group(1)}", f"{rel}: {m.group(0).strip()}", "warn")
    if re.search(r'function\s+\w+\s*\([^)]*\)\s*\{\s*(return\s+null;?\s*)?\}', t) and "NotImplemented" in t:
        stub_n += 1
        add("empty_stub", "Boş / NotImplemented stub", rel, "warn")
    if "throw new \\Exception('not implemented')" in t.lower() or "not implemented" in t.lower():
        add("not_implemented", "not implemented izi", rel, "warn")

# POST var, CSRF yok (kaba — qa-gate asıl kapı)
for f in list((p / "core").rglob("*.php"))[:80] if (p / "core").is_dir() else []:
    try:
        t = f.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    if "$_POST" in t or "$_REQUEST" in t:
        if not re.search(r'(guardPost|Csrf::|csrf_|verifyCsrf|requireValid)', t):
            # view/router dışı şüphe
            if "test" not in str(f).lower():
                add("csrf_suspect", "POST var, CSRF çağrısı görünmüyor", str(f.relative_to(p)), "warn")

report = {
    "schema_version": 1,
    "tool": "debt-scan",
    "project": str(p),
    "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "findings": findings,
    "warn_count": sum(1 for f in findings if f["severity"] == "warn"),
    "blocker_count": sum(1 for f in findings if f["severity"] == "blocker"),
    "todo_hits": todo_n,
}
out = p / "debt-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(fac := p / ".factory").mkdir(parents=True, exist_ok=True)
(fac / "debt-report.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")
print(f"==> debt-scan · {p.name} · warn={report['warn_count']} todo≈{todo_n}")
for f in findings[:15]:
    print(f"    [{f['severity'].upper()}] {f['id']}: {f['title']} — {f['detail']}")
if len(findings) > 15:
    print(f"    … +{len(findings)-15} daha")
if not findings:
    print("    (borç işareti yok)")
print(f"    rapor: {out}")
PY
