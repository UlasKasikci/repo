#!/bin/bash
set -euo pipefail

# Webrail — C.2 (Tur 2-15): insan ölçümü satırı ekleme yardımcısı.
# Gerçek proje ölçümü için gerekli opsiyonel alanlar metrics.jsonl'e buradan
# yazılır (agent satırlarından ayrık `kind: measure` satırı — append-only).
#
# Kullanım:
#   bash scripts/web/measure.sh <proje_dizini> <field> <value> [phase]
#
# Alanlar (RUN-REPORT ölçümü):
#   kur_duration_s      — /kur komutu süresi (saniye)
#   manual_p2_min       — manel P2 iskelet süresi (dakika; hybrid marker'dan
#                         otomatik de yazılır — state.sh advance P2→P3)
#   phase_human_assist  — true/false (hybrid girişinde otomatik yazılır)
#   discovery_minutes   — Şerit A keşif süresi (dk)
#   discovery_tokens    — keşif oturumu tahmini/ölçülen token (opsiyonel)
#   mode_promoted       — discovery→factory geçişi (mode.sh promote)
#   (serbest alan adları da kabul edilir)
#
# Satır şeması (append-only, agent satırıyla çakışmaz):
#   {"ts": "...", "kind": "measure", "field": "...", "value": <int|bool|str>,
#    "phase": "P2"?}
# Exit: 0 OK · 1 hata

usage() {
  echo "kullanım: bash scripts/web/measure.sh <proje_dizini> <field> <value> [phase]" >&2
  exit 1
}

PROJECT="${1:-}"
FIELD="${2:-}"
VALUE="${3:-}"
PHASE="${4:-}"

[[ -n "$PROJECT" && -n "$FIELD" && -n "$VALUE" ]] || usage
[[ -d "$PROJECT" ]] || { echo "measure: dizin yok: $PROJECT" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "measure: python3 gerekli" >&2; exit 1; }

PROJECT="$(cd "$PROJECT" && pwd)"
export _MS_PROJECT="$PROJECT" _MS_FIELD="$FIELD" _MS_VALUE="$VALUE" _MS_PHASE="$PHASE"

python3 - <<'PY'
import datetime, json, os, sys

project = os.environ["_MS_PROJECT"]
field = os.environ["_MS_FIELD"]
raw = os.environ["_MS_VALUE"]
phase = os.environ["_MS_PHASE"]

# değer koerisyonu: tam sayı → int, true/false → bool, aksi → str
value: object
try:
    value = int(raw)
except ValueError:
    if raw.lower() in ("true", "false"):
        value = raw.lower() == "true"
    else:
        value = raw

row = {
    "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "kind": "measure",
    "field": field,
    "value": value,
}
if phase:
    row["phase"] = phase

metrics = os.path.join(project, ".factory", "metrics.jsonl")
os.makedirs(os.path.dirname(metrics), exist_ok=True)
try:
    with open(metrics, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
except OSError as exc:
    print(f"measure: metrics.jsonl yazılamadı: {exc}", file=sys.stderr)
    sys.exit(1)
PY

echo "measure: $FIELD = $VALUE${PHASE:+ (phase=$PHASE)} → $PROJECT/.factory/metrics.jsonl"
