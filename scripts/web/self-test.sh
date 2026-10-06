#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — öz-test (CI ile aynı sahne)
# Senaryolar: syntax → araç ön-şartı → pozitif QA (statik 3'lü PASS) →
# paketleme + exclusion → state graph (qa-pass / 3 retry / 4. fail HALT) →
# negatif RBAC → negatif sepet → --allow-no-cart kaçışı → QA'sız paketleme reddi →
# orkestratör E2E (bekleme/bozuk rapor/DONE) → statik SKIPPED eşiği

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX="$ROOT/tests/fixtures/web-sample"
QA="$ROOT/scripts/web/qa-gate.sh"
PKG="$ROOT/scripts/web/package-yukleme.sh"
STATE="$ROOT/scripts/web/state.sh"
ORCH="$ROOT/scripts/web/orchestrate.sh"

die() {
  echo "SELF-TEST FAIL: $*" >&2
  exit 1
}
step() { echo; echo "===== $* ====="; }
run_rc() {
  local rc=0
  "$@" >&2 || rc=$?
  printf '%s' "$rc"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step "0) bash -n söz dizimi"
for s in state.sh qa-gate.sh package-yukleme.sh self-test.sh orchestrate.sh; do
  bash -n "$ROOT/scripts/web/$s" || die "bash -n: $s"
  echo "    OK: $s"
done

if [[ ! -d "$FIX" ]]; then
  echo
  echo "SELF-TEST: SKIP — fixture yok (tests/ bu repoya dahil edilmedi)"
  exit 0
fi
command -v php >/dev/null 2>&1 || die "php-cli yok"
command -v python3 >/dev/null 2>&1 || die "python3 yok"

# garantici teslimat: phpstan + phpunit + eslint kurulu olmalı (§8)
for _bin in "$HOME/.composer/vendor/bin" "$HOME/.config/composer/vendor/bin"; do
  if [[ -d "$_bin" ]]; then PATH="$_bin:$PATH"; fi
done
export PATH
command -v phpstan >/dev/null 2>&1 || die "phpstan yok — composer global require phpstan/phpstan"
command -v phpunit >/dev/null 2>&1 || die "phpunit yok — composer global require phpunit/phpunit"
if ! command -v npx >/dev/null 2>&1 || ! (cd "$FIX" && npx --no-install eslint --version >/dev/null 2>&1); then
  die "eslint yok — npm install -g eslint"
fi
echo "    araçlar: phpstan + phpunit + eslint OK"

step "1) pozitif QA (junk dahil, temiz proje)"
PROJ="$TMP/proj"
cp -R "$FIX" "$PROJ"
mkdir -p "$PROJ/node_modules" "$PROJ/.git"
echo "SECRET=1" > "$PROJ/.env"
echo "junk()" > "$PROJ/node_modules/junk.js"
echo '$a: red;' > "$PROJ/src.scss"
echo 'const x = 1;' > "$PROJ/app.ts"
printf '<?php\n// yardimci test dosyasi\n' > "$PROJ/helpers_test.php"
echo "junk" > "$PROJ/.git/config"
echo "# dev notlari" > "$PROJ/NOTES.md"

rc="$(run_rc bash "$QA" "$PROJ")"
[[ "$rc" == "0" ]] || { cat "$PROJ/qa-report.json" 2>/dev/null; die "qa-gate pozitif beklenen 0, gelen $rc"; }
python3 - "$PROJ/qa-report.json" <<'PY' || die "qa-report PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS", r
assert r["errors"] == [], r["errors"]
assert r["warnings"] == [], r["warnings"]
for chk in ("phpstan", "eslint", "phpunit"):
    assert r["checks"].get(chk) == "PASS", (chk, r["checks"])
assert r["checks"].get("static_coverage") != "FAIL", r["checks"]
PY
echo "    qa-report: PASS (0 error, 0 warning) · phpstan/eslint/phpunit = PASS"

step "2) paketleme + build isolation"
rc="$(run_rc bash "$PKG" "$PROJ")"
[[ "$rc" == "0" ]] || { cat "$PROJ/packaging-report.json" 2>/dev/null; die "packager beklenen 0, gelen $rc"; }
Y="$PROJ/Yukleme"
for req in index.php .htaccess robots.txt sitemap.xml core views assets/css assets/js assets/images SQL/veritabani.sql; do
  [[ -e "$Y/$req" ]] || die "Yukleme ağacı eksik: $req"
done
leak="$(find "$Y" \( -name node_modules -o -name .env -o -name .git -o -name '*.scss' \
  -o -name '*.ts' -o -name '*_test.php' -o -name NOTES.md -o -name '.DS_Store' \
  -o -name '._*' \) -print)"
[[ -z "$leak" ]] || die "denylist sızıntısı: $leak"
grep -q 'FOREIGN KEY' "$Y/SQL/veritabani.sql" || die "Yukleme/SQL/veritabani.sql FK içermiyor"
[[ ! -e "$Y/NOTES.md" ]] || die "NOTES.md pakete sızdı"
python3 - "$PROJ/packaging-report.json" <<'PY' || die "packaging-report geçersiz"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS", r["failures"]
assert r["files_count"] > 0, r
assert "index.php" in r["manifest"], r["manifest"].keys()
assert "SQL/veritabani.sql" in r["manifest"], r["manifest"].keys()
assert any(n.startswith("minify:") for n in r["notes"]), r["notes"]
assert "node_modules" in r["skipped"], r["skipped"]
assert not any(k.startswith("._") for k in r["manifest"]), "AppleDouble sızıntısı"
assert r["failures"] == [], r["failures"]
PY
echo "    packaging-report: PASS · exclusion + sha256 manifest OK"

step "3) state graph: start → P3 → qa-pass → P5"
bash "$STATE" start "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
grep -q '"current_phase": "P3"' "$PROJ/.factory/web-state.json" || die "P3 bekleniyordu"
rc="$(run_rc bash "$STATE" qa-pass "$PROJ")"
[[ "$rc" == "0" ]] || die "qa-pass rc=$rc"
grep -q '"current_phase": "P5"' "$PROJ/.factory/web-state.json" || die "P5 bekleniyordu"

step "4) qa-gate --record entegrasyonu (P3 → PASS → P5)"
bash "$STATE" start "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
rc="$(run_rc bash "$QA" "$PROJ" --record)"
[[ "$rc" == "0" ]] || die "--record qa-pass beklenen 0, gelen $rc"
grep -q '"current_phase": "P5"' "$PROJ/.factory/web-state.json" || die "--record sonrası P5 bekleniyordu"

step "5) retry döngüsü: 3 tolerans + 4. fail HALT"
bash "$STATE" start "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
for i in 1 2 3; do
  rc="$(run_rc bash "$STATE" qa-fail "$PROJ")"
  [[ "$rc" == "0" ]] || die "qa-fail #$i beklenen 0, gelen $rc"
  grep -q "\"retry_count\": $i" "$PROJ/.factory/web-state.json" || die "retry_count=$i bekleniyordu"
done
rc="$(run_rc bash "$STATE" qa-fail "$PROJ")"
[[ "$rc" == "2" ]] || die "4. qa-fail HALT (2) beklenir, gelen $rc"
grep -q '"status": "halted"' "$PROJ/.factory/web-state.json" || die "status=halted bekleniyordu"
rc="$(run_rc bash "$STATE" advance "$PROJ")"
[[ "$rc" == "2" ]] || die "halted state'te advance 2 dönmeli, gelen $rc"
echo "    HALT: 4. başarısızlıkta döngü durdu (max_retries=3)"

step "6) negatif: RBAC eksik (role_id yok)"
NEG="$TMP/rbac"
cp -R "$FIX" "$NEG"
sed 's/`role_id`/`perm_level`/g' "$NEG/SQL/veritabani.sql" > "$NEG/SQL/veritabani.sql.new"
mv "$NEG/SQL/veritabani.sql.new" "$NEG/SQL/veritabani.sql"
rc="$(run_rc bash "$QA" "$NEG")"
[[ "$rc" == "1" ]] || die "RBAC negatif beklenen 1, gelen $rc"
grep -q 'rbac' "$NEG/debug_report.json" || die "debug_report'ta rbac hatası yok"
python3 - "$NEG/debug_report.json" <<'PY' || die "debug_report halted=false olmalı"
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d["kind"] == "debug_report"
assert d["halted"] is False
assert any("rbac" in e for e in d["errors"])
assert d["next_actions"], d
PY
echo "    debug_report.json üretildi (halted=false)"

step "7) negatif: katalog var, sepet yok"
NEG2="$TMP/cart"
cp -R "$FIX" "$NEG2"
sed 's/`orders`/`fatura_kayitlari`/g' "$NEG2/SQL/veritabani.sql" > "$NEG2/SQL/veritabani.sql.new"
mv "$NEG2/SQL/veritabani.sql.new" "$NEG2/SQL/veritabani.sql"
rc="$(run_rc bash "$QA" "$NEG2")"
[[ "$rc" == "1" ]] || die "sepet negatif beklenen 1, gelen $rc"
grep -q 'eksik modül' "$NEG2/debug_report.json" || die "debug_report'ta eksik modül hatası yok"

step "8) --allow-no-cart kaçışı (onaylı istisna)"
rc="$(run_rc bash "$QA" "$NEG2" --allow-no-cart)"
[[ "$rc" == "0" ]] || die "--allow-no-cart PASS beklenen 0, gelen $rc"
python3 - "$NEG2/qa-report.json" <<'PY' || die "approved_exceptions kaydı yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS"
assert r["errors"] == []
assert r["approved_exceptions"], r
PY
echo "    istisna onaylandı: 0 error, 0 warning"

step "9) QA'sız paketleme reddi (State Graph kuralı 3)"
rc="$(run_rc bash "$PKG" "$NEG")"
[[ "$rc" != "0" ]] || die "QA FAIL ile paketleme geçti!"
[[ ! -e "$NEG/Yukleme" ]] || die "QA'sız Yukleme/ oluştu"
echo "    reddedildi (rc=$rc), Yukleme/ oluşturulmadı"

step "10) orkestratör E2E: bekleme(3) → bozuk rapor(1) → DONE(0)"
bash "$STATE" start "$PROJ" >/dev/null
rm -f "$PROJ/.factory/domain-report.json" "$PROJ/packaging-report.json"
rc="$(run_rc bash "$ORCH" "$PROJ")"
[[ "$rc" == "3" ]] || die "P1 bekleme exit 3 beklenir, gelen $rc"
echo '{ bozuk' > "$PROJ/.factory/domain-report.json"
rc="$(run_rc bash "$ORCH" "$PROJ")"
[[ "$rc" == "1" ]] || die "geçersiz domain-report exit 1 beklenir, gelen $rc"
cat > "$PROJ/.factory/domain-report.json" <<'JSON'
{
  "schema_version": 1,
  "project": "web-sample",
  "entities": [
    {"name": "roles", "fields": ["id", "name"]},
    {"name": "users", "fields": ["id", "role_id", "email", "password_hash"]},
    {"name": "products", "fields": ["id", "name", "price"]},
    {"name": "orders", "fields": ["id", "user_id", "total"]}
  ],
  "roles": ["admin", "editor", "user"],
  "module_matrix": [
    {"module": "rbac", "status": "present", "evidence": "roles + users.role_id FK"},
    {"module": "cart", "status": "present", "evidence": "orders tablosu"},
    {"module": "seo", "status": "present", "evidence": "robots.txt + sitemap.xml"},
    {"module": "kvkk", "status": "present", "evidence": "KVKK aydınlatma"}
  ],
  "injected_modules": [],
  "approvals": [],
  "edge_cases": ["gecersiz e-posta → 422", "CSRF geçersiz → 419"],
  "security_context": ["PDO prepared", "Argon2id", "CSRF token"],
  "sql_draft": {"tables": ["roles", "users", "products", "orders"], "seed_rows": 3},
  "result": "requirements-frozen"
}
JSON
rc="$(run_rc bash "$ORCH" "$PROJ")"
[[ "$rc" == "0" ]] || { cat "$PROJ/.factory/web-state.json" 2>/dev/null; die "tam zincir DONE exit 0 beklenir, gelen $rc"; }
grep -q '"current_phase": "DONE"' "$PROJ/.factory/web-state.json" || die "state DONE bekleniyordu"
grep -q '"status": "done"' "$PROJ/.factory/web-state.json" || die "status=done bekleniyordu"
[[ -f "$PROJ/Yukleme/index.php" ]] || die "Yukleme/ üretilemedi"
python3 - "$PROJ/packaging-report.json" <<'PY' || die "packaging-report PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS", r
PY
rc="$(run_rc bash "$ORCH" "$PROJ")"
[[ "$rc" == "0" ]] || die "ikinci çalıştırma (zaten DONE) exit 0 beklenir, gelen $rc"
echo "    E2E: 3 → 1 → 0 · P1..P5 → DONE · idempotent"

step "11) statik garanti eşiği: 3 SKIPPED → static_coverage FAIL"
NOSTAT="$TMP/nostat"
cp -R "$FIX" "$NOSTAT"
rm -f "$NOSTAT/phpstan.neon.dist" "$NOSTAT/.eslintrc.json" "$NOSTAT/phpunit.xml"
rm -rf "$NOSTAT/tests"
rc="$(run_rc bash "$QA" "$NOSTAT")"
[[ "$rc" == "1" ]] || die "statik SKIPPED eşiği FAIL (1) beklenir, gelen $rc"
grep -q 'static_coverage' "$NOSTAT/qa-report.json" || die "qa-report'ta static_coverage kontrolü yok"
echo "    static_coverage: FAIL (3/3 SKIPPED > 2)"

echo
echo "SELF-TEST: PASS — tüm senaryolar yeşil"
exit 0
