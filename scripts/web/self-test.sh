#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — öz-test (CI ile aynı sahne)
# Senaryolar: syntax → araç ön-şartı → pozitif QA (statik 3'lü PASS) →
# paketleme + exclusion → state graph (qa-pass / 3 retry / 4. fail HALT) →
# negatif RBAC → negatif sepet → --allow-no-cart kaçışı → QA'sız paketleme reddi →
# orkestratör E2E (bekleme/bozuk rapor/DONE) → asimetrik statik çekirdek
# (yalnız eslint SKIPPED PASS; phpstan/phpunit eksik FAIL) →
# semantik P1 kapısı (hollow + fs'de olmayan kanıt → domain_report FAIL) →
# SQL dump otomasyonu (deterministik üretim + sql_dump drift kapısı) →
# lighthouse raporlayıcı faz (SKIPPED/PASS/WARN/strict + --serve) →
# temiz bootstrap (dry-run dokunmaz, --yes kopyalar, hariçler + git izi) →
# staging paketleme + katmanlı smoke (blocker/raporlayıcı/force-fail guard) +
# arşiv MANIFEST + atomik takas + force-fail geri alma + KEEP prune →
# --auto metrik raporlayıcısı (NDJSON event → metrics.jsonl, parse fallback,
# reporter-only: gate/exit değişmez) →
# KVKK koşullu kanal (intent.compliance: yok→SKIPPED, kvkk→FAIL, iskelet→PASS) →
# P4 hata-enjeksiyon tam döngü (P1 üretimi+enjeksiyon → P3 QA FAIL → P4
# düzeltme → PASS → DONE, retry=1 + metrics P1/P4 satırları)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX="$ROOT/tests/fixtures/web-sample"
QA="$ROOT/scripts/web/qa-gate.sh"
PKG="$ROOT/scripts/web/package-yukleme.sh"
STATE="$ROOT/scripts/web/state.sh"
ORCH="$ROOT/scripts/web/orchestrate.sh"
LHS="$ROOT/scripts/web/lighthouse-verify.sh"
BOOTER="$ROOT/scripts/web/bootstrap-project.sh"
SMOKE="$ROOT/scripts/web/smoke-test.sh"

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

step "0) bash -n söz dizimi + python söz dizimi"
for s in state.sh qa-gate.sh package-yukleme.sh self-test.sh orchestrate.sh sql-dump.sh lighthouse-verify.sh bootstrap-project.sh smoke-test.sh; do
  bash -n "$ROOT/scripts/web/$s" || die "bash -n: $s"
  echo "    OK: $s"
done
python3 -m py_compile "$ROOT/scripts/web/domain-check.py" || die "py_compile: domain-check.py"
echo "    OK: domain-check.py"

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
[[ -f "$PROJ/debug_report.json" ]] || die "HALT debug_report.json üretildi"
python3 - "$PROJ/debug_report.json" <<'PY' || die "HALT debug_report içeriği"
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d["kind"] == "debug_report" and d["halted"] is True, d
assert d["retry_count"] == 4 and d["max_retries"] == 3, d
assert any("max_retries" in e for e in d["errors"]), d
assert d["next_actions"], d
PY
rc="$(run_rc bash "$STATE" advance "$PROJ")"
[[ "$rc" == "2" ]] || die "halted state'te advance 2 dönmeli, gelen $rc"
echo "    HALT: 4. başarısızlıkta döngü durdu (max_retries=3) + debug_report.json (halted=true)"

step "6) negatif: RBAC eksik (role_id yok)"
NEG="$TMP/rbac"
cp -R "$FIX" "$NEG"
while IFS= read -r f; do
  sed 's/`role_id`/`perm_level`/g' "$f" > "$f.new" && mv "$f.new" "$f"
done < <(find "$NEG/SQL/migrations" -type f -name '*.sql')
bash "$ROOT/scripts/web/sql-dump.sh" "$NEG" >/dev/null
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
while IFS= read -r f; do
  sed 's/`orders`/`fatura_kayitlari`/g' "$f" > "$f.new" && mv "$f.new" "$f"
done < <(find "$NEG2/SQL/migrations" -type f -name '*.sql')
bash "$ROOT/scripts/web/sql-dump.sh" "$NEG2" >/dev/null
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
    {
      "module": "rbac",
      "status": "present",
      "evidence": "SQL/veritabani.sql:users.role_id + roles seed",
      "justification": "users tablosunda role_id var ve roles tablosu FK ile bağlı — rol katmanı şemada present"
    },
    {
      "module": "cart",
      "status": "present",
      "evidence": "SQL/veritabani.sql:orders.user_id FK",
      "justification": "orders tablosu user_id FK ile sipariş akışını karşılıyor — sepet/sipariş mekanizması present"
    },
    {
      "module": "seo",
      "status": "present",
      "evidence": "robots.txt + sitemap.xml + index.php meta description",
      "justification": "robots.txt, sitemap.xml ve meta description çıktısı hazır — SEO modülü present"
    },
    {
      "module": "kvkk",
      "status": "present",
      "evidence": "index.php:session_set_cookie_params SameSite=Strict",
      "justification": "çerez onayı SameSite/HttpOnly ayarlarıyla yapıldı — KVKK aydınlatma metni home şablonunda"
    }
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
python3 - "$PROJ/packaging-report.json" "$PROJ/qa-report.json" <<'PY' || die "rapor doğrulama"
import json, sys
pkg = json.load(open(sys.argv[1], encoding="utf-8"))
assert pkg["result"] == "PASS", pkg
qa = json.load(open(sys.argv[2], encoding="utf-8"))
assert qa["checks"].get("domain_report") == "PASS", qa["checks"]
PY
rc="$(run_rc bash "$ORCH" "$PROJ")"
[[ "$rc" == "0" ]] || die "ikinci çalıştırma (zaten DONE) exit 0 beklenir, gelen $rc"
echo "    E2E: 3 → 1 → 0 · P1..P5 → DONE · idempotent · domain_report=PASS"

