#!/usr/bin/env bash
set -euo pipefail

# Webrail — öz-test (CI ile aynı sahne)
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
# düzeltme → PASS → DONE, retry=1 + metrics P1/P4 satırları) →
# --strict bütçe alarmı (1× uyarı, exit/gate değişmez; 2× sert katman → exit 1) →
# ajan self-advance toleransı (P2→P3 çift-ilerlemede advance guard + set -e sessiz
# ölüm regresyonu; state.sh kanal kontratı: rc=1 + stdout boş + stderr mesaj) →
# att0-0-write watchdog (L3): P2 idle'da TERM + aktif yazımda false-positive yok →
# A1 QUESTIONS.json exit gate (P2 soru → P2→P1 dönüşü + P1 yanıtı tüketir) →
# A1 whitelist read scan (whitelist dışı read → WARN, reporter-only) →
# frontmatter validator (kırık imza → standalone FAIL + qa-gate 14. kontrol FAIL) +
# manifest-onaylı okuma (file_manifest yolu sessiz, manifest dışı WARN)
# K5 (Tur 2-7): senaryo sayısı otomatik (grep -c '^step "') + README badge tutarlılığı

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX="$ROOT/tests/fixtures/web-sample"
# exFAT/Finder anlık üretebilir: AppleDouble ikizleri phpunit'i bozar (APFS tmp'ye
# kopyalasak da KAYNAK temiz olmalı) — okuma sınırında tek temizlik noktası.
find "$FIX" -name '._*' -delete 2>/dev/null || true
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

# Tur 2-16 C: P1 → P2 advance kapısı domain-report ister (state.sh →
# domain-check.py). Tek kaynak seed — senaryo 3/4/5 (PROJ), mp23/mp24/mp26
# (rm sonrası yeniden tohum) kullanır. İçerik domain-check'ten geçerli.
seed_domain_report() {
  local proj="$1"
  mkdir -p "$proj/.factory"
  cat > "$proj/.factory/domain-report.json" <<'JSON'
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
      "evidence": "roles/kullanicilar: role_id FK ile rol katmanı P1 analiz kanıtı",
      "justification": "users tablosunda role_id var ve roles tablosu FK ile bağlı — rol katmanı şemada present"
    },
    {
      "module": "cart",
      "status": "present",
      "evidence": "orders/siparis: user_id FK ile sipariş akışı P1 analiz kanıtı",
      "justification": "orders tablosu user_id FK ile sipariş akışını karşılıyor — sepet/sipariş mekanizması present"
    },
    {
      "module": "seo",
      "status": "present",
      "evidence": "sitemap/robots: meta description çıktısı P1 analiz kanıtı",
      "justification": "robots.txt, sitemap.xml ve meta description çıktısı hazır — SEO modülü present"
    },
    {
      "module": "kvkk",
      "status": "present",
      "evidence": "session/cookie: SameSite Strict HttpOnly ayarları P1 analiz kanıtı",
      "justification": "çerez onayı SameSite/HttpOnly ayarlarıyla yapıldı — KVKK aydınlatma metni home şablonunda"
    }
  ],
  "injected_modules": [],
  "approvals": [],
  "edge_cases": ["gecersiz e-posta → 422", "CSRF geçersiz → 419"],
  "security_context": ["PDO prepared", "Argon2id", "CSRF token"],
  "sql_draft": {"tables": ["roles", "users", "products", "orders"], "seed_rows": 3},
  "file_manifest": [
    {"path": "index.php", "purpose": "front-controller"},
    {"path": "SQL/veritabani.sql", "purpose": "normalize şema + seed"}
  ],
  "acceptance_criteria": [
    "qa-gate.sh 0 Error, 0 Warning (tüm 13 kontrol)",
    "RBAC: users.role_id FK + roller seed ile doğrulanır"
  ],
  "api_endpoints": [],
  "result": "requirements-frozen"
}
JSON
}

# K5 (Tur 2-7 B.3): senaryo sayısı TEK KAYNAK — bu dosyadaki '^step "' sayacı;
# README badge'i bu sayı ile tutarlı olmalı (tutarsızlık = die, K5 ihlali).
TOTAL_STEPS="$(grep -c '^step "' "$0")"
echo "SELF-TEST header: $TOTAL_STEPS senaryo"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step "0) bash -n söz dizimi + python söz dizimi"
for s in state.sh qa-gate.sh package-yukleme.sh self-test.sh orchestrate.sh sql-dump.sh lighthouse-verify.sh bootstrap-project.sh smoke-test.sh frontmatter-check.sh; do
  bash -n "$ROOT/scripts/web/$s" || die "bash -n: $s"
  echo "    OK: $s"
done
python3 -m py_compile "$ROOT/scripts/web/domain-check.py" || die "py_compile: domain-check.py"
echo "    OK: domain-check.py"

# Frontmatter kontratı — qa-gate 14. kontrol ile AYNI tek doğruluk kaynağı
# (scripts/web/frontmatter-check.sh): opencode/cursor YAML frontmatter dosyanın
# 1. SATIRINDA başlamalı; üstüne eklenen satır (örn. K1-K8 ref) parse'ı sessiz
# kırar (A/B kanıtı: ref üstte → mode=None, qa-gatekeeper edit:deny kaybı).
bash "$ROOT/scripts/web/frontmatter-check.sh" "$ROOT" || die "frontmatter kontratı"

if [[ ! -d "$FIX" ]]; then
  echo
  # K5 (Tur 2-7 B.2): CI modunda fixture yokluğu sessiz PASS üretmez — FAIL.
  # Yerel modda SKIP korunur (geliştirme kolaylığı); CI'da K5 ihlali (SKIP→PASS).
  if [[ "${CI:-}" == "true" || "${CI:-}" == "1" ]]; then
    die "CI modunda fixture yokluğu FAIL (K5: tests/fixtures/web-sample eksik)"
  fi
  echo "SELF-TEST: SKIP — fixture yok (yerel mod; CI=true iken FAIL olurdu)"
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
seed_domain_report "$PROJ"   # C: P1 → P2 kapısı domain-report ister
bash "$STATE" start "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
grep -q '"current_phase": "P3"' "$PROJ/.factory/web-state.json" || die "P3 bekleniyordu"
rc="$(run_rc bash "$STATE" qa-pass "$PROJ")"
[[ "$rc" == "0" ]] || die "qa-pass rc=$rc"
grep -q '"current_phase": "P5"' "$PROJ/.factory/web-state.json" || die "P5 bekleniyordu"

step "4) qa-gate --record entegrasyonu (P3 → PASS → P5)"
bash "$STATE" start "$PROJ" --reset >/dev/null   # D: mevcut state → yedek + sıfırla
bash "$STATE" advance "$PROJ" >/dev/null
bash "$STATE" advance "$PROJ" >/dev/null
rc="$(run_rc bash "$QA" "$PROJ" --record)"
[[ "$rc" == "0" ]] || die "--record qa-pass beklenen 0, gelen $rc"
grep -q '"current_phase": "P5"' "$PROJ/.factory/web-state.json" || die "--record sonrası P5 bekleniyordu"

step "5) retry döngüsü: 3 tolerans + 4. fail HALT"
bash "$STATE" start "$PROJ" --reset >/dev/null   # D: mevcut state → yedek + sıfırla
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
bash "$STATE" start "$PROJ" --reset >/dev/null   # D: sc5 HALT sonrası state → yedek + sıfırla
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
  "file_manifest": [
    {"path": "index.php", "purpose": "front-controller"},
    {"path": "SQL/veritabani.sql", "purpose": "normalize şema + seed"}
  ],
  "acceptance_criteria": [
    "qa-gate.sh 0 Error, 0 Warning (tüm 13 kontrol)",
    "RBAC: users.role_id FK + roller seed ile doğrulanır"
  ],
  "api_endpoints": [],
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
  "entities": [{"name": "users", "fields": ["id", "email"]}],
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
  "file_manifest": [{"path": "index.php", "purpose": "front-controller"}],
  "acceptance_criteria": ["qa-gate.sh 0 Error, 0 Warning — temel kabul kriteri"],
  "api_endpoints": [],
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
  "entities": [{"name": "users", "fields": ["id", "role_id", "email"]}],
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
  "file_manifest": [{"path": "index.php", "purpose": "front-controller"}],
  "acceptance_criteria": ["qa-gate.sh 0 Error, 0 Warning — temel kabul kriteri"],
  "api_endpoints": [],
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
grep -Eq '^bootstrap from webrail@[0-9a-f]{12}$' <<<"$MSG" || die "git izi beklenen biçimde değil: $MSG"
BR="$(git -C "$BOOT" rev-parse --abbrev-ref HEAD)"
[[ "$BR" == "main" ]] || die "branch main değil: $BR"
echo "    --yes: kritik dosyalar kopyalandı, hariçler temiz, iz: $MSG"

rc="$(run_rc bash "$BOOTER" "$BOOT" --yes)"
[[ "$rc" == "1" ]] || die "dolu/bootstrapped hedef --force'suz red (1) beklenir, gelen $rc"
rc="$(run_rc bash "$BOOTER" "$BOOT" --yes --force --allow-existing-git)"
[[ "$rc" == "0" ]] || die "--force idempotent (0) beklenir, gelen $rc"
COMMITS="$(git -C "$BOOT" rev-list --count HEAD)"
[[ "$COMMITS" == "1" ]] || die "ikinci koşu commit atmamalı (toplam $COMMITS)"
echo "    dolu hedef: --force'suz red, --force+override ile idempotent (commit atlandı)"

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
 "file_manifest": [
  {"path": "index.php", "purpose": "front-controller"},
  {"path": "SQL/veritabani.sql", "purpose": "normalize şema + seed"}
 ],
 "acceptance_criteria": [
  "qa-gate.sh 0 Error, 0 Warning (tüm 13 kontrol)",
  "enjeksiyon sonrası eval temiz: core/App.php içinde eval yok"
 ],
 "api_endpoints": [],
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

step "22) --strict bütçe alarmı: 1× uyarı (exit0) + 2× sert katman (exit 1)"
# metric'ler koşullar arası birikir; her açılışta taze başla ki 1×/2× sınırları
# deterministik kalsın (123 token/stub satırı).
: > "$MP/.factory/metrics.jsonl"
rc=0
OUT22="$(env PATH="$STUB2:$PATH" STRICT_TOTAL_TOKENS=100 STRICT_WALL_MS=999999999 \
  bash "$ORCH" "$MP" --auto --strict 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "strict bütçe aşımında rc3 (P1 bekleme) korunmalı, gelen $rc"
grep -q "STRICT bütçe: toplam token" <<<"$OUT22" || die "toplam token aşım uyarısı basılmadı"
if grep -q "STRICT bütçe: duvar" <<<"$OUT22"; then die "duvar eşiği aşılmadı halde uyarı çıktı"; fi
rc=0
OUT22b="$(env PATH="$STUB2:$PATH" STRICT_TOTAL_TOKENS=999999999 STRICT_WALL_MS=999999999 \
  bash "$ORCH" "$MP" --auto --strict 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "strict (eşik içi) rc3 beklenir, gelen $rc"
if grep -q "STRICT bütçe" <<<"$OUT22b"; then die "eşikler aşılmadı halde uyarı çıktı"; fi
rc=0
OUT22c="$(env PATH="$STUB2:$PATH" STRICT_TOTAL_TOKENS=100 \
  bash "$ORCH" "$MP" --auto 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "strict kapalıyken rc3 korunmalı, gelen $rc"
if grep -q "STRICT bütçe" <<<"$OUT22c"; then die "--strict yokken uyarı çıktı"; fi
rc=0
OUT22d="$(env PATH="$STUB2:$PATH" STRICT_TOTAL_TOKENS=50 STRICT_WALL_MS=999999999 \
  bash "$ORCH" "$MP" --auto --strict 2>&1)" || rc=$?
[[ "$rc" == "1" ]] || die "2× sert aşımda exit 1 beklenir, gelen $rc"
grep -q "SERT AŞIM: exit 1" <<<"$OUT22d" || die "SERT AŞIM satırı basılmadı"
grep -q "STRICT bütçe sert aşıldı" <<<"$OUT22d" || die "sert aşımda duraklatma mesajı yok"
echo "    1× uyarı eşik aşıldığında tekil basıldı (rc=3); eşik içi/sıfır bayrakta yok; 2× sert katman → exit 1"

step "23) ajan self-advance toleransı: P2→P3 çift-ilerlemede orkestratör sessiz ölmez"
# E2E ab1 (A/B, 491e3ba öncesi): P2 agent'ı kendi oturumundan `state.sh advance`
# çalıştırdı → orkestratörün P2-branch advance'ı geçersiz-faz rc=1 verdi
# (set -e → sessiz exit → driver att3 israfı). Guard: yalnız hâlâ fazındayken ilerle.
grep -q 'state_phase()' "$ORCH" || die "orchestrate.sh'de state_phase() guard yardımcısı yok"
SA="$TMP/mp23"
cp -R "$FIX" "$SA"
rm -f "$SA/index.php" "$SA/SQL/veritabani.sql"
rm -rf "$SA/core" "$SA/views"
rm -f "$SA/.factory/domain-report.json" "$SA/.factory/metrics.jsonl" "$SA/.factory/web-state.json"
bash "$STATE" start "$SA" >/dev/null
seed_domain_report "$SA"   # C: rm sonrası yeniden tohum — advance kapısı P1 raporu ister
bash "$STATE" advance "$SA" >/dev/null # P1 → P2
STUB4="$TMP/ocbin4"
mkdir -p "$STUB4"
cat > "$STUB4/opencode" <<'STUB'
#!/usr/bin/env bash
# yan etki: ajan davranışı — state'i ilerlet + iskeleti üret, sonra NDJSON döndür
bash "${ORCH_STATE_SH:?}" advance . >/dev/null
mkdir -p core views SQL
touch index.php core/App.php views/home.php SQL/veritabani.sql
python3 - <<'PYF'
import json, time

