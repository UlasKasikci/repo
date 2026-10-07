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
# temiz bootstrap (dry-run dokunmaz, --yes kopyalar, hariçler + git izi)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX="$ROOT/tests/fixtures/web-sample"
QA="$ROOT/scripts/web/qa-gate.sh"
PKG="$ROOT/scripts/web/package-yukleme.sh"
STATE="$ROOT/scripts/web/state.sh"
ORCH="$ROOT/scripts/web/orchestrate.sh"
LHS="$ROOT/scripts/web/lighthouse-verify.sh"
BOOTER="$ROOT/scripts/web/bootstrap-project.sh"

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
for s in state.sh qa-gate.sh package-yukleme.sh self-test.sh orchestrate.sh sql-dump.sh lighthouse-verify.sh bootstrap-project.sh; do
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

echo
echo "SELF-TEST: PASS — tüm senaryolar yeşil"
exit 0
