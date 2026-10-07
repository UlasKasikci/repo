#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — Orkestratör (State Graph faz sürücüsü)
# Kontrat: .factory/web-state-graph.json · Şemalar: .factory/contracts/*.schema.json
# Kullanım: bash scripts/web/orchestrate.sh <proje_dizini> [--auto] [--strict]
#   --auto   eksik LLM adımlarını `opencode run --format json --agent ...` ile
#            çalıştırır; her çalıştırmadan sonra .factory/metrics.jsonl'a
#            reporter-only metrik satırı eklenir (ts, phase, agent, rc,
#            latency_ms, tokens, events, session, parse_error) — metrik asla
#            exit kodu/gate değiştirmez; parse edilemezse parse_error=true.
#   --strict bütçe alarmı: metrics toplamı STRICT_* eşiklerini (1×) aşarsa
#            "STRICT bütçe:" uyarısı basılır — exit/gate DEĞİŞMEZ (reporter-only).
#            2× sert katman: eşiklerin ikikatını aşan durumda "SERT AŞIM" satırı
#            + exit 1 (duraklatılmış fazdan yeniden çalıştırarak devam edilir).
#            Eşikler env ile override edilebilir (aşağıda varsayılanlar).
# Exit: 0 = DONE · 1 = hata/geçersiz artefakt · 2 = HALT · 3 = bekleme (LLM adımı gerekli)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_SH="$ROOT/scripts/web/state.sh"
QA_GATE="$ROOT/scripts/web/qa-gate.sh"
PACKAGER="$ROOT/scripts/web/package-yukleme.sh"
CONTRACTS="$ROOT/.factory/contracts"

PROJECT="${1:-}"
AUTO=0
STRICT=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --auto) AUTO=1 ;;
    --strict) STRICT=1 ;;
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
  echo "kullanım: orchestrate.sh <proje_dizini> [--auto] [--strict]" >&2
  exit 1
}

[[ -n "$PROJECT" ]] || usage
[[ -d "$PROJECT" ]] || { echo "orkestratör: dizin yok: $PROJECT" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "orkestratör: python3 gerekli" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
STATE_FILE="$PROJECT/.factory/web-state.json"
GUARD=0

# --strict bütçe alarmı (reporter-only — exit/gate asla değişmez).
# Eşik varsayılanları n=2 emprik zeminden (E2E-1/2): P1 0.6–0.9M, P2 3.1–4.2M,
# toplam 4.2–4.8M token, duvar ~2.5s;WD 3s/9M altında pay bırakılır. Env ile override.
STRICT_WARNED=""
ORCH_START_MS="$(python3 -c 'import time; print(int(time.time() * 1000))')"
STRICT_TOTAL_TOKENS="${STRICT_TOTAL_TOKENS:-8000000}"
STRICT_P1_TOKENS="${STRICT_P1_TOKENS:-1500000}"
STRICT_PHASE_TOKENS="${STRICT_PHASE_TOKENS:-6000000}"
STRICT_WALL_MS="${STRICT_WALL_MS:-10800000}"

# NOT: python gövdesi AYRI top-level fonksiyonda — `$( ... <<'PY' )` içinde bash
# $() lexeri heredoc içindeki kesme işareti'yi kaçırıp quote dengesini bozabiliyor.
budget_lines() { # stdout: bütçe satırları (1× uyarı / 2× SERT AŞIM)
  METRICS_FILE="$PROJECT/.factory/metrics.jsonl" \
  STRICT_TOTAL_TOKENS="$STRICT_TOTAL_TOKENS" \
  STRICT_P1_TOKENS="$STRICT_P1_TOKENS" \
  STRICT_PHASE_TOKENS="$STRICT_PHASE_TOKENS" \
  STRICT_WALL_MS="$STRICT_WALL_MS" \
  ORCH_START_MS="$ORCH_START_MS" python3 - <<'PY'
import json
import os
import time

rows = []
path = os.environ.get("METRICS_FILE", "")
try:
    with open(path, encoding="utf-8") as fh:
        for ln in fh:
            ln = ln.strip()
            if ln:
                try:
                    rows.append(json.loads(ln))
                except Exception:
                    pass
except OSError:
    pass


def mil(n):
    return "%.2fM" % (n / 1000000.0)


def emit(label, value, limit, extra=""):
    # 2x → SERT AŞIM (exit 1'e giden sinyal); 1x → yalnız uyarı
    is_token = "token" in label
    fmt = mil if is_token else (lambda v: "%ds" % (v // 1000))
    if value > 2 * limit:
        print("==> STRICT bütçe: %s %s > %s (2x sert sınır) — SERT AŞIM: exit 1%s"
              % (label, fmt(value), fmt(limit), extra))
    elif value > limit:
        print("==> STRICT bütçe: %s %s > %s eşiği — uyarı; gate/exit değişmez%s"
              % (label, fmt(value), fmt(limit), extra))


for r in rows:
    ph = r.get("phase")
    t = int((r.get("tokens") or {}).get("total") or 0)
    if ph == "P1":
        emit("P1 token", t, int(os.environ["STRICT_P1_TOKENS"]),
             " (agent=%s)" % r.get("agent"))
    if ph in ("P2", "P4"):
        emit("%s token" % ph, t, int(os.environ["STRICT_PHASE_TOKENS"]),
             " (agent=%s)" % r.get("agent"))
total = sum(int((r.get("tokens") or {}).get("total") or 0) for r in rows)
emit("toplam token", total, int(os.environ["STRICT_TOTAL_TOKENS"]),
     " (%d satır)" % len(rows))
wall = int(time.time() * 1000) - int(os.environ["ORCH_START_MS"])
emit("duvar süresi", wall, int(os.environ["STRICT_WALL_MS"]))
PY
}

budget_check() { # 1× = WARN (return 0), 2× = SERT AŞIM (return 1); asla exit etmez
  [[ "$STRICT" -eq 1 ]] || return 0
  local out line hard=0
  out="$(budget_lines)" || out=""
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$STRICT_WARNED" in
      *"|$line|"*) continue ;;
    esac
    STRICT_WARNED="${STRICT_WARNED}|$line"
    echo "$line" >&2
    case "$line" in
      *"SERT AŞIM"*) hard=1 ;;
    esac
  done <<< "$out"
  [[ "$hard" -eq 0 ]] || return 1
  return 0
}

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

compliance_mode() { # intent.compliance → kvkk|gdpr|none (tek doğruluk kaynağı .factory/project-intent.json)
  if [[ -f "$PROJECT/.factory/project-intent.json" ]]; then
    COMPLIANCE="$(python3 - "$PROJECT/.factory/project-intent.json" <<'PY'
import json
import sys

try:
    v = json.load(open(sys.argv[1], encoding="utf-8")).get("compliance")
except Exception:
    v = None
print(v if v in ("kvkk", "gdpr") else "none")
PY
    )" || COMPLIANCE="none"
    printf '%s' "$COMPLIANCE"
  else
    printf 'none'
  fi
}

