#!/usr/bin/env bash
set -euo pipefail

# Webrail — State Graph kontrolcüsü
# Kontrat: .factory/web-state-graph.json  ·  Durum: <proje>/.factory/web-state.json
# Exit: 0 = OK · 1 = geçersiz geçiş/hata · 2 = HALT

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GRAPH="$ROOT/.factory/web-state-graph.json"

usage() {
  echo "kullanım: state.sh <status|start|advance|qa-pass|qa-fail|halt|questions> [proje_dizini] [--reset (yalnız start)]" >&2
  exit 1
}

OP="${1:-}"
PROJECT="${2:-.}"

# Tur 2-16 D: `--reset` yalnız start ile (varolan state'i yedekleyip sıfırlar).
RESET=0
if [[ $# -gt 2 ]]; then
  for _ARG in "${@:3}"; do
    case "$_ARG" in
      --reset) RESET=1 ;;
      *) echo "state: bilinmeyen argüman: $_ARG" >&2; usage ;;
    esac
  done
fi

[[ -n "$OP" ]] || usage
if [[ "$OP" == "retry" ]]; then OP="qa-fail"; fi
case "$OP" in
  status|start|advance|qa-pass|qa-fail|halt|questions) ;;
  *) echo "state: bilinmeyen işlem: $OP" >&2; usage ;;
esac
if [[ "$RESET" -eq 1 && "$OP" != "start" ]]; then
  echo "state: --reset yalnız start ile kullanılır" >&2
  usage
fi

command -v python3 >/dev/null 2>&1 || { echo "state: python3 gerekli" >&2; exit 1; }
[[ -d "$PROJECT" ]] || { echo "state: dizin yok: $PROJECT" >&2; exit 1; }
[[ -f "$GRAPH" ]] || { echo "state: kontrat yok: $GRAPH" >&2; exit 1; }

PROJECT="$(cd "$PROJECT" && pwd)"
export _ST_OP="$OP" _ST_PROJECT="$PROJECT" _ST_GRAPH="$GRAPH" _ST_RESET="$RESET"

# Şerit kilidi: discovery iken state geçişleri (start/advance/qa-*) kapalı
# status her zaman serbest; mode.json yoksa factory (eski projeler).
if [[ "$OP" != "status" ]]; then
  bash "$ROOT/scripts/web/mode.sh" require-factory "$PROJECT" || exit 1
fi

# C.2 (Tur 2-15): advance öncesi fazı yakala — hybrid marker'ından manel P2
# süresi python geçişten sonra (başarılı ise) hesaplanacak.
PRE_PHASE=""
if [[ "$OP" == "advance" ]]; then
  PRE_PHASE="$(python3 -c "import json,sys
try:
    print(json.load(open('$PROJECT/.factory/web-state.json'))['current_phase'])
except Exception:
    print('')" 2>/dev/null || true)"
fi

python3 - <<'PY'
import datetime, json, os, shutil, subprocess, sys

op = os.environ["_ST_OP"]
project = os.environ["_ST_PROJECT"]
graph_path = os.environ["_ST_GRAPH"]
state_path = os.path.join(project, ".factory", "web-state.json")

try:
    with open(graph_path, encoding="utf-8") as fh:
        graph = json.load(fh)
except (OSError, json.JSONDecodeError) as exc:
    print(f"state: kontrat okunamadı: {exc}", file=sys.stderr)
    sys.exit(1)

max_retries = int(graph.get("max_retries", 3))


def die(msg, code=1):
    print(f"state: {msg}", file=sys.stderr)
    sys.exit(code)


def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_state():
    if not os.path.exists(state_path):
        return None
    try:
        with open(state_path, encoding="utf-8") as fh:
            state = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        die(f"bozuk state dosyası: {state_path}: {exc}")
    if not isinstance(state, dict) or "current_phase" not in state:
        die(f"geçersiz state şeması: {state_path}")
    return state