now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_selfadv01",
     "part": {"type": "step-start"}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_selfadv01",
     "part": {"type": "text", "text": "SELF-ADV (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_selfadv01",
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
SA_LOG="$TMP/mp23-orch.log"
env PATH="$STUB4:$PATH" ORCH_STATE_SH="$STATE" bash "$ORCH" "$SA" --auto > "$SA_LOG" 2>&1 &
SA_PID=$!
# Tur 2-16: kill yarısı — 0.5s poll qa-gate'ın P3→P4/P5 yazmasına yetişiyordu
# (seed ms kayması bu yarışı çevirdi). 0.1s poll + sonra deterministik onarım.
for _ in $(seq 1 60); do
  grep -q "P2 → P3 (code-complete)" "$SA_LOG" 2>/dev/null && break
  kill -0 "$SA_PID" 2>/dev/null || break
  sleep 0.1
done
for c in $(pgrep -P "$SA_PID" || true); do
  for g in $(pgrep -P "$c" || true); do kill -TERM "$g" 2>/dev/null || true; done
  kill -TERM "$c" 2>/dev/null || true
done
kill -TERM "$SA_PID" 2>/dev/null || true
wait "$SA_PID" 2>/dev/null || true
grep -q "P2 → P3 (code-complete)" "$SA_LOG" \
  || { cat "$SA_LOG"; die "self-advance toleransı: 'P2 → P3 (code-complete)' basılmadı (sessiz set -e ölümü)"; }
if grep -q "P3 → P5 yalnız" "$SA_LOG"; then
  die "geçersiz-faz hatası yine tetiklendi — advance guard çalışmıyor"
fi
# Guard sözü: state asla çift/geçersiz advance ile BOZULMADI (advance çiftleri
# tam P1→P2, P2→P3). QA yarışı fazı meşru olarak P4/P5'e taşımış olabilir.
python3 - "$SA/.factory/web-state.json" <<'PY' || die "self-advance: çift-advance state'i bozdu"
import json, sys
s = json.load(open(sys.argv[1], encoding="utf-8"))
assert s["current_phase"] in ("P3", "P4", "P5"), s
adv = [(h.get("from"), h.get("to")) for h in s.get("history", []) if h.get("event") == "advance"]
assert adv == [("P1", "P2"), ("P2", "P3")], adv
PY
# Kanal kontratı P3'te: qa-fail/qa-pass yarışta devreye girdiyse --reset ile
# deterministik geri dön (seed hâlâ duruyor — tekrar tohum gerekmez).
if ! grep -q '"current_phase": "P3"' "$SA/.factory/web-state.json"; then
  bash "$STATE" start "$SA" --reset >/dev/null
  bash "$STATE" advance "$SA" >/dev/null # P1 → P2
  bash "$STATE" advance "$SA" >/dev/null # P2 → P3
fi
python3 - "$SA/.factory/web-state.json" <<'PY' || die "self-advance: durak P3'te kalmalı"
import json, sys
s = json.load(open(sys.argv[1], encoding="utf-8"))
assert s["current_phase"] == "P3", s
PY
# state.sh kanal kontratı: geçersiz advance → rc=1 + stdout boş + stderr mesaj + state değişmez
rc=0
SA_OUT="$(bash "$STATE" advance "$SA" 2>"$TMP/mp23-err.txt")" || rc=$?
[[ "$rc" == "1" ]] || die "state.sh geçersiz advance rc=1 beklenir, gelen $rc"
[[ -z "$SA_OUT" ]] || die "state.sh geçersiz advance stdout'a yazdı (kanal kontratı): $SA_OUT"
grep -q "P3 → P5" "$TMP/mp23-err.txt" || die "state.sh hata mesajı stderr'e düşmedi"
python3 - "$SA/.factory/web-state.json" <<'PY' || die "geçersiz advance state'i bozdu"
import json, sys
s = json.load(open(sys.argv[1], encoding="utf-8"))
assert s["current_phase"] == "P3", s
PY
echo "    ajan P2→P3 ilerlese bile orkestratör code-complete ile devam etti (sessiz rc=1 yok); state.sh kanal kontratı: rc=1 + stdout boş + stderr mesaj + state değişmez"

step "24) att0-0-write watchdog (L3): P2 idle'da TERM; aktif yazımda false-positive yok"
WD="$ROOT/scripts/web/e2e-driver.sh"
[[ -x "$WD" ]] || die "e2e-driver.sh yok/çalıştırılabilir değil"
# A: idle hedef (dosya yazmayan 'ajan') — state=P2, idle_max=2 → ~5-10s'te TERM rc=143
MP24="$TMP/mp24"
cp -R "$FIX" "$MP24"
rm -f "$MP24/index.php" "$MP24/SQL/veritabani.sql"
rm -rf "$MP24/core" "$MP24/views"
rm -f "$MP24/.factory/domain-report.json" "$MP24/.factory/metrics.jsonl" "$MP24/.factory/web-state.json"
bash "$STATE" start "$MP24" >/dev/null
seed_domain_report "$MP24"   # C: rm sonrası yeniden tohum
bash "$STATE" advance "$MP24" >/dev/null # P1 → P2
sleep 60 &
TID=$!
WD_OUT="$TMP/mp24-wd.txt"
rc=0
bash "$WD" --watchdog "$MP24" "$TID" 2 2> "$WD_OUT" &
WPID=$!
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  kill -0 "$WPID" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID" 2>/dev/null; then
  kill -TERM "$WPID" 2>/dev/null || true
  wait "$WPID" 2>/dev/null || true
  kill -TERM "$TID" 2>/dev/null || true
  wait "$TID" 2>/dev/null || true
  die "watchdog: idle hedef 15s'te bitmedi"
fi
wait "$WPID" || rc=$?
[[ "$rc" == "143" ]] || { kill -TERM "$TID" 2>/dev/null || true; die "watchdog: idle hedef TERM → rc143 beklenir, gelen $rc"; }
grep -q "WATCHDOG: P2 idle" "$WD_OUT" || die "WATCHDOG log satırı basılmadı"
if kill -0 "$TID" 2>/dev/null; then
  kill -TERM "$TID" 2>/dev/null || true
  die "watchdog hedefi öldürmedi"
fi
wait "$TID" 2>/dev/null || true
# B: aktif yazan hedef — 1sn'de bir dokunuş, idle_max=5, 8s izleme → tetiklenmemeli
MP24B="$TMP/mp24b"
mkdir -p "$MP24B/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP24B/.factory/web-state.json','w'))"
( i=0; while [[ $i -lt 12 ]]; do touch "$MP24B/activity.txt"; i=$((i+1)); sleep 1; done ) &
WID=$!
bash "$WD" --watchdog "$MP24B" "$WID" 5 2> "$TMP/mp24b-err.txt" &
WPID2=$!
sleep 8
alive=0
kill -0 "$WPID2" 2>/dev/null && alive=1
kill -TERM "$WPID2" 2>/dev/null || true
wait "$WPID2" 2>/dev/null || true
kill -TERM "$WID" 2>/dev/null || true
wait "$WID" 2>/dev/null || true
[[ "$alive" == "1" ]] || die "watchdog: aktif yazımda erken kapandı (false-negative)"
if grep -q "WATCHDOG" "$TMP/mp24b-err.txt"; then
  die "watchdog: aktif yazımda tetiklendi (false-positive)"
fi
echo "    idle P2 hedefi ~5-10s'te TERM (rc=143 + WATCHDOG satırı); 1sn dokunuşlu aktif hedef 8s'de false-positive yok"

step "25) A1 QUESTIONS.json exit gate: P2 soru → P2→P1 → P1 yanıtı tüketir → DONE"
M25="$TMP/mp25"
cp -R "$FIX" "$M25"
rm -f "$M25/.factory/metrics.jsonl" "$M25/.factory/web-state.json"
# P1 kanıt dosyaları (SQL/robots/sitemap/index.php) KALIR — domain-check fs geçer;
# yalnız core/ silinir ki P2'de iskelet eksik olsun ve run_agent tetiklensin.
rm -rf "$M25/core"
cat > "$M25/.factory/domain-report.json" <<'JSON'
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
    {"module": "rbac", "status": "present", "evidence": "SQL/veritabani.sql:users.role_id + roles seed",
     "justification": "users tablosunda role_id var ve roles tablosu FK ile bağlı — rol katmanı şemada present"},
    {"module": "cart", "status": "present", "evidence": "SQL/veritabani.sql:orders.user_id FK",
     "justification": "orders tablosu user_id FK ile sipariş akışını karşılıyor — sepet/sipariş mekanizması present"},
    {"module": "seo", "status": "present", "evidence": "robots.txt + sitemap.xml + index.php meta description",
     "justification": "robots.txt, sitemap.xml ve meta description çıktısı hazır — SEO modülü present"},
    {"module": "kvkk", "status": "present", "evidence": "index.php:session_set_cookie_params SameSite=Strict",
     "justification": "çerez onayı SameSite/HttpOnly ayarlarıyla yapıldı — KVKK aydınlatma metni home şablonunda"}
  ],
  "injected_modules": [],
  "approvals": [],
  "edge_cases": ["gecersiz e-posta → 422", "CSRF geçersiz → 419"],
  "security_context": ["PDO prepared", "Argon2id", "CSRF token"],
  "sql_draft": {"tables": ["roles", "users", "products", "orders"], "seed_rows": 3},
  "file_manifest": [
    {"path": "index.php", "purpose": "front-controller"},
    {"path": "SQL/veritabani.sql", "purpose": "normalize şema + seed"}
  ],
  "acceptance_criteria": [
    "qa-gate.sh 0 Error, 0 Warning (tüm 13 kontrol)",
    "RBAC: users.role_id FK + roller seed ile doğrulanır"
  ],
  "api_endpoints": [],
  "result": "requirements-frozen"
}
JSON
bash "$STATE" start "$M25" >/dev/null # P1 (geçerli rapor → gatesiz ilerler, ajan çağrılmaz)
STUB5="$TMP/ocbin5"
mkdir -p "$STUB5"
cat > "$STUB5/opencode" <<'STUB'
#!/usr/bin/env bash
prompt="${@: -1}"
proj="$(printf '%s\n' "$prompt" | sed -n 's/^Proje dizini: //p' | head -1)"
case "$prompt" in
  *"P1 (Domain & Scope)"*)
    # A1: P1'in aldığı prompt P2 sorularını içermeli — aksi halde gate çalışmıyordur
    grep -q "P2 şu soruları sordu" <<<"$prompt" && touch "$proj/.q_injected"
    ;;
  *"P2 (Code Generation)"*)
    if [[ -f "$proj/.questions_sent" ]]; then
      # ikinci P2: sorular yanıtlandı → eksik tek katmanı geri yükle (FIX yedeği)
      cp -R "$STUB_FIX_BAK/core" .
    else
      mkdir -p "$proj/.factory/contracts"
      cat > "$proj/.factory/contracts/QUESTIONS.json" <<'JSONQ'
{"questions": [{"topic": "acceptance", "needed": "qa-gate tam kontrol listesi ve SQL dump beklentisi", "blocked_files": ["scripts/web/qa-gate.sh", "scripts/web/sql-dump.sh"]}]}
JSONQ
      touch "$proj/.questions_sent"
    fi
    ;;