p1_gate_ok() {
  validate_artifact "$1" "$CONTRACTS/p1-domain-report.schema.json" && semantic_domain "$1"
}

record_agent_metrics() { # $1=agent $2=phase $3=rc $4=start_ms $5=end_ms $6=event dosyası
  # reporter-only: text çıktısını stdout'a basar, metrik satırını append eder;
  # hiçbir koşulda non-zero çıkış üretmez (gate değişmez).
  METRICS_FILE="$PROJECT/.factory/metrics.jsonl" \
  MET_AGENT="$1" MET_PHASE="$2" MET_RC="$3" MET_START="$4" MET_END="$5" MET_EV="$6" python3 - <<'PY'
import datetime
import json
import os
import sys

path = os.environ["MET_EV"]
out_path = os.environ["METRICS_FILE"]
events = 0
malformed = 0
tokens = {"input": 0, "output": 0, "total": 0, "reasoning": 0,
          "cache_read": 0, "cache_write": 0}
steps = 0
text_parts = 0
text_chars = 0
session = None
span_first = None
span_last = None
cost = 0.0
parse_error = None
texts = []

try:
    with open(path, encoding="utf-8", errors="replace") as fh:
        for ln in fh:
            ln = ln.strip()
            if not ln:
                continue
            try:
                ev = json.loads(ln)
            except Exception:
                malformed += 1
                continue
            if not isinstance(ev, dict):
                malformed += 1
                continue
            events += 1
            session = ev.get("sessionID") or session
            ts = ev.get("timestamp")
            if isinstance(ts, (int, float)):
                span_first = ts if span_first is None else min(span_first, ts)
                span_last = ts if span_last is None else max(span_last, ts)
            if ev.get("type") == "text":
                part = ev.get("part") or {}
                if isinstance(part.get("text"), str):
                    text_parts += 1
                    text_chars += len(part["text"])
                    texts.append(part["text"])
            elif ev.get("type") == "step_finish":
                steps += 1
                part = ev.get("part") or {}
                tok = part.get("tokens") or {}
                if isinstance(tok, dict):
                    tokens["input"] += int(tok.get("input") or 0)
                    tokens["output"] += int(tok.get("output") or 0)
                    tokens["total"] += int(tok.get("total") or 0)
                    tokens["reasoning"] += int(tok.get("reasoning") or 0)
                    cache = tok.get("cache") or {}
                    tokens["cache_read"] += int(cache.get("read") or 0)
                    tokens["cache_write"] += int(cache.get("write") or 0)
                try:
                    cost += float(part.get("cost") or 0)
                except (TypeError, ValueError):
                    pass
except Exception as exc:  # dosya yok/okunamadı
    parse_error = str(exc)

if events == 0 and parse_error is None:
    parse_error = "no JSON events (stdout boş veya format tanınmadı)"

record = {
    "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "phase": os.environ["MET_PHASE"],
    "agent": os.environ["MET_AGENT"],
    "rc": int(os.environ["MET_RC"]),
    "latency_ms": max(0, int(os.environ["MET_END"]) - int(os.environ["MET_START"])),
    "parse_error": parse_error is not None,
}
if parse_error is None:
    record.update({
        "events": events,
        "steps": steps,
        "session": session,
        "event_span_ms": (int(span_last - span_first)
                          if span_first is not None and span_last is not None else None),
        "tokens": tokens,
        "text_parts": text_parts,
        "text_chars": text_chars,
        "cost": round(cost, 6),
    })
else:
    record["error"] = parse_error
if malformed:
    record["malformed_lines"] = malformed

try:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False) + "\n")
except Exception:
    pass  # metrik asla gate'i etkilemez