step "11) asimetrik statik çekirdek: yalnız eslint SKIPPED → PASS; phpstan/phpunit eksik → FAIL"
NOESLINT="$TMP/noeslint"
cp -R "$FIX" "$NOESLINT"
rm -f "$NOESLINT/.eslintrc.json"
rc="$(run_rc bash "$QA" "$NOESLINT")"
[[ "$rc" == "0" ]] || { cat "$NOESLINT/qa-report.json" 2>/dev/null; die "yalnız eslint SKIPPED PASS (0) beklenir, gelen $rc"; }
python3 - "$NOESLINT/qa-report.json" <<'PY' || die "asimetrik eşik A durumu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
c = r["checks"]
assert c.get("eslint") == "SKIPPED", c
assert c.get("phpstan") == "PASS", c
assert c.get("phpunit") == "PASS", c
assert c.get("static_coverage") == "PASS", c
PY
echo "    yalnız eslint SKIPPED → PASS (static_coverage=PASS)"

NOPHPSTAN="$TMP/nophpstan"
cp -R "$FIX" "$NOPHPSTAN"
rm -f "$NOPHPSTAN/phpstan.neon.dist"
rc="$(run_rc bash "$QA" "$NOPHPSTAN")"
[[ "$rc" == "1" ]] || die "phpstan yapılandırması yok → FAIL (1) beklenir, gelen $rc"
python3 - "$NOPHPSTAN/qa-report.json" <<'PY' || die "asimetrik eşik B durumu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("phpstan") == "FAIL", r["checks"]
assert r["checks"].get("static_coverage") == "FAIL", r["checks"]
assert any("phpstan yapılandırması yok" in e for e in r["errors"]), r["errors"]
PY
echo "    phpstan yapılandırması yok → FAIL + static_coverage=FAIL"

NOPHPUNIT="$TMP/nophpunit"
cp -R "$FIX" "$NOPHPUNIT"
rm -f "$NOPHPUNIT/phpunit.xml"
rc="$(run_rc bash "$QA" "$NOPHPUNIT")"
[[ "$rc" == "1" ]] || die "phpunit yapılandırması yok → FAIL (1) beklenir, gelen $rc"
python3 - "$NOPHPUNIT/qa-report.json" <<'PY' || die "asimetrik eşik C durumu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("phpunit") == "FAIL", r["checks"]
assert r["checks"].get("static_coverage") == "FAIL", r["checks"]
assert any("phpunit yapılandırması yok" in e for e in r["errors"]), r["errors"]
PY
echo "    phpunit yapılandırması yok → FAIL + static_coverage=FAIL"

step "12) semantik P1 kapısı: hollow module_matrix → domain_report FAIL"
HOLLOW="$TMP/hollow"
cp -R "$FIX" "$HOLLOW"
mkdir -p "$HOLLOW/.factory"
cat > "$HOLLOW/.factory/domain-report.json" <<'JSON'
{
  "schema_version": 1,
  "project": "web-sample",
  "entities": [{"name": "users"}],
  "roles": ["user"],
  "module_matrix": [
    {"module": "rbac", "status": "present", "evidence": "ok", "justification": "rbac"},
    {"module": "rbac", "status": "present", "evidence": "SQL/veritabani.sql:users", "justification": "roles tablosu var ve kullanıcılar role_id üzerinden sınıflandırılıyor"},
    {"module": "cart", "status": "present", "evidence": "orders tablosu var", "justification": "sipariş tablosu bulunduğu için sepet mevcut kabul edildi"},
    {"module": "seo", "status": "present", "evidence": "robots.txt mevcut", "justification": "robots.txt ve sitemap.xml dosyaları proje kökünde hazır"}
  ],
  "injected_modules": [],
  "approvals": [],
  "edge_cases": ["x"],
  "security_context": ["y"],
  "sql_draft": {"tables": ["users"]},
  "result": "requirements-frozen"
}
JSON
rc="$(run_rc bash "$QA" "$HOLLOW")"
[[ "$rc" == "1" ]] || die "hollow module_matrix FAIL (1) beklenir, gelen $rc"
python3 - "$HOLLOW/qa-report.json" <<'PY' || die "domain_report semantik hataları raporda yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("domain_report") == "FAIL", r["checks"]
joined = " ".join(r["errors"])
assert "justification yetersiz" in joined, r["errors"]
assert "modül tekrarı" in joined, r["errors"]
assert "kaynak referansı" in joined, r["errors"]
PY
echo "    hollow matrix: domain_report FAIL (şablon justification + modül tekrarı + kaynaksız evidence)"

# fs-uydurma: şemaya uygun ama olmayan dosyaya atıf → hem qa-gate hem orkestratör reddi
PHANTOM="$TMP/phantom"
cp -R "$FIX" "$PHANTOM"
mkdir -p "$PHANTOM/.factory"
cat > "$PHANTOM/.factory/domain-report.json" <<'JSON'
{
  "schema_version": 1,
  "project": "web-sample",
  "entities": [{"name": "users"}],
  "roles": ["user"],
  "module_matrix": [
    {"module": "rbac", "status": "present", "evidence": "SQL/veritabani.sql:users.role_id üzerinden doğrulandı", "justification": "users tablosunda role_id sütunu var ve roles tablosuna FK ile bağlı — rol katmanı şemada present"},
    {"module": "cart", "status": "present", "evidence": "SQL/veritabani.sql:orders.user_id FK satırı", "justification": "orders tablosu user_id FK ile sipariş akışını karşılıyor — sepet/sipariş mekanizması present"},
    {"module": "seo", "status": "present", "evidence": "robots.txt + sitemap.xml kök çıktıları", "justification": "robots.txt ve sitemap.xml dosyaları proje kökünde hazır — SEO modülü present"},
    {"module": "kvkk", "status": "present", "evidence": "docs/KVKK-Aydinlatma.md aydınlatma metni", "justification": "KVKK aydınlatma metni docs/KVKK-Aydinlatma.md dosyasında yayımlanmış durumda"}
  ],
  "injected_modules": [],
  "approvals": [],
  "edge_cases": ["x"],
  "security_context": ["y"],
  "sql_draft": {"tables": ["users", "orders", "products", "roles"]},
  "result": "requirements-frozen"
}
JSON
rc="$(run_rc bash "$QA" "$PHANTOM")"
[[ "$rc" == "1" ]] || die "fs-uydurma evidence FAIL (1) beklenir, gelen $rc"
python3 - "$PHANTOM/qa-report.json" <<'PY' || die "fs-uydurma tespiti raporda yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("domain_report") == "FAIL", r["checks"]
assert any("kaynak dosyası bulunamadı" in e and "KVKK-Aydinlatma" in e for e in r["errors"]), r["errors"]
PY
echo "    fs-uydurma: qa-gate domain_report FAIL (olmayan dosyaya atıf)"
rc="$(run_rc bash "$ORCH" "$PHANTOM")"
[[ "$rc" == "1" ]] || die "orkestratör fs-uydurma P1 reddi (1) beklenir, gelen $rc"
echo "    fs-uydurma: orkestratör P1 → exit 1 (domain-check.py fs katmanı)"
# nokta-dosya kanıtı: `.eslintrc.json` noktalı adla fs'e sorulur → mevcutsa PASS
python3 - "$PHANTOM/.factory/domain-report.json" <<'PY' || die "dotfile kanıtı kurulamadı"
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
for cell in d["module_matrix"]:
    if cell["module"] == "kvkk":
        cell["evidence"] = ".eslintrc.json yapılandırma + sitemap.xml kanıtı"
