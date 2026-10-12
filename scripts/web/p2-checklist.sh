#!/usr/bin/env bash
set -euo pipefail

# Webrail — P2 scaffold önizleme (hybrid DX)
# Kullanım: bash scripts/web/p2-checklist.sh [proje]
# Exit: 0 hepsi var · 1 eksik var

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "p2-checklist: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

ok=0
miss=0
check() {
  local p="$1"
  if [[ -e "$PROJECT/$p" ]]; then
    echo "  OK  $p"
    ok=$((ok + 1))
  else
    echo "  --  $p"
    miss=$((miss + 1))
  fi
}

echo "==> P2 checklist · $PROJECT"
check "index.php"
check "core"
check "views"
check "SQL/veritabani.sql"
check "phpstan.neon.dist"
check "phpunit.xml"
check ".eslintrc.json"
check "tests"
[[ -f "$PROJECT/.factory/module-apply-report.json" ]] \
  && echo "  OK  module-apply-report.json" \
  || echo "  --  module-apply-report.json (önerilir: module-apply.sh)"

echo "  özet: var=$ok eksik=$miss"
[[ "$miss" -eq 0 ]]