for t in texts:
    sys.stdout.write(t if t.endswith("\n") else t + "\n")
PY
}

run_agent() { # $1=agent $2=prompt $3=phase(P1|P2|P4)
  local agent="$1" prompt="$2" phase="${3:-unknown}"
  if ! command -v opencode >/dev/null 2>&1; then
    echo "orkestratör: opencode CLI yok — --auto kullanılamaz" >&2
    return 1
  fi
  echo "==> opencode agent: $agent ($phase)"
  local ev rc=0 start_ms end_ms
  ev="$(mktemp)"
  start_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  CURRENT_EV="$ev" CURRENT_AGENT="$agent" CURRENT_PHASE="$phase" CURRENT_START_MS="$start_ms"
  (cd "$PROJECT" && opencode run --format json --agent "$agent" "$prompt") > "$ev" || rc=$?
  end_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  record_agent_metrics "$agent" "$phase" "$rc" "$start_ms" "$end_ms" "$ev" || true
  if ! budget_check; then
    echo "orkestratör: STRICT bütçe sert aşıldı (2×) — duraklatıldı; yeniden çalıştırarak devam edebilirsin" >&2
    exit 1
  fi
  CURRENT_EV=""
  rm -f "$ev"
  return "$rc"
}

# B4: kill-safe metrik — TERM/INT ile öldürülürken uçuş halindeki çağrı
# satırı metrics.jsonl'e rc=143 olarak düşer (watchdog kill_tree sırası:
# çocuklar önce → trap opencode öldükten sonra koşar, çift satır olmaz).
CURRENT_EV="" CURRENT_AGENT="" CURRENT_PHASE="" CURRENT_START_MS=""
on_kill_metrics() {
  if [[ -n "$CURRENT_EV" && -f "$CURRENT_EV" ]]; then
    local now_ms
    now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
    record_agent_metrics "$CURRENT_AGENT" "$CURRENT_PHASE" 143 \
      "${CURRENT_START_MS:-$now_ms}" "$now_ms" "$CURRENT_EV" || true
    rm -f "$CURRENT_EV"
  fi
  exit 143
}
trap on_kill_metrics TERM INT

scaffold_ok() {
  [[ -f "$PROJECT/index.php" ]] || return 1
  [[ -d "$PROJECT/core" ]] && [[ -n "$(ls -A "$PROJECT/core" 2>/dev/null)" ]] || return 1
  [[ -d "$PROJECT/views" ]] && [[ -n "$(ls -A "$PROJECT/views" 2>/dev/null)" ]] || return 1
  [[ -f "$PROJECT/SQL/veritabani.sql" ]] || return 1
  return 0
}

# B2 (E2E-1/2, write SchemaError: Expected string, got {...}) — tüm üretim ajanlarına
# aynı açık kural; opencode sürümü değil model parametre tipi sorunu.
WRITE_RULE="Araç kuralı: write tool çağrısında content parametresi DÜZ STRING olmalı
(JSON objesi/array DEĞİL); JSON içeriğini string olarak gömün — aksi SchemaError."