with open(p, "w", encoding="utf-8") as fh:
    json.dump(d, fh, ensure_ascii=False)
PY
rc="$(run_rc bash "$QA" "$PHANTOM")"
[[ "$rc" == "0" ]] || die "nokta-dosya kanıtı PASS (0) beklenir, gelen $rc"
python3 - "$PHANTOM/qa-report.json" <<'PY' || die "dotfile domain_report PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("domain_report") == "PASS", r["checks"]
PY
echo "    nokta-dosya kanıtı (.eslintrc.json): noktalı adla fs kontrolü → PASS"

step "13) SQL dump otomasyonu: deterministik üretim + drift kapısı"
DUMP="$TMP/dumpproj"
cp -R "$FIX" "$DUMP"
T1="$TMP/dump1.sql"
T2="$TMP/dump2.sql"
bash "$ROOT/scripts/web/sql-dump.sh" "$DUMP" --output "$T1" >/dev/null
bash "$ROOT/scripts/web/sql-dump.sh" "$DUMP" --output "$T2" >/dev/null
cmp -s "$T1" "$T2" || die "sql-dump: iki koşu farklı çıktı (determinizm bozuk)"
cmp -s "$T1" "$DUMP/SQL/veritabani.sql" || die "sql-dump: üretilen dump commit'li SQL/veritabani.sql ile farklı"
grep -q 'Kaynak Hash: [0-9a-f]\{12\}' "$T1" || die "dump başlığında Kaynak Hash yok"
grep -q -- '============ SCHEMA ============' "$T1" || die "dump'ta SCHEMA bölümü yok"
grep -q -- '============ SEED ============' "$T1" || die "dump'ta SEED bölümü yok"
grep -q 'source: SQL/migrations/schema/001_core.sql' "$T1" || die "schema source marker yok"
printf '\n-- elle eklendi satir\n' >> "$DUMP/SQL/veritabani.sql"
rc="$(run_rc bash "$QA" "$DUMP")"
[[ "$rc" == "1" ]] || die "dump drift FAIL (1) beklenir, gelen $rc"
python3 - "$DUMP/qa-report.json" <<'PY' || die "sql_dump drift tespiti raporda yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("sql_dump") == "FAIL", r["checks"]
assert any("senkron değil" in e for e in r["errors"]), r["errors"]
PY
echo "    deterministik üretim (iki koşu byte-identical + commit'li dosyayla eşit) + drift → sql_dump FAIL"

# SKIPPED bütçesi bilinçli: iki kanal yan yana PASS edebilir, ama her kanalın
# kendi zorunlu çekirdeği var — sql_dump SKIPPED olsa bile sql_schema koşulsuzdur.
DUAL="$TMP/dual"
cp -R "$FIX" "$DUAL"
rm -rf "$DUAL/SQL/migrations"
rm -f "$DUAL/.eslintrc.json"
rc="$(run_rc bash "$QA" "$DUAL")"
[[ "$rc" == "0" ]] || die "dual-SKIPPED PASS (0) beklenir, gelen $rc"
python3 - "$DUAL/qa-report.json" <<'PY' || die "dual-SKIPPED kanal denetimi"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
c = r["checks"]
assert r["result"] == "PASS" and r["errors"] == [], (r["result"], r["errors"])
assert c.get("sql_dump") == "SKIPPED" and c.get("eslint") == "SKIPPED", c
assert c.get("sql_schema") == "PASS" and c.get("static_coverage") == "PASS", c
PY
echo "    dual-SKIPPED (sql_dump+eslint) PASS — kanal-bazlı çekirdekler ayakta"
rm -f "$DUAL/SQL/veritabani.sql"
rc="$(run_rc bash "$QA" "$DUAL")"
[[ "$rc" == "1" ]] || die "migrations+dump birlikte yokken FAIL (1) beklenir, gelen $rc"
grep -q '"sql_schema": "FAIL"' "$DUAL/qa-report.json" || die "sql_schema FAIL değildi (koşulsuz AND kuralı)"
echo "    migrations + dump birlikte yokken sql_schema FAIL (eski tip dump zorunlu)"

step "14) lighthouse-verify: raporlayıcı faz (SKIPPED → PASS → WARN → strict + --serve)"
LHP="$TMP/lhproj"
cp -R "$FIX" "$LHP"
rc="$(run_rc env -u LIGHTHOUSE_URL bash "$LHS" "$LHP")"
[[ "$rc" == "0" ]] || die "lighthouse env yok rc0 beklenir, gelen $rc"
python3 - "$LHP/.factory/lighthouse-report.json" <<'PY' || die "SKIPPED raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["tool"] == "lighthouse-verify" and r["result"] == "SKIPPED", r
assert any("LIGHTHOUSE_URL" in n for n in r["nots"]), r["nots"]
PY
echo "    env yok → SKIPPED (rc0, neden raporlandı)"

STUB="$TMP/lhbin"
mkdir -p "$STUB"
cat > "$STUB/lighthouse" <<'STUB'
#!/usr/bin/env bash
OUT=""
for a in "$@"; do case "$a" in --output-path=*) OUT="${a#*=}";; esac; done
if [[ -z "$OUT" ]]; then echo "fake lighthouse 1.0"; exit 0; fi
python3 - "$OUT" "${LH_FAKE_SCORE:-0.96}" <<'PYF'
import json, sys
json.dump({
 "categories": {"performance": {"score": float(sys.argv[2])}, "accessibility": {"score": 1.0},
                "best-practices": {"score": 1.0}, "seo": {"score": 0.93}},
 "audits": {"largest-contentful-paint": {"numericValue": 1800},
            "cumulative-layout-shift": {"numericValue": 0.02}}
}, open(sys.argv[1], "w"))
PYF
STUB
chmod +x "$STUB/lighthouse"

