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

# 1) tek remote (yalnız ad listesi — URL biçimi CI/local'de tab/space fark eder)
REMOTE_LIST="$(git remote 2>/dev/null | sort | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
[[ "$REMOTE_LIST" == "origin" ]] || bad "yalnız origin olmalı — mevcut: [${REMOTE_LIST}]"
ok "remote: yalnız origin"
ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
[[ "$ORIGIN" == *UlasKasikci/repo* ]] || bad "origin UlasKasikci/repo değil: $ORIGIN"
ok "origin=$ORIGIN"

# 2) yasaklı marka / org (bu betiği hariç tut — pattern string'i self-hit yapmasın)
git grep -n -i -e 'clariongemini' -e 'App-Fabrika' -e 'APP-FABRIKA' -e 'app-fabrika' -- \
  ':!.factory/e2e-runs' ':!**/node_modules/**' ':!scripts/web/preflight.sh' \
  > /tmp/preflight-brand.txt 2>/dev/null || true
if [[ -s /tmp/preflight-brand.txt ]]; then
  bad "yasaklı marka/org izi bulundu ($(wc -l </tmp/preflight-brand.txt | tr -d ' ') satır)"
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
         scripts/web/qa-gate.sh scripts/web/state.sh scripts/web/mode.sh \
         scripts/web/measure.sh scripts/web/webrail.sh scripts/web/status.sh \
         scripts/web/module-apply.sh scripts/web/p2-checklist.sh \
         .factory/contracts/decision.schema.json \
         .factory/modules/catalog.json \
         .factory/modules/auth-rbac/manifest.json \
         .factory/modules/kvkk/manifest.json \
         .factory/modules/admin-crud/manifest.json \
         .factory/modules/seo/manifest.json \
         docs/CUSTOMER-START.md docs/WEB-EDITION.md \
         docs/templates/DISCOVERY.md \
         .cursor/commands/kesfet.md .opencode/command/kesfet.md \
         .cursor/commands/webrail.md .opencode/command/webrail.md \
         .cursor/commands/yama.md .opencode/command/yama.md; do
  [[ -f "$f" ]] || bad "eksik: $f"
done
ok "karar/handoff/müşteri/mode/modül dosyaları mevcut"

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
         scripts/web/state.sh scripts/web/orchestrate.sh scripts/web/bootstrap-project.sh \
         scripts/web/mode.sh scripts/web/measure.sh scripts/web/webrail.sh \
         scripts/web/status.sh scripts/web/module-apply.sh scripts/web/p2-checklist.sh; do
  bash -n "$s" || bad "bash -n FAIL: $s"
done
python3 -m py_compile scripts/web/decision.py || bad "decision.py compile FAIL"
ok "bash -n + decision.py"

# paket files/ mevcut
for pkg in auth-rbac kvkk admin-crud seo; do
  [[ -d ".factory/modules/$pkg/files" ]] || bad "modül files yok: $pkg"
done
ok "modül paketleri (4)"

# 8) mode kilidi duman: discovery → start RED → promote → start OK
TMPM="$(mktemp -d)"
mkdir -p "$TMPM/.factory"
bash scripts/web/mode.sh init "$TMPM" >/dev/null
if bash scripts/web/state.sh start "$TMPM" >/dev/null 2>&1; then
  bad "discovery iken state start açılmamalı"
fi
# şablon yer tutucusu ile promote RED
if bash scripts/web/mode.sh promote "$TMPM" >/dev/null 2>&1; then
  bad "boş DISCOVERY ile promote açılmamalı"
fi
# proje adı doldur → promote → start
python3 - <<PY
from pathlib import Path
p = Path("$TMPM/DISCOVERY.md")
t = p.read_text(encoding="utf-8")
t = t.replace("_(buraya yaz — promote için zorunlu)_", "Preflight Smoke")
p.write_text(t, encoding="utf-8")
PY
bash scripts/web/mode.sh promote "$TMPM" >/dev/null \
  || bad "dolu DISCOVERY promote FAIL"
bash scripts/web/state.sh start "$TMPM" >/dev/null || bad "factory state start FAIL"
rm -rf "$TMPM"
ok "mode discovery→promote→start"

# 9) decide duman testi (mode yok = factory geriye uyum)
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
