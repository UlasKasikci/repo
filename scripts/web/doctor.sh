#!/usr/bin/env bash
set -euo pipefail

# Webrail Error Doctor — hata tespit → tarif → güvenli apply → (isteğe) qa yeniden
# Kullanım:
#   bash scripts/web/doctor.sh <proje>              # teşhis + FIX-BRIEF
#   bash scripts/web/doctor.sh <proje> --apply      # yalnız safe_apply tarifler
#   bash scripts/web/doctor.sh <proje> --loop       # apply → qa-gate döngüsü (max 3)
#   bash scripts/web/doctor.sh <proje> --qa-first   # önce qa-gate çalıştır
# Exit: 0 PASS/temiz · 1 kalan hata · 2 HALT/kullanım
#
# Fark (katalog skill sitelerinden): metin “debugging skill” değil — qa-report
# kanıtına bağlı deterministik tarif + token-ucuz FIX-BRIEF.md.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
shift || true
APPLY=0
LOOP=0
QA_FIRST=0
MAX_LOOP=3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --loop) LOOP=1; APPLY=1; shift ;;
    --qa-first) QA_FIRST=1; shift ;;
    --max) MAX_LOOP="${2:-3}"; shift 2 ;;
    -h|--help)
      sed -n '4,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "doctor: bilinmeyen: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$PROJECT" ]] || { echo "doctor: dizin yok: $PROJECT" >&2; exit 2; }
PROJECT="$(cd "$PROJECT" && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "doctor: python3 gerekli" >&2; exit 2; }

FAC="$PROJECT/.factory"
mkdir -p "$FAC"
RECIPES="$PROJECT/.factory/contracts/doctor-recipes.json"
[[ -f "$RECIPES" ]] || RECIPES="$ROOT/.factory/contracts/doctor-recipes.json"
[[ -f "$RECIPES" ]] || { echo "doctor: doctor-recipes.json yok" >&2; exit 2; }

FIX="$ROOT/tests/fixtures/web-sample"
MOD_ROOT="$PROJECT/.factory/modules"
[[ -d "$MOD_ROOT/auth-rbac" ]] || MOD_ROOT="$ROOT/.factory/modules"
QA="$ROOT/scripts/web/qa-gate.sh"
SQL_DUMP="$ROOT/scripts/web/sql-dump.sh"
MEASURE="$ROOT/scripts/web/measure.sh"

run_qa() {
  bash "$QA" "$PROJECT" >/dev/null 2>&1 || true
}

if [[ "$QA_FIRST" -eq 1 ]] || [[ ! -f "$PROJECT/qa-report.json" ]]; then
  echo "==> doctor: qa-gate önce"
  run_qa
fi

export _D_PROJECT="$PROJECT" _D_RECIPES="$RECIPES" _D_FIX="$FIX" \
       _D_MOD="$MOD_ROOT" _D_ROOT="$ROOT" _D_APPLY="$APPLY" \
       _D_LOOP="$LOOP" _D_MAX="$MAX_LOOP" _D_QA="$QA" \
       _D_SQL="$SQL_DUMP" _D_MEASURE="$MEASURE"

python3 - <<'PY'
import json, os, shutil, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

project = Path(os.environ["_D_PROJECT"])
recipes_path = Path(os.environ["_D_RECIPES"])
fix = Path(os.environ["_D_FIX"])
mod_root = Path(os.environ["_D_MOD"])
root = Path(os.environ["_D_ROOT"])
do_apply = os.environ["_D_APPLY"] == "1"
do_loop = os.environ["_D_LOOP"] == "1"
max_loop = int(os.environ.get("_D_MAX") or "3")
qa_sh = os.environ["_D_QA"]
sql_sh = os.environ["_D_SQL"]
measure_sh = os.environ.get("_D_MEASURE") or ""

recipes_doc = json.loads(recipes_path.read_text(encoding="utf-8"))
recipes = recipes_doc.get("recipes") or []


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_qa():
    for cand in (project / "qa-report.json", project / ".factory" / "qa-report.json"):
        if cand.is_file():
            try:
                return json.loads(cand.read_text(encoding="utf-8")), cand
            except Exception:
                pass
    return None, None


