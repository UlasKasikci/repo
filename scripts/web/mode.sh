#!/usr/bin/env bash
set -euo pipefail

# Webrail — keşif/fabrika mod kilidi
# Kullanım:
#   bash scripts/web/mode.sh status|init|promote|require-factory [proje]
# Exit: 0 OK · 1 FAIL

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OP="${1:-}"
PROJECT="${2:-.}"

usage() {
  echo "kullanım: mode.sh <status|init|promote|require-factory> [proje_dizini]" >&2
  exit 1
}

[[ -n "$OP" ]] || usage
[[ -d "$PROJECT" ]] || { echo "mode: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
MODE_FILE="$PROJECT/.factory/mode.json"
DISCOVERY="$PROJECT/DISCOVERY.md"
TPL="$ROOT/docs/templates/DISCOVERY.md"
export MODE_FILE PROJECT DISCOVERY

read_mode() {
  python3 - <<'PY'
import json, os, sys
p = os.environ["MODE_FILE"]
if not os.path.isfile(p):
    print("factory")  # geriye uyum: mode yoksa fabrika (eski projeler)
    sys.exit(0)
try:
    d = json.load(open(p, encoding="utf-8"))
except Exception as e:
    print(f"mode: bozuk mode.json: {e}", file=sys.stderr)
    sys.exit(1)
print(d.get("mode") or "discovery")
PY
}

case "$OP" in
  status)
    export MODE_FILE
    m="$(read_mode)"
    echo "mode: $m ($MODE_FILE)"
    [[ -f "$DISCOVERY" ]] && echo "discovery: var ($DISCOVERY)" || echo "discovery: yok"
    ;;

  init)
    mkdir -p "$PROJECT/.factory"
    if [[ ! -f "$DISCOVERY" && -f "$TPL" ]]; then
      cp "$TPL" "$DISCOVERY"
      echo "mode: DISCOVERY.md şablonu kopyalandı"
    fi
    python3 - <<PY
import json, os, sys
from datetime import datetime, timezone
path = os.environ["MODE_FILE"]
os.makedirs(os.path.dirname(path), exist_ok=True)
# Idempotent: mevcut discovery/factory mode.json'u yeniden yazma
# (--force bootstrap ikinci commit üretmesin)
if os.path.isfile(path):
    try:
        existing = json.load(open(path, encoding="utf-8"))
        if existing.get("mode") in ("discovery", "factory"):
            print(f"mode: init → {existing.get('mode')} (korundu)")
            sys.exit(0)
    except Exception:
        pass
doc = {
    "schema_version": 1,
    "mode": "discovery",
    "promoted_at": None,
    "discovery_path": "DISCOVERY.md",
    "note": "Keşif (saf IDE) — kod yok. promote ile factory.",
    "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("mode: init → discovery")
PY
    export MODE_FILE
    ;;

  promote)
    export MODE_FILE
    [[ -f "$DISCOVERY" ]] || {
      echo "mode: DISCOVERY.md yok — önce /kesfet veya şablonu doldur" >&2
      exit 1
    }
    # Proje adı satırı şablon yer tutucusu olmamalı
    if ! grep -Eq '^\*\*Proje adı:\*\*[[:space:]]+([^_[:space:]]|[^_].+)' "$DISCOVERY" \
      || grep -Eq '^\*\*Proje adı:\*\*.*_buraya yaz' "$DISCOVERY"; then
      echo "mode: DISCOVERY.md → **Proje adı:** doldurulmalı (şablon yer tutucusu kabul değil)" >&2
      exit 1
    fi
    # Üretim kodu erken yazılmışsa uyar (soft fail değil — promote engeli)
    for p in core views SQL/veritabani.sql index.php; do
      if [[ -e "$PROJECT/$p" ]]; then
        echo "mode: uyarı — keşifte üretim izi var: $p (yine de promote edilebilir; P1 ile hizala)" >&2
      fi
    done
    python3 - <<PY
import json, os
from datetime import datetime, timezone
path = os.environ["MODE_FILE"]
os.makedirs(os.path.dirname(path), exist_ok=True)
doc = {}
if os.path.isfile(path):
    try:
        doc = json.load(open(path, encoding="utf-8"))
    except Exception:
        doc = {}
doc.update({
    "schema_version": 1,
    "mode": "factory",
    "promoted_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "discovery_path": "DISCOVERY.md",
    "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
})
json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("mode: promote → factory")
PY
    bash "$ROOT/scripts/web/measure.sh" "$PROJECT" mode_promoted true A0 || true
    bash "$ROOT/scripts/web/run-status.sh" "$PROJECT" || true
    echo "mode: sonraki → bash scripts/web/state.sh start $PROJECT"
    ;;

  require-factory)
    export MODE_FILE
    m="$(read_mode)"
    if [[ "$m" != "factory" ]]; then
      echo "mode: şu an '$m' — fabrika kapıları kapalı." >&2
      echo "mode: 1) DISCOVERY.md doldur  2) bash scripts/web/mode.sh promote $PROJECT" >&2
      echo "mode: (keşif = saf IDE; kod üretimi factory modunda)" >&2
      exit 1
    fi
    ;;

  *) usage ;;
esac
