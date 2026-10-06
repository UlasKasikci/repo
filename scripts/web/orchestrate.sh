#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — Orkestratör (State Graph faz sürücüsü)
# Kontrat: .factory/web-state-graph.json · Şemalar: .factory/contracts/*.schema.json
# Kullanım: bash scripts/web/orchestrate.sh <proje_dizini> [--auto]
#   --auto   eksik LLM adımlarını `opencode run --agent ...` ile çalıştırır
# Exit: 0 = DONE · 1 = hata/geçersiz artefakt · 2 = HALT · 3 = bekleme (LLM adımı gerekli)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_SH="$ROOT/scripts/web/state.sh"
QA_GATE="$ROOT/scripts/web/qa-gate.sh"
PACKAGER="$ROOT/scripts/web/package-yukleme.sh"
CONTRACTS="$ROOT/.factory/contracts"

PROJECT="${1:-}"
AUTO=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --auto) AUTO=1 ;;
    -*) echo "orkestratör: bilinmeyen bayrak: $arg" >&2; exit 1 ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
PROJECT="${POSITIONAL[0]:-}"
if [[ "${#POSITIONAL[@]}" -gt 1 ]]; then
  echo "orkestratör: fazla argüman: ${POSITIONAL[*]:1}" >&2
  exit 1
fi

usage() {
  echo "kullanım: orchestrate.sh <proje_dizini> [--auto]" >&2
  exit 1
}