def match_recipe(err: str):
    low = err.lower()
    for r in recipes:
        if r.get("id") == "unknown":
            continue
        for m in r.get("match") or []:
            if m.lower() in low:
                return r
    for r in recipes:
        if r.get("id") == "unknown":
            return r
    return {"id": "unknown", "safe_apply": False, "action": "brief", "fix": "manuel"}


def copy_file(rel: str) -> bool:
    src = fix / rel
    dst = project / rel
    if not src.is_file():
        return False
    if dst.exists():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return True


def apply_module(name: str) -> list[str]:
    done = []
    pkg = mod_root / name
    files = pkg / "files"
    if not files.is_dir():
        return done
    for src in files.rglob("*"):
        if not src.is_file():
            continue
        rel = src.relative_to(files)
        dst = project / rel
        if dst.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        done.append(str(rel))
    return done


def apply_mvc() -> list[str]:
    done = []
    for rel in (
        "index.php", ".htaccess", "core/App.php", "core/Database.php",
        "views/home.php", "assets/css/app.css", "assets/js/app.js",
        "robots.txt", "sitemap.xml",
    ):
        if copy_file(rel):
            done.append(rel)
    # core/views dirs ensured by files
    return done


def apply_recipe(r: dict, err: str) -> dict:
    action = r.get("action")
    applied = []
    skipped = []
    note = ""
    if action == "sql_dump" or action == "sql_dump_or_brief":
        mig = project / "SQL" / "migrations"
        if mig.is_dir() and any(mig.rglob("*.sql")):
            rc = subprocess.call(["bash", sql_sh, str(project)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if rc == 0:
                applied.append("sql-dump.sh")
            else:
                skipped.append("sql-dump failed")
                note = "sql-dump rc!=0"
        else:
            skipped.append("no migrations")
            note = "SQL/migrations yok — LLM P2"
    elif action == "copy_fixture":
        for f in r.get("files") or []:
            if copy_file(f):
                applied.append(f)
            else:
                skipped.append(f)
    elif action == "copy_mvc_skeleton":
        applied.extend(apply_mvc())
        if not applied:
            skipped.append("already present or fixture missing")
    elif action == "module_apply":
        name = r.get("module") or ""
        files = apply_module(name)
        if files:
            applied.extend(files[:5])
            if len(files) > 5:
                applied.append(f"...+{len(files)-5}")
            note = f"module={name} n={len(files)}"
        else:
            skipped.append(name or "module")
            note = "paket yok veya dosyalar mevcut"
    else:
        skipped.append("brief-only")
        note = r.get("fix") or ""
    return {
        "recipe": r.get("id"),
        "error": err,
        "safe": bool(r.get("safe_apply")),
        "applied": applied,
        "skipped": skipped,
        "note": note,
        "fix": r.get("fix"),
        "tokens_note": r.get("tokens_note"),
    }


def diagnose(errors: list[str]) -> list[dict]:
    out = []
    seen = set()
    for err in errors:
        r = match_recipe(err)
        key = (r.get("id"), err)
        if key in seen:
            continue
        seen.add(key)
        out.append({
            "recipe": r.get("id"),
            "error": err,
            "safe_apply": bool(r.get("safe_apply")),
            "action": r.get("action"),
            "fix": r.get("fix"),
            "tokens_note": r.get("tokens_note"),
            "module": r.get("module"),
        })
    return out


def write_brief(diags: list[dict], remaining: list[str]) -> Path:
    lines = [
        "# Webrail FIX-BRIEF (Error Doctor)",
        "",
        f"Proje: `{project.name}` · {now()}",
        "",
        "Token kuralı: **yalnız bu brief + işaretli dosyalar**. qa-report.json’ı satır satır LLM’e yapıştırma.",
        "",
        "## Kalan hatalar",
        "",
    ]
    if not remaining:
        lines.append("- (yok — QA PASS hedefi)")
    else:
        for e in remaining:
            lines.append(f"- {e}")
    lines += ["", "## Tarifler (manuel / LLM)", ""]
    for d in diags:
        if d.get("safe_apply") and do_apply:
            continue
        lines.append(f"### `{d.get('recipe')}`")
        lines.append(f"- Hata: {d.get('error')}")
        lines.append(f"- Fix: {d.get('fix')}")
        lines.append(f"- Token: {d.get('tokens_note')}")
        lines.append("")
    lines += [
        "## Doğrulama",
        "",
        "```bash",
        f"bash scripts/web/qa-gate.sh {project}",
        "```",
        "",
        "PASS olmadan paketleme yok. `guard.sh claim-pass` kanıtsız DENY.",
        "",
    ]
    path = project / "FIX-BRIEF.md"
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def measure(event: str, value):
    if not measure_sh or not Path(measure_sh).is_file():
        return
    subprocess.call(
        ["bash", measure_sh, str(project), event, str(value), "P4"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def one_pass(apply: bool):
    qa, qa_path = load_qa()
    if not qa:
        return {
            "result": "NO_QA",
            "errors": [],
            "diagnosis": [],
            "actions": [],
            "remaining": ["qa-report.json yok — --qa-first çalıştır"],
        }
    result = str(qa.get("result") or "").upper()
    errors = list(qa.get("errors") or [])
    if result == "PASS" and not errors:
        return {
            "result": "PASS",
            "errors": [],
            "diagnosis": [],
            "actions": [],
            "remaining": [],
            "qa_path": str(qa_path) if qa_path else None,
        }
    diags = diagnose(errors)
    actions = []
    if apply:
        for d in diags:
            r = next((x for x in recipes if x.get("id") == d["recipe"]), d)
            if not r.get("safe_apply"):
                continue
            actions.append(apply_recipe(r, d["error"]))
    return {
        "result": result or "FAIL",
        "errors": errors,
        "diagnosis": diags,
        "actions": actions,
        "remaining": errors,
        "qa_path": str(qa_path) if qa_path else None,
    }


rounds = []
final = one_pass(do_apply)

if do_loop:
    for i in range(max_loop):
        rounds.append({"round": i + 1, **{k: final[k] for k in ("result", "actions", "errors")}})
        if final.get("result") == "PASS":
            break
        safe_left = any(a.get("applied") for a in final.get("actions") or [])
        # re-qa
        subprocess.call(["bash", qa_sh, str(project)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        nxt = one_pass(True)
        if not any(a.get("applied") for a in nxt.get("actions") or []) and nxt.get("result") != "PASS":
            final = nxt
            rounds.append({"round": i + 2, "note": "safe apply tükendi", **{k: nxt[k] for k in ("result", "errors")}})
            break
        final = nxt
        if final.get("result") == "PASS":
            rounds.append({"round": i + 2, "result": "PASS", "errors": []})
            break
else:
    rounds = [{"round": 1, "result": final.get("result"), "errors": final.get("errors")}]

# brief: kalan + unsafe
unsafe = [d for d in final.get("diagnosis") or [] if not d.get("safe_apply")]
remaining = final.get("errors") or []
brief = write_brief(final.get("diagnosis") or [], remaining)

report = {
    "schema_version": 1,
    "tool": "doctor",
    "project": str(project),
    "at": now(),
    "mode": "loop" if do_loop else ("apply" if do_apply else "diagnose"),
    "result": final.get("result"),
    "rounds": rounds,
    "diagnosis": final.get("diagnosis") or [],
    "actions": final.get("actions") or [],
    "remaining_errors": remaining,
    "fix_brief": str(brief.relative_to(project)) if brief else None,
    "tokens_policy": "LLM yalnız FIX-BRIEF.md + işaretli dosya; qa-report dump yasak",
}
out = project / "doctor-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
fac = project / ".factory"
fac.mkdir(parents=True, exist_ok=True)
(fac / "doctor-report.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")

n_applied = sum(len(a.get("applied") or []) for a in (final.get("actions") or []))
measure("doctor_applied", n_applied)
measure("doctor_remaining", len(remaining))

print(f"==> doctor · {project.name} · mode={report['mode']} · result={report['result']}")
print(f"    teşhis: {len(report['diagnosis'])} tarif · apply satırı: {len(report['actions'])}")
for d in report["diagnosis"][:12]:
    mark = "SAFE" if d.get("safe_apply") else "BRIEF"
    print(f"    [{mark}] {d.get('recipe')}: {d.get('error')[:90]}")
for a in report["actions"]:
    if a.get("applied"):
        print(f"    + uygulandı ({a.get('recipe')}): {', '.join(a['applied'][:4])}")
if remaining:
    print(f"    kalan hata: {len(remaining)} → {brief.name}")
else:
    print(f"    kalan hata: 0 · brief: {brief.name}")
print(f"    rapor: {out}")

if report["result"] == "PASS" and not remaining:
    sys.exit(0)
sys.exit(1)
PY
