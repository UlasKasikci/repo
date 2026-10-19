#!/usr/bin/env bash
set -euo pipefail

# Webrail — IDE komut drift (Cursor ↔ OpenCode)
# Kullanım: bash scripts/web/orphan-commands.sh [kök]
# Exit: 0 OK · 1 drift (orphan)

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
CUR="$ROOT/.cursor/commands"
OC="$ROOT/.opencode/command"

# Bilinçli Cursor-only (OpenCode karşılığı yok / farklı ad)
ALLOW_CURSOR_ONLY="after-action cevap"
# Bilinçli OpenCode-only
ALLOW_OC_ONLY=""

[[ -d "$CUR" && -d "$OC" ]] || {
  echo "orphan-commands: .cursor/commands veya .opencode/command yok" >&2
  exit 1
}

export _OC_CUR="$CUR" _OC_OC="$OC" _OC_ALLOW_C="$ALLOW_CURSOR_ONLY" _OC_ALLOW_O="$ALLOW_OC_ONLY"
python3 - <<'PY'
import os, sys
from pathlib import Path

cur = Path(os.environ["_OC_CUR"])
oc = Path(os.environ["_OC_OC"])
allow_c = set((os.environ.get("_OC_ALLOW_C") or "").split())
allow_o = set((os.environ.get("_OC_ALLOW_O") or "").split())

def names(d: Path) -> set[str]:
    return {p.stem for p in d.glob("*.md") if p.is_file()}

c_names = names(cur)
o_names = names(oc)
only_c = sorted((c_names - o_names) - allow_c)
only_o = sorted((o_names - c_names) - allow_o)

print(f"==> orphan-commands · cursor={len(c_names)} opencode={len(o_names)}")
if only_c:
    print(f"  ORPHAN cursor-only: {only_c}", file=sys.stderr)
if only_o:
    print(f"  ORPHAN opencode-only: {only_o}", file=sys.stderr)
if only_c or only_o:
    sys.exit(1)
print("    parity OK (allowlist hariç)")
sys.exit(0)
PY
