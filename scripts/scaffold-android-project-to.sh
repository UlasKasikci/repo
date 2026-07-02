#!/usr/bin/env bash
# Android mimari iskeletini hedef dizine oluşturur.
# Kullanım:
#   ./scripts/scaffold-android-project-to.sh <hedef-dizin> "AppName" "com.sirket.app"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"
APP_NAME="${2:-}"
PACKAGE="${3:-}"

if [[ -z "$TARGET" || -z "$APP_NAME" || -z "$PACKAGE" ]]; then
  echo "Kullanım: $0 <hedef-dizin> <AppName> <com.sirket.app>"
  exit 1
fi

TARGET="$(mkdir -p "$TARGET" && cd "$TARGET" && pwd)"

python3 "$ROOT/scripts/governance/validate-project-intent.py" \
  --mode scaffold --platform android --require-role android-app || exit 2

APP_CLASS="$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9]//g')"
PKG_PATH="${PACKAGE//.//}"
TEMPLATE="$ROOT/templates/android/project"

echo "==> Android iskeleti: $APP_NAME ($PACKAGE)"
echo "    Hedef: $TARGET"

python3 - "$TEMPLATE" "$TARGET" "$APP_NAME" "$PACKAGE" "$APP_CLASS" "$PKG_PATH" << 'PYEOF'
import sys
import shutil
from pathlib import Path

template, target, app_name, package, app_class, pkg_path = sys.argv[1:7]
template = Path(template)
target = Path(target)

def subst(content: str) -> str:
    return (content
        .replace("{{APP_NAME}}", app_name)
        .replace("{{PACKAGE}}", package)
        .replace("{{APP_CLASS}}", app_class)
        .replace("{{PACKAGE_PATH}}", pkg_path))

def copy_tree(src: Path, dst: Path):
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        rel_str = subst(str(rel))
        dest = dst / rel_str
        if item.is_dir():
            dest.mkdir(parents=True, exist_ok=True)
        else:
            dest.parent.mkdir(parents=True, exist_ok=True)
            try:
                dest.write_text(subst(item.read_text(encoding="utf-8")), encoding="utf-8")
            except UnicodeDecodeError:
                shutil.copy2(item, dest)

if (target / "settings.gradle.kts").exists():
    print("HATA: Android projesi zaten mevcut (settings.gradle.kts)")
    sys.exit(1)

copy_tree(template, target)
print("  Modüller: app + 7 core + 3 feature")
PYEOF

bash "$ROOT/scripts/bootstrap-gradle-wrapper.sh" "$TARGET"
chmod +x "$TARGET/gradlew" 2>/dev/null || true
echo "==> Scaffold tamamlandı: $TARGET"