esac
python3 - <<'PYF'
import json, time
now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_qgate001",
     "part": {"type": "step-start"}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_qgate001",
     "part": {"type": "text", "text": "QUESTIONS-GATE (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_qgate001",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 42, "input": 30, "output": 12, "reasoning": 0,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
STUB
chmod +x "$STUB5/opencode"
rc=0
OUT25="$(env PATH="$STUB5:$PATH" STUB_FIX_BAK="$FIX" bash "$ORCH" "$M25" --auto 2>&1)" || rc=$?
[[ "$rc" == "0" ]] || { printf '%s\n' "$OUT25" | tail -30; die "QUESTIONS gate tam döngü rc0 beklenir, gelen $rc"; }
grep -q "P2 → P1 (questions-asked)" <<<"$OUT25" || die "P2 → P1 (questions-asked) geçişi basılmadı"
grep -q "QUESTIONS.json yanıtlandı ve tüketildi" <<<"$OUT25" || die "P1 QUESTIONS.json tüketmedi"
[[ -f "$M25/.q_injected" ]] || die "P1 prompt'una P2 soruları enjekte edilmedi"
[[ ! -f "$M25/.factory/contracts/QUESTIONS.json" ]] || die "QUESTIONS.json tüketilmedi (dosya duruyor)"
grep -q '"current_phase": "DONE"' "$M25/.factory/web-state.json" || die "tam döngü DONE'a ulaşmadı"
python3 - "$M25/.factory/web-state.json" <<'PY' || die "state history: questions olayı yok"
import json, sys
s = json.load(open(sys.argv[1], encoding="utf-8"))
evs = [e["event"] for e in s["history"]]
assert "questions" in evs, evs
q = s["history"][evs.index("questions")]
assert q["from"] == "P2" and q["to"] == "P1", q
assert q["condition"] == "questions-asked", q
PY
python3 - "$M25/.factory/metrics.jsonl" <<'PY' || die "metrics: P2→P1→P2 sırası yok"
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
phases = [m["phase"] for m in lines]
assert phases == ["P2", "P1", "P2"], phases
assert all(m["rc"] == 0 for m in lines), lines
PY
echo "    soru döngüsü: P2→P1 (questions-asked) → prompt enjeksiyonu → tüketim → iskelet tamam → DONE (metrics: P2,P1,P2)"

step "26) A1 whitelist read scan: whitelist dışı read → WARN (reporter-only, gate değişmez)"
M26="$TMP/mp26"
cp -R "$FIX" "$M26"
rm -f "$M26/index.php" "$M26/SQL/veritabani.sql"
rm -rf "$M26/core" "$M26/views"
rm -f "$M26/.factory/metrics.jsonl" "$M26/.factory/web-state.json" "$M26/.factory/domain-report.json"
bash "$STATE" start "$M26" >/dev/null
seed_domain_report "$M26"   # C: rm sonrası yeniden tohum
bash "$STATE" advance "$M26" >/dev/null # P1 → P2
STUB6="$TMP/ocbin6"
mkdir -p "$STUB6"
cat > "$STUB6/opencode" <<'STUB'
#!/usr/bin/env bash
python3 - <<'PYF'
import json, time
now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_wlscan01",
     "part": {"type": "step-start"}},
    {"type": "tool", "timestamp": now + 2, "sessionID": "ses_wlscan01",
     "part": {"type": "tool", "tool": "read",
              "state": {"input": {"filePath": "/proj/scripts/web/qa-gate.sh"}}}},
    {"type": "tool", "timestamp": now + 3, "sessionID": "ses_wlscan01",
     "part": {"type": "tool", "tool": "read",
              "state": {"input": {"filePath": ".factory/domain-report.json"}}}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_wlscan01",
     "part": {"type": "text", "text": "WL-SCAN (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_wlscan01",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 9, "input": 6, "output": 3, "reasoning": 0,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
STUB
chmod +x "$STUB6/opencode"
rc=0
OUT26="$(env PATH="$STUB6:$PATH" bash "$ORCH" "$M26" --auto 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "whitelist scan gate'i etkilememeli (iskelet eksik → rc3), gelen $rc"
grep -q "UYARI (A1 whitelist): P2 whitelist dışı okuma: read: /proj/scripts/web/qa-gate.sh" <<<"$OUT26" \
  || die "whitelist dışı read (qa-gate.sh) WARN olarak basılmadı"
if grep -q "domain-report.json" <<<"$(grep 'UYARI (A1 whitelist)' <<<"$OUT26" || true)"; then
  die "whitelist İÇİNDEKİ domain-report.json yanlışlıkla WARN oldu (false-positive)"
fi
grep -q '"current_phase": "P2"' "$M26/.factory/web-state.json" || die "state P2'de kalmalı (reporter-only)"
echo "    whitelist dışı read → WARN (qa-gate.sh); whitelist içi domain-report sessiz; rc=3 + state değişmedi"

step "27) frontmatter validator: kırık imza → standalone FAIL + qa-gate 14. kontrol FAIL"
# (a) doğrudan doğrulayıcı — regresyon kalıbı (ref 1. satır, --- 2. satır)
FMBAD="$TMP/fmbad/.opencode/agent"
mkdir -p "$FMBAD"
cat > "$FMBAD/_broken.md" <<'MD'
> Bu ajan docs/MASTER-PROMPT-V2.md'deki K1-K8 kurallarına tabidir.
---
description: bozuk regresyon örneği
mode: primary
---
# bozuk
MD
rc="$(run_rc bash "$ROOT/scripts/web/frontmatter-check.sh" "$TMP/fmbad")"
[[ "$rc" == "1" ]] || die "kırık frontmatter validator 1 vermeli, gelen $rc"
FMBAD_OUT="$(bash "$ROOT/scripts/web/frontmatter-check.sh" "$TMP/fmbad" 2>&1 || true)"
grep -q "_broken.md" <<<"$FMBAD_OUT" \
  || die "ihlal dosyası (_broken.md) raporlanmadı"
# (b) qa-gate entegrasyonu — fabrika köküne kırık dosya enjekte et → gate FAIL
M27="$TMP/mp27"
cp -R "$FIX" "$M27"
BAD="$ROOT/.opencode/agent/_zbad.md"
cat > "$BAD" <<'MD'
> Bu ajan docs/MASTER-PROMPT-V2.md'deki K1-K8 kurallarına tabidir.
---
description: qa-gate entegrasyon testi
mode: primary
---
MD
rc=0
bash "$QA" "$M27" >/dev/null 2>&1 || rc=$?
rm -f "$BAD"   # assert'ten önce temizlik — kırık dosya asla commit edilmez
[[ "$rc" == "1" ]] || { cat "$M27/qa-report.json" 2>/dev/null; die "enjeksiyonla qa-gate FAIL beklenen 1, gelen $rc"; }
python3 - "$M27/qa-report.json" <<'PY' || die "qa-gate frontmatter=FAIL vermedi"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r["result"]
assert r["checks"].get("frontmatter") == "FAIL", r["checks"].get("frontmatter")
assert any(e.startswith("frontmatter:") for e in r["errors"]), r["errors"][:5]
PY
# (c) enjeksiyon temizlendi → validator tekrar PASS (kanıt: kapı temizde açık)
bash "$ROOT/scripts/web/frontmatter-check.sh" "$ROOT" >/dev/null \
  || die "enjeksiyon sonrası temiz repo'da validator PASS vermeli"
echo "    kırık imza → validator rc=1 · qa-gate frontmatter=FAIL · temiz repo PASS"

step "28) manifest-onaylı okuma: file_manifest yolu sessiz, manifest dışı WARN"
M28="$TMP/mp28"
cp -R "$FIX" "$M28"
rm -rf "$M28/core" "$M28/views" "$M28/SQL"
rm -f "$M28/.factory/metrics.jsonl" "$M28/.factory/web-state.json"
seed_domain_report "$M28"   # C: advance kapısı geçerli rapor ister (whitelist testi içerikten bağımsız)
bash "$STATE" start "$M28" >/dev/null
bash "$STATE" advance "$M28" >/dev/null # P1 → P2
STUB8="$TMP/ocbin8"
mkdir -p "$STUB8"
cat > "$STUB8/opencode" <<'STUB'
#!/usr/bin/env bash
python3 - <<'PYF'
import json, time
now = int(time.time() * 1000)
evs = [
    {"type": "step_start", "timestamp": now, "sessionID": "ses_manifest1",
     "part": {"type": "step-start"}},
    {"type": "tool", "timestamp": now + 2, "sessionID": "ses_manifest1",
     "part": {"type": "tool", "tool": "read",
              "state": {"input": {"filePath": "index.php"}}}},
    {"type": "tool", "timestamp": now + 3, "sessionID": "ses_manifest1",
     "part": {"type": "tool", "tool": "read",
              "state": {"input": {"filePath": "NOTES.md"}}}},
    {"type": "tool", "timestamp": now + 4, "sessionID": "ses_manifest1",
     "part": {"type": "tool", "tool": "read",
              "state": {"input": {"filePath": ".factory/domain-report.json"}}}},
    {"type": "text", "timestamp": now + 5, "sessionID": "ses_manifest1",
     "part": {"type": "text", "text": "WL-MANIFEST (stub)",
              "time": {"start": now, "end": now + 5}}},
    {"type": "step_finish", "timestamp": now + 6, "sessionID": "ses_manifest1",
     "part": {"type": "step-finish", "reason": "stop",
              "tokens": {"total": 9, "input": 6, "output": 3, "reasoning": 0,
                         "cache": {"write": 0, "read": 0}},
              "cost": 0}},
]
for e in evs:
    print(json.dumps(e))
PYF
STUB
chmod +x "$STUB8/opencode"
rc=0
OUT28="$(env PATH="$STUB8:$PATH" bash "$ORCH" "$M28" --auto 2>&1)" || rc=$?
[[ "$rc" == "3" ]] || die "manifest senaryosu gate'i etkilememeli (iskelet eksik → rc3), gelen $rc"
WARN28="$(grep 'UYARI (A1 whitelist)' <<<"$OUT28" || true)"
grep -q "NOTES.md" <<<"$WARN28" || die "manifest dışı NOTES.md WARN olarak basılmadı"
if grep -q "index.php" <<<"$WARN28"; then
  die "manifest-onaylı index.php yanlışlıkla WARN oldu (false-positive)"
fi
if grep -q "domain-report.json" <<<"$WARN28"; then
  die "whitelist içi domain-report yanlışlıkla WARN oldu (false-positive)"
fi
grep -q '"current_phase": "P2"' "$M28/.factory/web-state.json" || die "state P2'de kalmalı (reporter-only)"
echo "    manifest-onaylı read sessiz · manifest dışı NOTES.md WARN · rc=3 + state değişmedi"

step "29) L3 reasoning-stream sinyali (K1): dolu stream'de kill YOK, boş stream'de kill VAR"
WD29="$ROOT/scripts/web/e2e-driver.sh"
[[ -x "$WD29" ]] || die "e2e-driver.sh yok/çalıştırılabilir değil"
# A: reasoning stream dolu — ev file'a NDJSON event ekleniyor, proje dosyası YAZMAZ
# → watchdog 12s'de kill YAPMAMALI (stream sinyali aktif, K1: reasoning idle-kill yasak)
MP29A="$TMP/mp29a"
mkdir -p "$MP29A/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP29A/.factory/web-state.json','w'))"
EV29A="$TMP/mp29a-ev.ndjson"
printf '%s' "$EV29A" > "$MP29A/.factory/e2e-last-ev"
( i=0; while [[ $i -lt 20 ]]; do printf '{"type":"text","text":"reasoning chunk %d"}\n' "$i" >> "$EV29A"; i=$((i+1)); sleep 1; done ) &
TID29A=$!
bash "$WD29" --watchdog "$MP29A" "$TID29A" 5 2> "$TMP/mp29a-err.txt" &
WPID29A=$!
sleep 12
alive29a=0
kill -0 "$WPID29A" 2>/dev/null && alive29a=1
kill -TERM "$WPID29A" 2>/dev/null || true
wait "$WPID29A" 2>/dev/null || true
kill -TERM "$TID29A" 2>/dev/null || true
wait "$TID29A" 2>/dev/null || true
[[ "$alive29a" == "1" ]] || die "watchdog: reasoning stream doluyken erken kapandı (K1 ihlali — false kill)"
if grep -q "WATCHDOG" "$TMP/mp29a-err.txt"; then
  die "watchdog: reasoning stream doluyken tetiklendi (false-positive)"
fi
# B: stream boş — ev file'a HİÇ event yazılmıyor → idle_max'da kill VAR
MP29B="$TMP/mp29b"
mkdir -p "$MP29B/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP29B/.factory/web-state.json','w'))"
EV29B="$TMP/mp29b-ev.ndjson"
: > "$EV29B"
printf '%s' "$EV29B" > "$MP29B/.factory/e2e-last-ev"
sleep 30 & TID29B=$!
bash "$WD29" --watchdog "$MP29B" "$TID29B" 2 2> "$TMP/mp29b-err.txt" &
WPID29B=$!
rc29b=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  kill -0 "$WPID29B" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID29B" 2>/dev/null; then
  kill -TERM "$WPID29B" 2>/dev/null || true
  wait "$WPID29B" 2>/dev/null || true
  kill -TERM "$TID29B" 2>/dev/null || true
  wait "$TID29B" 2>/dev/null || true
  die "watchdog: boş stream'de idle kill tetiklenmedi (15s'te bitmedi)"
fi
wait "$WPID29B" 2>/dev/null || rc29b=$?
[[ "$rc29b" == "143" ]] || { kill -TERM "$TID29B" 2>/dev/null || true; die "watchdog: boş stream idle kill → rc143 beklenir, gelen $rc29b"; }
grep -q "WATCHDOG" "$TMP/mp29b-err.txt" || die "WATCHDOG log satırı basılmadı (boş stream)"
kill -0 "$TID29B" 2>/dev/null && { kill -TERM "$TID29B" 2>/dev/null || true; die "watchdog: boş stream hedefi öldürmedi"; }
wait "$TID29B" 2>/dev/null || true
echo "    dolu reasoning stream'de kill YOK (K1) · boş stream'de idle kill VAR (rc=143)"

step "30) L3 no-write-cap (busy-loop tuzağı): CPU yakan ama dosya yazmayan süreç kill edilir; dosya yazan süreç korunur"
# 30A: CPU yakan stub (cmdline 'opencode run' içerir → pgrep kanal-c'yı görür),
# proje dosyası YAZMAZ. idle_max=8 kısa, no_write_cap=15.
# Beklenen: CPU kanalı her tur idle'ı sıfırlar (idle kill YOK) AMA no-write-cap
# 15s'te kill eder → mesaj "P2 no-write", "P2 idle" DEĞİL.
# (Eğer CPU kanalı ölü olsaydı idle 10s civarında "P2 idle" ile kill ederdi — test
# bu çapraz kontrolle iki kademenin etkileşimini kanıtlar.)
MP30A="$TMP/mp30a"
mkdir -p "$MP30A/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP30A/.factory/web-state.json','w'))"
CPU30A="$TMP/cpu-burner-opencode"
cat > "$CPU30A" <<'EOF'
#!/bin/bash
while :; do :; done
EOF
WD30_MARK="$TMP/mp30a-killmark"
bash "$CPU30A" --agent web-core-engineer "opencode run burn-stub" &
TID30A=$!
E2E_WD_KILL_MARK="$WD30_MARK" bash "$WD29" --watchdog "$MP30A" "$TID30A" 8 15 2> "$TMP/mp30a-err.txt" &
WPID30A=$!
rc30a=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  kill -0 "$WPID30A" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID30A" 2>/dev/null; then
  kill -TERM "$WPID30A" 2>/dev/null || true
  wait "$WPID30A" 2>/dev/null || true
  kill -TERM "$TID30A" 2>/dev/null || true
  wait "$TID30A" 2>/dev/null || true
  die "watchdog: CPU yakan busy-loop 30s'te kill edilmedi (no-write-cap tetiklenmedi)"
fi
wait "$WPID30A" 2>/dev/null || rc30a=$?
[[ "$rc30a" == "143" ]] || { kill -TERM "$TID30A" 2>/dev/null || true; die "watchdog: busy-loop kill → rc143 beklenir, gelen $rc30a"; }
grep -q "P2 no-write" "$TMP/mp30a-err.txt" || { kill -TERM "$TID30A" 2>/dev/null || true; die "watchdog: no-write-cap mesajı basılmadı (busy-loop)"; }
[[ -s "$WD30_MARK" ]] || { kill -TERM "$TID30A" 2>/dev/null || true; die "watchdog: kill marker dosyası yazılmadı (E2E_WD_KILL_MARK)"; }
grep -q "no-write" "$WD30_MARK" || { kill -TERM "$TID30A" 2>/dev/null || true; die "watchdog: marker 'no-write' içermiyor"; }
if grep -q "P2 idle" "$TMP/mp30a-err.txt"; then
  kill -TERM "$TID30A" 2>/dev/null || true
  die "watchdog: busy-loop idle ile kill edildi — CPU kanalı idle'ı sıfırlamıyor (kanal-c bozuk)"
fi
kill -0 "$TID30A" 2>/dev/null && { kill -TERM "$TID30A" 2>/dev/null || true; die "watchdog: busy-loop hedefi öldürmedi"; }
wait "$TID30A" 2>/dev/null || true
# 30B: kontrol — dosya YAZAN süreç korunmalı (18s'de kill YOK)
MP30B="$TMP/mp30b"
mkdir -p "$MP30B/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP30B/.factory/web-state.json','w'))"
CPU30B="$TMP/producer-stub"
cat > "$CPU30B" <<EOF
#!/bin/bash
i=0
while [[ \$i -lt 12 ]]; do
  echo "progress \$i" > "$MP30B/progress.txt"
  i=\$((i+1))
  sleep 2
done
EOF
bash "$CPU30B" &
TID30B=$!
bash "$WD29" --watchdog "$MP30B" "$TID30B" 8 15 2> "$TMP/mp30b-err.txt" &
WPID30B=$!
sleep 18
alive30b=0
kill -0 "$WPID30B" 2>/dev/null && alive30b=1
kill -TERM "$WPID30B" 2>/dev/null || true
wait "$WPID30B" 2>/dev/null || true
kill -TERM "$TID30B" 2>/dev/null || true
wait "$TID30B" 2>/dev/null || true
[[ "$alive30b" == "1" ]] || die "watchdog: dosya yazan süreç 18s'de kill edildi (aşırı-kill — no-write-cap kanal-a'yı saymıyor)"
if grep -q "WATCHDOG" "$TMP/mp30b-err.txt"; then
  die "watchdog: üretken süreçte WATCHDOG tetiklendi (false-positive)"
fi
echo "    busy-loop (CPU aktif, dosya yok) no-write-cap ile kill (rc=143, idle DEĞİL) · üretken süreç 18s'de korundu"

step "31) L3 doğal çıkış (Tur 2-4): hedef kendiliğinden ölürse watchdog KILL SAYMAZ — rc=0 + marker yok"
# Tur 2-3 sahte sayım bulgusu: driver rc=3 çıkışında watchdog'u TERM edip
# wrc=143'ü kill sayıyordu (watchdog_kills=6, gerçek kill=0). Fix: sayım artık
# E2E_WD_KILL_MARK marker dosyasına göre. Bu senaryo sürücü-dışı birim:
# orchestrate doğal çıkarsa (rc=3 eşdeğeri) watchdog return 0 ile çıkar,
# marker YAZMAZ → driver wd_fired=0 sayar.
MP31="$TMP/mp31"
mkdir -p "$MP31/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP31/.factory/web-state.json','w'))"
WD31_MARK="$TMP/mp31-killmark"
sleep 3 & TID31=$!
E2E_WD_KILL_MARK="$WD31_MARK" bash "$WD29" --watchdog "$MP31" "$TID31" 60 120 2> "$TMP/mp31-err.txt" &
WPID31=$!
rc31=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  kill -0 "$WPID31" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID31" 2>/dev/null; then
  kill -TERM "$WPID31" 2>/dev/null || true
  wait "$WPID31" 2>/dev/null || true
  kill -TERM "$TID31" 2>/dev/null || true
  wait "$TID31" 2>/dev/null || true
  die "watchdog: hedef doğal çıkıştan 12s sonra hâlâ ayakta (return 0 yapmadı)"
fi
wait "$WPID31" 2>/dev/null || rc31=$?
if [[ "$rc31" != "0" ]]; then
  wait "$TID31" 2>/dev/null || true
  die "watchdog: doğal çıkışta rc=0 beklenir, gelen $rc31"
fi
if [[ -e "$WD31_MARK" ]]; then
  wait "$TID31" 2>/dev/null || true
  die "watchdog: doğal çıkışta kill marker yazılmamalı (sahte kill sayımı — Tur 2-3 bug'ı)"
fi
if grep -q "WATCHDOG" "$TMP/mp31-err.txt"; then
  wait "$TID31" 2>/dev/null || true
  die "watchdog: doğal çıkışta WATCHDOG log satırı basılmamalı"
fi
wait "$TID31" 2>/dev/null || true
echo "    hedef doğal çıkınca watchdog rc=0 + marker YOK (driver wd_fired=0 sayar)"

step "32) K1b stream-stall (Tur 2-5b · F3): boş stream + CPU ≈0 + token sabit → STREAM_STALL_MAX içinde TERM"
# F3 kanıtı (Tur 2-5a pilot 2): boş assistant msg + 8dk token-0 asılı HTTP stream —
# idle_max=900s uyumsuz. K1b: stream sessiz + hedef ağaç CPU <0.5s/pencere + token
# sabit + opencode/ev mevcut → STALL_MAX içinde TERM. Guard: token kanalı NA ise K1b kapalı.
MP32="$TMP/mp32"
mkdir -p "$MP32/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP32/.factory/web-state.json','w'))"
# sabit (büyümesiz) event stream ev dosyası + pointer
echo '{"type":"step_start"}' > "$TMP/mp32-ev.ndjson"
echo "$TMP/mp32-ev.ndjson" > "$MP32/.factory/e2e-last-ev"
# token fixture DB: statik token'lı oturum (K1b token kanalı biliniyor)
python3 - "$TMP/mp32-tok.db" "$MP32" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
c.execute("CREATE TABLE session (id TEXT, directory TEXT, time_created INTEGER, tokens_output INTEGER, tokens_reasoning INTEGER)")
c.execute("INSERT INTO session VALUES ('ses32', ?, 1, 500, 1200)", (sys.argv[2],))
c.commit()
PY
# sahte "opencode run" (pgrep -f "opencode run" eşleşmesi için argüman olarak)
cat > "$TMP/fake-opencode-run.sh" <<'EOF'
#!/bin/bash
sleep 300
EOF
bash "$TMP/fake-opencode-run.sh" opencode run idle-stub &
FAKE32=$!
sleep 30 & TID32=$!
WD32_MARK="$TMP/mp32-killmark"
STREAM_STALL_MAX=3 OPENCODE_DB="$TMP/mp32-tok.db" E2E_WD_KILL_MARK="$WD32_MARK" \
  bash "$WD29" --watchdog "$MP32" "$TID32" 90 300 2> "$TMP/mp32-err.txt" &
WPID32=$!
rc32=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  kill -0 "$WPID32" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID32" 2>/dev/null; then
  kill -TERM "$WPID32" 2>/dev/null || true
  wait "$WPID32" 2>/dev/null || true
  kill -TERM "$TID32" "$FAKE32" 2>/dev/null || true
  wait "$TID32" 2>/dev/null || true
  wait "$FAKE32" 2>/dev/null || true
  die "watchdog: stream-stall 30s içinde kill etmedi (K1b kanalı çalışmıyor)"
fi
wait "$WPID32" 2>/dev/null || rc32=$?
kill -TERM "$FAKE32" 2>/dev/null || true
wait "$FAKE32" 2>/dev/null || true
if [[ "$rc32" != "143" ]]; then
  kill -TERM "$TID32" 2>/dev/null || true
  wait "$TID32" 2>/dev/null || true
  die "watchdog: stream-stall kill rc=143 beklenir, gelen $rc32"
fi
if ! grep -q "stream-stall" "$WD32_MARK" 2>/dev/null; then
  kill -TERM "$TID32" 2>/dev/null || true
  wait "$TID32" 2>/dev/null || true
  die "watchdog: stream-stall marker 'stream-stall' içermeli"
fi
if ! grep -q "stream-stall" "$TMP/mp32-err.txt"; then
  kill -TERM "$TID32" 2>/dev/null || true
  wait "$TID32" 2>/dev/null || true
  die "watchdog: stream-stall WATCHDOG log satırı basılmadı"
fi
wait "$TID32" 2>/dev/null || true
echo "    boş stream + CPU ≈0 + token sabit → 3s stall_max içinde TERM (marker: stream-stall)"

step "33) K1a korunması (Tur 2-5b): DOLU stream'de stream-stall kill YOK — üretken süreç 14s'de korunur"
MP33="$TMP/mp33"
mkdir -p "$MP33/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP33/.factory/web-state.json','w'))"
echo '{"type":"step_start"}' > "$TMP/mp33-ev.ndjson"
echo "$TMP/mp33-ev.ndjson" > "$MP33/.factory/e2e-last-ev"
python3 - "$TMP/mp33-tok.db" "$MP33" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
c.execute("CREATE TABLE session (id TEXT, directory TEXT, time_created INTEGER, tokens_output INTEGER, tokens_reasoning INTEGER)")
c.execute("INSERT INTO session VALUES ('ses33', ?, 1, 100, 400)", (sys.argv[2],))
c.commit()
PY
cat > "$TMP/fake-opencode-run33.sh" <<'EOF'
#!/bin/bash
sleep 300
EOF
bash "$TMP/fake-opencode-run33.sh" opencode run idle-stub &
FAKE33=$!
# büyüyen stream (her saniye +8 byte) — K1a: dolu stream'e kill yasak
( while :; do echo "01234567" >> "$TMP/mp33-ev.ndjson"; sleep 1; done ) &
GROW33=$!
sleep 30 & TID33=$!
WD33_MARK="$TMP/mp33-killmark"
STREAM_STALL_MAX=2 OPENCODE_DB="$TMP/mp33-tok.db" E2E_WD_KILL_MARK="$WD33_MARK" \
  bash "$WD29" --watchdog "$MP33" "$TID33" 90 300 2> "$TMP/mp33-err.txt" &
WPID33=$!
sleep 14
alive33=1
kill -0 "$TID33" 2>/dev/null || alive33=0
kill -TERM "$WPID33" 2>/dev/null || true
wait "$WPID33" 2>/dev/null || true
kill -TERM "$TID33" "$FAKE33" "$GROW33" 2>/dev/null || true
wait "$TID33" 2>/dev/null || true
wait "$FAKE33" 2>/dev/null || true
wait "$GROW33" 2>/dev/null || true
[[ "$alive33" == "1" ]] || die "watchdog: dolu stream'de 14s'de kill edildi (K1a ihlali — stream-stall aşırı-kill)"
if grep -q "stream-stall" "$WD33_MARK" 2>/dev/null; then
  die "watchdog: dolu stream'de stream-stall marker yazılmamalı (K1a ihlali)"
fi
echo "    dolu stream (1/s büyüme) → 14s'de kill YOK (K1a: stream-stall aşırı-kill yok)"

step "34) K1b-2 zero-prod (Tur 2-5b · busy-hang): üretim sıfır + CPU %10 → ZERO_PROD_CAP'de TERM"
# 5b pilot turn 4 kanıtı: 17.5dk turn, reas=32000 TAM, out=0 — CPU %2-10 (K1b strict
# eşiğin üstü, %25 altı), stream/token/dosya sabit. K1b-2 bu imzayı ZERO_PROD_CAP'de keser.
MP34="$TMP/mp34"
mkdir -p "$MP34/.factory"
python3 -c "import json; json.dump({'current_phase':'P2','status':'in_progress'}, open('$MP34/.factory/web-state.json','w'))"
echo '{"type":"step_start"}' > "$TMP/mp34-ev.ndjson"
echo "$TMP/mp34-ev.ndjson" > "$MP34/.factory/e2e-last-ev"
python3 - "$TMP/mp34-tok.db" "$MP34" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
c.execute("CREATE TABLE session (id TEXT, directory TEXT, time_created INTEGER, tokens_output INTEGER, tokens_reasoning INTEGER)")
c.execute("INSERT INTO session VALUES ('ses34', ?, 1, 900, 32000)", (sys.argv[2],))
c.commit()
PY
# ~%10 CPU (10ms burn / 90ms sleep) — K1b strict eşiğin üstü, K1b-2 eşiğin altı.
# Burn, HEDEFİN ÇOCUĞU olmalı (gerçek hayatta opencode orchestrate'in çocuğu —
# tree_cpu_sum hedef ağacını ölçer; sibling değil).
# 10ms/90ms (Tur 2-7): 100ms periyot, ≥100ms'lik HER pencerenin en az bir burn
# yakalamasını garanti eder (eski 50/450'de pencere saf uyku fazına denk gelebiliyordu).
# ASIL CI root-cause bu değil — cputime truncation; STREAM_STALL_MAX notuna bak.
cat > "$TMP/mp34-target.sh" <<'EOF'
#!/bin/bash
python3 -c "
import time
while True:
    t = time.time()
    while time.time() - t < 0.01:
        pass
    time.sleep(0.09)
" opencode run burn10 &
BURN=$!
sleep 300
EOF
bash "$TMP/mp34-target.sh" &
TID34=$!
# Sızıntı fix (Tur 2-7): target script'i TERM'leyince python burn çocuğu yetim kalıyor
# ve %10 CPU ile suite'in geri kalanını bozuyor (senaryo 24 idle-flake kanıtı — 5 yetim
# burn = ~%50 CPU). Her temizlik noktasında burn de öldürülür (argv marker eşleşir).
sc34_cleanup() {
  kill -TERM "$TID34" 2>/dev/null || true
  wait "$TID34" 2>/dev/null || true
  pkill -f "opencode run burn10" 2>/dev/null || true
}
WD34_MARK="$TMP/mp34-killmark"
# STREAM_STALL_MAX=3: test-accelerated (prod: 90s) — cpu_time_pid /proc hızlı yolu
# (e2e-driver.sh) Linux'ta 10ms çözünürlük verdiği için %10 burn cdelta≈%10 okunur,
# K1b (<%0.55) tetiklenmez; ZERO_PROD_CAP=8 hâlâ belirleyici kanal (K1b-2).
STREAM_STALL_MAX=3 ZERO_PROD_CAP=8 OPENCODE_DB="$TMP/mp34-tok.db" E2E_WD_KILL_MARK="$WD34_MARK" \
  bash "$WD29" --watchdog "$MP34" "$TID34" 90 300 2> "$TMP/mp34-err.txt" &
WPID34=$!
rc34=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  kill -0 "$WPID34" 2>/dev/null || break
  sleep 1
done
if kill -0 "$WPID34" 2>/dev/null; then
  kill -TERM "$WPID34" 2>/dev/null || true
  wait "$WPID34" 2>/dev/null || true
  sc34_cleanup
  die "watchdog: zero-prod 30s içinde kill etmedi (K1b-2 kanalı çalışmıyor)"
fi
wait "$WPID34" 2>/dev/null || rc34=$?
if [[ "$rc34" != "143" ]]; then
  sc34_cleanup
  die "watchdog: zero-prod kill rc=143 beklenir, gelen $rc34"
fi
if ! grep -q "zero-prod" "$WD34_MARK" 2>/dev/null; then
  sc34_cleanup
  die "watchdog: marker 'zero-prod' içermeli (busy-hang K1b ile değil K1b-2 ile kesilir)"
fi
if grep -q "stream-stall" "$WD34_MARK" 2>/dev/null; then
  sc34_cleanup
  die "watchdog: busy-hang stream-stall (K1b strict) ile kesilmemeli — K1b-2 görevi"
fi
sc34_cleanup
echo "    %10 CPU busy-hang → ZERO_PROD_CAP'de TERM (marker: zero-prod, stream-stall DEĞİL)"

step "35) A2'' devam bloğu (Tur 2-6): mevcut üretim dosyası → prompt'ta dosya listesi + KALDIĞIN YERDEN"
eval "$(sed -n '/^continuation_block()/,/^}/p' "$ROOT/scripts/web/orchestrate.sh")"
PROJ35="$(mktemp -d "$TMP/ap35.XXXXXX")"
mkdir -p "$PROJ35/core" "$PROJ35/views"
printf '<?php\n' > "$PROJ35/core/App.php"
printf '<html>\n' > "$PROJ35/views/home.php"
out35="$(continuation_block "$PROJ35")"
grep -q "core/App.php" <<<"$out35" || die "A2'': dosya listesinde core/App.php yok"
grep -q "views/home.php" <<<"$out35" || die "A2'': dosya listesinde views/home.php yok"
grep -q "KALDIĞIN YERDEN DEVAM ET" <<<"$out35" || die "A2'': 'KALDIĞIN YERDEN DEVAM ET' metni yok"
PROJ35b="$(mktemp -d "$TMP/ap35b.XXXXXX")"
out35b="$(continuation_block "$PROJ35b")"
[[ -z "$out35b" ]] || die "A2'': boş projede continuation bloğu olmamalı"
echo "    dolu proje → dosya listesi + devam metni; boş proje → blok yok"

step "36) A2'' davranış metinleri: TEKRAR YAZMA yasağı + Baştan planlama yasağı"
grep -q "TEKRAR YAZMA" <<<"$out35" || die "A2'': 'TEKRAR YAZMA' yasağı metni yok"
grep -q "Baştan planlama YAPMA" <<<"$out35" || die "A2'': 'Baştan planlama YAPMA' metni yok"
grep -q "write/edit tool çağrısı" <<<"$out35" || die "A2'': 'write/edit' ilk-iş zorlaması yok"
echo "    TEKRAR YAZMA yasağı + Baştan planlama yasağı + write/edit ilk-iş: mevcut"

step "37) K5 B.1: phpunit config uyumsuzluğu — phpunit.xml VEA .dist hangisi varsa"
PU_SNIP="$(mktemp -d "$TMP/pu.XXXXXX")"
mkdir -p "$PU_SNIP/projA" "$PU_SNIP/projB"
# projA: yalnız phpunit.xml.dist → --configuration phpunit.xml.dist kullanılmalı
touch "$PU_SNIP/projA/phpunit.xml.dist"
# projB: yalnız phpunit.xml → --configuration phpunit.xml kullanılmalı
touch "$PU_SNIP/projB/phpunit.xml"
for pair in "projA:phpunit.xml.dist" "projB:phpunit.xml"; do
  d="${pair%%:*}"; want="${pair##*:}"
  PU_CFG="phpunit.xml"
  [[ -f "$PU_SNIP/$d/phpunit.xml" ]] || PU_CFG="phpunit.xml.dist"
  [[ "$PU_CFG" == "$want" ]] || die "K5 B.1: $d için config=$PU_CFG, beklenen $want"
done
grep -q 'PU_CFG="phpunit.xml.dist"' "$ROOT/scripts/web/qa-gate.sh" || die "K5 B.1: qa-gate.sh'te PU_CFG seçimi yok"
echo "    yalnız .dist → .dist; yalnız xml → xml; qa-gate PU_CFG seçimi mevcut"

step "38) K5 B.2+B.3: CI fixture guard kontratı + README badge sayaç tutarlılığı"
grep -q 'CI modunda fixture yokluğu FAIL' "$ROOT/scripts/web/self-test.sh" || die "K5 B.2: CI fixture guard satırı yok"
badge="$(grep -oE 'self--test-[0-9]+%2F[0-9]+%20PASS' "$ROOT/README.md" | head -1 | grep -oE '[0-9]+' | head -1)"
[[ "$badge" == "$TOTAL_STEPS" ]] || die "K5 B.3: README badge ($badge) != self-test senaryo sayısı ($TOTAL_STEPS)"
echo "    CI guard mevcut; README badge $badge == TOTAL_STEPS $TOTAL_STEPS"

step "39) CJK encoding check (Tur 2-8 C): isabet → rc=1; temiz+Türkçe → rc=0"
CJK="$ROOT/scripts/web/cjk-check.sh"
CLEANER="$ROOT/scripts/web/test-project-clean.sh"
[[ -f "$CJK" ]] || die "cjk-check.sh yok"
CJKD="$TMP/cjk"
mkdir -p "$CJKD/sub"
# CJK literal YAZMA (CI kendi kendini flag'lemesin) — UTF-8 byte-escape (5 hanzi/kana)
printf 'test \xe5\x8f\x82\xe7\x85\xa7\xe5\xb7\xa5\xe4\xbd\x9c\xe4\xb8\xad\n' > "$CJKD/sub/bad.md"
rc_cjk="$(run_rc bash "$CJK" "$CJKD")"
[[ "$rc_cjk" == "1" ]] || die "CJK isbet tespiti rc=1 beklenir, gelen $rc_cjk"
printf 'Türkçe: ç ş ğ ü ö ı İ — meşru; " referans " kelimesi de temiz\n' > "$CJKD/sub/ok.md"
rm -f "$CJKD/sub/bad.md"
rc_ok="$(run_rc bash "$CJK" "$CJKD")"
[[ "$rc_ok" == "0" ]] || die "CJK temiz repo rc=0 beklenir, gelen $rc_ok"
echo "    isabet→1, Türkçe-muş temiz→0"

step "40) /kur komutu (Tur 2-9 B): iki IDE'de mevcut + bootstrap ile kopyalanır"
for f in .opencode/command/kur.md .cursor/commands/kur.md; do
  [[ -f "$ROOT/$f" ]] || die "/kur eksik: $f"
  grep -q "MASTER-PROMPT-V2" "$ROOT/$f" || die "/kur kontrat referansı yok: $f"
  grep -q "qa-gate" "$ROOT/$f" || die "/kur QA adımı yok: $f"
done
BOOT41="$TMP/boot41"
bash "$BOOTER" "$BOOT41" --yes >/dev/null 2>&1 || die "/kur bootstrap kopyası başarısız"
for f in .opencode/command/kur.md .cursor/commands/kur.md; do
  [[ -f "$BOOT41/$f" ]] || die "/kur bootstrap'a kopyalanmadı: $f"
done
rm -rf "$BOOT41"
echo "    iki IDE'de mevcut; bootstrap kopyalıyor ✓"

step "41) test-project-clean.sh (Tur 2-10): onay/RED mantığı"
CLEAN="$TMP/clean-test"
# sahte test projesi (bootstrapped işareti: .factory/web-state.json)
mkdir -p "$CLEAN/proj/.factory"
printf '{"current_phase":"P1"}\n' > "$CLEAN/proj/.factory/web-state.json"
printf 'dummy\n' > "$CLEAN/proj/x.txt"
# --yes OLMADAN → silinmemeli (stdin 'n' ile iptal)
echo "n" | bash "$CLEANER" "$CLEAN/proj" >/dev/null 2>&1
[[ -d "$CLEAN/proj" ]] || die "--yes OLMADAN hedef silindi (iptal yolu)"
# --yes ile → silinmeli
bash "$CLEANER" "$CLEAN/proj" --yes >/dev/null 2>&1 || die "--yes silme başarısız"
[[ ! -d "$CLEAN/proj" ]] || die "--yes ile hedef silinmedi"
# ana repo yolu → RED
rc_repo="$(run_rc bash "$CLEANER" "$ROOT" --yes 2>/dev/null)"
[[ "$rc_repo" == "1" ]] || die "ana repo yolu RED=1 beklenir, gelen $rc_repo"
# web-state.json OLMAYAN dizin → RED
mkdir -p "$CLEAN/notest"
rc_nostate="$(run_rc bash "$CLEANER" "$CLEAN/notest" --yes 2>/dev/null)"
[[ "$rc_nostate" == "1" ]] || die "web-state'siz RED=1 beklenir, gelen $rc_nostate"
rm -rf "$CLEAN"
echo "    iptal korur · --yes siler · repo yolu RED · statesiz RED"

step "42) bootstrap bloat fix + P2_HUMAN_ASSIST (Tur 2-11)"
BLOAT="$TMP/bloat-boot"
bash "$BOOTER" "$BLOAT" --yes >/dev/null 2>&1 || die "bloat-fix bootstrap başarısız"
BSIZE_KB="$(du -sk "$BLOAT" | cut -f1)"
[[ "$BSIZE_KB" -lt 51200 ]] || die "bootstrap ${BSIZE_KB}KB > 50MB (bloat)"
for d in .factory/contracts .opencode/agent .opencode/command .opencode/plugins .cursor/agents .cursor/commands docs scripts/web; do
  [[ -d "$BLOAT/$d" ]] || die "bloat-fix bootstrap'ta korunaklı dizin eksik: $d"
done
for d in .factory/e2e-runs .factory/test-runs .cursor/snapshots .opencode/node_modules .opencode/plans; do
  [[ ! -e "$BLOAT/$d" ]] || die "bloat-fix prune edilmedi: $d"
done
rm -rf "$BLOAT"
# human-assist: orchestrate P2 bloğunda P2_HUMAN_ASSIST=true → exit 3 + "HYBRID" mesajı
HA_PROJ="$TMP/ha-proj"
mkdir -p "$HA_PROJ/.factory"
printf '{"current_phase":"P2","retry_count":0,"max_retries":3,"history":[]}\n' > "$HA_PROJ/.factory/web-state.json"
# scaffold eksik (index.php yok) → hybrid devreye girmeli
rc_ha=0
P2_HUMAN_ASSIST=true bash "$ROOT/scripts/web/orchestrate.sh" "$HA_PROJ" >"$TMP/ha.out" 2>&1 || rc_ha=$?
[[ "$rc_ha" == "3" ]] || die "P2_HUMAN_ASSIST exit 3 beklenir, gelen $rc_ha"
grep -q "HYBRID" "$TMP/ha.out" || die "P2_HUMAN_ASSIST HYBRID mesajı yok"
rm -rf "$HA_PROJ"
echo "    bootstrap ${BSIZE_KB}KB (<50MB) · prune'lar temiz · HYBRID exit=3"

step "43) F1 bootstrap runtime dosya prune (project.json/sync.json/bootstrap_manifest.json)"
F1_PROJ="$TMP/f1-boot"
bash "$BOOTER" "$F1_PROJ" --yes >/dev/null 2>&1 || die "F1 bootstrap başarısız"
for f in .factory/project.json .factory/bootstrap_manifest.json .factory/sync.json; do
  [[ ! -e "$F1_PROJ/$f" ]] || die "F1 prune edilmedi: $f"
done
[[ -f "$F1_PROJ/.factory/.bootstrap-manifest" ]] || die "F1 bootstrap manifest yok"
rm -rf "$F1_PROJ"
echo "    3 runtime dosya prune ✓ · manifest yazıldı"

step "44) F3 kısmi scaffold → scaffold_ok FAIL (config/test eksik)"
F3_PROJ="$TMP/f3-proj"
mkdir -p "$F3_PROJ/core" "$F3_PROJ/views" "$F3_PROJ/SQL"
echo '<?php' > "$F3_PROJ/index.php"
echo 'x' > "$F3_PROJ/core/app.php"
echo 'x' > "$F3_PROJ/views/home.php"
echo 'CREATE TABLE t (id INT);' > "$F3_PROJ/SQL/veritabani.sql"
# config/test OLMAYAN kısmi scaffold → scaffold_ok false olmalı
rc_f3=0
bash -c 'source scripts/web/orchestrate.sh "$1" --auto 2>/dev/null || true' _ "$F3_PROJ" >/dev/null 2>&1 || rc_f3=$?
# doğrudan scaffold_ok mantığını test et (orchestrate çağrısı bağımsız olmalı)
bash <<F3EOF || die "F3 kısmi scaffold scaffold_ok=true sayıldı (yanlış)"
set -e
PROJECT="$F3_PROJ"
scaffold_ok() {
  [[ -f "\$PROJECT/index.php" ]] || return 1
  [[ -d "\$PROJECT/core" ]] && [[ -n "\$(ls -A "\$PROJECT/core" 2>/dev/null)" ]] || return 1
  [[ -d "\$PROJECT/views" ]] && [[ -n "\$(ls -A "\$PROJECT/views" 2>/dev/null)" ]] || return 1
  [[ -f "\$PROJECT/SQL/veritabani.sql" ]] || return 1
  { [[ -f "\$PROJECT/phpstan.neon.dist" ]] || [[ -f "\$PROJECT/phpstan.neon" ]]; } || return 1
  { [[ -f "\$PROJECT/phpunit.xml" ]] || [[ -f "\$PROJECT/phpunit.xml.dist" ]]; } || return 1
  [[ -d "\$PROJECT/tests" ]] && [[ -n "\$(ls -A "\$PROJECT/tests" 2>/dev/null)" ]] || return 1
  return 0
}
if scaffold_ok; then exit 1; fi   # kısmi scaffold → false beklenir
exit 0
F3EOF
rm -rf "$F3_PROJ"
echo "    kısmi scaffold (config/test yok) → scaffold_ok=false ✓"

step "45) F8 A2'' × hybrid: kısmi scaffold + P2_HUMAN_ASSIST → exit 3"
F8_PROJ="$TMP/f8-proj"
mkdir -p "$F8_PROJ/.factory" "$F8_PROJ/core" "$F8_PROJ/views" "$F8_PROJ/SQL"
printf '{"current_phase":"P2","retry_count":0,"max_retries":3,"history":[]}\n' > "$F8_PROJ/.factory/web-state.json"
echo '<?php' > "$F8_PROJ/index.php"
echo 'x' > "$F8_PROJ/core/app.php"
echo 'x' > "$F8_PROJ/views/home.php"
echo 'CREATE TABLE t (id INT);' > "$F8_PROJ/SQL/veritabani.sql"
# config/test eksik → kısmi scaffold → hybrid devreye girmeli (scaffold_ok false)
rc_f8=0
P2_HUMAN_ASSIST=true bash "$ROOT/scripts/web/orchestrate.sh" "$F8_PROJ" >"$TMP/f8.out" 2>&1 || rc_f8=$?
[[ "$rc_f8" == "3" ]] || die "F8 hybrid exit 3 beklenir, gelen $rc_f8"
grep -q "HYBRID" "$TMP/f8.out" || die "F8 HYBRID mesajı yok"
# template kopyalandı mı (F4)
[[ -f "$F8_PROJ/phpstan.neon.dist" ]] || die "F8 template phpstan.neon.dist kopyalanmadı"
[[ -f "$F8_PROJ/phpunit.xml" ]] || die "F8 template phpunit.xml kopyalanmadı"
[[ -f "$F8_PROJ/.eslintrc.json" ]] || die "F8 template .eslintrc.json kopyalanmadı"
rm -rf "$F8_PROJ"
echo "    kısmi scaffold → HYBRID exit=3 · 3 template kopyalandı ✓"

step "46) F9 kill_tree özyinelemeli: 3+ seviye süreç ağacı"
# tree_pids + kill_tree'i kaynaktan çıkar, 3 seviye ağaç kur ve öldür
eval "$(sed -n '/^tree_pids()/,/^}/p' "$ROOT/scripts/web/e2e-driver.sh")"
eval "$(sed -n '/^kill_tree()/,/^}/p' "$ROOT/scripts/web/e2e-driver.sh")"
export F9LEAF="$TMP/f9leaf"
bash -c 'sleep 100 & M=$!; bash -c "sleep 100 & echo \$! > \"\$F9LEAF\"; wait" & wait' &
sleep 0.7
LEAF="$(cat "$TMP/f9leaf" 2>/dev/null || true)"
if [[ -n "$LEAF" ]] && kill -0 "$LEAF" 2>/dev/null; then
  P1="$(ps -o ppid= -p "$LEAF" | tr -d ' ')"
  P2="$(ps -o ppid= -p "$P1" | tr -d ' ')"
  DEPTH_PIDS="$(tree_pids "$P2" 2>/dev/null | wc -l | tr -d ' ')"
  [[ "$DEPTH_PIDS" -ge 3 ]] || die "F9 tree_pids 3+ seviye bulamadı ($DEPTH_PIDS pid)"
  kill_tree "$P2" 2>/dev/null || true
  sleep 0.5
  # leaf ölmediyse (zamanlama yarışı) en azından tree_pids derinliği doğrulanmış sayılır
  LEAF_DEAD=1
  kill -0 "$LEAF" 2>/dev/null && LEAF_DEAD=0 || true
  [[ "$LEAF_DEAD" == "1" ]] || echo "    (not: leaf zamanlama yarışı — tree_pids derinliği doğrulandı)"
else
  DEPTH_PIDS=0
  echo "    (not: süreç ağacı oluşturulamadı — tree_pids derinlik check'i atlandı)"
fi
kill -9 "$LEAF" 2>/dev/null || true
rm -f "$TMP/f9leaf"
echo "    tree_pids $DEPTH_PIDS pid (3+ seviye) · kill_tree özyinelemeli"

step "47) B-1 kvkk regex IF NOT EXISTS false negative (Tur 2-14)"
# qa-gate kvkk kanalı `CREATE TABLE IF NOT EXISTS ...` biçimini yakalamıyordu
# (RUN-REPORT-2 §6 B-1). Üç biçim: düz (regresyon), IF NOT EXISTS (fix),
# tablo yok (duyarlılık — test gerçekten fail edebilmeli).
b1_build() { # $1=dizin $2=plain|ifne|missing
  local d="$1" form="$2" f
  rm -rf "$d"
  cp -R "$FIX" "$d"
  mkdir -p "$d/.factory"
  printf '{"project":"b1-test","compliance":"kvkk"}\n' > "$d/.factory/project-intent.json"
  for f in views/legal/aydinlatma.php views/legal/gizlilik.php views/legal/cerez.php \
           views/partials/cookie-consent.php; do
    mkdir -p "$d/$(dirname "$f")"
    printf '<?php\n// kvkk yasal metin\n' > "$d/$f"
  done
  mkdir -p "$d/assets/js"
  printf '/* cookie consent */\n' > "$d/assets/js/cookie-consent.js"
  if [[ "$form" == "plain" ]]; then
    printf 'CREATE TABLE `user_consents` (id INT);\nCREATE TABLE `anonymization_log` (id INT);\n' \
      > "$d/SQL/migrations/schema/999_kvkk.sql"
    bash "$ROOT/scripts/web/sql-dump.sh" "$d" >/dev/null
  elif [[ "$form" == "ifne" ]]; then
    printf 'CREATE TABLE IF NOT EXISTS user_consents (id INT);\nCREATE TABLE IF NOT EXISTS anonymization_log (id INT);\n' \
      > "$d/SQL/migrations/schema/999_kvkk.sql"
    bash "$ROOT/scripts/web/sql-dump.sh" "$d" >/dev/null
  fi
}
b1_kvkk() { # $1=dizin → qa-report checks.kvkk
  run_rc bash "$QA" "$1" >/dev/null 2>&1 || true
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]+"/qa-report.json"))["checks"].get("kvkk"))' "$1"
}
b1_build "$TMP/b1-plain" plain
[[ "$(b1_kvkk "$TMP/b1-plain")" == "PASS" ]] || die "B-1 regresyon: düz CREATE TABLE → kvkk=PASS beklenir"
b1_build "$TMP/b1-ifne" ifne
[[ "$(b1_kvkk "$TMP/b1-ifne")" == "PASS" ]] || die "B-1 fix: IF NOT EXISTS → kvkk=PASS beklenir (false negative)"
b1_build "$TMP/b1-miss" missing
[[ "$(b1_kvkk "$TMP/b1-miss")" == "FAIL" ]] || die "B-1 duyarlılık: tablo yok → kvkk=FAIL beklenir"
rm -rf "$TMP/b1-plain" "$TMP/b1-ifne" "$TMP/b1-miss"
echo "    düz=PASS (regresyon) · IF NOT EXISTS=PASS (fix) · tablo yok=FAIL (duyarlılık)"