def save_state(state):
    os.makedirs(os.path.dirname(state_path), exist_ok=True)
    tmp = state_path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(state, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    os.replace(tmp, state_path)


def log(state, event, **kw):
    state.setdefault("history", []).append(dict({"at": now(), "event": event}, **kw))


def require_state():
    state = load_state()
    if state is None:
        die(f"state yok: {state_path} — önce `state.sh start`")
    if state.get("status") == "halted" and op != "status":
        die(f"HALT durumu (retry={state.get('retry_count')}) — yeniden `state.sh start --reset` gerekir", 2)
    return state


if op == "status":
    state = load_state()
    if state is None:
        die("state yok — `state.sh start` ile başlat")
    print(json.dumps(state, ensure_ascii=False, indent=2))
    sys.exit(0)

if op == "start":
    # Tur 2-16 D (ChatGPT 3.2): varolan state SİLGİ — yalnız açık `--reset` ile;
    # önce web-state.backup-<ts>.json'a yedek (geri alınabilirlik).
    existing = load_state()
    reset = os.environ.get("_ST_RESET", "0") == "1"
    if existing is not None and not reset:
        die("state zaten var: %s — kaybı önlemek için `state.sh start --reset` "
            "(mevcut durum .factory/web-state.backup-<ts>.json'a yedeklenir)" % state_path)
    backup_path = None
    if existing is not None:
        ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%SZ")
        backup_path = os.path.join(project, ".factory", f"web-state.backup-{ts}.json")
        shutil.copy2(state_path, backup_path)
    state = {
        "schema_version": 1,
        "project": os.path.basename(project),
        "current_phase": "P1",
        "status": "in_progress",
        "retry_count": 0,
        "max_retries": max_retries,
        "last_error": None,
        "history": [],
    }
    log(state, "start", phase="P1")
    if backup_path:
        log(state, "reset-backup", backup=os.path.basename(backup_path))
    save_state(state)
    msg = "state: P1 başladı (retry=0)"
    if backup_path:
        msg += f" · önceki state yedeklendi: {backup_path}"
    print(msg)
    sys.exit(0)

state = require_state()
phase = state.get("current_phase")

if op == "advance":
    nxt = {"P1": "P2", "P2": "P3"}.get(phase)
    if nxt is None:
        if phase == "P3":
            die("P3 → P5 yalnız `qa-pass` ile (qa-gate.sh --record PASS)")
        if phase == "P4":
            die("P4 → düzeltme sonrası `qa-pass` veya `qa-fail` beklenir")
        if phase == "P5":
            pkg_path = os.path.join(project, "packaging-report.json")
            if not os.path.exists(pkg_path):
                die("P5 → DONE yalnız paketleme raporu varken geçerli "
                    "(önce `package-yukleme.sh` → packaging-report.json)")
            try:
                with open(pkg_path, encoding="utf-8") as fh:
                    pkg = json.load(fh)
            except (OSError, json.JSONDecodeError) as exc:
                die(f"packaging-report.json okunamadı: {exc}")
            if pkg.get("result") != "PASS":
                die("packaging-report.json result != PASS — yükleme doğrulanamadı")
            state["current_phase"] = "DONE"
            state["status"] = "done"
            state["last_error"] = None
            log(state, "advance", **{"from": "P5", "to": "DONE", "condition": "yukleme-verified"})
            save_state(state)
            print("state: P5 → DONE (yukleme-verified)")
            sys.exit(0)
        die(f"geçersiz faz: {phase}")
    # Tur 2-16 C (ChatGPT 3.1): P1 → P2 kapı artefaktı — MUTATION ÖNCESİ,
    # state değiştirmeden durur (exit 1 + stderr; stdout boş kanal kontratı).
    if phase == "P1":
        report_path = os.path.join(project, ".factory", "domain-report.json")
        if not os.path.exists(report_path):
            die("P1 → P2 kapı artefaktı yok: .factory/domain-report.json "
                "(Domain Architect raporu zorunlu — domain-report olmadan P2'ye geçilmez)")
        checker = os.path.join(os.path.dirname(graph_path), os.pardir,
                               "scripts", "web", "domain-check.py")
        if not os.path.isfile(checker):
            die(f"domain-check.py bulunamadı: {checker}")
        proc = subprocess.run(
            ["python3", checker, report_path, project],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            detail = next(
                (ln for ln in (proc.stderr + "\n" + proc.stdout).splitlines() if ln.strip()),
                f"exit {proc.returncode}",
            )
            die(f"P1 domain raporu geçersiz — advance engellendi: {detail}")
    state["current_phase"] = nxt
    log(state, "advance", **{"from": phase, "to": nxt})
    save_state(state)
    print(f"state: {phase} → {nxt}")
    sys.exit(0)

if op == "qa-pass":
    if phase not in ("P3", "P4"):
        die(f"qa-pass yalnız P3/P4'te geçerli (şimdi: {phase})")
    state["current_phase"] = "P5"
    state["status"] = "in_progress"
    state["last_error"] = None
    log(state, "qa-pass", **{"from": phase, "to": "P5"})
    save_state(state)
    print(f"state: QA PASS {phase} → P5 (paketleme kapısı açık)")
    sys.exit(0)

# A1 (K4 runtime güvencesi): P2 → P1 yalnız QUESTIONS.json kanalıyla (tek istisna).
# Geçiş grafiğinde condition=questions-asked, artifact=.factory/contracts/QUESTIONS.json.
if op == "questions":
    if phase != "P2":
        die(f"questions yalnız P2'de geçerli (şimdi: {phase})")
    state["current_phase"] = "P1"
    log(state, "questions", **{"from": "P2", "to": "P1",
                               "condition": "questions-asked",
                               "artifact": ".factory/contracts/QUESTIONS.json"})
    save_state(state)
    print("state: P2 → P1 (questions-asked)")
    sys.exit(0)

if op == "qa-fail":
    if phase == "P5":
        die("P5'te qa-fail geçersiz — paketleme QA sonrası fazdır")
    state["retry_count"] = int(state.get("retry_count", 0)) + 1
    state["last_error"] = "qa-fail"
    if state["retry_count"] > max_retries:
        state["status"] = "halted"
        state["current_phase"] = "P4"
        state["last_error"] = f"max_retries aşıldı ({state['retry_count']} > {max_retries})"
        log(state, "halt", retry_count=state["retry_count"], max_retries=max_retries)
        save_state(state)
        # HALT kanıtı: qa-gate ile aynı şemada debug_report.json üret (mesajla söz
        # verilen dosyayı gerçekten yaz)
        debug_report = {
            "schema_version": 1,
            "tool": "state.sh",
            "kind": "debug_report",
            "project": project,
            "phase": "P4",
            "halted": True,
            "retry_count": state["retry_count"],
            "max_retries": max_retries,
            "errors": [f"max_retries aşıldı ({state['retry_count']} > {max_retries})"],
            "warnings": [],
            "approved_exceptions": [],
            "checks": {},
            "next_actions": [
                "HALT: max_retries aşıldı — mimari durdu",
                "debug_report.json dosyasını geliştiriciye sun",
                "Kök nedeni çözmeden P5 (paketleme) yasak",
            ],
            "at": now(),
        }
        dr_path = os.path.join(project, "debug_report.json")
        with open(dr_path, "w", encoding="utf-8") as fh:
            json.dump(debug_report, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(
            f"state: HALT — {state['retry_count']}. başarısızlık, max_retries={max_retries} aşıldı; "
            f"debug_report.json üretildi ve mimari durdu",
            file=sys.stderr,
        )
        sys.exit(2)
    state["current_phase"] = "P4"
    log(state, "qa-fail", retry_count=state["retry_count"], max_retries=max_retries)
    save_state(state)
    print(
        f"state: QA FAIL #{state['retry_count']}/{max_retries} → P4 (revision döngüsü)",
    )
    sys.exit(0)

if op == "halt":
    state["status"] = "halted"
    state["last_error"] = "manuel halt"
    log(state, "halt", reason="manual")
    save_state(state)
    print("state: HALT yazıldı", file=sys.stderr)
    sys.exit(2)

die(f"işlenemedi: {op}")
PY

# C.2 (Tur 2-15): başarılı P2 → P3 geçişinde hybrid marker'ından manel P2 süresi
# (dakika) metrics.jsonl'e yazılır ve marker temizlenir. Agent satırlarından
# ayrık `kind: measure` satırı — asla geçişin kendisini etkilemez (|| true).
if [[ "$OP" == "advance" && "$PRE_PHASE" == "P2" ]]; then
  _MARKER="$PROJECT/.factory/hybrid-p2-start"
  if [[ -f "$_MARKER" ]]; then
    _START="$(tr -cd '0-9' < "$_MARKER" 2>/dev/null || true)"
    [[ -n "$_START" ]] || _START=0
    _NOW="$(date +%s)"
    _MIN=$(( (_NOW - _START) / 60 ))
    [[ "$_MIN" -ge 0 ]] || _MIN=0
    bash "$ROOT/scripts/web/measure.sh" "$PROJECT" manual_p2_min "$_MIN" P2 || true
    rm -f "$_MARKER"
  fi
fi

# P1 → P2: Decision Layer (orchestrate dışı advance'te de karar üret)
if [[ "$OP" == "advance" && "$PRE_PHASE" == "P1" ]]; then
  bash "$ROOT/scripts/web/decide.sh" "$PROJECT" || {
    echo "state: decide.sh başarısız — decision.json olmadan P2 riskli" >&2
    exit 1
  }
fi

# Handoff: başarılı state yazımlarından sonra RUN-STATUS.md (IDE/personel devamı)
if [[ "$OP" != "status" ]]; then
  bash "$ROOT/scripts/web/run-status.sh" "$PROJECT" || true
fi