rc="$(run_rc env PATH="$STUB:$PATH" LIGHTHOUSE_URL=http://127.0.0.1:9/ bash "$LHS" "$LHP")"
[[ "$rc" == "0" ]] || die "lighthouse PASS rc0 beklenir, gelen $rc"
python3 - "$LHP/.factory/lighthouse-report.json" <<'PY' || die "PASS raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS", r
assert r["scores"]["performance"] == 96 and r["metrics"]["lcp_ms"] == 1800, r
assert r["violations"] == [], r
PY
echo "    eşik üstü → PASS (kategori skorları + LCP/CLS raporlandı)"

rc="$(run_rc env PATH="$STUB:$PATH" LH_FAKE_SCORE=0.85 LIGHTHOUSE_URL=http://127.0.0.1:9/ bash "$LHS" "$LHP")"
[[ "$rc" == "0" ]] || die "lighthouse WARN v1 rc0 beklenir, gelen $rc"
python3 - "$LHP/.factory/lighthouse-report.json" <<'PY' || die "WARN raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "WARN", r
assert any("performance 85" in v for v in r["violations"]), r["violations"]
PY
echo "    eşik altı → WARN ama v1'de rc0 (raporlayıcı: CI flaky değil)"

rc="$(run_rc env PATH="$STUB:$PATH" LH_FAKE_SCORE=0.85 LIGHTHOUSE_URL=http://127.0.0.1:9/ bash "$LHS" "$LHP" --strict)"
[[ "$rc" == "1" ]] || die "lighthouse --strict WARN rc1 beklenir, gelen $rc"
echo "    --strict: WARN → exit 1 (sıkılaştırma kapısı hazır)"

LH_PORT=$((21000 + RANDOM % 2000))
rc="$(run_rc env PATH="$STUB:$PATH" LIGHTHOUSE_PORT="$LH_PORT" LIGHTHOUSE_URL= bash "$LHS" "$LHP" --serve)"
[[ "$rc" == "0" ]] || die "lighthouse --serve rc0 beklenir, gelen $rc"
python3 - "$LHP/.factory/lighthouse-report.json" <<'PY' || die "--serve raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS" and r["url"].startswith("http://127.0.0.1:"), r
assert any("--serve" in n for n in r["nots"]), r["nots"]
PY
echo "    --serve: php -S ayağa kalktı, URL türetildi, süreç kapatıldı"

if command -v lighthouse >/dev/null 2>&1; then
  echo "    (gerçek lighthouse kurulu — araç-yok yolu bu ortamda atlandı)"
else
  rc="$(run_rc env LIGHTHOUSE_URL=http://127.0.0.1:9/ bash "$LHS" "$LHP")"
  [[ "$rc" == "0" ]] || die "lighthouse araç yok rc0 beklenir, gelen $rc"
  python3 - "$LHP/.factory/lighthouse-report.json" <<'PY' || die "araç-yok SKIPPED raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "SKIPPED", r
assert any("kurulu değil" in n for n in r["nots"]), r["nots"]
PY
  echo "    araç yok → SKIPPED (kurulum ipucuyla)"
fi

step "15) bootstrap: dry-run dokunmaz, --yes kopyalar, hariçler + git izi"
BOOT="$TMP/bootnew"
OUT="$(bash "$BOOTER" "$BOOT" 2>&1)" || die "bootstrap dry-run hata verdi"
[[ ! -e "$BOOT" ]] || die "dry-run hedefe dokundu"
grep -q 'DRY-RUN' <<<"$OUT" || die "DRY-RUN etiketi yok"
grep -Eq 'kopyalanacak: [0-9]+ dosya \([0-9]+ bayt\)' <<<"$OUT" || die "plan sayımı yok"
echo "    dry-run: dosya/bayt planı yazdı, hedefe dokunmadı"

rc="$(run_rc bash "$BOOTER" "$BOOT" --yes)"
[[ "$rc" == "0" ]] || die "bootstrap --yes rc0 beklenir, gelen $rc"
for f in scripts/web/qa-gate.sh scripts/web/orchestrate.sh scripts/web/domain-check.py \
         .factory/contracts/p1-domain-report.schema.json .factory/web-state-graph.json \
         .factory/meta.json .cursor/rules/25-web-domain-architect.mdc \
         .cursor/agents/web-qa-gatekeeper.md .opencode/agent/web-domain-architect.md \
         .opencode/command/web-baslat.md docs/WEB-EDITION.md CLAUDE.md .cursorrules opencode.json; do
  [[ -e "$BOOT/$f" ]] || die "kopyalanmamalı eksik: $f"
done
for f in scripts/web/self-test.sh scripts/web/bootstrap-project.sh tests .github \
         .factory/context .factory/freeze.json .factory/web-state.json \
         .cursor/skills .cursor/mcp.json .opencode/node_modules .opencode/plans; do
  [[ ! -e "$BOOT/$f" ]] || die "kopyalanmamalıydı: $f"
done
MSG="$(git -C "$BOOT" log -1 --format=%s)"
grep -Eq '^bootstrap from app-fabrika@[0-9a-f]{12}$' <<<"$MSG" || die "git izi beklenen biçimde değil: $MSG"
BR="$(git -C "$BOOT" rev-parse --abbrev-ref HEAD)"
[[ "$BR" == "main" ]] || die "branch main değil: $BR"
echo "    --yes: kritik dosyalar kopyalandı, hariçler temiz, iz: $MSG"

rc="$(run_rc bash "$BOOTER" "$BOOT" --yes)"
[[ "$rc" == "1" ]] || die "dolu hedef --force'suz red (1) beklenir, gelen $rc"
rc="$(run_rc bash "$BOOTER" "$BOOT" --yes --force)"
[[ "$rc" == "0" ]] || die "--force idempotent (0) beklenir, gelen $rc"
COMMITS="$(git -C "$BOOT" rev-list --count HEAD)"
[[ "$COMMITS" == "1" ]] || die "ikinci koşu commit atmamalı (toplam $COMMITS)"
echo "    dolu hedef: --force'suz red, --force ile idempotent (commit atlandı)"