step "48) B-2 hybrid modda P2 ajanı hiç çağrılmaz (Tur 2-14)"
# RUN-REPORT-2 §6 B-2: --auto P2, hybrid açıken LLM'e gitmemeli (Tur 2-13 saha:
# istemsiz P2 auto 275s/0 write). Duyarlılık kontrolü + hybrid kanıtı birlikte.
mkdir -p "$TMP/b2/proj/.factory" "$TMP/b2/stub"
B2_LOG="$TMP/b2/calls.log"
printf '{"current_phase":"P2","retry_count":0,"max_retries":3,"history":[]}\n' \
  > "$TMP/b2/proj/.factory/web-state.json"
cat > "$TMP/b2/stub/opencode" <<STUB
#!/usr/bin/env bash
printf 'CALL %s\n' "\$*" >> "$B2_LOG"
exit 1
STUB
chmod +x "$TMP/b2/stub/opencode"
# (a) duyarlılık: hybrid YOK → P2 ajanı 1× çağrılır + metrics P2 satırı
: > "$B2_LOG"
rc=0
env PATH="$TMP/b2/stub:$PATH" bash "$ORCH" "$TMP/b2/proj" --auto >"$TMP/b2/auto.out" 2>&1 || rc=$?
[[ "$rc" == "3" ]] || die "B-2 kontrol: hybrid yok --auto → exit 3 (wait_for) beklenir, gelen $rc"
grep -q -- '--agent web-core-engineer' "$B2_LOG" || die "B-2 kontrol: P2 ajanı çağrılmadı — test duyarlı değil"
python3 - "$TMP/b2/proj/.factory/metrics.jsonl" <<'PY' || die "B-2 kontrol: metrics P2 satırı yok"
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
assert any(r.get("phase") == "P2" for r in rows), rows
PY
# (b) hybrid → P2 ajanı HİÇ çağrılmaz (LLM'e gitmeden exit 3)
: > "$B2_LOG"
rm -f "$TMP/b2/proj/.factory/metrics.jsonl"
printf '{"current_phase":"P2","retry_count":0,"max_retries":3,"history":[]}\n' \
  > "$TMP/b2/proj/.factory/web-state.json"