p1_prompt() {
  local c
  c="$(compliance_mode)"
  cat <<EOF
P1 (Domain & Scope) analizini uygula — App-Fabrika Web Edition.
Proje dizini: $PROJECT
Kanonik şartname: $ROOT/docs/WEB-EDITION.md (§3 proaktif domain denetimi: RBAC, sepet/sipariş, SEO/KVKK).
Çıktıyı MUTLAKA UTF-8 JSON olarak şu dosyaya yaz: $PROJECT/.factory/domain-report.json
$WRITE_RULE
Şema: $CONTRACTS/p1-domain-report.schema.json
Zorunlu alanlar: schema_version=1, project, entities, roles,
module_matrix (≥4 modül; her hücre: {module, status: present|missing|injected|proposed,
evidence: dosya/satır kaynağı örn. SQL/veritabani.sql:users.role_id veya core/App.php:21 —
adı geçen dosyalar proje kökünde GERÇEKTEN VAR olmalı (domain-check.py fs doğrulaması),
justification: ≥20 karakter gerçek gerekçe} — şablon/boş değer yasak,
qa-gate domain_report denetimini geçirmez),
injected_modules, approvals, edge_cases, security_context,
sql_draft.tables, result="requirements-frozen".
compliance: $c — intent.compliance (enum kvkk|gdpr|none; şemada opsiyonel alan) —
domain-report.compliance alanına aynen yaz; kvkk/gdpr ise module_matrix'te
kvkk modülünü present/injected olarak gerekçelendir.
EOF
}

p2_prompt() {
  local c
  c="$(compliance_mode)"
  cat <<EOF
P2 (Code Generation) — App-Fabrika Web Edition MVC iskeletini tamamla.
Proje dizini: $PROJECT
$WRITE_RULE
Girdi kontratı: $PROJECT/.factory/domain-report.json (P1 çıktısı) — entities[] tablo
adları ve module_matrix kararları (present|injected|missing|proposed) P2 şemasına,
SQL migrations/ ve views/ akışına bağlayıcıdır; görmezden gelme.
Zorunlu yapı: index.php (front-controller), core/ (App, Database, CSRF), views/,
SQL/veritabani.sql (FK + index + seed, UTF-8), assets/css, assets/js.
SQL kaynakları SQL/migrations/{schema,seed}/*.sql altında olsun; dump'ı
\`bash scripts/web/sql-dump.sh .\` ile üret (qa-gate sql_dump drift kapısı byte-identical
ister — elle dump düzenleme FAIL olur).
Araç yapılandırmaları: phpstan.neon.dist (level 8), .eslintrc.json, phpunit.xml + tests/ birim testi.
Güvenlik: PDO prepared statement, htmlspecialchars çıktı, CSRF, PASSWORD_ARGON2ID.
Yalnız $PROJECT dizinine yaz; QA betiklerine dokunma.
EOF
  if [[ "$c" != "none" ]]; then
    cat <<EOF

KVKK/GDPR bloğu (intent.compliance=$c — zorunlu, qa-gate kvkk kanalı denetler):
- views/legal/aydinlatma.php, views/legal/gizlilik.php, views/legal/cerez.php —
  gerçek yasal metinler (yer tutucu değil; KVKK maddeleri/KVKK-GDPR referanslı)
- views/partials/cookie-consent.php + assets/js/cookie-consent.js — çerez onay
  banner'ı: açık rıza, red/onay tercihi, tercih saklama ve tekrar açılma
- SQL/migrations/schema/*_kvkk.sql: user_consents (id, user_id FK cascade, purpose,
  granted, created_at) + anonymization_log (id, user_id, action, basis, performed_at);
  ardından \`bash scripts/web/sql-dump.sh .\` ile dump'ı yeniden üret (drift FAIL)
EOF
  fi
}

p4_prompt() {
  cat <<EOF
P4 (Revision) — QA hatalarını düzelt.
Proje dizini: $PROJECT
$WRITE_RULE
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
  if ! budget_check; then
    echo "orkestratör: STRICT bütçe sert aşıldı (2×) — duraklatıldı; yeniden çalıştırarak devam edebilirsin" >&2
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
          if [[ "$AUTO" -eq 1 ]] && run_agent web-domain-architect "$(p1_prompt)" P1; then
            p1_gate_ok "$R" || { echo "orkestratör: domain-report.json P1 kapısını geçemedi — $S + domain-check.py" >&2; exit 1; }
          else
            echo "orkestratör: domain-report.json P1 kapısını geçemedi — $S + domain-check.py" >&2
            exit 1
          fi
        fi
      else
        if [[ "$AUTO" -eq 1 ]]; then
          run_agent web-domain-architect "$(p1_prompt)" P1 || wait_for "P1: web-domain-architect çalıştırılamadı"
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
          run_agent web-core-engineer "$(p2_prompt)" P2 || wait_for "P2: web-core-engineer çalıştırılamadı"
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
          run_agent web-core-engineer "$(p4_prompt)" P4 || wait_for "P4: web-core-engineer düzeltme yapamadı"
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
