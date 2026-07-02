#!/usr/bin/env bash
# Tam Android mimari iskeletini oluşturur.
# Kullanım: ./scripts/scaffold-android-project.sh "AppName" "com.sirket.app"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${1:-}"
PACKAGE="${2:-}"

if [[ -z "$APP_NAME" || -z "$PACKAGE" ]]; then
  echo "Kullanım: $0 <AppName> <com.sirket.app>"
  exit 1
fi

python3 "$ROOT/scripts/governance/validate-project-intent.py" \
  --mode scaffold --platform android --require-role android-app || exit 2

APP_CLASS="$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9]//g')"
PKG_PATH="${PACKAGE//.//}"
TEMPLATE="$ROOT/templates/android/project"

echo "==> Android mimari iskeleti oluşturuluyor: $APP_NAME ($PACKAGE)"

python3 - "$TEMPLATE" "$ROOT" "$APP_NAME" "$PACKAGE" "$APP_CLASS" "$PKG_PATH" << 'PYEOF'
import os, sys, shutil
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
print(f"  Modüller: app + 7 core + 3 feature")
print(f"  Compose Liquid Glass tema hazır")
print(f"  OEM, Billing, FCM, Security şablonları dahil")
PYEOF

bash "$ROOT/scripts/bootstrap-gradle-wrapper.sh" "$ROOT"
chmod +x "$ROOT/gradlew" 2>/dev/null || true
echo "==> Scaffold tamamlandı."
echo "    Sonraki: ./gradlew assembleDebug (JDK 17+ gerekir)"