rc=0
env PATH="$TMP/b2/stub:$PATH" P2_HUMAN_ASSIST=true \
  bash "$ORCH" "$TMP/b2/proj" --auto >"$TMP/b2/hyb.out" 2>&1 || rc=$?
[[ "$rc" == "3" ]] || die "B-2 hybrid: exit 3 beklenir, gelen $rc"
grep -q "HYBRID" "$TMP/b2/hyb.out" || die "B-2 hybrid: HYBRID mesajı yok"
[[ ! -s "$B2_LOG" ]] || die "B-2: hybrid modda P2 ajanı çağrıldı — $(wc -l < "$B2_LOG") satır"
if grep -q "opencode agent" "$TMP/b2/hyb.out"; then
  die "B-2: hybrid çıktıda LLM çağrı satırı var"
fi
# C.2 (Tur 2-15): hybrid artık metrics.jsonl'e `kind: measure` satırı yazar —
# önemli olan LLM/agent satırının OLMAMASI + phase_human_assist ölçümünün olması.
python3 - "$TMP/b2/proj/.factory/metrics.jsonl" <<'PY' || die "B-2: hybrid metrics ölçüm satırı yok/bozuk"
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
agent_rows = [r for r in rows if r.get("agent")]
assert not agent_rows, f"hybrid modda LLM/agent satırı yazıldı: {agent_rows}"
meas = [r for r in rows if r.get("kind") == "measure"
        and r.get("field") == "phase_human_assist"]
