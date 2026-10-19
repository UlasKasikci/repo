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

# workspace-role: fabrika vs müşteri (bootstrap → customer-app)
WS_ROLE="webrail-factory"
if [[ -f .factory/workspace-role.json ]]; then
  WS_ROLE="$(python3 -c "import json; print(json.load(open('.factory/workspace-role.json')).get('role') or '')" 2>/dev/null || true)"
fi
[[ -n "$WS_ROLE" ]] || WS_ROLE="webrail-factory"
if [[ -f WEBRAIL-CUSTOMER.md ]] || [[ -f .factory/.bootstrap-manifest ]]; then
  WS_ROLE="customer-app"
fi

echo "==> Webrail preflight @ $(git rev-parse --short HEAD 2>/dev/null || echo '?') · role=$WS_ROLE"

ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
REMOTE_LIST="$(git remote 2>/dev/null | sort | tr '\n' ' ' | sed 's/[[:space:]]*$//')"

# 1) remote politikası — role'e göre
if [[ "$WS_ROLE" == "customer-app" ]]; then
  if [[ "$ORIGIN" == *UlasKasikci/repo* ]]; then
    bad "müşteri projesi fabrika remote'una (UlasKasikci/repo) bağlı — TEHLİKE; git remote remove origin"
  else
    ok "customer remote fabrika değil (${ORIGIN:-yok})"
  fi
  # müşteride origin zorunlu değil; varsa tek origin yeter
  if [[ -n "$REMOTE_LIST" && "$REMOTE_LIST" != "origin" ]]; then
    bad "müşteri: beklenen remote yalnız origin veya yok — mevcut: [${REMOTE_LIST}]"
  else
    ok "customer remote list: [${REMOTE_LIST:-boş}]"
  fi
else
  [[ "$REMOTE_LIST" == "origin" ]] || bad "yalnız origin olmalı — mevcut: [${REMOTE_LIST}]"
  ok "remote: yalnız origin"
  [[ "$ORIGIN" == *UlasKasikci/repo* ]] || bad "origin UlasKasikci/repo değil: $ORIGIN"
  ok "origin=$ORIGIN"
fi

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
         scripts/web/module-apply.sh scripts/web/p2-checklist.sh scripts/web/guard.sh \
         scripts/web/doctor.sh \
         scripts/web/plan-from-brief.sh \
         scripts/web/gap-scan.sh \
         scripts/web/denetle.sh \
         scripts/web/plan-sync.sh \
         scripts/web/debt-scan.sh \
         scripts/web/classify-fail.sh \
         scripts/web/reality-check.sh \
         scripts/web/adaptive-recover.sh \
         scripts/web/gap-inject.sh \
         scripts/web/orphan-commands.sh \
         .factory/contracts/failure-report.schema.json \
         docs/templates/PLAN.md \
         docs/templates/AGENT-CONTRACT.md \
         docs/PROJECT-ARCHETYPES.md \
         docs/GAP-APPROVAL-MATRIX.md \
         docs/V1.4-ROADMAP.md \
         .factory/modules/payment/manifest.json \
         .factory/modules/reviews/manifest.json \
         .opencode/skills/payment-basics/SKILL.md \
         .opencode/skills/reviews-basics/SKILL.md \
         .factory/auto-hooks.json \
         .cursor/commands/denetle.md \
         .opencode/command/denetle.md \
         .factory/workspace-role.json \
         .factory/workspace-role.customer.json \
         .factory/contracts/doctor-recipes.json \
         .factory/contracts/decision.schema.json \
         .opencode/skills/error-doctor/SKILL.md \
         .cursor/commands/doktor.md .opencode/command/doktor.md \
         .opencode/command/web-faz.md \
         .cursor/skills/auth-rbac/SKILL.md \
         .cursor/skills/error-doctor/SKILL.md \
         .cursor/skills/zero-hallucination/SKILL.md \
         docs/IDE-HANDOFF.md docs/templates/PHASE-LOG.md \
         scripts/web/phase-log.sh \
         .opencode/agent/hallucination-guard.md \
         .opencode/agent/phase-verifier.md \
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
[[ "$SKILL_OPEN" -eq 0 ]] && ok "skills READY (kvkk/auth/admin/seo/error-doctor)"
# AppleDouble (exFAT/Finder): commit’te olmamalı. Yerel oluşum FAIL değil (flaky);
# tracked ise FAIL. Push öncesi: find . -name '._*' -not -path './.git/*' -delete
AD_TRACKED="$(git ls-files | grep -c '/\._\|^\._' || true)"
if [[ "${AD_TRACKED:-0}" -gt 0 ]]; then
  bad "AppleDouble ._ git’te tracked ($AD_TRACKED) — untrack + sil"
else
  ok "AppleDouble ._ tracked=0"
fi
AD_N="$(find . -name '._*' -not -path './.git/*' -not -path './.opencode/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${AD_N:-0}" -gt 0 ]]; then
  echo "  WARN AppleDouble yerel ($AD_N) — push öncesi sil (gate FAIL değil)"
fi
# meta sayaç = self-test step
META_N="$(python3 -c "import json;print(json.load(open('.factory/meta.json')).get('self_test_scenarios') or 0)" 2>/dev/null || echo 0)"
STEP_N="$(grep -c '^step "' scripts/web/self-test.sh)"
[[ "$META_N" == "$STEP_N" ]] || bad "meta self_test_scenarios=$META_N != self-test steps=$STEP_N"
ok "meta senaryo ($META_N) = self-test"

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
         scripts/web/status.sh scripts/web/module-apply.sh scripts/web/p2-checklist.sh \
         scripts/web/guard.sh scripts/web/doctor.sh scripts/web/phase-log.sh \
         scripts/web/plan-from-brief.sh scripts/web/gap-scan.sh scripts/web/denetle.sh \
         scripts/web/plan-sync.sh scripts/web/debt-scan.sh \
         scripts/web/classify-fail.sh scripts/web/reality-check.sh scripts/web/adaptive-recover.sh \
         scripts/web/gap-inject.sh scripts/web/orphan-commands.sh; do
  bash -n "$s" || bad "bash -n FAIL: $s"
done
# orphan command drift
bash scripts/web/orphan-commands.sh . || bad "orphan-commands drift"
# README profesyonel kimlik
grep -q 'System Architect' README.md || bad "README: System Architect yok"
grep -q 'mermaid' README.md || bad "README: mermaid diyagram yok"
ok "README System Architect + diyagram"

# Android kırıntı — kurallar ağacında olmamalı
if [[ -f .cursor/rules/03-android-elite.mdc ]] || [[ -f .cursor/commands/baslat.md ]]; then
  bad "Android/legacy kırıntı hâlâ kurallarda (03-android veya /baslat)"
else
  ok "Android legacy rules/commands yok"
fi
# Olumlu Android uygulama izi (yasak listesindeki "Compose yasak" cümlesi FAIL değil)
if grep -Rql 'gradle-build-loop\.sh\|@AndroidEntryPoint\|init-new-app\.sh\|YAPILACAKLAR\.md oku' .cursor/rules --include='*.mdc' 2>/dev/null; then
  bad "Webrail rules içinde Android uygulama protokolü kaldı"
else
  ok "rules web-only (Android protokol yok)"
fi
python3 -m py_compile scripts/web/decision.py || bad "decision.py compile FAIL"
ok "bash -n + decision.py"

# paket files/ mevcut
for pkg in auth-rbac kvkk admin-crud seo payment reviews; do
  [[ -d ".factory/modules/$pkg/files" ]] || bad "modül files yok: $pkg"
done
ok "modül paketleri (6)"

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
