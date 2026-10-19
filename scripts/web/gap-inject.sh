#!/usr/bin/env bash
set -euo pipefail

# Webrail — gap-report → domain-report module_matrix (arketip-filtreli)
# Kullanım: bash scripts/web/gap-inject.sh <proje>
# Exit: 0 OK · 1 hata · 2 domain-report yok (atla)

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "gap-inject: dizin yok" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

[[ -f "$PROJECT/gap-report.json" ]] || {
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  bash "$ROOT/scripts/web/gap-scan.sh" "$PROJECT" >/dev/null || true
}
[[ -f "$PROJECT/.factory/domain-report.json" ]] || {
  echo "gap-inject: domain-report yok — atlandı"
  exit 2
}

export _GI_PROJECT="$PROJECT"
python3 - <<'PY'
import json, os
from datetime import datetime, timezone
from pathlib import Path

p = Path(os.environ["_GI_PROJECT"])
fac = p / ".factory"
gap = json.loads((p / "gap-report.json").read_text(encoding="utf-8"))
rep_path = fac / "domain-report.json"
rep = json.loads(rep_path.read_text(encoding="utf-8"))

archetype = gap.get("archetype") or "brochure"
# project-intent override
pi = fac / "project-intent.json"
if pi.is_file():
    try:
        intent = json.loads(pi.read_text(encoding="utf-8"))
        t = (intent.get("project_type") or intent.get("archetype") or "").strip().lower()
        if t:
            archetype = t
    except Exception:
        pass

# Arketip → enjekte edilebilir modüller (showcase/onepage'e ödeme/yorum YOK)
ALLOWED = {
    "ecommerce": {"cart", "payment", "reviews", "rbac", "seo", "kvkk"},
    "catalog_rfq": {"cart", "rbac", "seo", "kvkk"},  # payment yok
    "showcase": {"seo", "kvkk", "rbac"},
    "brochure": {"seo", "kvkk"},
    "onepage": {"seo"},
    "webapp": {"rbac", "seo", "kvkk"},
}
allowed = ALLOWED.get(archetype, {"seo", "kvkk"})

ID_TO_MOD = {
    "cart_missing": "cart",
    "payment_missing": "payment",
    "reviews_missing": "reviews",
    "rbac_missing": "rbac",
    "seo_missing": "seo",
    "kvkk_missing": "kvkk",
    "rfq_missing": "cart",
}

matrix = list(rep.get("module_matrix") or [])
existing = {str(r.get("module", "")).lower() for r in matrix if isinstance(r, dict)}
injected = []

for f in gap.get("findings") or []:
    if f.get("severity") not in ("blocker", "warn"):
        continue
    mod = ID_TO_MOD.get(f.get("id") or "")
    if not mod or mod not in allowed:
        continue
    if mod in existing:
        continue
    row = {
        "module": mod,
        "status": "proposed",
        "evidence": f"gap-scan:{f.get('id')} (archetype={archetype})",
        "justification": (
            f"gap-inject: {f.get('title') or mod} — arketip={archetype}; "
            f"{(f.get('detail') or '')[:80]}"
        ),
    }
    matrix.append(row)
    existing.add(mod)
    injected.append(mod)

rep["module_matrix"] = matrix
rep["gap_inject"] = {
    "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "archetype": archetype,
    "injected": injected,
}
# proposed list for humans
proposed = rep.get("proposed") or []
if not isinstance(proposed, list):
    proposed = []
for m in injected:
    if m not in proposed:
        proposed.append(m)
rep["proposed"] = proposed

rep_path.write_text(json.dumps(rep, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"==> gap-inject · {p.name} · archetype={archetype} · injected={injected or '[]'}")
PY