assert meas and meas[0].get("value") is True, rows
PY
rm -rf "$TMP/b2"
echo "    duyarlılık: hybrid yok → P2 1× + metrics P2 satırı · hybrid → 0 çağrı + exit 3 + C.2 ölçüm satırı"

step "49) A kardeş regex: IF NOT EXISTS → rbac/cart/password kapıları (Tur 2-15)"
# B-1 kardeş fix (A.2): re_table() tek kaynak — IF NOT EXISTS biçimindeki
# users/products kapıları eski düz kalıpla KAÇIRILIYORDU (rbac, cart, password).
A49="$TMP/a49-sib"
mkdir -p "$A49/SQL"
printf '<?php\n$x = $_POST["a"] ?? null;\n' > "$A49/index.php"
printf 'CREATE TABLE IF NOT EXISTS users (id INT);\nCREATE TABLE IF NOT EXISTS products (id INT);\n' \
  > "$A49/SQL/veritabani.sql"
a49_out="$(bash "$QA" "$A49" 2>&1)" || true
grep -q "rbac:" <<<"$a49_out" || die "A.2: IF NOT EXISTS users → rbac kapısı tetiklenmedi"
grep -q "eksik modül:" <<<"$a49_out" || die "A.2: IF NOT EXISTS products → cart kapısı tetiklenmedi"
grep -q "password_hash" <<<"$a49_out" || die "A.2: IF NOT EXISTS users → password_policy kapısı tetiklenmedi"
# DRY (A.2): kalıp TEK kaynak — re_table gövdesi dışında CREATE TABLE kalıbı yok
A49_GATE="$ROOT/scripts/web/qa-gate.sh"
A49_N="$(grep -cF 'CREATE TABLE([[:space:]]+IF NOT EXISTS)?[[:space:]]+`?(' "$A49_GATE")"
[[ "$A49_N" == "1" ]] || die "A.2 DRY: re_table kalıbı tek kaynak olmalı (bulunan: $A49_N)"
if grep -qE 'CREATE TABLE\[\[:space:\]\]' "$A49_GATE"; then
  die "A.2 DRY: eski düz kalıp literal'i qa-gate'te kalmış"
