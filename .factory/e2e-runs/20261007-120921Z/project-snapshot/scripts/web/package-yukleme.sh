#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — Production Deployment & Packager (Phase 5)
# Kullanım: package-yukleme.sh [proje_dizini]
# Ön koşul: qa-gate.sh PASS (0 error, 0 warning) — aksi halde paketleme yasak.
# Çıktı: <proje>/Yukleme/  (§14 ağaç) + <proje>/packaging-report.json
# Opsiyonel: YUKLEME_EXTRA="uploads storage" ile ek üretim dizinleri
# Akış: QA ön kontrol → staging (.factory/yukleme-staging) build → denylist/§14 →
#   smoke-test.sh (lokal php -S, katmanlı) → rapor → PASS: eski Yukleme/ arşive
#   (.factory/yukleme-archive/<ts>-<hash12> + MANIFEST.json; son YUKLEME_ARCHIVE_KEEP,
#   varsayılan 3) taşınır, staging atomik takasla Yukleme/ olur; FAIL: staging →
#   .factory/yukleme-failed (+ FAIL MANIFEST), mevcut Yukleme/ dokunulmadan korunur.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QA_GATE="$ROOT/scripts/web/qa-gate.sh"
SMOKE="$ROOT/scripts/web/smoke-test.sh"
YUKLEME_EXTRA="${YUKLEME_EXTRA:-}"

