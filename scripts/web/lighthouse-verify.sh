#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — Lighthouse canlı doğrulama (P5 SONRASI bağımsız raporlayıcı faz)
# State graph'a girmez, qa-gate'i ağırlaştırmaz; bloklayıcı DEĞİLDİR (v1).
#
# Kullanım:
#   bash scripts/web/lighthouse-verify.sh <proje_dizini> [--serve] [--port N] [--strict]
#
#   LIGHTHOUSE_URL=https://localhost:8443  → çalışan uygulamaya koş (cihazda/sunucuda)
#   --serve                                 → php -S ile geçici sunucu kalkar, biter kapanır
#   --strict                                → eşik altı WARN'i exit 1 yapar (sonraki sıkılaştırma)
#
# Araç: `lighthouse` (npm install -g lighthouse) — PATH veya proje node_modules/.bin.
# Çıktı: <proje>/.factory/lighthouse-report.json
#   result: PASS (eşikler tam) · WARN (eşik altı — v1'de yine exit 0) · SKIPPED (env/araç yok)
# Eşikler (v1 raporlayıcı): kategori ≥90 (performance/accessibility/best-practices/seo),
#   LCP < 2500ms · CLS < 0.1
# Exit: 0 PASS/WARN/SKIPPED · 1 yalnız --strict ile WARN veya iç hata

PROJECT="${1:-}"
shift || true
SERVE=0
STRICT=0
PORT="${LIGHTHOUSE_PORT:-8973}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serve)  SERVE=1; shift ;;
    --strict) STRICT=1; shift ;;
    --port)   PORT="${2:?--port için sayı gerekli}"; shift 2 ;;
    -h|--help)
      sed -n '4,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [[ -z "$PROJECT" ]]; then PROJECT="$1"; else
        echo "lighthouse-verify: bilinmeyen argüman: $1" >&2; exit 1
      fi
      shift
      ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "kullanım: lighthouse-verify.sh <proje_dizini> [--serve] [--port N] [--strict]" >&2; exit 1; }