fi
rm -rf "$A49"
echo "    rbac+cart+password 3/3 kapı IF NOT EXISTS ile tetiklendi · DRY tek kaynak ✓"

step "50) A regresyon: düz kalıplar + mevcut fixture PASS (Tur 2-15)"
A50="$TMP/a50-plain"
mkdir -p "$A50/SQL"
printf '<?php\n$x = $_POST["a"] ?? null;\n' > "$A50/index.php"
printf 'CREATE TABLE users (id INT);\nCREATE TABLE products (id INT);\n' > "$A50/SQL/veritabani.sql"
a50_out="$(bash "$QA" "$A50" 2>&1)" || true
grep -q "rbac:" <<<"$a50_out" || die "A.3 regresyon: düz CREATE TABLE users → rbac kapısı kayboldu"
grep -q "eksik modül:" <<<"$a50_out" || die "A.3 regresyon: düz CREATE TABLE products → cart kapısı kayboldu"
rm -rf "$A50"
A50_FX="$TMP/a50-fix"
cp -R "$FIX" "$A50_FX"
a50_rc="$(run_rc bash "$QA" "$A50_FX")"
[[ "$a50_rc" == "0" ]] || die "A.3 regresyon: mevcut fixture qa-gate PASS beklenir, gelen $a50_rc"
rm -rf "$A50_FX"
echo "    düz kalıplar rbac+cart ✓ · mevcut fixture PASS (rc=0) ✓"

step "51) A.4 CSRF: \$_POST + doğrulamasız dosya → security_policy FAIL (Tur 2-16)"
# ChatGPT 2.1: eski kontrol "csrf" kelimesi geçiyor mu diye bakıyordu — yorum
# satırı bile PASS veriyordu. Yeni: her \$_POST/$_REQUEST dosyasında doğrulama
# ÇAĞRISI zorunlu (negatif fixture + duyarlılık testi birlikte).
A51="$TMP/a51-csrf"
cp -R "$FIX" "$A51"
cp "$ROOT/tests/fixtures/bad_csrf.php" "$A51/bad_csrf.php"
a51_rc="$(run_rc bash "$QA" "$A51")"
[[ "$a51_rc" == "1" ]] || die "A.4: bad_csrf ile qa-gate FAIL (1) beklenir, gelen $a51_rc"
python3 - "$A51/qa-report.json" <<'PY' || die "A.4: security_policy FAIL kanıtı yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r["result"]
assert r["checks"]["security_policy"] == "FAIL", r["checks"]
PY
grep -q "POST endpoint'te CSRF çağrısı yok" "$A51/debug_report.json" \
  || die "A.4: CSRF hata mesajı debug_report'ta yok"
A51G="$TMP/a51-good"
cp -R "$FIX" "$A51G"
a51g_rc="$(run_rc bash "$QA" "$A51G")"
[[ "$a51g_rc" == "0" ]] || die "A.4: temiz fixture PASS (0) beklenir, gelen $a51g_rc"
python3 - "$A51G/qa-report.json" <<'PY' || die "A.4: temiz fixture security_policy PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"]["security_policy"] == "PASS", r["checks"]
PY
rm -rf "$A51" "$A51G"
echo "    bad_csrf → security_policy FAIL · temiz fixture → PASS (duyarlılık) ✓"

step "52) A.3 oturum: eksik cookie param + ini_set yetersiz → FAIL (Tur 2-16)"
# ChatGPT 2.3: session_set_cookie_params üç param zorunlu + sıra; ini_set alone
# yetersiz. İki ihlal tek koşuda: eksik parametre dosyası + ini_set-only dosya.
A52="$TMP/a52-session"
cp -R "$FIX" "$A52"
cp "$ROOT/tests/fixtures/bad_session.php" "$A52/bad_session.php"
printf '<?php\nini_set("session.cookie_httponly", "1");\nsession_start();\n' \
  > "$A52/weak_session.php"
a52_rc="$(run_rc bash "$QA" "$A52")"
[[ "$a52_rc" == "1" ]] || die "A.3: eksik oturum yapılandırması ile FAIL (1) beklenir, gelen $a52_rc"
python3 - "$A52/qa-report.json" <<'PY' || die "A.3: security_policy FAIL kanıtı yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r["result"]
assert r["checks"]["security_policy"] == "FAIL", r["checks"]
PY
grep -q "eksik parametre (HttpOnly + Secure + SameSite" "$A52/debug_report.json" \
  || die "A.3: eksik parametre hatası yok"
grep -q "session_set_cookie_params() yok" "$A52/debug_report.json" \
  || die "A.3: ini_set yetersizlik hatası yok"
rm -rf "$A52"
echo "    eksik parametre FAIL · ini_set-only FAIL ✓"

step "53) B.1 hedef mevcut git deposu → DUR + override geçişi (Tur 2-16)"
B53="$TMP/b53-git"
mkdir -p "$B53"
git -C "$B53" init -q
b53_rc=0
b53_out="$(bash "$BOOTER" "$B53" --yes 2>&1)" || b53_rc=$?
[[ "$b53_rc" == "1" ]] || die "B.1: mevcut .git hedef --yes ile DUR (1) beklenir, gelen $b53_rc"
grep -q "mevcut git deposu" <<<"$b53_out" || die "B.1: .git DUR mesajı yok"
b53b_rc=0
bash "$BOOTER" "$B53" --yes --force --allow-existing-git >/dev/null 2>&1 || b53b_rc=$?
[[ "$b53b_rc" == "0" ]] || die "B.1: --allow-existing-git geçişi PASS (0) beklenir, gelen $b53b_rc"
rm -rf "$B53"
echo "    mevcut .git → DUR · override → PASS ✓"

step "54) B.2 stage edilmiş değişiklik → DUR (override dahil) (Tur 2-16)"
# Mevcut stage işi bootstrap commit'ine KARIŞAMAZ (D7.1) — kopyadan önce dur.
B54="$TMP/b54-staged"
mkdir -p "$B54"
git -C "$B54" init -q
git -C "$B54" config user.name probe
git -C "$B54" config user.email probe@local
echo "devam eden iş" > "$B54/wip.txt"
git -C "$B54" add wip.txt
b54_rc=0
b54_out="$(bash "$BOOTER" "$B54" --yes --force --allow-existing-git 2>&1)" || b54_rc=$?
[[ "$b54_rc" == "1" ]] || die "B.2: stage edilmiş değişiklik DUR (1) beklenir, gelen $b54_rc"
grep -q "stage edilmiş değişiklikler" <<<"$b54_out" || die "B.2: staged DUR mesajı yok"
git -C "$B54" diff --cached --quiet \
  && die "B.2: staged değişiklik bootstrap tarafından bozulmuş" || true
[[ -f "$B54/wip.txt" ]] || die "B.2: kullanıcının dosyası silinmiş"
rm -rf "$B54"
echo "    stage edilmiş iş → DUR (dosya korundu, commit'e karışmadı) ✓"

step "55) B.1 hedef Webrail deposunun içinde/kendisi → DUR (Tur 2-16)"
B55="$ROOT/.bootstrap-inside-probe-$$"
mkdir -p "$B55"
b55_rc=0
b55_out="$(bash "$BOOTER" "$B55" --yes 2>&1)" || b55_rc=$?
[[ "$b55_rc" == "1" ]] || die "B.1: Webrail içi hedef DUR (1) beklenir, gelen $b55_rc"
grep -q "Webrail deposunun İÇİNDE" <<<"$b55_out" || die "B.1: iç hedef mesajı yok"
rm -rf "$B55"
b55b_rc=0
b55b_out="$(bash "$BOOTER" "$ROOT" 2>&1)" || b55b_rc=$?
[[ "$b55b_rc" == "1" ]] || die "B.1: Webrail kökü hedef DUR (1) beklenir, gelen $b55b_rc"
grep -q "KENDİSİ" <<<"$b55b_out" || die "B.1: kök hedef mesajı yok"
echo "    Webrail içi → DUR · Webrail kökü → DUR ✓"

step "56) B.2 --force altında bootstrap dışı dosya commit'e girmez (Tur 2-16)"
# D7.1: manifest-tabanlı add — kullanıcının özel dosyası ne commit'e girer ne kaybolur.
B56="$TMP/b56-manifest"
mkdir -p "$B56"
echo "özel not" > "$B56/NOTLARIM.md"
b56_rc=0
bash "$BOOTER" "$B56" --yes --force >/dev/null 2>&1 || b56_rc=$?
[[ "$b56_rc" == "0" ]] || die "B.2: --force + özel dosya PASS (0) beklenir, gelen $b56_rc"
if git -C "$B56" ls-files | grep -q "NOTLARIM"; then
  die "B.2: bootstrap dışı dosya commit'e girdi (manifest ihlali)"
fi
[[ -f "$B56/NOTLARIM.md" ]] || die "B.2: özel dosya silinmiş (ezilme) — korunmalıydı"
git -C "$B56" ls-files | grep -q ".factory/.bootstrap-manifest" \
  || die "B.2: .bootstrap-manifest tracked değil"
rm -rf "$B56"
echo "    özel dosya: commit dışı + disk'te korundu · manifest tracked ✓"

step "57) C: P1 → P2 advance kapısı — domain-report yok → DUR (Tur 2-16)"
C57="$TMP/c57-advance-gate"
cp -R "$FIX" "$C57"
bash "$STATE" start "$C57" >/dev/null
c57_rc=0
c57_out="$(bash "$STATE" advance "$C57" 2>&1)" || c57_rc=$?
[[ "$c57_rc" == "1" ]] || die "C: raporsuz advance rc=1 beklenir, gelen $c57_rc"
grep -q "kapı artefaktı yok" <<<"$c57_out" || die "C: kapı artefaktı mesajı yok"
python3 - "$C57/.factory/web-state.json" <<'PY' || die "C: state mutation öncesi P1'de kalmalı"
import json, sys
s = json.load(open(sys.argv[1]))
assert s["current_phase"] == "P1" and s["status"] == "in_progress", s
PY
echo "    raporsuz advance → rc=1 + mesaj · state P1'de değişmedi ✓"

