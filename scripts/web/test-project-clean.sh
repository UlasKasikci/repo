#!/bin/bash
# Tur 2-10 · Aşama 5 — test projesi temizlik betiği.
# Kullanım: bash scripts/web/test-project-clean.sh <target-dir> [--yes]
# Silmeden önce raporlar .factory/test-runs/ altında zaten saklıdır; betik
# yalnızca hedefi güvenle siler ve last-target.txt'yi günceller.
set -euo pipefail

usage() { echo "kullanım: bash scripts/web/test-project-clean.sh <target-dir> [--yes]" >&2; exit 1; }
[[ $# -ge 1 ]] || usage
TARGET="$1"
ASSUME_YES="${2:-}"

# 1) hedef var mı
[[ -e "$TARGET" ]] || { echo "hata: hedef yok: $TARGET" >&2; exit 1; }

# 2) test projesi mi? — .factory/web-state.json zorunlu (bootstrapped test işareti)
[[ -f "$TARGET/.factory/web-state.json" ]] || {
  echo "hata: $TARGET/.factory/web-state.json yok — bu bir test projesi değil, silme RED" >&2; exit 1; }

# 3) yanlış silme önlemi — hedef ANA REPO'nun kendisi veya altında olamaz
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TGT_ABS="$(cd "$TARGET" && pwd)"
case "$TGT_ABS" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    echo "hata: hedef ana repo içinde ($TGT_ABS ⊆ $REPO_ROOT) — silme RED" >&2; exit 1 ;;
esac
# kök / home / ana dizin koruması
[[ "$TGT_ABS" == "/" ]] && { echo "hata: kök dizin silinmez" >&2; exit 1; }
[[ "$TGT_ABS" == "$HOME" ]] && { echo "hata: home silinmez" >&2; exit 1; }

# 4) boyut raporla
SIZE="$(du -sh "$TARGET" 2>/dev/null | cut -f1)"
echo "hedef:  $TGT_ABS"
echo "boyut:  ${SIZE:-?}"
echo "phase:  $(python3 -c "import json;print(json.load(open('$TARGET/.factory/web-state.json')).get('current_phase','?'))" 2>/dev/null || echo '?')"

# 5) onay
if [[ "$ASSUME_YES" != "--yes" ]]; then
  printf 'SİL? Bu işlem geri alınamaz. [y/N]: '
  read -r ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "iptal — hedef korundu."; exit 0; }
fi

# 6) sil
rm -rf "$TARGET"
echo "silindi: $TGT_ABS"

# 7) last-target.txt + cleanup.log
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
RUNS="$REPO_DIR/.factory/test-runs"
mkdir -p "$RUNS"
echo "" > "$RUNS/last-target.txt"
{
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) cleaned $TGT_ABS (size=$SIZE)"
} >> "$RUNS/cleanup.log"
echo "log: $RUNS/cleanup.log · last-target.txt güncellendi"