step "16) smoke-test: lokal katmanlı kapı + canlı raporlayıcı + force-fail guard"
GOOD="$TMP/smokegood"
mkdir -p "$GOOD"
cat > "$GOOD/index.php" <<'PHP'
<?php
header('Content-Type: text/html; charset=utf-8');
echo '<!doctype html><html lang="tr"><head><meta charset="utf-8"><title>smoke</title></head><body>ok</body></html>';
PHP
printf 'User-agent: *\nAllow: /\n' > "$GOOD/robots.txt"
printf '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"></urlset>\n' > "$GOOD/sitemap.xml"

rc="$(run_rc bash "$SMOKE" "$GOOD")"
[[ "$rc" == "0" ]] || die "smoke iyi dizin rc0 beklenir, gelen $rc"
python3 - "$TMP/smoke-report.json" <<'PY' || die "smoke PASS raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS", (r["result"], r["errors"], r["violations"])
assert r["mode"] == "local" and r["strict"] is False, r
assert r["errors"] == [] and r["violations"] == [], (r["errors"], r["violations"])
assert any(".htaccess" in n for n in r["notes"]), r["notes"]
names = [c["name"] for c in r["checks"]]
for need in ("php_lint", "server_start", "root_transport", "robots_txt", "sitemap_xml"):
    assert need in names, names
assert all(c["ok"] for c in r["checks"]), [c for c in r["checks"] if not c["ok"]]
PY
echo "    iyi dizin: php -l + php -S + / ve robots/sitemap 200 → PASS (.htaccess notu raporda)"

BAD="$TMP/smokebad"
mkdir -p "$BAD"
printf '<?php echo "x";\n' > "$BAD/index.php"
rc="$(run_rc env SMOKE_REPORT="$TMP/smoke-bad-report.json" bash "$SMOKE" "$BAD")"
[[ "$rc" == "1" ]] || die "smoke robots'suz FAIL rc1 beklenir, gelen $rc"
python3 - "$TMP/smoke-bad-report.json" <<'PY' || die "smoke FAIL raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r
assert any("robots.txt" in e for e in r["errors"]), r["errors"]
PY
echo "    robots/sitemap yok → blocker FAIL (rc1, hata raporda)"

rc=0
GUARD_OUT="$(env SMOKE_TEST_FORCE_FAIL=1 bash "$SMOKE" "$GOOD" 2>&1)" || rc=$?
[[ "$rc" == "1" ]] || die "force-fail guard rc1 beklenir, gelen $rc"
grep -q 'SELF_TEST' <<<"$GUARD_OUT" || die "guard mesajı SELF_TEST içermeli: $GUARD_OUT"
echo "    SMOKE_TEST_FORCE_FAIL SELF_TEST'siz reddedildi (yalnız öz-test ortamı)"

rc=0
env SELF_TEST=1 SMOKE_TEST_FORCE_FAIL=1 SMOKE_REPORT="$TMP/smoke-forced.json" \
  bash "$SMOKE" "$GOOD" >/dev/null 2>&1 || rc=$?
[[ "$rc" == "1" ]] || die "SMOKE_TEST_FORCE_FAIL=1 rc1 beklenir, gelen $rc"
python3 - "$TMP/smoke-forced.json" <<'PY' || die "forced FAIL raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r
assert any("zorlanan" in e for e in r["errors"]), r["errors"]
PY
echo "    SELF_TEST=1 ile zorlanan hata → FAIL raporu (geri alma kancası çalışıyor)"

rc="$(run_rc env SMOKE_REPORT="$TMP/smoke-live.json" bash "$SMOKE" --url "http://127.0.0.1:9/")"
[[ "$rc" == "0" ]] || die "canlı kapalı port WARN rc0 beklenir, gelen $rc"
python3 - "$TMP/smoke-live.json" <<'PY' || die "canlı WARN raporu"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "WARN" and r["mode"] == "live", r
assert any("ulaşılamadı" in v for v in r["violations"]), r["violations"]
assert r["errors"] == [], r["errors"]
PY
rc="$(run_rc env SMOKE_REPORT="$TMP/smoke-live-strict.json" bash "$SMOKE" --url "http://127.0.0.1:9/" --strict)"
[[ "$rc" == "1" ]] || die "canlı --strict WARN rc1 beklenir, gelen $rc"
echo "    canlı: kapalı port → WARN rc0; --strict → rc1 (sıkılaştırma kapısı hazır)"

step "17) staging paketleme: arşiv + MANIFEST + atomik takas + geri alma + KEEP prune"
ROLL="$TMP/pkgroll"
cp -R "$FIX" "$ROLL"
ARC="$ROLL/.factory/yukleme-archive"

rc="$(run_rc bash "$PKG" "$ROLL")"
[[ "$rc" == "0" ]] || die "staging paketleme #1 rc0 beklenir, gelen $rc"
[[ -d "$ROLL/Yukleme" ]] || die "Yukleme/ oluşmadı (staging takası)"
if [[ -d "$ARC" ]]; then die "ilk koşuda arşiv olmamalı"; fi
if [[ -d "$ROLL/.factory/yukleme-staging" ]]; then die "staging kalmamalı (takas sonrası)"; fi
echo "    #1: staging build + smoke → ilk Yukleme/ (arşiv boş, staging taşındı)"

printf '\n<!-- rev2 -->\n' >> "$ROLL/views/home.php"
rc="$(run_rc bash "$PKG" "$ROLL")"
[[ "$rc" == "0" ]] || die "staging paketleme #2 rc0 beklenir, gelen $rc"
C="$(ls -1 "$ARC" | wc -l | tr -d ' ')"
[[ "$C" == "1" ]] || die "arşiv 1 beklenir, gelen $C"
ADIR="$ARC/$(ls -1 "$ARC" | head -1)"
[[ -f "$ADIR/MANIFEST.json" ]] || die "arşiv MANIFEST.json yok"
grep -q 'rev2' "$ROLL/Yukleme/views/home.php" || die "yeni paket rev2 içermeli"
if grep -q 'rev2' "$ADIR/views/home.php" 2>/dev/null; then
  die "arşiv rev2 içermemeli (eski paket arşivlenmedi)"
