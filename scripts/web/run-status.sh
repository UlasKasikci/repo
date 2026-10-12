#!/usr/bin/env bash
set -euo pipefail

# Webrail — zorunlu handoff dosyası (IDE/personel kesintisiz devam)
# Kullanım: bash scripts/web/run-status.sh [proje_dizini]
# Çıktı: <proje>/RUN-STATUS.md  (commit edilir; gitignore'da değil)

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "run-status: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
OUT="$PROJECT/RUN-STATUS.md"

python3 - "$PROJECT" "$OUT" <<'PY'
import json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

project = Path(sys.argv[1])
out = Path(sys.argv[2])
state_path = project / ".factory" / "web-state.json"
decision_path = project / ".factory" / "decision.json"

phase = status = "—"
retry = "—"
last_err = "—"
if state_path.is_file():
    s = json.loads(state_path.read_text(encoding="utf-8"))
    phase = s.get("current_phase") or "—"
    status = s.get("status") or "—"
    retry = f"{s.get('retry_count', 0)}"
    last_err = s.get("last_error") or "—"

mod_summary = "(decision.json yok — P1 sonrası: bash scripts/web/decide.sh .)"
qa_extra = ""
next_block = "- State ve domain-report okunmadan üretim yapma.\n- P1 sonrası: `bash scripts/web/decide.sh .`"
if decision_path.is_file():
    d = json.loads(decision_path.read_text(encoding="utf-8"))
    mods = d.get("modules_to_apply") or []
    mod_summary = ", ".join(
        f"{m.get('module')}→{m.get('skill') or 'skill-yok'}" for m in mods
    ) or "(modül yok)"
    qa_extra = d.get("qa_gate_extra") or ""
    acts = d.get("next_actions") or []
    if acts:
        next_block = "\n".join(f"- {a}" for a in acts)

ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
try:
    git_hash = subprocess.check_output(
        ["git", "-C", str(project), "rev-parse", "--short", "HEAD"],
        stderr=subprocess.DEVNULL, text=True,
    ).strip()
except (subprocess.CalledProcessError, FileNotFoundError):
    git_hash = "—"

text = f"""# RUN-STATUS — Webrail handoff

> Her IDE / personel oturumu **bu dosyayı önce okur**. Halüsinasyon yasağı:
> state ve bu özet ile çelişen iddia geçersizdir.

| Alan | Değer |
|------|-------|
| Güncelleme (UTC) | {ts} |
| Proje | `{project.name}` |
| Faz | **{phase}** |
| Status | {status} |
| Retry | {retry} / 3 |
| Son hata | {last_err} |
| Git | {git_hash} |
| Decision modülleri | {mod_summary} |
| QA_GATE_EXTRA önerisi | `{qa_extra}` |

## Sonraki adımlar

{next_block}

## Ortak komutlar (IDE-agnostik)

```bash
bash scripts/web/state.sh status .
bash scripts/web/decide.sh .                 # karar katmanı (JEV-mantık, ücretsiz)
bash scripts/web/orchestrate.sh . --auto
bash scripts/web/qa-gate.sh . ${{QA_GATE_EXTRA:-}}
bash scripts/web/package-yukleme.sh .        # yalnız QA PASS
```

## Okunacak tek doğruluk kaynakları

1. `.factory/web-state.json` — faz
2. `.factory/domain-report.json` — P1 dondurulmuş gereksinim
3. `.factory/decision.json` — modül/bağlam/routing kararı
4. `qa-report.json` — son QA (varsa)
5. `docs/WEB-EDITION.md` — kanonik spec

Cursor · OpenCode · Claude Code · Antigravity: hepsi aynı dosyalara bağlıdır.
"""
out.write_text(text, encoding="utf-8")
print(f"run-status: yazıldı → {out} (faz={phase})")
PY