[[ -n "$PROJECT" ]] || usage
[[ -d "$PROJECT" ]] || { echo "orkestratör: dizin yok: $PROJECT" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "orkestratör: python3 gerekli" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
STATE_FILE="$PROJECT/.factory/web-state.json"
GUARD=0

wait_for() {
  echo "==> BEKLEME (exit 3): $1" >&2
  echo "    İlgili ajanı çalıştır veya --auto ile orchestrate.sh tekrar çalıştır." >&2
  exit 3
}

validate_artifact() {
  python3 - "$1" "$2" <<'PY'
import json, sys

doc_path, schema_path = sys.argv[1], sys.argv[2]
try:
    with open(doc_path, encoding="utf-8") as fh:
        doc = json.load(fh)
except Exception as exc:
    print(f"geçersiz JSON: {exc}", file=sys.stderr)
    sys.exit(1)
try:
    with open(schema_path, encoding="utf-8") as fh:
        schema = json.load(fh)
except Exception as exc:
    print(f"şema okunamadı: {exc}", file=sys.stderr)
    sys.exit(1)

try:
    import jsonschema
except ImportError:
    jsonschema = None

if jsonschema is not None:
    try:
        jsonschema.validate(doc, schema)
        sys.exit(0)
    except jsonschema.ValidationError as exc:
        path = "/".join(str(p) for p in exc.absolute_path) or "<kök>"
        print(f"şema ihlali: {exc.message} (yol: {path})", file=sys.stderr)
        sys.exit(1)

errs = []


def check(val, sch, path):
    if "const" in sch and val != sch["const"]:
        errs.append(f"{path}: {sch['const']!r} beklenir, bulundu: {val!r}")
    if "enum" in sch and val not in sch["enum"]:
        errs.append(f"{path}: {sch['enum']!r} geçerli, bulundu: {val!r}")
    typ = sch.get("type")
    if typ == "object" and isinstance(val, dict):
        for key in sch.get("required", []):
            if key not in val:
                errs.append(f"{path}.{key}: zorunlu alan eksik")
        for key, sub in sch.get("properties", {}).items():
            if key in val:
                check(val[key], sub, f"{path}.{key}")
    elif typ == "array" and isinstance(val, list):
        min_items = int(sch.get("minItems", 0))
        if len(val) < min_items:
            errs.append(f"{path}: en az {min_items} öğe gerekli")
        items = sch.get("items")
        if isinstance(items, dict):
            for i, item in enumerate(val):
                check(item, items, f"{path}[{i}]")
    elif typ == "string" and not isinstance(val, str):
        errs.append(f"{path}: tip string beklenir, {type(val).__name__} bulundu")
    elif typ == "string" and "minLength" in sch and len(val) < int(sch["minLength"]):
        errs.append(f"{path}: en az {sch['minLength']} karakter gerekir ({len(val)} bulundu)")
    elif typ == "integer" and not isinstance(val, int):
        errs.append(f"{path}: tip integer beklenir, {type(val).__name__} bulundu")


check(doc, schema, "$")
if errs:
    print("\n".join(errs), file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

read_state() {
  python3 - "$STATE_FILE" <<'PY'
import json, os, sys
path = sys.argv[1]
if not os.path.exists(path):
    print("NONE in_progress")
    sys.exit(0)
try:
    with open(path, encoding="utf-8") as fh:
        state = json.load(fh)
except (OSError, json.JSONDecodeError):
    print("BOZUK in_progress")
    sys.exit(0)
print(state.get("current_phase", "NONE"), state.get("status", "in_progress"))
PY
}

get_retry() {
  python3 - "$STATE_FILE" <<'PY'
import json, os, sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as fh:
        print(int(json.load(fh).get("retry_count", 0) or 0))
except Exception:
    print(0)
PY
}

semantic_domain() {
  python3 "$ROOT/scripts/web/domain-check.py" "$1" "$PROJECT"
}

p1_gate_ok() {
  validate_artifact "$1" "$CONTRACTS/p1-domain-report.schema.json" && semantic_domain "$1"
}

run_agent() {
  local agent="$1" prompt="$2"
  if ! command -v opencode >/dev/null 2>&1; then
    echo "orkestratör: opencode CLI yok — --auto kullanılamaz" >&2
    return 1
  fi
  echo "==> opencode agent: $agent"
  (cd "$PROJECT" && opencode run --agent "$agent" "$prompt")
}

scaffold_ok() {
  [[ -f "$PROJECT/index.php" ]] || return 1
  [[ -d "$PROJECT/core" ]] && [[ -n "$(ls -A "$PROJECT/core" 2>/dev/null)" ]] || return 1
  [[ -d "$PROJECT/views" ]] && [[ -n "$(ls -A "$PROJECT/views" 2>/dev/null)" ]] || return 1
  [[ -f "$PROJECT/SQL/veritabani.sql" ]] || return 1
  return 0
}

p1_prompt() {
  cat <<EOF
P1 (Domain & Scope) analizini uygula — App-Fabrika Web Edition.
Proje dizini: $PROJECT
Kanonik şartname: $ROOT/docs/WEB-EDITION.md (§3 proaktif domain denetimi: RBAC, sepet/sipariş, SEO/KVKK).
Çıktıyı MUTLAKA UTF-8 JSON olarak şu dosyaya yaz: $PROJECT/.factory/domain-report.json
Şema: $CONTRACTS/p1-domain-report.schema.json
Zorunlu alanlar: schema_version=1, project, entities, roles,
module_matrix (≥4 modül; her hücre: {module, status: present|missing|injected|proposed,
evidence: dosya/satır kaynağı örn. SQL/veritabani.sql:users.role_id veya core/App.php:21 —
adı geçen dosyalar proje kökünde GERÇEKTEN VAR olmalı (domain-check.py fs doğrulaması),
justification: ≥20 karakter gerçek gerekçe} — şablon/boş değer yasak,
qa-gate domain_report denetimini geçirmez),
injected_modules, approvals, edge_cases, security_context,
sql_draft.tables, result="requirements-frozen".
EOF
}

p2_prompt() {
  cat <<EOF
P2 (Code Generation) — App-Fabrika Web Edition MVC iskeletini tamamla.
Proje dizini: $PROJECT
Zorunlu yapı: index.php (front-controller), core/ (App, Database, CSRF), views/,
SQL/veritabani.sql (FK + index + seed, UTF-8), assets/css, assets/js.
SQL kaynakları SQL/migrations/{schema,seed}/*.sql altında olsun; dump'ı
\`bash scripts/web/sql-dump.sh .\` ile üret (qa-gate sql_dump drift kapısı byte-identical
ister — elle dump düzenleme FAIL olur).
Araç yapılandırmaları: phpstan.neon.dist (level 8), .eslintrc.json, phpunit.xml + tests/ birim testi.
Güvenlik: PDO prepared statement, htmlspecialchars çıktı, CSRF, PASSWORD_ARGON2ID.
Yalnız $PROJECT dizinine yaz; QA betiklerine dokunma.
EOF
}

p4_prompt() {
  cat <<EOF
P4 (Revision) — QA hatalarını düzelt.
Proje dizini: $PROJECT
Girdi: $PROJECT/qa-report.json ve $PROJECT/debug_report.json (errors[] listesi).
Hedef: bash scripts/web/qa-gate.sh ile 0 Error, 0 Warning.
Yalnız proje dosyalarını düzenle; scripts/web/* betiklerine ve .factory/ kontratlarına dokunma.
EOF
}

echo "==> Orkestratör: $PROJECT (auto=$AUTO)"

while true; do
  GUARD=$((GUARD + 1))
  if [[ "$GUARD" -gt 32 ]]; then
    echo "orkestratör: döngü sınırı aşıldı (32) — mimari durduruldu" >&2
    exit 1
  fi

  if [[ ! -f "$STATE_FILE" ]]; then
    bash "$STATE_SH" start "$PROJECT" >/dev/null
  fi

  read -r PHASE STATUS <<< "$(read_state)" || true
  PHASE="${PHASE:-NONE}"

  if [[ "$PHASE" == "BOZUK" ]]; then
    echo "orkestratör: bozuk state dosyası: $STATE_FILE" >&2
    exit 1
  fi
  if [[ "$STATUS" == "halted" || "$PHASE" == "HALT" ]]; then
    echo "orkestratör: HALT durumu (faz=$PHASE) — debug_report.json'ı incele" >&2
    exit 2
  fi

  case "$PHASE" in
    P1)
      R="$PROJECT/.factory/domain-report.json"
      S="$CONTRACTS/p1-domain-report.schema.json"
      if [[ -f "$R" ]]; then
        if ! p1_gate_ok "$R"; then
          if [[ "$AUTO" -eq 1 ]] && run_agent web-domain-architect "$(p1_prompt)"; then
            p1_gate_ok "$R" || { echo "orkestratör: domain-report.json P1 kapısını geçemedi — $S + domain-check.py" >&2; exit 1; }
          else
            echo "orkestratör: domain-report.json P1 kapısını geçemedi — $S + domain-check.py" >&2
            exit 1
          fi
        fi
      else
        if [[ "$AUTO" -eq 1 ]]; then
          run_agent web-domain-architect "$(p1_prompt)" || wait_for "P1: web-domain-architect çalıştırılamadı"
          [[ -f "$R" ]] || wait_for "P1: $R üretilmedi"
          p1_gate_ok "$R" || { echo "orkestratör: domain-report.json P1 kapısını geçemedi — $S + domain-check.py" >&2; exit 1; }
        else
          wait_for "P1: eksik artefakt .factory/domain-report.json (web-domain-architect)"
        fi
      fi
      bash "$STATE_SH" advance "$PROJECT" >/dev/null
      echo "==> P1 → P2 (requirements-frozen)"
      ;;

    P2)
      if ! scaffold_ok; then
        if [[ "$AUTO" -eq 1 ]]; then
          run_agent web-core-engineer "$(p2_prompt)" || wait_for "P2: web-core-engineer çalıştırılamadı"
          scaffold_ok || wait_for "P2: MVC iskeleti eksik (index.php, core/, views/, SQL/veritabani.sql)"
        else
          wait_for "P2: MVC iskeleti eksik (web-core-engineer)"
        fi
      fi
      bash "$STATE_SH" advance "$PROJECT" >/dev/null
      echo "==> P2 → P3 (code-complete)"
      ;;

    P3|P4)
      if [[ "$PHASE" == "P4" ]]; then
        if [[ "$AUTO" -eq 1 ]]; then
          run_agent web-core-engineer "$(p4_prompt)" || wait_for "P4: web-core-engineer düzeltme yapamadı"
        else
          wait_for "P4: revision bekleniyor (retry $(get_retry)/3 — web-core-engineer)"
        fi
      fi
      rc=0
      bash "$QA_GATE" "$PROJECT" --record || rc=$?
      case "$rc" in
        0) echo "==> QA PASS $PHASE → P5" ;;
        2) echo "orkestratör: HALT — 4. QA başarısızlığı, debug_report.json" >&2; exit 2 ;;
        1)
          if [[ "$AUTO" -eq 1 ]]; then
            continue
          fi
          wait_for "QA FAIL (retry $(get_retry)/3) — qa-report.json hatalarını düzelt"
          ;;
        *) echo "orkestratör: qa-gate beklenmeyen çıkış: $rc" >&2; exit 1 ;;
      esac
      ;;

    P5)
      rc=0
      bash "$PACKAGER" "$PROJECT" || rc=$?
      if [[ "$rc" -ne 0 ]]; then
        echo "orkestratör: paketleme başarısız (exit $rc)" >&2
        exit "$rc"
      fi
      bash "$STATE_SH" advance "$PROJECT" >/dev/null
      echo "==> ORCHESTRATE: DONE — $PROJECT"
      echo "    qa-report.json + packaging-report.json + Yukleme/ üretildi"
      exit 0
      ;;

    DONE)
      echo "==> ORCHESTRATE: zaten DONE — $PROJECT"
      exit 0
      ;;

    *)
      echo "orkestratör: bilinmeyen faz: $PHASE" >&2
      exit 1
      ;;
  esac
done
