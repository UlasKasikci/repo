#!/usr/bin/env bash
set -euo pipefail

# Webrail — tek giriş sarmalayıcı (F1)
# Kullanım:
#   bash scripts/web/webrail.sh <proje_dizini> [--brief "..."] [--yes] [--skip-preflight]
# Exit: 0 OK · 1 FAIL
#
# Sıra: preflight (fabrika) → bootstrap (yoksa) → from-brief|promote ipucu → state start → status

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT=""
BRIEF=""
YES=0
SKIP_PREFLIGHT=0

usage() {
  echo "kullanım: webrail.sh <proje_dizini> [--brief \"metin\"] [--yes] [--skip-preflight]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brief)
      shift
      BRIEF="${1:-}"
      [[ -n "$BRIEF" ]] || usage
      shift
      ;;
    --yes) YES=1; shift ;;
    --skip-preflight) SKIP_PREFLIGHT=1; shift ;;
    -h|--help) usage ;;
    *)
      if [[ -z "$PROJECT" ]]; then
        PROJECT="$1"
        shift
      else
        echo "webrail: bilinmeyen argüman: $1" >&2
        usage
      fi
      ;;
  esac
done

[[ -n "$PROJECT" ]] || usage

# Fabrika mı? (self-test yalnız fabrikada)
FACTORY_ROOT="$ROOT"
if [[ ! -f "$FACTORY_ROOT/scripts/web/self-test.sh" ]]; then
  # bootstrapped müşteri: preflight atlanır (fabrika script'leri kopyalı)
  SKIP_PREFLIGHT=1
fi

if [[ "$SKIP_PREFLIGHT" -eq 0 ]]; then
  echo "==> webrail: preflight"
  bash "$FACTORY_ROOT/scripts/web/preflight.sh" || {
    echo "webrail: preflight FAIL — müşteriye geçme" >&2
    exit 1
  }
fi

# Bootstrap gerekirse
NEED_BOOT=0
if [[ ! -d "$PROJECT" ]]; then
  NEED_BOOT=1
elif [[ ! -f "$PROJECT/.factory/mode.json" && ! -f "$PROJECT/.factory/.bootstrap-manifest" ]]; then
  # boş veya kısmi
  if [[ -z "$(ls -A "$PROJECT" 2>/dev/null || true)" ]]; then
    NEED_BOOT=1
  elif [[ ! -f "$PROJECT/scripts/web/state.sh" ]]; then
    NEED_BOOT=1
  fi
fi

if [[ "$NEED_BOOT" -eq 1 ]]; then
  if [[ "$YES" -ne 1 ]]; then
    echo "webrail: hedef bootstrap gerektiriyor — plan:"
    bash "$FACTORY_ROOT/scripts/web/bootstrap-project.sh" "$PROJECT" || true
    echo "webrail: onay için --yes ekleyin" >&2
    exit 1
  fi
  echo "==> webrail: bootstrap"
  bash "$FACTORY_ROOT/scripts/web/bootstrap-project.sh" "$PROJECT" --yes
fi

[[ -d "$PROJECT" ]] || { echo "webrail: proje yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
SCRIPTS="$PROJECT/scripts/web"
[[ -f "$SCRIPTS/mode.sh" ]] || SCRIPTS="$FACTORY_ROOT/scripts/web"

# Mode init güvence
bash "$SCRIPTS/mode.sh" init "$PROJECT" >/dev/null || true

MODE="$(python3 -c "import json;p='$PROJECT/.factory/mode.json'
import os
print(json.load(open(p))['mode'] if os.path.isfile(p) else 'factory')")"

if [[ -n "$BRIEF" ]]; then
  echo "==> webrail: from-brief → promote"
  bash "$SCRIPTS/mode.sh" from-brief "$PROJECT" "$BRIEF"
  MODE="factory"
elif [[ "$MODE" == "discovery" ]]; then
  # Elle doldurulmuş DISCOVERY varsa promote dene
  if grep -Eq '^\*\*Proje adı:\*\*[[:space:]]+([^_[:space:]]|[^_].+)' "$PROJECT/DISCOVERY.md" 2>/dev/null \
     && ! grep -Eq '^\*\*Proje adı:\*\*.*_buraya yaz' "$PROJECT/DISCOVERY.md" 2>/dev/null; then
    echo "==> webrail: DISCOVERY dolu → promote"
    bash "$SCRIPTS/mode.sh" promote "$PROJECT"
    MODE="factory"
  else
    echo "==> webrail: mode=discovery — DISCOVERY doldur (/kesfet) veya --brief \"...\""
    bash "$SCRIPTS/status.sh" "$PROJECT"
    exit 0
  fi
fi

# State start (yoksa)
if [[ ! -f "$PROJECT/.factory/web-state.json" ]]; then
  echo "==> webrail: state start (P1)"
  bash "$SCRIPTS/state.sh" start "$PROJECT"
else
  echo "==> webrail: state mevcut — start atlandı"
fi

echo "==> webrail: P2 önerisi → P2_HUMAN_ASSIST=true bash scripts/web/orchestrate.sh . --auto"
bash "$SCRIPTS/status.sh" "$PROJECT"
echo "webrail: hazır — sonraki: /web-baslat (P1) · module-apply · hybrid P2"
exit 0
