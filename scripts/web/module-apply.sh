#!/usr/bin/env bash
set -euo pipefail

# Webrail — decision.json modules_to_apply → paket kopyala (LLM’den önce)
# Kullanım: bash scripts/web/module-apply.sh <proje> [--force] [--module NAME]
# Exit: 0 OK · 1 FAIL

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
shift || true
FORCE=0
ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --module) ONLY="${2:-}"; shift 2 ;;
    *) echo "module-apply: bilinmeyen: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$PROJECT" ]] || { echo "module-apply: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
bash "$ROOT/scripts/web/mode.sh" require-factory "$PROJECT" || exit 1

DEC="$PROJECT/.factory/decision.json"
[[ -f "$DEC" ]] || { echo "module-apply: decision.json yok — önce decide.sh" >&2; exit 1; }

# Paket kökü: proje veya fabrika
MOD_ROOT="$PROJECT/.factory/modules"
[[ -d "$MOD_ROOT/auth-rbac" ]] || MOD_ROOT="$ROOT/.factory/modules"
[[ -d "$MOD_ROOT" ]] || { echo "module-apply: modules kökü yok" >&2; exit 1; }

export _MA_PROJECT="$PROJECT" _MA_MOD_ROOT="$MOD_ROOT" _MA_DEC="$DEC" _MA_FORCE="$FORCE" _MA_ONLY="$ONLY" _MA_MEASURE="$ROOT/scripts/web/measure.sh"

python3 - <<'PY'
import json, os, shutil, sys
from pathlib import Path

project = Path(os.environ["_MA_PROJECT"])
mod_root = Path(os.environ["_MA_MOD_ROOT"])
force = os.environ["_MA_FORCE"] == "1"
only = (os.environ.get("_MA_ONLY") or "").strip().lower()
dec = json.loads(Path(os.environ["_MA_DEC"]).read_text(encoding="utf-8"))
mods = dec.get("modules_to_apply") or []

# alias → paket id
alias_map = {}
for pkg_dir in mod_root.iterdir():
    if not pkg_dir.is_dir():
        continue
    man = pkg_dir / "manifest.json"
    if not man.is_file():
        continue
    try:
        m = json.loads(man.read_text(encoding="utf-8"))
    except Exception:
        continue
    pid = m.get("id") or pkg_dir.name
    alias_map[pid] = pkg_dir
    for a in m.get("aliases") or []:
        alias_map[str(a).lower()] = pkg_dir

copied = []
skipped = []
tokens = 0

def apply_pkg(pkg: Path) -> None:
    global tokens
    files = pkg / "files"
    if not files.is_dir():
        print(f"module-apply: {pkg.name}: files/ yok — atlandı", file=sys.stderr)
        return
    man = {}
    mp = pkg / "manifest.json"
    if mp.is_file():
        man = json.loads(mp.read_text(encoding="utf-8"))
    n = 0
    for src in files.rglob("*"):
        if not src.is_file():
            continue
        rel = src.relative_to(files)
        dst = project / rel
        if dst.exists() and not force:
            skipped.append(str(rel))
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        n += 1
    if n:
        copied.append(pkg.name)
        tokens += int(man.get("tokens_avoided_est") or 0)
        print(f"module-apply: {pkg.name} → {n} dosya")

seen_pkg = set()
for row in mods:
    if not isinstance(row, dict):
        continue
    name = (row.get("module") or "").strip().lower().replace("_", "-")
    if only and name != only and alias_map.get(name, Path()).name != only:
        continue
    pkg = alias_map.get(name)
    if pkg is None:
        # skill-only satır
        continue
    if pkg.resolve() in seen_pkg:
        continue
    seen_pkg.add(pkg.resolve())
    apply_pkg(pkg)

# --module ile decision dışı doğrudan paket
if only and only not in {p.name for p in seen_pkg}:
    pkg = alias_map.get(only)
    if pkg:
        apply_pkg(pkg)

report = {
    "copied": copied,
    "skipped_existing": skipped[:50],
    "tokens_avoided_est": tokens,
}
out = project / ".factory" / "module-apply-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"module-apply: done · packages={copied} · tokens_avoided_est={tokens}")
if not copied and not skipped:
    print("module-apply: uyarı — kopyalanacak paket yok (catalog skill-only olabilir)", file=sys.stderr)
PY

# metrics
TOK="$(python3 -c "import json;print(json.load(open('$PROJECT/.factory/module-apply-report.json')).get('tokens_avoided_est',0))")"
COPIED="$(python3 -c "import json;print(len(json.load(open('$PROJECT/.factory/module-apply-report.json')).get('copied') or []))")"
bash "$ROOT/scripts/web/measure.sh" "$PROJECT" modules_copied "$COPIED" P2 || true
bash "$ROOT/scripts/web/measure.sh" "$PROJECT" tokens_avoided_est "$TOK" P2 || true
echo "module-apply: rapor → $PROJECT/.factory/module-apply-report.json"
