#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — QA & Security Gatekeeper (Phase 3/4)
# Kullanım: qa-gate.sh [proje_dizini] [--record] [--allow-no-cart]
#   --record          state grafiğini günceller (qa-pass / qa-fail); faz P3/P4 olmalı
#   --allow-no-cart   katalog var, sepet/sipariş yok istisnasını onaylı istisnaya yazar
# Kabul: 0 Error, 0 Warning (Check: PASS) — aksi halde paketleme yasak.
# Exit: 0 = PASS · 1 = FAIL (retry) · 2 = HALT (max_retries aşıldı)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_SH="$ROOT/scripts/web/state.sh"

PROJECT=""
RECORD=0
ALLOW_NO_CART=0

usage() {
  echo "kullanım: qa-gate.sh [proje_dizini] [--record] [--allow-no-cart]" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --record) RECORD=1 ;;
    --allow-no-cart) ALLOW_NO_CART=1 ;;
    -h|--help) usage ;;
    -*) echo "qa-gate: bilinmeyen bayrak: $arg" >&2; usage ;;
    *) if [[ -z "$PROJECT" ]]; then PROJECT="$arg"; else usage; fi ;;
  esac
done
[[ -n "$PROJECT" ]] || PROJECT="."

command -v python3 >/dev/null 2>&1 || { echo "qa-gate: python3 gerekli" >&2; exit 1; }
[[ -d "$PROJECT" ]] || { echo "qa-gate: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

# composer global araç dizinleri (phpstan, phpunit) PATH'e ekle
for _bin in "$HOME/.composer/vendor/bin" "$HOME/.config/composer/vendor/bin"; do
  if [[ -d "$_bin" ]]; then PATH="$_bin:$PATH"; fi
done
export PATH

ERR_FILE="$(mktemp)"
WARN_FILE="$(mktemp)"
EXC_FILE="$(mktemp)"
CHK_FILE="$(mktemp)"
trap 'rm -f "$ERR_FILE" "$WARN_FILE" "$EXC_FILE" "$CHK_FILE"' EXIT

err()  { printf '%s\n' "${1//$'\n'/ }" >> "$ERR_FILE"; }
warn() { printf '%s\n' "${1//$'\n'/ }" >> "$WARN_FILE"; }
exc()  { printf '%s\n' "${1//$'\n'/ }" >> "$EXC_FILE"; }
set_check() { printf '%s=%s\n' "$1" "$2" >> "$CHK_FILE"; }
err_count() { wc -l < "$ERR_FILE" | tr -d ' '; }
warn_count() { wc -l < "$WARN_FILE" | tr -d ' '; }

_before=0
check_begin() { _before="$(err_count)"; }
check_end() {
  if [[ "$(err_count)" == "$_before" ]]; then set_check "$1" PASS; else set_check "$1" FAIL; fi
}

rel() { printf '%s' "${1#"$PROJECT"/}"; }

echo "==> QA Gate: $PROJECT"

# --- PHP dosya envanteri (node_modules/vendor/Yukleme/.factory/.git hariç) ---
PHP_FILES=()
while IFS= read -r f; do PHP_FILES+=("$f"); done < <(
  find "$PROJECT" \( -name node_modules -o -name vendor -o -name Yukleme -o -name .factory -o -name .git -o -name '._*' \) -prune \
    -o -type f -name '*.php' -print | sort
)
PHP_COUNT=${#PHP_FILES[@]}

# --- 1) PHP syntax (php -l) ---
check_begin
if ! command -v php >/dev/null 2>&1; then
  err "php: php-cli bulunamadı — syntax doğrulaması mümkün değil (php 8.1+ zorunlu)"
else
  if [[ "$PHP_COUNT" -eq 0 ]]; then
    err "php: hiç .php dosyası bulunamadı"
  else
    for f in "${PHP_FILES[@]}"; do
      if ! php -l "$f" >/dev/null 2>&1; then
        detail="$(php -l "$f" 2>&1 | head -2 | tr '\n' ' ' || true)"
        err "php: sözdizimi hatası: $(rel "$f") — $detail"
      fi
    done
  fi
fi
check_end php_lint

# --- 2) Yapısal zorunluluklar ---
check_begin
for req in index.php .htaccess robots.txt sitemap.xml; do
  [[ -f "$PROJECT/$req" ]] || err "yapı: $req eksik"
done
[[ -d "$PROJECT/core" ]] || err "yapı: core/ dizini eksik (MVC çekirdek)"
[[ -d "$PROJECT/views" ]] || err "yapı: views/ dizini eksik (şablonlar)"
if [[ -d "$PROJECT/views" ]]; then
  find "$PROJECT/views" -type f -name '*.php' ! -name '._*' -print -quit | grep -q . \
    || err "yapı: views/ altında hiç .php şablonu yok"
fi
check_end structure

# --- 3) SQL şeması: UTF-8, FK, seed, RBAC, sepet ---
check_begin
SQL_FILE=""
if [[ -f "$PROJECT/SQL/veritabani.sql" ]]; then
  SQL_FILE="$PROJECT/SQL/veritabani.sql"
else
  while IFS= read -r f; do SQL_FILE="$f"; break; done < <(
    find "$PROJECT" \( -name node_modules -o -name vendor -o -name Yukleme -o -name .factory -o -name .git -o -name '._*' \) -prune \
      -o -type f -name '*.sql' -print | sort
  )
fi

if [[ -z "$SQL_FILE" ]]; then
  err "sql: SQL/veritabani.sql bulunamadı (tablolar, FK, index, seed tek dump'ta)"
else
  iconv -f UTF-8 -t UTF-8 "$SQL_FILE" >/dev/null 2>&1 \
    || err "sql: $(rel "$SQL_FILE") UTF-8 değil"
  grep -Eiq 'CREATE TABLE' "$SQL_FILE" || err "sql: CREATE TABLE yok"
  grep -Eiq 'FOREIGN KEY' "$SQL_FILE" || err "sql: FOREIGN KEY yok (ilişkisel şema + cascade zorunlu)"
  grep -Eiq 'INSERT INTO' "$SQL_FILE" || err "sql: seed verisi (INSERT INTO) yok"

  USERS_RE='CREATE TABLE[[:space:]]+`?(users|kullanicilar|kullanıcılar|members|uyeler)'
  CATALOG_RE='CREATE TABLE[[:space:]]+`?(products|urunler|urun|catalog|katalog)'
  CART_RE='CREATE TABLE[[:space:]]+`?(orders|siparisler|siparis|sepet|cart|teklifler|quotes)'

  if grep -Eiq "$USERS_RE" "$SQL_FILE"; then
    grep -Eiq '(role_id|permissions)' "$SQL_FILE" \
      || err "rbac: users tablosu var ama role_id/permissions sütunu yok — Admin/Moderatör/Kullanıcı rol katmanı zorunlu"
  fi
  if grep -Eiq "$CATALOG_RE" "$SQL_FILE"; then
    if ! grep -Eiq "$CART_RE" "$SQL_FILE"; then
      if [[ "$ALLOW_NO_CART" -eq 1 ]]; then
        exc "katalog var, sepet/sipariş yok — kullanıcı onayıyla istisna (--allow-no-cart)"
      else
        err "eksik modül: ürün/katalog tablosu var ama sipariş/sepet/teklif mekanizması yok — modül eklenmeli veya --allow-no-cart ile açık onay verilmeli"
      fi
    fi
  fi
fi
check_end sql_schema

# --- 3b) SQL dump determinizmi: SQL/migrations → veritabani.sql senkronluğu ---
set_check sql_dump SKIPPED
if [[ -d "$PROJECT/SQL/migrations/schema" ]]; then
  check_begin
  DUMP_TMP="$(mktemp)"
  if ! bash "$ROOT/scripts/web/sql-dump.sh" "$PROJECT" --output "$DUMP_TMP" >/dev/null 2>&1; then
    err "sql: sql-dump.sh başarısız — SQL/migrations/{schema,seed} okunamadı"
  elif [[ -f "$PROJECT/SQL/veritabani.sql" ]] && ! cmp -s "$DUMP_TMP" "$PROJECT/SQL/veritabani.sql"; then
    err "sql: SQL/veritabani.sql SQL/migrations ile senkron değil (drift) — \`bash scripts/web/sql-dump.sh $PROJECT\` ile yeniden üret"
  fi
  rm -f "$DUMP_TMP"
  check_end sql_dump
fi

# --- 4) OWASP statik grep'leri ---
check_begin
SEC_PATTERNS=(
  'eval[[:space:]]*\('
  'mysql_(query|connect|fetch)'
  'mysqli?_query[[:space:]]*\([^;]*\$_(GET|POST|REQUEST|COOKIE)'
  '->query[[:space:]]*\([^;]*\$_(GET|POST|REQUEST)'
  '(md5|sha1)[[:space:]]*\([[:space:]]*(\$_(POST|GET)|\$(password|pass|sifre|pwd))'
  'base64_decode[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST)'
  '(include|require)(_once)?[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST)'
)
SEC_LABELS=(
  "güvenlik: eval() kullanımı"
  "güvenlik: eski mysql_* API (PDO Prepared Statement kullan)"
  "güvenlik: superglobal doğrudan sorguya giriyor (SQL injection riski)"
  "güvenlik: ->query() doğrudan superglobal alıyor (SQL injection riski)"
  "güvenlik: ham md5/sha1 parola özeti (password_hash/password_verify kullan)"
  "güvenlik: base64_decode(superglobal) deseni"
  "güvenlik: include/require superglobal ile (LFI riski)"
)
if [[ "$PHP_COUNT" -gt 0 ]]; then
  i=0
  while [[ "$i" -lt "${#SEC_PATTERNS[@]}" ]]; do
    pat="${SEC_PATTERNS[$i]}"
    label="${SEC_LABELS[$i]}"
    for f in "${PHP_FILES[@]}"; do
      hit="$(grep -m1 -nE -e "$pat" "$f" || true)"
      if [[ -n "$hit" ]]; then
        ln="${hit%%:*}"
        err "$label: $(rel "$f"):$ln"
      fi
    done
    i=$((i + 1))
  done
fi
check_end security_grep

# --- 5) CSRF / oturum / parola politikası ---
check_begin
if [[ "$PHP_COUNT" -gt 0 ]]; then
  if grep -lE '\$_POST|\$_REQUEST' "${PHP_FILES[@]}" >/dev/null 2>&1; then
    grep -Eiq 'csrf' "${PHP_FILES[@]}" \
      || err "güvenlik: POST/REQUEST kullanımı var ama CSRF token doğrulaması yok"
  fi
  if grep -l 'session_start' "${PHP_FILES[@]}" >/dev/null 2>&1; then
    grep -Eiq 'httponly|session_set_cookie_params|session\.cookie_httponly' "${PHP_FILES[@]}" \
      || err "güvenlik: session_start() var ama HttpOnly/Secure çerez yapılandırması yok"
  fi
fi
check_end security_policy

# users tablosu varsa kod parola hash'lemeli
if [[ -n "$SQL_FILE" && "$PHP_COUNT" -gt 0 ]] && grep -Eiq 'CREATE TABLE[[:space:]]+`?(users|kullanicilar|kullanıcılar|members|uyeler)' "$SQL_FILE"; then
  check_begin
  grep -Eiq 'password_hash|password_verify' "${PHP_FILES[@]}" \
    || err "güvenlik: users tablosu var ama kodda password_hash/password_verify yok (ARGON2ID/BCRYPT)"
  check_end password_policy
else
  set_check password_policy SKIPPED
fi

# --- 5b) P1 domain artefaktı semantik denetimi (hollow + filesystem) ---
# domain-report.json varsa dolu ve doğru olmak zorunda: ≥4 modül, benzersiz ad,
# her hücrede justification (≥20 kr) + evidence (≥10 kr, dosya/satır kaynağı) ve
# evidence'da geçen dosyaların proje kökünde gerçekten var olması (fs doğrulaması).
# Tek doğruluk kaynağı: scripts/web/domain-check.py (orchestrate.sh P1'de de çağırır).
set_check domain_report SKIPPED
DOMAIN_REPORT="$PROJECT/.factory/domain-report.json"
if [[ -f "$DOMAIN_REPORT" ]]; then
  check_begin
  DR_TMP="$(mktemp)"
  DR_RC=0
  python3 "$ROOT/scripts/web/domain-check.py" "$DOMAIN_REPORT" "$PROJECT" \
    >/dev/null 2>"$DR_TMP" || DR_RC=$?
  if [[ "$DR_RC" -ne 0 ]]; then
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then err "domain_report: $line"; fi
    done < "$DR_TMP"
  fi
  rm -f "$DR_TMP"
  check_end domain_report
fi

# --- 5c) KVKK/GDPR kanalı (intent.compliance; koşullu — §3) ---
# compliance = kvkk|gdpr ise P2 KVKK bloğu zorunlu: legal view'lar, çerez onay
# bileşeni ve rıza/anonimleştirme tabloları. none/alan yoksa bu kanal SKIPPED
# kalır (ayrı kanal — SKIPPED bütçesine girmez, PASS'i etkilemez).
set_check kvkk SKIPPED
COMPLIANCE="none"
if [[ -f "$PROJECT/.factory/project-intent.json" ]]; then
  COMPLIANCE="$(python3 - "$PROJECT/.factory/project-intent.json" <<'PY'
import json
import sys

try:
    v = json.load(open(sys.argv[1], encoding="utf-8")).get("compliance")
except Exception:
    v = None
print(v if v in ("kvkk", "gdpr") else "none")
PY
  )" || COMPLIANCE="none"
fi
if [[ "$COMPLIANCE" != "none" ]]; then
  check_begin
  for f in views/legal/aydinlatma.php views/legal/gizlilik.php views/legal/cerez.php \
           views/partials/cookie-consent.php assets/js/cookie-consent.js; do
    [[ -f "$PROJECT/$f" ]] || err "kvkk: $f eksik (compliance=$COMPLIANCE — P2 KVKK bloğu zorunlu)"
  done
  if [[ -f "$PROJECT/SQL/veritabani.sql" ]]; then
    grep -Eiq 'CREATE TABLE[[:space:]]+`?user_consents' "$PROJECT/SQL/veritabani.sql" \
      || err "kvkk: user_consents tablosu yok (açık rıza kaydı — SQL/veritabani.sql)"
    grep -Eiq 'CREATE TABLE[[:space:]]+`?anonymization_log' "$PROJECT/SQL/veritabani.sql" \
      || err "kvkk: anonymization_log tablosu yok (anonimleştirme izi — SQL/veritabani.sql)"
  fi
  check_end kvkk
fi

# --- 5d) Fabrika kontratı: ajan/rule frontmatter (K6 istisnası — somut regresyon) ---
# K1-K8 ref satırı frontmatter üstüne eklenince opencode mode/permission parse'ı
# sessiz kırılmıştı (14 dosya; A/B: qa-gatekeeper permission.edit=deny kaybı) →
# fabrika kendi agent/rule/skill dosyalarını her gate koşusunda doğrular.
# Tarama hedefi fabrika kökü (ROOT); proje kendi .opencode/.cursor taşıyorsa o da.
set_check frontmatter SKIPPED
_fm_roots=("$ROOT")
if [[ "$PROJECT" != "$ROOT" ]] && [[ -d "$PROJECT/.opencode" || -d "$PROJECT/.cursor" ]]; then
  _fm_roots+=("$PROJECT")
fi
_fm_targets=()
for _r in "${_fm_roots[@]}"; do
  if [[ -d "$_r/.opencode/agent" || -d "$_r/.cursor/agents" || -d "$_r/.cursor/rules" || -d "$_r/.cursor/skills" || -d "$_r/.opencode/skills" ]]; then
    _fm_targets+=("$_r")
  fi
done
if [[ ${#_fm_targets[@]} -gt 0 ]]; then
  check_begin
  for _r in "${_fm_targets[@]}"; do
    FM_OUT="$(bash "$ROOT/scripts/web/frontmatter-check.sh" "$_r" 2>&1)" || {
      while IFS= read -r _l; do
        [[ -n "$_l" ]] && err "frontmatter: $_l"
      done <<<"$FM_OUT"
    }
  done
  check_end frontmatter
fi

# --- 6) Statik analiz + birim test (garantici çekirdek — asimetrik kural) ---
# phpstan + phpunit ZORUNLUDUR: yapılandırması yoksa o kontrol doğrudan FAIL.
# Yalnız eslint SKIPPED olabilir (ör. JS'siz proje).
# static_coverage = phpstan PASS ∧ phpunit PASS (aksi her koşulda FAIL).
# Araç, yapılandırma varken kurulu değilse de o kontrol FAIL (§8).

set_check phpstan SKIPPED
if [[ -f "$PROJECT/phpstan.neon" || -f "$PROJECT/phpstan.neon.dist" ]]; then
  if command -v phpstan >/dev/null 2>&1 || [[ -x "$PROJECT/vendor/bin/phpstan" ]]; then
    check_begin
    (cd "$PROJECT" && phpstan analyse --no-progress --error-format=raw >/dev/null 2>&1) \
      || err "statik: phpstan Level 8 hatası verdi"
    check_end phpstan
  else
    check_begin
    err "statik: phpstan yapılandırması var ama araç kurulu değil — composer global require phpstan/phpstan"
    check_end phpstan
  fi
else
  check_begin
  err "statik: phpstan yapılandırması yok — phpstan.neon[.dist] zorunlu (§8 garantici çekirdek)"
  check_end phpstan
fi

set_check eslint SKIPPED
if [[ -f "$PROJECT/.eslintrc" || -f "$PROJECT/.eslintrc.json" || -f "$PROJECT/eslint.config.js" ]]; then
  if command -v npx >/dev/null 2>&1 && (cd "$PROJECT" && npx --no-install eslint --version >/dev/null 2>&1); then
    check_begin
    (cd "$PROJECT" && npx --no-install eslint . >/dev/null 2>&1) \
      || err "statik: eslint hatası verdi"
    check_end eslint
  else
    check_begin
    err "statik: eslint yapılandırması var ama araç kurulu değil — npm install -g eslint"
    check_end eslint
  fi
else
  set_check eslint SKIPPED
fi

set_check phpunit SKIPPED
if [[ -f "$PROJECT/phpunit.xml" || -f "$PROJECT/phpunit.xml.dist" ]]; then
  PU=""
  if [[ -x "$PROJECT/vendor/bin/phpunit" ]]; then
    PU="$PROJECT/vendor/bin/phpunit"
  elif command -v phpunit >/dev/null 2>&1; then
    PU="phpunit"
  fi
  if [[ -n "$PU" ]]; then
    # K5 (Tur 2-7 B.1): hangi config dosyası varsa onu kullan — phpunit.xml.dist
    # olan projede sabit "phpunit.xml" testin ÇALIŞMAMASINA (sessiz skip) yol açıyordu.
    PU_CFG="phpunit.xml"
    [[ -f "$PROJECT/phpunit.xml" ]] || PU_CFG="phpunit.xml.dist"
    check_begin
    if ! (cd "$PROJECT" && "$PU" --configuration "$PU_CFG" >/dev/null 2>&1); then
      _hint=""
      if find "$PROJECT" -type f -name '._*Test.php' -not -path '*/node_modules/*' 2>/dev/null | grep -q .; then
        _hint=" — AppleDouble ikizi (._*Test.php) PHPUnit tarayıcısını bozar; find . -name '._*' -delete (exFAT)"
      fi
      err "test: phpunit birim testleri başarısız${_hint}"
    fi
    check_end phpunit
  else
    check_begin
    err "test: phpunit yapılandırması var ama araç kurulu değil — composer global require phpunit/phpunit"
    check_end phpunit
  fi
else
  check_begin
  err "test: phpunit yapılandırması yok — phpunit.xml zorunlu (§8 garantici çekirdek)"
  check_end phpunit
fi

if grep -qx 'phpstan=PASS' "$CHK_FILE" && grep -qx 'phpunit=PASS' "$CHK_FILE"; then
  set_check static_coverage PASS
else
  check_begin
  err "statik/test: garantici çekirdek (phpstan + phpunit) PASS değil — yalnız eslint SKIPPED olabilir; phpstan/phpunit zorunlu"
  check_end static_coverage
fi

# --- Sonuç: 0 Error, 0 Warning ---
E_COUNT="$(err_count)"
W_COUNT="$(warn_count)"
RESULT="PASS"
if [[ "$E_COUNT" -gt 0 || "$W_COUNT" -gt 0 ]]; then RESULT="FAIL"; fi

STATE_FILE="$PROJECT/.factory/web-state.json"
STATE_RC=0

if [[ "$RECORD" -eq 1 ]]; then
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "qa-gate: --record için state yok — önce \`state.sh start\` + \`advance\`" >&2
    exit 1
  fi
  if [[ "$RESULT" == "PASS" ]]; then
    if ! bash "$STATE_SH" qa-pass "$PROJECT"; then
      err "state: qa-pass reddedildi — faz P3/P4 değil (state.sh status ile kontrol et)"
      RESULT="FAIL"
      E_COUNT="$(err_count)"
    fi
  else
    bash "$STATE_SH" qa-fail "$PROJECT" || STATE_RC=$?
  fi
fi

# --- Raporlar (state güncellemesinden sonra; son state'i yansıtır) ---
export QG_PROJECT="$PROJECT" QG_RESULT="$RESULT" QG_RECORD="$RECORD"
export QG_ERR="$ERR_FILE" QG_WARN="$WARN_FILE" QG_EXC="$EXC_FILE" QG_CHK="$CHK_FILE"
export QG_STATE_RC="$STATE_RC"
python3 - <<'PY'
import json, os, datetime

project = os.environ["QG_PROJECT"]
result = os.environ["QG_RESULT"]
state_rc = int(os.environ["QG_STATE_RC"])


def lines(path):
    with open(path, encoding="utf-8") as fh:
        return [ln for ln in fh.read().splitlines() if ln.strip()]


errors = lines(os.environ["QG_ERR"])
warnings = lines(os.environ["QG_WARN"])
exceptions = lines(os.environ["QG_EXC"])
checks = dict(ln.split("=", 1) for ln in lines(os.environ["QG_CHK"]))

state_path = os.path.join(project, ".factory", "web-state.json")
state = None
if os.path.exists(state_path):
    with open(state_path, encoding="utf-8") as fh:
        state = json.load(fh)

now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
halted = state_rc == 2 or (state is not None and state.get("status") == "halted")

qa_report = {
    "schema_version": 1,
    "tool": "qa-gate",
    "version": "1.0.0",
    "project": project,
    "result": result,
    "checks": checks,
    "errors": errors,
    "warnings": warnings,
    "approved_exceptions": exceptions,
    "state": None if state is None else {
        "current_phase": state.get("current_phase"),
        "retry_count": state.get("retry_count"),
        "max_retries": state.get("max_retries"),
        "status": state.get("status"),
    },
    "at": now,
}
with open(os.path.join(project, "qa-report.json"), "w", encoding="utf-8") as fh:
    json.dump(qa_report, fh, ensure_ascii=False, indent=2)
    fh.write("\n")

if result == "FAIL":
    next_actions = ["Hataları düzelt ve `bash scripts/web/qa-gate.sh <proje>` tekrar çalıştır"]
    if halted:
        next_actions = [
            "HALT: max_retries aşıldı — mimari durdu",
            "debug_report.json dosyasını geliştiriciye sun",
            "Kök nedeni çözmeden P5 (paketleme) yasak",
        ]
    debug_report = {
        "schema_version": 1,
        "tool": "qa-gate",
        "kind": "debug_report",
        "project": project,
        "phase": "P3/P4",
        "halted": halted,
        "retry_count": None if state is None else state.get("retry_count"),
        "max_retries": None if state is None else state.get("max_retries"),
        "errors": errors,
        "warnings": warnings,
        "approved_exceptions": exceptions,
        "checks": checks,
        "next_actions": next_actions,
        "at": now,
    }
    with open(os.path.join(project, "debug_report.json"), "w", encoding="utf-8") as fh:
        json.dump(debug_report, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
PY

echo "==> QA: $RESULT · hata=$E_COUNT uyarı=$W_COUNT"
if [[ -s "$EXC_FILE" ]]; then
  while IFS= read -r line; do echo "    [istisna] $line"; done < "$EXC_FILE"
fi
if [[ "$W_COUNT" -gt 0 ]]; then
  while IFS= read -r line; do echo "    [uyarı] $line"; done < "$WARN_FILE"
fi
if [[ "$RESULT" == "FAIL" ]]; then
  while IFS= read -r line; do echo "    [hata]  $line"; done < "$ERR_FILE"
  echo "==> Raporda: $PROJECT/qa-report.json + debug_report.json"
  if [[ "$STATE_RC" -eq 2 ]]; then
    echo "==> HALT: max_retries aşıldı — döngü durdu" >&2
    exit 2
  fi
  exit 1
fi
echo "==> Check: PASS (0 error, 0 warning) — P5 (paketleme) kapısı açık · rapor: $PROJECT/qa-report.json"
exit 0
