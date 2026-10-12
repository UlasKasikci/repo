#!/usr/bin/env bash
set -euo pipefail

# Webrail — müşteri projesi ÖNCESİ hazırlık kapısı
# Kullanım: bash scripts/web/preflight.sh
# Exit: 0 READY · 1 FAIL (müşteriye başlama)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
ERR=0
ok() { echo "  OK  $*"; }
bad() { echo "  FAIL $*" >&2; ERR=1; }

echo "==> Webrail preflight @ $(git rev-parse --short HEAD 2>/dev/null || echo '?')"

# 1) tek remote
if git remote -v 2>/dev/null | grep -viE '^(origin\t|$)' | grep -q .; then
  bad "yalnız origin olmalı — ekstra remote var: $(git remote | tr '\n' ' ')"
else
  ok "remote: yalnız origin"
fi
ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
[[ "$ORIGIN" == *UlasKasikci/repo* ]] || bad "origin UlasKasikci/repo değil: $ORIGIN"
ok "origin=$ORIGIN"

# 2) yasaklı marka / org
if git grep -n -i 'clariongemini\|App-Fabrika\|APP-FABRIKA\|app-fabrika' -- \
  ':!.factory/e2e-runs' ':!**/node_modules/**' >/tmp/preflight-brand.txt 2>/dev/null; then
  bad "yasaklı marka/org izi bulundu ($(wc -l </tmp/preflight-brand.txt) satır)"
  head -5 /tmp/preflight-brand.txt >&2 || true
else
  ok "marka/org temiz"
fi

# 3) e2e-runs takip edilmiyor
TRACKED_E2E="$(git ls-files '.factory/e2e-runs' | wc -l | tr -d ' ')"
[[ "$TRACKED_E2E" == "0" ]] || bad "e2e-runs hâlâ tracked ($TRACKED_E2E dosya)"
ok "e2e-runs tracked=0"

# 4) Decision Layer + handoff araçları
for f in scripts/web/decide.sh scripts/web/decision.py scripts/web/run-status.sh \
         scripts/web/bootstrap-project.sh scripts/web/orchestrate.sh \
         scripts/web/qa-gate.sh scripts/web/state.sh \
         .factory/contracts/decision.schema.json \
         .factory/modules/catalog.json \
         docs/CUSTOMER-START.md docs/WEB-EDITION.md; do
  [[ -f "$f" ]] || bad "eksik: $f"
done
ok "karar/handoff/müşteri dosyaları mevcut"

# 5) skills READY (açık uç yok)
SKILL_OPEN=0
for s in .opencode/skills/*/SKILL.md; do
  [[ -f "$s" ]] || continue
  if grep -Eq 'v2.de doldurul|iskelet — v2|içerik doldurulacak' "$s"; then
    bad "skill açık uç: $s"
    SKILL_OPEN=1
  fi
  grep -q '\*\*Durum:\*\* READY' "$s" || bad "skill READY değil: $s"
done
[[ "$SKILL_OPEN" -eq 0 ]] && ok "skills READY (kvkk/auth/admin/seo)"

# 6) catalog → skill yolları çözülür
python3 - <<'PY' || bad "catalog skill yolları kırık"
import json
from pathlib import Path
root = Path(".")
cat = json.loads((root / ".factory/modules/catalog.json").read_text(encoding="utf-8"))
for name, meta in (cat.get("modules") or {}).items():
    skill = meta.get("skill")
    if skill is None:
        continue
    p = root / skill
    assert p.is_file(), f"{name} → {skill} yok"
print("catalog ok")
PY
ok "catalog skill yolları"

# 7) sözdizimi
for s in scripts/web/decide.sh scripts/web/run-status.sh scripts/web/preflight.sh \
         scripts/web/state.sh scripts/web/orchestrate.sh scripts/web/bootstrap-project.sh; do
  bash -n "$s" || bad "bash -n FAIL: $s"
done
python3 -m py_compile scripts/web/decision.py || bad "decision.py compile FAIL"
ok "bash -n + decision.py"

# 8) decide duman testi
TMP="$(mktemp -d)"
mkdir -p "$TMP/.factory"
bash scripts/web/state.sh start "$TMP" >/dev/null
python3 - <<PY
import json
from pathlib import Path
p=Path("$TMP/.factory/domain-report.json")
r={
  "schema_version":1,"project":"preflight","entities":[{"name":"users","fields":["id","role_id"]}],
  "roles":["admin","user"],
  "module_matrix":[
    {"module":"rbac","status":"injected","evidence":"e"*8,"justification":"j"*20},
    {"module":"seo","status":"present","evidence":"e"*8,"justification":"j"*20},
    {"module":"auth","status":"present","evidence":"e"*8,"justification":"j"*20},
    {"module":"admin","status":"proposed","evidence":"e"*8,"justification":"j"*20},
  ],
  "injected_modules":[],"approvals":[],"edge_cases":["x"],"security_context":{"csrf":True},
  "sql_draft":{"tables":["users"]},"file_manifest":["index.php"],"acceptance_criteria":["login"],
  "api_endpoints":[],"result":"PASS","compliance":"kvkk"
}
p.write_text(json.dumps(r),encoding="utf-8")
PY
bash scripts/web/decide.sh "$TMP" >/dev/null
[[ -f "$TMP/.factory/decision.json" && -f "$TMP/RUN-STATUS.md" ]] \
  || bad "decide/run-status duman testi"
rm -rf "$TMP"
ok "decide + RUN-STATUS duman testi"

echo
if [[ "$ERR" -ne 0 ]]; then
  echo "==> PREFLIGHT: FAIL — müşteri projesine BAŞLAMA" >&2
  exit 1
fi
echo "==> PREFLIGHT: READY — müşteri bootstrap'a geçilebilir"
echo "    Sonraki: docs/CUSTOMER-START.md → bootstrap-project.sh <hedef> --yes"
exit 0
