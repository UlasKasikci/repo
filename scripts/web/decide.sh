#!/usr/bin/env bash
set -euo pipefail

# Webrail Decision Layer — açık kaynak JEV-mantığı (ücretli JEV yok)
# Kullanım: bash scripts/web/decide.sh [proje_dizini]
# Çıktı: <proje>/.factory/decision.json

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "decide: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "decide: python3 gerekli" >&2; exit 1; }

python3 "$ROOT/scripts/web/decision.py" "$PROJECT" --factory-root "$ROOT"

# Handoff güncelle (varsa)
if [[ -x "$ROOT/scripts/web/run-status.sh" ]] || [[ -f "$ROOT/scripts/web/run-status.sh" ]]; then
  bash "$ROOT/scripts/web/run-status.sh" "$PROJECT" || true
fi