fi
python3 - "$ADIR/MANIFEST.json" <<'PY' || die "arşiv MANIFEST içeriği"
import json, re, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
assert re.fullmatch(r"[0-9a-f]{64}", m["source_hash"] or ""), m
assert re.fullmatch(r"[0-9a-f]{64}", m["sql_dump_hash"] or ""), m
assert m["smoke_result"] == "PASS", m
assert m["built_at"], m
PY
echo "    #2: eski Yukleme/ → arşiv/<ts>-<hash12> + MANIFEST (source/sql hash, PASS); takas rev2'li"

H1="$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$ROLL/Yukleme/index.php")"
rc="$(run_rc env SELF_TEST=1 SMOKE_TEST_FORCE_FAIL=1 bash "$PKG" "$ROLL")"
[[ "$rc" == "1" ]] || die "force-fail paketleme rc1 beklenir, gelen $rc"
H2="$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$ROLL/Yukleme/index.php")"
[[ "$H1" == "$H2" ]] || die "Yukleme/ bozuldu — geri alma başarısız"
if [[ -d "$ROLL/.factory/yukleme-staging" ]]; then die "FAIL sonrası staging kalmamalı"; fi
[[ -f "$ROLL/.factory/yukleme-failed/MANIFEST.json" ]] || die "yukleme-failed/MANIFEST.json yok"
C="$(ls -1 "$ARC" | wc -l | tr -d ' ')"
[[ "$C" == "1" ]] || die "FAIL arşive dokunmamalı (arşiv=$C)"
python3 - "$ROLL/packaging-report.json" "$ROLL/.factory/yukleme-failed/MANIFEST.json" <<'PY' || die "FAIL raporları"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r
assert any("smoke" in f for f in r["failures"]), r["failures"]
m = json.load(open(sys.argv[2], encoding="utf-8"))
assert m["smoke_result"] == "FAIL", m
PY
echo "    force-fail: staging → yukleme-failed + MANIFEST(FAIL); eski Yukleme/ bayt bayt korundu"

printf '\n<!-- rev3 -->\n' >> "$ROLL/views/home.php"
rc="$(run_rc env YUKLEME_ARCHIVE_KEEP=2 bash "$PKG" "$ROLL")"
[[ "$rc" == "0" ]] || die "staging paketleme #4 rc0 beklenir, gelen $rc"
C="$(ls -1 "$ARC" | wc -l | tr -d ' ')"
[[ "$C" == "2" ]] || die "arşiv 2 beklenir (1+1), gelen $C"
printf '\n<!-- rev4 -->\n' >> "$ROLL/views/home.php"
rc="$(run_rc env YUKLEME_ARCHIVE_KEEP=2 bash "$PKG" "$ROLL")"
[[ "$rc" == "0" ]] || die "staging paketleme #5 rc0 beklenir, gelen $rc"
C="$(ls -1 "$ARC" | wc -l | tr -d ' ')"
[[ "$C" == "2" ]] || die "KEEP=2 prune → 2 beklenir, gelen $C"
grep -q 'rev4' "$ROLL/Yukleme/views/home.php" || die "en yeni paket rev4 içermeli"
echo "    YUKLEME_ARCHIVE_KEEP=2: arşiv 3 → prune → 2 (en yeniler kaldı)"

step "18) orchestrate --auto metrik raporlayıcısı: event → metrics.jsonl + parse fallback"
STUB2="$TMP/ocbin"
mkdir -p "$STUB2"
cat > "$STUB2/opencode" <<'STUB'
#!/usr/bin/env bash
if [[ "${STUB_MODE:-ok}" == "garbage" ]]; then
  echo "opencode: plain log line, not json"
  exit 0
fi
python3 - <<'PYF'
import json
import time

