#!/usr/bin/env bash
# Geçici dizinde template Android iskeleti derler (CI + JDK doğrulama).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${CI_TEMPLATE_BUILD_DIR:-$(mktemp -d)}"
KEEP="${CI_KEEP_BUILD_DIR:-0}"

cleanup() {
  [[ "$KEEP" == "1" ]] || [[ "$WORK" == /* && "$WORK" == *"/tmp/"* ]] && rm -rf "$WORK" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> CI template build"
echo "    Workdir: $WORK"

APP_FABRIKA_ALLOW_TEMPLATE_SCAFFOLD=1 "$ROOT/scripts/scaffold-android-project-to.sh" "$WORK/ci-smoke" "FactoryCiSmoke" "com.ulas.factory.ci"
bash "$ROOT/scripts/bootstrap-gradle-wrapper.sh" "$WORK/ci-smoke" &>/dev/null

# CI smoke: minimal google-services.json (Firebase plugin requires file; not a real project)
GS_EXAMPLE="$ROOT/templates/android/project/app/google-services.json.example"
if [[ -f "$GS_EXAMPLE" ]]; then
  sed "s/{{PACKAGE}}/com.ulas.factory.ci/g" "$GS_EXAMPLE" > "$WORK/ci-smoke/app/google-services.json"
fi

if ! command -v java &>/dev/null; then
  echo "HATA: JDK 17+ gerekli"
  exit 1
fi

(cd "$WORK/ci-smoke" && ./gradlew assembleDebug --no-daemon --quiet)
echo "==> CI template build başarılı."
