#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — deterministik SQL dump üretici (P2/P5 yardımcı)
# Kaynak:  <proje>/SQL/migrations/schema/*.sql  +  <proje>/SQL/migrations/seed/*.sql
# Çıktı:   <proje>/SQL/veritabani.sql  (veya --output <path>)
# Kullanım: bash scripts/web/sql-dump.sh <proje_dizini> [--output <path>]
#
# Determinizm sözleşmesi:
#   - Dosya sırası: LC_ALL=C artan ad sıralaması
#   - Saat damgası ASLA yazılmaz (aynı kaynak → byte-identical çıktı)
#   - Tarih yorumu opsiyonel SQL/migrations/SURUM dosyasından okunur (ilk satır)
#   - CRLF → LF normalizasyonu
#   - Kaynak Hash (sha256, 12 hex) başlıkta — sürüm takibi
#
# qa-gate.sh `sql_dump` kontrolü bu scripti --output ile temp'e üretir ve
# commit'li SQL/veritabani.sql ile byte-karşılaştırır (drift → FAIL).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PROJECT="${1:-}"
OUTPUT=""
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT="${2:?--output için yol gerekli}"
      shift 2
      ;;
    *)
      if [[ -z "$PROJECT" ]]; then PROJECT="$1"; else
        echo "sql-dump: bilinmeyen argüman: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

usage() { echo "kullanım: sql-dump.sh <proje_dizini> [--output <path>]" >&2; exit 1; }

[[ -n "$PROJECT" ]] || usage
command -v python3 >/dev/null 2>&1 || { echo "sql-dump: python3 gerekli" >&2; exit 1; }
[[ -d "$PROJECT" ]] || { echo "sql-dump: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

SCHEMA_DIR="$PROJECT/SQL/migrations/schema"
SEED_DIR="$PROJECT/SQL/migrations/seed"
[[ -d "$SCHEMA_DIR" ]] || { echo "sql-dump: kaynak yok: SQL/migrations/schema" >&2; exit 1; }
if [[ -z "$OUTPUT" ]]; then OUTPUT="$PROJECT/SQL/veritabani.sql"; fi

python3 - "$PROJECT" "$SCHEMA_DIR" "$SEED_DIR" "$OUTPUT" <<'PY'
import hashlib
import os
import sys

project, schema_dir, seed_dir, out_path = sys.argv[1:5]


def collect(directory, kind):
    if not os.path.isdir(directory):
        return []
    names = sorted(
        n for n in os.listdir(directory)
        if n.endswith(".sql") and not n.startswith("._")
        and os.path.isfile(os.path.join(directory, n))
    )
    files = []
    for name in names:
        with open(os.path.join(directory, name), "rb") as fh:
            data = fh.read().replace(b"\r\n", b"\n")
        files.append((kind, name, data))
    return files


schema = collect(schema_dir, "schema")
seed = collect(seed_dir, "seed")
if not schema:
    print("sql-dump: SQL/migrations/schema altında hiç .sql yok", file=sys.stderr)
    sys.exit(1)

digest = hashlib.sha256()
for kind, name, data in schema + seed:
    digest.update(kind.encode() + b"\0" + name.encode() + b"\0" + data + b"\n")
src_hash = digest.hexdigest()[:12]

date_note = "yerel"
surum = os.path.join(schema_dir, "..", "SURUM")
if os.path.isfile(surum):
    with open(surum, encoding="utf-8") as fh:
        first = fh.readline().strip()
    if first:
        date_note = first


def section(title, files):
    blocks = []
    for kind, name, data in files:
        marker = f"-- source: SQL/migrations/{kind}/{name}"
        blocks.append(marker + "\n" + data.decode("utf-8").rstrip("\n"))
    body = "\n\n".join(blocks)
    return f"-- ============ {title} ============\n{body}"


header = "\n".join([
    "-- App-Fabrika Web Edition — veritabani.sql (sql-dump.sh ile üretildi)",
    f"-- Kaynak: SQL/migrations/schema ({len(schema)} dosya) + SQL/migrations/seed ({len(seed)} dosya)",
    f"-- Sürüm Tarihi: {date_note} · Kaynak Hash: {src_hash}",
    "-- Deterministik: saat damgası yok — aynı kaynak = byte-identical çıktı",
    "-- Elle DÜZENLEMEYİN: kaynakları SQL/migrations/ altında değiştirin, sonra:",
    "--   bash scripts/web/sql-dump.sh <proje>",
    "",
])

parts = [header, section("SCHEMA", schema)]
if seed:
    parts.append(section("SEED", seed))
text = "\n\n".join(parts) + "\n"

out_dir = os.path.dirname(os.path.abspath(out_path))
os.makedirs(out_dir, exist_ok=True)
with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(text)

print(f"sql-dump: {out_path} ({len(schema)} schema + {len(seed)} seed, hash={src_hash})")
PY