[[ -d "$PROJECT" ]] || { echo "lighthouse-verify: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
mkdir -p "$PROJECT/.factory"
REPORT="$PROJECT/.factory/lighthouse-report.json"
command -v python3 >/dev/null 2>&1 || { echo "lighthouse-verify: python3 gerekli" >&2; exit 1; }

URL="${LIGHTHOUSE_URL:-}"
NOTS=""
SRV_PID=""

cleanup() {
  if [[ -n "$SRV_PID" ]]; then
    kill "$SRV_PID" 2>/dev/null || true
    wait "$SRV_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

add_not() {
  if [[ -n "$NOTS" ]]; then NOTS="$NOTS · $1"; else NOTS="$1"; fi
}

# write_report <result> <lighthouse-json|>
write_report() {
  R_RESULT="$1" R_LH="${2:-}" R_URL="$URL" R_NOTS="$NOTS" R_STRICT="$STRICT" \
  python3 - "$REPORT" <<'PY'
import json
import os
import sys

path = sys.argv[1]
result = os.environ.get("R_RESULT", "SKIPPED")
lh_path = os.environ.get("R_LH", "")
url = os.environ.get("R_URL", "")
strict = os.environ.get("R_STRICT", "0") == "1"
nots = [s for s in os.environ.get("R_NOTS", "").split(" · ") if s]
thresholds = {"category_min": 90, "lcp_max_ms": 2500, "cls_max": 0.1}
out = {
    "tool": "lighthouse-verify",
    "result": result,
    "url": url,
    "strict": strict,
    "scores": None,
    "metrics": None,
    "thresholds": thresholds,
    "violations": [],
    "nots": nots,
}

if lh_path and os.path.isfile(lh_path):
    try:
        with open(lh_path, encoding="utf-8") as fh:
            data = json.load(fh)
        # gerçek LH şeması: categories.<id>.score (0..1) — .value DEĞİL
        scores = {
            key: round(float(cat.get("score") or 0) * 100)
            for key, cat in data.get("categories", {}).items()
        }
        metrics = {}
        audits = data.get("audits", {})
        lcp = audits.get("largest-contentful-paint", {}).get("numericValue")
        cls = audits.get("cumulative-layout-shift", {}).get("numericValue")
        if lcp is not None:
            metrics["lcp_ms"] = round(float(lcp))
        if cls is not None:
            metrics["cls"] = round(float(cls), 3)
        out["scores"] = scores
        out["metrics"] = metrics

        violations = [
            f"{key} {value} < {thresholds['category_min']}"
            for key, value in sorted(scores.items())
            if value < thresholds["category_min"]
        ]
        if metrics.get("lcp_ms", 0) > thresholds["lcp_max_ms"]:
            violations.append(f"LCP {metrics['lcp_ms']}ms > {thresholds['lcp_max_ms']}ms")
        if metrics.get("cls", 0) > thresholds["cls_max"]:
            violations.append(f"CLS {metrics['cls']} > {thresholds['cls_max']}")
        out["violations"] = violations
        if result == "PASS" and violations:
            out["result"] = "WARN"
            nots.append("eşik altı: " + ", ".join(violations))
            out["nots"] = nots
    except Exception as exc:  # bozuk/eksik LH çıktısı → raporlayıcı: WARN, asla çökme
        out["result"] = "WARN"
        out["nots"] = nots + [f"lighthouse JSON okunamadı: {exc}"]

with open(path, "w", encoding="utf-8") as fh:
    json.dump(out, fh, indent=2, ensure_ascii=False)
    fh.write("\n")

sys.exit(9 if strict and out["result"] == "WARN" else 0)
PY
}

# --- geçici sunucu (--serve) ---
if [[ "$SERVE" -eq 1 ]]; then
  command -v php >/dev/null 2>&1 || { echo "lighthouse-verify: --serve için php gerekli" >&2; exit 1; }
  if command -v curl >/dev/null 2>&1; then
    php -S "127.0.0.1:$PORT" -t "$PROJECT" >/dev/null 2>&1 &
    SRV_PID=$!
    READY=0
    for _i in $(seq 1 40); do
      if curl -s -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then READY=1; break; fi
      sleep 0.25
    done
    if [[ "$READY" -ne 1 ]]; then
      echo "lighthouse-verify: --serve sunucusu hazır değil (port $PORT)" >&2
      exit 1
    fi
    URL="http://127.0.0.1:$PORT/"
    add_not "--serve: php -S 127.0.0.1:$PORT (geçici)"
  else
    echo "lighthouse-verify: --serve için curl gerekli" >&2
    exit 1
  fi
fi

# --- 1) hedef URL ---
if [[ -z "$URL" ]]; then
  add_not "LIGHTHOUSE_URL tanımlı değil — çalışan uygulama URL'si verin (veya --serve)"
  write_report "SKIPPED"
  echo "lighthouse-verify: SKIPPED — LIGHTHOUSE_URL yok (rapor: $REPORT)"
  exit 0
fi

# --- 2) araç ---
LH_CMD=""
if command -v lighthouse >/dev/null 2>&1; then
  LH_CMD="lighthouse"
elif [[ -x "$PROJECT/node_modules/.bin/lighthouse" ]]; then
  LH_CMD="$PROJECT/node_modules/.bin/lighthouse"
else
  add_not "lighthouse kurulu değil — npm install -g lighthouse"
  write_report "SKIPPED"
  echo "lighthouse-verify: SKIPPED — araç yok (rapor: $REPORT)"
  exit 0
fi

# --- 3) koşu ---
LH_OUT="$(mktemp)"
LH_ERR="$(mktemp)"
LH_RC=0
"$LH_CMD" "$URL" \
  --output=json \
  --output-path="$LH_OUT" \
  --only-categories=performance,accessibility,best-practices,seo \
  --quiet \
  --chrome-flags="--headless=new --no-sandbox --disable-gpu" \
  >"$LH_ERR" 2>&1 || LH_RC=$?

if [[ "$LH_RC" -ne 0 || ! -s "$LH_OUT" ]]; then
  add_not "lighthouse koştu ama çıktı alınamadı (rc=$LH_RC): $(tail -c 300 "$LH_ERR" 2>/dev/null | tr '\n' ' ')"
  add_not "Chrome/Chromium gerekli (debian: chromium-browser; macOS: brew install --cask chrome)"
  RC2=0
  write_report "WARN" || RC2=$?
  echo "lighthouse-verify: WARN — koşu başarısız (rapor: $REPORT)"
  rm -f "$LH_OUT" "$LH_ERR"
  if [[ "$RC2" -eq 9 ]]; then exit 1; fi
  if [[ "$RC2" -ne 0 ]]; then echo "lighthouse-verify: rapor yazımı başarısız" >&2; exit 1; fi
  exit 0
fi
rm -f "$LH_ERR"

RC=0
write_report "PASS" "$LH_OUT" || RC=$?
rm -f "$LH_OUT"

if [[ "$RC" -eq 9 ]]; then
  echo "lighthouse-verify: WARN (strict) — eşik altı, exit 1 (rapor: $REPORT)"
  exit 1
elif [[ "$RC" -ne 0 ]]; then
  echo "lighthouse-verify: rapor yazımı başarısız" >&2
  exit 1
fi

RESULT_SHOWN="$(python3 -c "import json;print(json.load(open('$REPORT'))['result'])")"
echo "lighthouse-verify: $RESULT_SHOWN (rapor: $REPORT)"
exit 0