now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_stub0001",
     "part": {"type": "step-start"}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_stub0001",
     "part": {"type": "text", "text": "PONG (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_stub0001",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 123, "input": 100, "output": 23, "reasoning": 7,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
STUB
chmod +x "$STUB2/opencode"

MP="$TMP/mp18"
cp -R "$FIX" "$MP"
rm -f "$MP/.factory/domain-report.json"
rc=0
AUTO_OUT="$(env PATH="$STUB2:$PATH" STUB_MODE=ok bash "$ORCH" "$MP" --auto 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "auto+stub bekleme rc3 beklenir, gelen $rc"
grep -q 'PONG (stub)' <<<"$AUTO_OUT" || die "agent metni stdout'a basılmadı: $AUTO_OUT"
[[ -f "$MP/.factory/metrics.jsonl" ]] || die "metrics.jsonl üretilmedi"
python3 - "$MP/.factory/metrics.jsonl" <<'PY' || die "metrik satırı (ok modu)"
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
assert len(lines) == 1, lines
m = lines[0]
assert m["parse_error"] is False, m
assert m["phase"] == "P1" and m["agent"] == "web-domain-architect", m
assert m["rc"] == 0, m
assert isinstance(m["latency_ms"], int) and m["latency_ms"] >= 0, m
assert m["events"] == 3 and m["steps"] == 1 and m["text_parts"] == 1, m
assert m["tokens"]["total"] == 123 and m["tokens"]["input"] == 100, m
assert m["tokens"]["cache_read"] == 0, m
assert m["session"] and m["session"].startswith("ses_"), m
assert m["event_span_ms"] == 6, m
PY
echo "    ok modu: NDJSON → 1 satır metrik (tokens/session/span) + agent metni basıldı; P1 bekleme rc3 KORUNDU"

rc="$(run_rc env PATH="$STUB2:$PATH" STUB_MODE=garbage bash "$ORCH" "$MP" --auto)"
[[ "$rc" == "3" ]] || die "garbage modunda da rc3 beklenir, gelen $rc"
python3 - "$MP/.factory/metrics.jsonl" <<'PY' || die "parse_error satırı"
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
assert len(lines) == 2, lines
m = lines[1]
assert m["parse_error"] is True and m.get("error"), m
assert "rc" in m and "latency_ms" in m and "phase" in m, m
PY
echo "    garbage modu: parse_error=true (+rc/latency yine yazıldı), gate yine rc3"

step "19) KVKK koşullu kanal: intent.compliance — yok→SKIPPED, kvkk→FAIL, iskelet→PASS"
K1="$TMP/kv1"
cp -R "$FIX" "$K1"
rc="$(run_rc bash "$QA" "$K1")"
[[ "$rc" == "0" ]] || { cat "$K1/qa-report.json" 2>/dev/null; die "intent yoksa QA PASS"; }
python3 - "$K1/qa-report.json" <<'PY' || die "kvkk SKIPPED"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("kvkk") == "SKIPPED", r["checks"]
PY
echo "    intent yok → kvkk SKIPPED (QA PASS — ayrı kanal, bütçesiz)"

K2="$TMP/kv2"
cp -R "$FIX" "$K2"
printf '{"schema_version": 1, "compliance": "kvkk"}\n' > "$K2/.factory/project-intent.json"
rc="$(run_rc bash "$QA" "$K2")"
[[ "$rc" == "1" ]] || die "kvkk iskelet eksikken QA FAIL (1) beklenir, gelen $rc"
python3 - "$K2/qa-report.json" <<'PY' || die "kvkk FAIL kanıtı"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("kvkk") == "FAIL", r["checks"]
assert any(e.startswith("kvkk: views/legal/") for e in r["errors"]), r["errors"]
assert any("user_consents" in e for e in r["errors"]), r["errors"]
PY
echo "    compliance=kvkk + iskelet yok → kvkk FAIL (legal view + rıza tablosu hataları)"

mkdir -p "$K2/views/legal" "$K2/views/partials" "$K2/assets/js" "$K2/SQL/migrations/schema"
for v in aydinlatma gizlilik cerez; do
  cat > "$K2/views/legal/$v.php" <<'PHPV'
<?php
declare(strict_types=1);
$title = 'KVKK / Çerez Bilgilendirmesi';
?>
<section class="legal">
  <h1><?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></h1>
  <p>6698 sayılı KVKK ve GDPR aydınlatma metni — tam hukuki metin proje kapsamında doldurulur.</p>
</section>
PHPV
done
cat > "$K2/views/partials/cookie-consent.php" <<'PHPV'
<?php
declare(strict_types=1);
$mesaj = 'Deneyimi iyileştirmek icin bu site zorunlu ve istatistik cerezleri kullanir.';
?>
<div id="cookie-consent" class="cookie-banner" hidden data-consent="pending">
  <p><?= htmlspecialchars($mesaj, ENT_QUOTES, 'UTF-8') ?></p>
  <button type="button" data-action="accept">Kabul</button>
  <button type="button" data-action="reject">Reddet</button>
</div>
PHPV
cat > "$K2/assets/js/cookie-consent.js" <<'JSV'
document.addEventListener('DOMContentLoaded', function () {
  // cookie consent banner controller (acik riza)
});
JSV
cat > "$K2/SQL/migrations/schema/002_kvkk.sql" <<'SQLV'
CREATE TABLE user_consents (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    purpose VARCHAR(64) NOT NULL,
    granted TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_consents_user (user_id),
    CONSTRAINT fk_user_consents_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE anonymization_log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    action VARCHAR(64) NOT NULL,
    basis VARCHAR(64) NOT NULL,
    performed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_anon_user (user_id),
    CONSTRAINT fk_anonymization_log_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQLV
bash "$ROOT/scripts/web/sql-dump.sh" "$K2" >/dev/null || die "kvkk dump üretilemedi"
rc="$(run_rc bash "$QA" "$K2")"
[[ "$rc" == "0" ]] || { cat "$K2/qa-report.json" 2>/dev/null; die "iskelet tamken QA PASS"; }
python3 - "$K2/qa-report.json" <<'PY' || die "kvkk PASS kanıtı"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"].get("kvkk") == "PASS", r["checks"]
assert r["checks"].get("sql_dump") in ("PASS", "SKIPPED"), r["checks"]
assert r["checks"].get("php_lint") == "PASS", r["checks"]
PY
echo "    iskelet (3 legal + consent bileşeni + user_consents/anonymization_log + dump) → kvkk PASS"

step "20) kill-safe metrik (B4): TERM ile uçuş halindeyken rc=143 satırı düşer"
STUB3="$TMP/ocbin3"
mkdir -p "$STUB3"
cat > "$STUB3/opencode" <<'STUB'
#!/usr/bin/env bash
# -u: kill edilince tampon kaybı olmasın (event'ler anında akmalı)
python3 -u - <<'PYF'
import json
import time

now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_kill0001",
     "part": {"type": "step-start"}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_kill0001",
     "part": {"type": "text", "text": "IN-FLIGHT (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_kill0001",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 555, "input": 500, "output": 55, "reasoning": 0,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
sleep 30
STUB
chmod +x "$STUB3/opencode"
MP20="$TMP/mp20"
cp -R "$FIX" "$MP20"
rm -f "$MP20/.factory/domain-report.json" "$MP20/.factory/metrics.jsonl"
KILL_LOG="$TMP/mp20-orch.log"
env PATH="$STUB3:$PATH" bash "$ORCH" "$MP20" --auto > "$KILL_LOG" 2>&1 &
ORCH_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  grep -q "opencode agent: web-domain-architect" "$KILL_LOG" 2>/dev/null && break
  sleep 0.5
done
if ! grep -q "opencode agent" "$KILL_LOG" 2>/dev/null; then
  kill -TERM "$ORCH_PID" 2>/dev/null || true
  die "B4: orchestrate run_agent'a ulaşamadı"
fi
sleep 0.5
# watchdog kill_tree sırası: önce çocuklar (stub), sonra orchestrate
for c in $(pgrep -P "$ORCH_PID" || true); do
  for g in $(pgrep -P "$c" || true); do kill -TERM "$g" 2>/dev/null || true; done
  kill -TERM "$c" 2>/dev/null || true
done
kill -TERM "$ORCH_PID" 2>/dev/null || true
rc=0
wait "$ORCH_PID" || rc=$?
[[ "$rc" == "143" ]] || die "B4: orchestrate TERM sonrası 143 beklenir, gelen $rc"
[[ -f "$MP20/.factory/metrics.jsonl" ]] || die "B4: kill-safe metrics satırı düşmedi"
python3 - "$MP20/.factory/metrics.jsonl" <<'PY' || die "B4: kill-safe metrik satırı doğrulaması"
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
assert len(lines) == 1, lines
m = lines[0]
assert m["rc"] == 143, m
assert m["phase"] == "P1" and m["agent"] == "web-domain-architect", m
assert m["parse_error"] is False, m
assert m["events"] == 3 and m["tokens"]["total"] == 555, m
assert isinstance(m["latency_ms"], int) and m["latency_ms"] >= 0, m
PY
echo "    TERM → uçuş halindeki P1 satırı rc=143 tek satır olarak yazıldı (events=3, tokens=555, çift satır yok)"

step "21) P4 hata-enjeksiyon tam döngü: P1 üretimi+enjeksiyon → P3 QA FAIL → P4 düzeltme → PASS → DONE"
STUB4="$TMP/ocbin4"
mkdir -p "$STUB4"
cat > "$STUB4/opencode" <<'STUB'
#!/usr/bin/env bash
prompt="${@: -1}"
proj="$(printf '%s\n' "$prompt" | sed -n 's/^Proje dizini: //p' | head -1)"
case "$prompt" in
  *"P1 (Domain & Scope)"*)
    cat > "$proj/.factory/domain-report.json" <<'JSON'
{
 "schema_version": 1, "project": "web-sample", "compliance": "none",
 "entities": [
  {"name": "roles", "fields": ["id", "code", "name"]},
  {"name": "users", "fields": ["id", "role_id", "email", "password_hash"]},
  {"name": "products", "fields": ["id", "title", "price", "is_active"]},
  {"name": "orders", "fields": ["id", "user_id", "product_id", "total"]}],
 "roles": ["admin", "user"],
 "module_matrix": [
  {"module": "rbac", "status": "present",
   "evidence": "SQL/veritabani.sql:24 role_id sutunu users tablosunda",
   "justification": "users.role_id FOREIGN KEY ile rol baglantisi tanimli, admin katmani hazir"},
  {"module": "cart-order", "status": "present",
   "evidence": "SQL/veritabani.sql:44 orders tablosu products FK ile bagli",
   "justification": "sepet ve siparis akisi icin orders/products tablolari iliskili kurulmus"},
  {"module": "contact-messaging", "status": "missing",
   "evidence": "SQL/veritabani.sql CREATE TABLE listesinde messages gormuyor",
   "justification": "mesajlasma tablosu iskelette yer almıyor, P2 asamasinda eklenmeli"},
  {"module": "kvkk-compliance", "status": "missing",
   "evidence": "views/home.php icinde consent akisi ve cerceve yok",
   "justification": "compliance=none secimi geregi aydinlatma metni ve consent tablosu istenmiyor"},
  {"module": "seo", "status": "injected",
   "evidence": "robots.txt ve sitemap.xml proje kokunde mevcut",
   "justification": "arama motoru tarama kurallari ve site haritasi ciktilari iskelete eklendi"},
  {"module": "csrf-protection", "status": "injected",
   "evidence": "core/App.php uzerinden POST isteklerinde token dogrulamasi",
   "justification": "form gonderimlerinde CSRF token zorunlulugu uygulamaya islenmis durumda"}],
 "injected_modules": ["seo", "csrf-protection"],
 "approvals": ["rbac-present", "cart-order-present"],
 "edge_cases": ["bos sepet ile siparis verilemez", "rol yukseltme yetkisi yalnizca admin"],
 "security_context": ["PDO prepared statements", "PASSWORD_ARGON2ID", "CSRF token dogrulamasi", "htmlspecialchars ciktisi"],
 "sql_draft": {"tables": ["roles", "users", "products", "orders"]},
 "result": "requirements-frozen"
}
JSON
    printf '%s\n' 'eval($_GET["q"]); // INJECTED' >> "$proj/core/App.php"
    ;;
  *"P4 (Revision)"*)
    grep -v '// INJECTED' "$proj/core/App.php" > "$proj/core/App.php.tmp" && mv "$proj/core/App.php.tmp" "$proj/core/App.php"
    ;;
esac
python3 - <<'PYF'
import json, time
now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_stub0001",
     "part": {"type": "step-start"}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_stub0001",
     "part": {"type": "text", "text": "P4-STUB (injection tour)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_stub0001",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 77, "input": 60, "output": 17, "reasoning": 0,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
STUB
chmod +x "$STUB4/opencode"
MP21="$TMP/mp21"
cp -R "$FIX" "$MP21"
rm -f "$MP21/.factory/domain-report.json" "$MP21/.factory/metrics.jsonl"
rc=0
OUT21="$(env PATH="$STUB4:$PATH" bash "$ORCH" "$MP21" --auto 2>&1)" || rc=$?
[[ "$rc" == "0" ]] || { printf '%s\n' "$OUT21" | tail -30; die "P4 enjeksiyon döngüsü rc0 beklenir, gelen $rc"; }
grep -q "QA FAIL #1/3" <<<"$OUT21" || die "döngüde QA FAIL #1/3 (P4 geçişi) görülmedi"
grep -q "QA PASS P4 → P5" <<<"$OUT21" || die "P4 → P5 geçişi görülmedi"
grep -q "ORCHESTRATE: DONE" <<<"$OUT21" || die "ORCHESTRATE: DONE yok"
python3 - "$MP21/.factory/web-state.json" <<'PY' || die "state: P4 döngüsü bekleneni karşılamıyor"
import json, sys
s = json.load(open(sys.argv[1], encoding="utf-8"))
assert s["current_phase"] == "DONE", s
assert s["retry_count"] == 1, s
evs = [e["event"] for e in s["history"]]
assert "qa-fail" in evs and "qa-pass" in evs, evs
assert evs.index("qa-fail") < evs.index("qa-pass"), evs
PY
python3 - "$MP21/.factory/metrics.jsonl" <<'PY' || die "metrics: P1/P4 satırları doğrulanamadı"
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
assert len(lines) == 2, lines
assert [(m["phase"], m["agent"], m["rc"]) for m in lines] == [
    ("P1", "web-domain-architect", 0), ("P4", "web-core-engineer", 0)], lines
assert all(m["parse_error"] is False for m in lines), lines
PY
if grep -q 'INJECTED' "$MP21/core/App.php"; then die "P4 enjeksiyon kalıntısı core/App.php'de duruyor"; fi
python3 - "$MP21/qa-report.json" <<'PY' || die "son qa-report PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "PASS" and r["errors"] == [], r
PY
[[ -e "$MP21/Yukleme/index.php" ]] || die "P5 sonrası Yukleme/index.php yok"
echo "    FAIL #1 → P4 düzeltme → PASS: retry=1, DONE, metrics P1+P4 (rc=0), eval temiz, Yukleme üretildi"

echo
echo "SELF-TEST: PASS — tüm senaryolar yeşil"
exit 0