PROJECT="${1:-.}"
command -v python3 >/dev/null 2>&1 || { echo "packager: python3 gerekli" >&2; exit 1; }
[[ -d "$PROJECT" ]] || { echo "packager: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
OUT="$PROJECT/.factory/yukleme-staging"

if [[ "$OUT" == "$PROJECT" || "$OUT" == "/" || -z "$OUT" ]]; then
  echo "packager: güvensiz çıktı dizini: $OUT" >&2
  exit 1
fi

FAIL_FILE="$(mktemp)"
SKIP_FILE="$(mktemp)"
NOTE_FILE="$(mktemp)"
trap 'rm -f "$FAIL_FILE" "$SKIP_FILE" "$NOTE_FILE"' EXIT

fail() { printf '%s\n' "${1//$'\n'/ }" >> "$FAIL_FILE"; }
skip() { printf '%s\n' "$1" >> "$SKIP_FILE"; }
note() { printf '%s\n' "$1" >> "$NOTE_FILE"; }
fail_count() { wc -l < "$FAIL_FILE" | tr -d ' '; }

tree_hash() { # $1=dizin → içerik hash'i (ad + bayt, sıralı, deterministik)
  python3 - "$1" <<'PY'
import hashlib
import os
import sys

root = sys.argv[1]
h = hashlib.sha256()
for dp, dns, fns in os.walk(root):
    dns.sort()
    for n in sorted(fns):
        p = os.path.join(dp, n)
        h.update(os.path.relpath(p, root).encode("utf-8") + b"\0")
        with open(p, "rb") as fh:
            h.update(fh.read())
        h.update(b"\n")
print(h.hexdigest())
PY
}

write_provenance() { # $1=dizin $2=source_hash $3=smoke_result → MANIFEST.json
  PROV_DIR="$1" PROV_HASH="$2" PROV_SMOKE="$3" python3 - <<'PY'
import datetime
import hashlib
import json
import os

d = os.environ["PROV_DIR"]
sql_p = os.path.join(d, "SQL", "veritabani.sql")
sql_hash = None
if os.path.isfile(sql_p):
    with open(sql_p, "rb") as fh:
        sql_hash = hashlib.sha256(fh.read()).hexdigest()
m = {
    "tool": "package-yukleme",
    "source_hash": os.environ["PROV_HASH"],
    "sql_dump_hash": sql_hash,
    "built_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "smoke_result": os.environ["PROV_SMOKE"],
}
with open(os.path.join(d, "MANIFEST.json"), "w", encoding="utf-8") as fh:
    json.dump(m, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
}

echo "==> QA ön kontrolü (paketleme kapısı): $PROJECT"
rc=0
bash "$QA_GATE" "$PROJECT" || rc=$?
if [[ "$rc" -ne 0 ]]; then
  echo "packager: QA gate PASS değil — Yukleme/ oluşturulamaz (State Graph kuralı 3)" >&2
  exit "$rc"
fi

echo "==> Paketleme (staging): $OUT"
rm -rf "$OUT"
mkdir -p "$OUT"

# --- Whitelist kopya ---
for f in index.php .htaccess robots.txt sitemap.xml; do
  if [[ -f "$PROJECT/$f" ]]; then
    cp "$PROJECT/$f" "$OUT/$f"
  else
    fail "eksik dosya: $f"
  fi
done

for d in core views; do
  if [[ -d "$PROJECT/$d" ]]; then
    cp -R "$PROJECT/$d" "$OUT/$d"
  else
    fail "eksik dizin: $d/"
  fi
done

mkdir -p "$OUT/assets"
for sub in css js images; do
  if [[ -d "$PROJECT/assets/$sub" ]]; then
    cp -R "$PROJECT/assets/$sub" "$OUT/assets/$sub"
  else
    mkdir -p "$OUT/assets/$sub"
    note "boş dizin üretildi: assets/$sub"
  fi
done

# --- Ek üretim dizinleri (opsiyonel) ---
for extra in $YUKLEME_EXTRA; do
  if [[ -e "$PROJECT/$extra" ]]; then
    mkdir -p "$(dirname "$OUT/$extra")"
    cp -R "$PROJECT/$extra" "$OUT/$extra"
    note "ek alandan kopyalandı: $extra"
  else
    fail "YUKLEME_EXTRA bulunamadı: $extra"
  fi
done

# --- SQL: doğrula + kopyala ---
SQL_SRC=""
if [[ -f "$PROJECT/SQL/veritabani.sql" ]]; then
  SQL_SRC="$PROJECT/SQL/veritabani.sql"
else
  while IFS= read -r f; do SQL_SRC="$f"; break; done < <(
    find "$PROJECT" \( -name node_modules -o -name vendor -o -name Yukleme -o -name .factory -o -name .git -o -name '._*' \) -prune \
      -o -type f -name '*.sql' -print | sort
  )
fi
if [[ -z "$SQL_SRC" ]]; then
  fail "SQL/veritabani.sql bulunamadı"
else
  sql_ok=1
  iconv -f UTF-8 -t UTF-8 "$SQL_SRC" >/dev/null 2>&1 || { fail "SQL UTF-8 değil: $SQL_SRC"; sql_ok=0; }
  grep -Eiq 'CREATE TABLE' "$SQL_SRC" || { fail "SQL: CREATE TABLE yok"; sql_ok=0; }
  grep -Eiq 'FOREIGN KEY' "$SQL_SRC" || { fail "SQL: FOREIGN KEY yok"; sql_ok=0; }
  grep -Eiq 'INSERT INTO' "$SQL_SRC" || { fail "SQL: seed INSERT yok"; sql_ok=0; }
  if [[ "$sql_ok" -eq 1 ]]; then
    mkdir -p "$OUT/SQL"
    cp "$SQL_SRC" "$OUT/SQL/veritabani.sql"
  fi
fi

# --- Build isolation: denylist budama (savunma hattı) ---
find "$OUT" -type d \( -name node_modules -o -name .git -o -name .factory -o -name vendor -o -name tests \) \
  -prune -exec rm -rf {} \; 2>/dev/null || true
find "$OUT" -type f \( -name '*.scss' -o -name '*.ts' -o -name '*.tsx' -o -name '*.map' \
  -o -name '.DS_Store' -o -name '._*' -o -name '.env' -o -name '*_test.php' -o -name 'qa-report.json' \
  -o -name 'debug_report.json' -o -name 'packaging-report.json' \) -delete 2>/dev/null || true

# --- Minify (terser/csso varsa; yoksa not düş, geç) ---
shopt -s nullglob
css_files=("$OUT"/assets/css/*.css)
js_files=("$OUT"/assets/js/*.js)
if command -v npx >/dev/null 2>&1; then
  if [[ "${#css_files[@]}" -gt 0 ]]; then
    minified=0
    for f in "${css_files[@]}"; do
      if (cd "$PROJECT" && npx --no-install csso "$f" -o "$f.min" >/dev/null 2>&1); then
        mv "$f.min" "$f"; minified=1
      fi
    done
    if [[ "$minified" -eq 0 ]]; then note "minify: skipped (csso yok — assets/css aynen paketlendi)"; fi
  fi
  if [[ "${#js_files[@]}" -gt 0 ]]; then
    minified=0
    for f in "${js_files[@]}"; do
      if (cd "$PROJECT" && npx --no-install terser "$f" -c -m -o "$f.min" >/dev/null 2>&1); then
        mv "$f.min" "$f"; minified=1
      fi
    done
    if [[ "$minified" -eq 0 ]]; then note "minify: skipped (terser yok — assets/js aynen paketlendi)"; fi
  fi
else
  note "minify: skipped (npx yok)"
fi
shopt -u nullglob

# --- Denylist doğrulama: sızıntı varsa FAIL ---
LEAK="$(find "$OUT" \( -name node_modules -o -name .git -o -name .env -o -name .factory \
  -o -name '*.scss' -o -name '*.ts' -o -name '*.tsx' -o -name '*_test.php' \
  -o -name qa-report.json -o -name debug_report.json -o -name packaging-report.json \
  -o -name .DS_Store -o -name '._*' \) -print 2>/dev/null | head -5 || true)"
if [[ -n "$LEAK" ]]; then
  while IFS= read -r line; do fail "denylist sızıntısı: ${line#"$OUT"/}"; done <<< "$LEAK"
fi

# --- §14 zorunlu ağaç ---
for req in index.php .htaccess robots.txt sitemap.xml core views \
           assets/css assets/js assets/images SQL/veritabani.sql; do
  [[ -e "$OUT/$req" ]] || fail "ağaç eksik: Yukleme/$req"
done

# --- Skipped listesi (proje kökünde üretime girmeyenler) ---
ALLOWED="index.php .htaccess robots.txt sitemap.xml core views assets SQL Yukleme"
while IFS= read -r entry; do
  name="$(basename "$entry")"
  keep=0
  for a in $ALLOWED; do if [[ "$name" == "$a" ]]; then keep=1; fi; done
  for extra in $YUKLEME_EXTRA; do if [[ "$name" == "$extra" ]]; then keep=1; fi; done
  if [[ "$keep" -eq 1 ]]; then continue; fi
  skip "$name"
done < <(find "$PROJECT" -mindepth 1 -maxdepth 1 -not -name '.DS_Store' -not -name '._*' | sort)

# --- Smoke test (staging lokal sunucuda, katmanlı) ---
echo "==> Smoke test (lokal php -S): paket bütünlüğü"
SMOKE_REPORT="$PROJECT/.factory/smoke-report.json"
export SMOKE_REPORT
smoke_rc=0
bash "$SMOKE" "$OUT" || smoke_rc=$?
SMOKE_RES="not-run"
if [[ -f "$SMOKE_REPORT" ]]; then
  SMOKE_RES="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("result","not-run"))' "$SMOKE_REPORT" 2>/dev/null || echo "not-run")"
  while IFS= read -r l; do
    if [[ -n "$l" ]]; then note "$l"; fi
  done < <(
    python3 - "$SMOKE_REPORT" <<'PY'
import json
import sys

r = json.load(open(sys.argv[1], encoding="utf-8"))
for key in ("violations", "notes"):
    for v in r.get(key, []):
        print("smoke: " + v)
PY
  )
fi
if [[ "$smoke_rc" -ne 0 ]]; then
  fail "smoke: paket lokal sunucuda doğrulanamadı — detay: .factory/smoke-report.json"
fi

RESULT="PASS"
if [[ "$(fail_count)" -gt 0 ]]; then RESULT="FAIL"; fi

# --- Rapor ---
export PK_PROJECT="$PROJECT" PK_OUT="$OUT" PK_RESULT="$RESULT" PK_SQL="$SQL_SRC"
export PK_FAIL="$FAIL_FILE" PK_SKIP="$SKIP_FILE" PK_NOTE="$NOTE_FILE"
python3 - <<'PY'
import hashlib, json, os, datetime

project = os.environ["PK_PROJECT"]
out = os.environ["PK_OUT"]
result = os.environ["PK_RESULT"]
sql_src = os.environ["PK_SQL"]


def lines(path):
    with open(path, encoding="utf-8") as fh:
        return [ln for ln in fh.read().splitlines() if ln.strip()]


files = {}
total = 0
for root, dirs, names in os.walk(out):
    dirs.sort()
    for name in sorted(names):
        p = os.path.join(root, name)
        rel = os.path.relpath(p, out)
        with open(p, "rb") as fh:
            digest = hashlib.sha256(fh.read()).hexdigest()
        size = os.path.getsize(p)
        files[rel] = {"sha256": digest, "bytes": size}
        total += size

report = {
    "schema_version": 1,
    "tool": "package-yukleme",
    "version": "1.0.0",
    "project": project,
    "output": os.path.join(project, "Yukleme"),
    "result": result,
    "files_count": len(files),
    "bytes_total": total,
    "sql_source": sql_src or None,
    "sql_output": "SQL/veritabani.sql" if os.path.exists(os.path.join(out, "SQL", "veritabani.sql")) else None,
    "failures": lines(os.environ["PK_FAIL"]),
    "skipped": lines(os.environ["PK_SKIP"]),
    "notes": lines(os.environ["PK_NOTE"]),
    "manifest": files,
    "at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(os.path.join(project, "packaging-report.json"), "w", encoding="utf-8") as fh:
    json.dump(report, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

FINAL="$PROJECT/Yukleme"
echo "==> Paketleme: $RESULT"
if [[ "$RESULT" == "FAIL" ]]; then
  # staging → .factory/yukleme-failed (rollback: mevcut Yukleme/ dokunulmadan korunur)
  if [[ -d "$OUT" ]]; then
    FHASH="$(tree_hash "$OUT")"
    rm -rf "$PROJECT/.factory/yukleme-failed"
    mv "$OUT" "$PROJECT/.factory/yukleme-failed"
    write_provenance "$PROJECT/.factory/yukleme-failed" "$FHASH" "$SMOKE_RES"
  fi
  while IFS= read -r line; do echo "    [hata] $line"; done < "$FAIL_FILE"
  echo "==> Eski Yukleme/ korundu; hatalı paket: .factory/yukleme-failed"
  echo "==> Raporda: $PROJECT/packaging-report.json"
  exit 1
fi

# --- PASS: eski Yukleme/ → arşiv (MANIFEST ile), staging → atomik takas ---
if [[ -d "$FINAL" ]]; then
  AHASH="$(tree_hash "$FINAL")"
  TS="$(date -u +%Y%m%d-%H%M%S)"
  ARCH="$PROJECT/.factory/yukleme-archive/${TS}-${AHASH:0:12}"
  mkdir -p "$PROJECT/.factory/yukleme-archive"
  mv "$FINAL" "$ARCH"
  write_provenance "$ARCH" "$AHASH" "PASS"
  KEEP="${YUKLEME_ARCHIVE_KEEP:-3}"
  if [[ "$KEEP" =~ ^[0-9]+$ ]]; then
    # prune: en yeni KEEP paketi tut (locale bağımsız — head -n -N macOS'ta yok)
    python3 - "$PROJECT/.factory/yukleme-archive" "$KEEP" <<'PY'
import os
import shutil
import sys

d, keep = sys.argv[1], int(sys.argv[2])
entries = sorted(os.listdir(d))
for old in (entries if keep <= 0 else entries[:-keep]):
    shutil.rmtree(os.path.join(d, old), ignore_errors=True)
PY
  fi
fi
mv "$OUT" "$FINAL"

echo "==> Yukleme/ ağacı:"
(cd "$FINAL" && find . -not -name '._*' | sort | sed 's/^/    /' | head -60) || true
echo "==> Rapor: $PROJECT/packaging-report.json (sha256 manifest)"
echo "==> FTP yüklemeye hazır: $FINAL"
exit 0