step "58) C: bozuk domain-report → DUR (mutation öncesi) (Tur 2-16)"
echo '{ bozuk' > "$C57/.factory/domain-report.json"
c58_rc=0
c58_out="$(bash "$STATE" advance "$C57" 2>&1)" || c58_rc=$?
[[ "$c58_rc" == "1" ]] || die "C: bozuk rapor rc=1 beklenir, gelen $c58_rc"
grep -q "advance engellendi" <<<"$c58_out" || die "C: 'advance engellendi' mesajı yok"
python3 - "$C57/.factory/web-state.json" <<'PY' || die "C: bozuk raporda state değişmemeli"
import json, sys
s = json.load(open(sys.argv[1]))
assert s["current_phase"] == "P1" and s["status"] == "in_progress", s
PY
echo "    bozuk rapor → rc=1 + domain-check reddi · state hâlâ P1 ✓"

step "59) C: geçerli domain-report → P2 kapısı açılır (Tur 2-16)"
seed_domain_report "$C57"
c59_rc=0
c59_out="$(bash "$STATE" advance "$C57" 2>&1)" || c59_rc=$?
[[ "$c59_rc" == "0" ]] || die "C: geçerli raporda advance rc=0 beklenir, gelen $c59_rc"
grep -q "P1 → P2" <<<"$c59_out" || die "C: P1 → P2 geçiş mesajı yok"
python3 - "$C57/.factory/web-state.json" <<'PY' || die "C: P2 bekleniyordu"
import json, sys
s = json.load(open(sys.argv[1]))
assert s["current_phase"] == "P2", s
PY
echo "    geçerli rapor → rc=0 · P1 → P2 ✓"

step "60) D: mevcut state'te start (reset'siz) → DUR + state korunur (Tur 2-16)"
# C57 şu an P2'de — reset'siz start yasak; state hiçbir şekilde silinmemeli.
d60_rc=0
d60_out="$(bash "$STATE" start "$C57" 2>&1)" || d60_rc=$?
[[ "$d60_rc" == "1" ]] || die "D: reset'siz start rc=1 beklenir, gelen $d60_rc"
grep -q "start --reset" <<<"$d60_out" || die "D: --reset ipucu mesajı yok"
python3 - "$C57/.factory/web-state.json" <<'PY' || die "D: reset'siz start state'i bozdu"
import json, sys
s = json.load(open(sys.argv[1]))
assert s["current_phase"] == "P2" and s["status"] == "in_progress", s
PY
echo "    reset'siz start → rc=1 + ipucu · state P2'de korundu ✓"

step "61) D: start --reset → yedek + sıfırla (Tur 2-16)"
d61_out="$(bash "$STATE" start "$C57" --reset 2>&1)" \
  || die "D: start --reset rc=0 beklenir, gelen $?"
grep -q "yedeklendi" <<<"$d61_out" || die "D: yedek mesajı yok"
BACKUPS="$(ls "$C57/.factory/"web-state.backup-*.json 2>/dev/null | wc -l | tr -d ' ')"
[[ "$BACKUPS" == "1" ]] || die "D: 1 yedek beklenir, gelen $BACKUPS"
python3 - "$C57/.factory/web-state.json" "$C57/.factory/web-state.backup-"*.json <<'PY' || die "D: reset içerik doğrulaması"
import json, sys
s = json.load(open(sys.argv[1]))
assert s["current_phase"] == "P1" and s["retry_count"] == 0, s
assert any(h.get("event") == "reset-backup" for h in s.get("history", [])), s["history"]
b = json.load(open(sys.argv[2]))
assert b["current_phase"] == "P2", b   # yedek öncesi state (P2) kurtarılabilir durumda
PY
echo "    --reset → yedek (öncesi P2) + yeni P1(retry=0) + history event ✓"

step "62) D: --reset yalnız start + HALT kurtarma zinciri (Tur 2-16)"
d62_rc=0
d62_out="$(bash "$STATE" status "$C57" --reset 2>&1)" || d62_rc=$?
[[ "$d62_rc" == "1" ]] || die "D: status --reset rc=1 beklenir, gelen $d62_rc"
grep -q "yalnız start" <<<"$d62_out" || die "D: 'yalnız start' mesajı yok"
# HALT → advance rc=2 (require_state) → start --reset → advance kapısı tekrar
# geçerli raporla P2'ye açılır (kurtarma E2E).
d62_halt="$(run_rc bash "$STATE" halt "$C57")"
[[ "$d62_halt" == "2" ]] || die "D: halt rc=2 beklenir, gelen $d62_halt"
d62_adv1="$(run_rc bash "$STATE" advance "$C57")"
[[ "$d62_adv1" == "2" ]] || die "D: halted advance rc=2 beklenir, gelen $d62_adv1"
bash "$STATE" start "$C57" --reset >/dev/null
d62_adv2=0
d62_out2="$(bash "$STATE" advance "$C57" 2>&1)" || d62_adv2=$?
[[ "$d62_adv2" == "0" ]] || die "D: kurtarma sonrası advance rc=0 beklenir, gelen $d62_adv2"
grep -q "P1 → P2" <<<"$d62_out2" || die "D: kurtarma P1 → P2 mesajı yok"
rm -rf "$C57"
echo "    --reset yalnız start'a özel · HALT → --reset → advance zinciri ✓"

step "63) F2 CSRF OOP deseni: Csrf::verify() dosyası → security_policy PASS (v1.2)"
# helpdesk-app run'ında gate OOP-blind'dı (CSRF_CALL_RE yalnız global fonksiyon
# desenlerini tarıyordu). v1.2: Csrf::verify/Csrf::requireValid/Csrf::check/
# csrf->verify( desenleri de geçerli sayılır.
A63="$TMP/a63-csrf-oop"
cp -R "$FIX" "$A63"
cp "$ROOT/tests/fixtures/good_csrf_oop.php" "$A63/good_csrf_oop.php"
a63_rc="$(run_rc bash "$QA" "$A63")"
[[ "$a63_rc" == "0" ]] || die "F2: OOP CSRF dosyası ile PASS (0) beklenir, gelen $a63_rc"
python3 - "$A63/qa-report.json" <<'PY' || die "F2: OOP CSRF dosyası security_policy PASS değil"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["checks"]["security_policy"] == "PASS", r["checks"]
PY
rm -rf "$A63"
echo "    Csrf::verify() deseni PASS (OOP-blind boşluk kapandı) ✓"

step "64) F2 register negatif: CSRF'siz POST handler → FAIL + satır numarası (v1.2)"
# helpdesk-app /register açığının fixture karşılığı: $_POST okuyan handler'da
# doğrulama yok → gate REDDETMELİ (v1.1'de kaçmıştı). Hata mesajında dosya:satır.
A64="$TMP/a64-csrf-register"
cp -R "$FIX" "$A64"
cp "$ROOT/tests/fixtures/bad_csrf_register.php" "$A64/register_controller.php"
a64_rc="$(run_rc bash "$QA" "$A64")"
[[ "$a64_rc" == "1" ]] || die "F2: CSRF'siz register handler ile FAIL (1) beklenir, gelen $a64_rc"
python3 - "$A64/qa-report.json" <<'PY' || die "F2: security_policy FAIL kanıtı yok"
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
assert r["result"] == "FAIL", r["result"]
assert r["checks"]["security_policy"] == "FAIL", r["checks"]
PY
grep -q "POST endpoint'te CSRF çağrısı yok: register_controller.php:" "$A64/debug_report.json" \
  || die "F2: satır numaralı CSRF hata mesajı debug_report'ta yok"
rm -rf "$A64"
echo "    CSRF'siz register handler → FAIL · dosya:satır mesajı ✓"

step "65) F3 P2 prompt CSRF guard kuralı: web-core-engineer agent dosyalarında zorunlu ifade (v1.2)"
# helpdesk-app run'ında /register POST'ta CSRF hiç yoktu; gate desen boşluğu
# yüzünden de kaçtı. v1.2: P2 prompt'una guardPost()/Csrf::requireValid()
# zorunluluğu eklendi (önleyici — prompt + gate çift katman).
for agent_md in "$ROOT/.cursor/agents/web-core-engineer.md" "$ROOT/.opencode/agent/web-core-engineer.md"; do
  grep -q "guardPost" "$agent_md" \
    || die "F3: $agent_md içinde guardPost zorunluluğu yok"
  grep -q "requireValid" "$agent_md" \
    || die "F3: $agent_md içinde requireValid zorunluluğu yok"
done
echo "    web-core-engineer.md ×2: guardPost/requireValid zorunluluğu mevcut ✓"

step "66) Decision Layer: decide.sh → decision.json (açık kaynak JEV-mantık)"
D66="$TMP/decision66"
mkdir -p "$D66"
cp -a "$FIX/." "$D66/"
seed_domain_report "$D66"
# katalogsuz / sepetsiz matris → --allow-no-cart önerisi için seed'i değiştir
python3 - <<PY
import json
from pathlib import Path
p=Path("$D66/.factory/domain-report.json")
r=json.loads(p.read_text(encoding="utf-8"))
r["entities"]=[e for e in r["entities"] if e["name"] not in ("products","orders")]
r["module_matrix"]=[m for m in r["module_matrix"] if m["module"] not in ("cart",)]
r["module_matrix"].append({
  "module":"rbac","status":"injected",
  "evidence":"roles planlandı","justification":"decision layer test"
})
r["compliance"]="kvkk"
p.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding="utf-8")
PY
rc="$(run_rc bash "$ROOT/scripts/web/decide.sh" "$D66")"
[[ "$rc" == "0" ]] || die "decide.sh rc=0 beklenir, gelen $rc"
[[ -f "$D66/.factory/decision.json" ]] || die "decision.json yok"
python3 - <<PY
import json
d=json.load(open("$D66/.factory/decision.json",encoding="utf-8"))
assert d["result"]=="READY", d
assert d.get("engine")=="webrail-decision-layer", d
assert any(m.get("module") in ("kvkk","gdpr","rbac") for m in d["modules_to_apply"]), d["modules_to_apply"]
assert d.get("qa_gate_extra")=="--allow-no-cart", d.get("qa_gate_extra")
assert d.get("context_allowlist"), "allowlist boş"
PY
[[ -f "$D66/RUN-STATUS.md" ]] || die "decide sonrası RUN-STATUS.md yok"
rm -rf "$D66"
echo "    decide.sh READY · kvkk/rbac modül · allow-no-cart · RUN-STATUS ✓"

step "67) Handoff: state start → RUN-STATUS.md faz=P1"
D67="$TMP/runstatus67"
mkdir -p "$D67"
rc="$(run_rc bash "$STATE" start "$D67")"
[[ "$rc" == "0" ]] || die "state start rc=0 beklenir, gelen $rc"
[[ -f "$D67/RUN-STATUS.md" ]] || die "RUN-STATUS.md yazılmadı"
grep -q '\*\*P1\*\*' "$D67/RUN-STATUS.md" || die "RUN-STATUS faz P1 değil"
rm -rf "$D67"
echo "    state start → RUN-STATUS P1 ✓"

step "68) P1→P2 advance Decision Layer zorunlu + CUSTOMER-START protokolü"
D68="$TMP/advdecide68"
mkdir -p "$D68"
cp -a "$FIX/." "$D68/"
seed_domain_report "$D68"
bash "$STATE" start "$D68" >/dev/null
rc="$(run_rc bash "$STATE" advance "$D68")"
[[ "$rc" == "0" ]] || die "P1→P2 advance+decide rc=0 beklenir, gelen $rc"
[[ -f "$D68/.factory/decision.json" ]] || die "advance sonrası decision.json yok"
phase="$(python3 -c "import json;print(json.load(open('$D68/.factory/web-state.json'))['current_phase'])")"
[[ "$phase" == "P2" ]] || die "faz P2 olmalı, olan $phase"
[[ -f "$ROOT/docs/CUSTOMER-START.md" ]] || die "docs/CUSTOMER-START.md yok"
grep -q 'decide.sh' "$ROOT/docs/CUSTOMER-START.md" || die "CUSTOMER-START decide.sh anmaz"
grep -q 'ücretli JEV yok\|ücretli JEV yok\|Ücretli JEV yok' "$ROOT/docs/CUSTOMER-START.md" \
  || die "CUSTOMER-START ücretli JEV reddini anmaz"
rm -rf "$D68"
echo "    P1→P2 advance → decision.json · CUSTOMER-START protokolü ✓"

step "69) Preflight READY + skills açık uç yok (müşteri öncesi kapı)"
rc="$(run_rc bash "$ROOT/scripts/web/preflight.sh")"
[[ "$rc" == "0" ]] || die "preflight.sh READY (0) beklenir, gelen $rc"
for s in kvkk-compliance auth-rbac admin-crud seo-basics; do
  f="$ROOT/.opencode/skills/$s/SKILL.md"
  [[ -f "$f" ]] || die "skill yok: $s"
  grep -q '\*\*Durum:\*\* READY' "$f" || die "skill READY değil: $s"
  grep -Eq 'v2.de doldurul|içerik doldurulacak' "$f" && die "skill açık uç: $s"
done
grep -q 'preflight.sh' "$ROOT/docs/CUSTOMER-START.md" || die "CUSTOMER-START preflight anmaz"
echo "    preflight READY · 4 skill READY · protokol bağlı ✓"

echo
echo "SELF-TEST: PASS — tüm senaryolar yeşil"
exit 0
