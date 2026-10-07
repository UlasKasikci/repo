#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — deploy sonrası smoke test (P5 paket doğrulama)
# Kullanım:
#   bash scripts/web/smoke-test.sh <paket_dizini>
#       lokal mod: katmanlı kapı — blocker (php -l, php -S ayağa kalkar,
#       GET / transport, /robots.txt + /sitemap.xml statik 200 — Content-Type
#       text/plain|xml, çünkü php -S'de eksik dosya index.php'ye düşüp 200 verir)
#       + raporlayıcı (/ durum kodu, <html> marker'ı, PHP Fatal imzası, SMOKE_PATHS)
#   bash scripts/web/smoke-test.sh --url <http://...> [--strict]
#       canlı mod: yalnız raporlayıcı katman (bloker yok — sunucu zaten canlı)
# Çevre:
#   SMOKE_PATHS="/admin /api/health"  ek rota denetimi (yalnız raporlayıcı → WARN)
#   SMOKE_PORT=18123                  taban port (yoksa 18000+RANDOM%2000;
#                                     adaylar +0..+4, süreç ölürse sonraki port,
#                                     yanıt-tekrar-dene 15×200ms — sabit uyku yok)
#   SMOKE_REPORT=<yol>                JSON rapor (varsayılan: hedefin ANA dizininde —
#                                     asla paket içine yazılmaz; --url için ./smoke-report.json)
# Sonuç: PASS (0) · WARN (0; --strict ile 1) · FAIL (1)
#   blocker hatası → FAIL: paket yayınlanamaz (package-yukleme.sh reddeder)
#   raporlayıcı ihlali → WARN: paket gider, ihlaller rapora yazılır (canlıda doğrula)
# Not: php -S .htaccess rewrite kurallarını uygulamaz; rewrite bağımlı rotalar
#   yalnız --url canlı modda doğrulanır (lokalde yalnız rapor notu).
# Test-only: SMOKE_TEST_FORCE_FAIL=1 + SELF_TEST=1 → bilinçli hata (öz-test geri alma kancası)

MODE="local"
TARGET=""
URL=""
STRICT=0

die() { echo "smoke-test: $*" >&2; exit 1; }

usage() {
  sed -n '4,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

if [[ -n "${SMOKE_TEST_FORCE_FAIL:-}" && "${SELF_TEST:-}" != "1" ]]; then
  echo "smoke-test: SMOKE_TEST_FORCE_FAIL yalnız öz-test ortamında kullanılabilir (SELF_TEST=1 ile)" >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      [[ $# -ge 2 ]] || die "--url değeri gerekli"
      MODE="live"
      URL="$2"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "bilinmeyen bayrak: $1"
      ;;
    *)
      [[ -z "$TARGET" ]] || die "tek hedef beklenir (fazla argüman: $1)"
      TARGET="$1"
      shift
      ;;
  esac
done

if [[ "$MODE" == "live" ]]; then
  [[ -n "$URL" ]] || die "--url gerekli"
  [[ -z "$TARGET" ]] || die "canlı modda dizin verilmez (yalnız --url)"
else
  [[ -n "$TARGET" ]] || die "paket dizini gerekli (veya --url <canlı>)"
  [[ -d "$TARGET" ]] || die "dizin yok: $TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

command -v python3 >/dev/null 2>&1 || die "python3 gerekli (§8)"
command -v curl >/dev/null 2>&1 || die "curl gerekli"

REPORT="${SMOKE_REPORT:-}"
if [[ -z "$REPORT" ]]; then
  if [[ "$MODE" == "local" ]]; then
    # paket İÇİNDE değil, ana dizininde — denylist sızıntısı imkânsız
    REPORT="$(dirname "$TARGET")/smoke-report.json"
  else
    REPORT="$PWD/smoke-report.json"
  fi
fi
mkdir -p "$(dirname "$REPORT")"

ERR_F="$(mktemp)"
VIOL_F="$(mktemp)"
NOTE_F="$(mktemp)"
CK_F="$(mktemp)"
BODY_F="$(mktemp)"
HDR_F="$(mktemp)"
SRV_PID=""

cleanup() {
  if [[ -n "$SRV_PID" ]]; then
    kill "$SRV_PID" 2>/dev/null || true
    wait "$SRV_PID" 2>/dev/null || true
  fi
  rm -f "$ERR_F" "$VIOL_F" "$NOTE_F" "$CK_F" "$BODY_F" "$HDR_F"
}
trap cleanup EXIT

err() { printf '%s\n' "${1//$'\n'/ }" >> "$ERR_F"; }
viol() { printf '%s\n' "${1//$'\n'/ }" >> "$VIOL_F"; }
info() { printf '%s\n' "${1//$'\n'/ }" >> "$NOTE_F"; }
ck() { # $1=0|1 $2=ad $3=detay
  local d="${3:-}"
  d="${d//$'\n'/ }"
  d="${d//|//}"
  printf '%s|%s|%s\n' "$1" "$2" "$d" >> "$CK_F"
}
http_code() { # $1=url $2=gövde hedefi → stdout: HTTP kodu (ulaşılamazsa 000)
  local c
  c="$(curl -s -o "$2" -w '%{http_code}' --max-time 10 "$1" 2>/dev/null || true)"
  if [[ -z "$c" ]]; then c="000"; fi
  printf '%s' "$c"
}
http_meta() { # $1=url $2=gövde $3=header dosyası → stdout: "kod<TAB>content-type"
  local c ctype
  c="$(curl -s -D "$3" -o "$2" -w '%{http_code}' --max-time 10 "$1" 2>/dev/null || true)"
  if [[ -z "$c" ]]; then c="000"; fi
  ctype="$(grep -i '^content-type:' "$3" 2>/dev/null | head -1 | cut -d: -f2- | tr -d '\r' | sed 's/^[[:space:]]*//' || true)"
  printf '%s\t%s' "$c" "$ctype"
}
content_reporter() { # $1=kaynak(lokal|canlı) — / gövdesi BODY_F üzerinde
  if grep -Eiq 'PHP (Fatal error|Parse error)|Uncaught (Throwable|Exception|Error)' "$BODY_F"; then
    viol "yanıtta PHP hata imzası (Fatal/Parse/Uncaught) — ortamsal olabilir (DB/ortam); SMOKE_URL ile canlı doğrulayın"
    ck 0 content_signature "hata imzası var"
  else
    ck 1 content_signature "temiz"
  fi
  if grep -Eiq '<html' "$BODY_F"; then
    ck 1 html_marker "<html> var"
  else
    viol "yanıtta <html> marker'ı yok ($1)"
    ck 0 html_marker "yok"
  fi
}
extra_paths_reporter() { # $1=base url (sonunda / yok)
  if [[ -z "${SMOKE_PATHS:-}" ]]; then return 0; fi
  local path c
  for path in $SMOKE_PATHS; do
    c="$(http_code "$1$path" /dev/null)"
    if [[ "$c" == 2* || "$c" == 3* ]]; then
      ck 1 "path:$path" "HTTP $c"
    else
      viol "GET $path → HTTP $c (php -S rewrite uygulamaz; canlıda --url ile doğrulayın)"
      ck 0 "path:$path" "HTTP $c"
    fi
  done
}

FORCED=0
if [[ -n "${SMOKE_TEST_FORCE_FAIL:-}" ]]; then
  FORCED=1
  err "zorlanan hata (SMOKE_TEST_FORCE_FAIL — öz-test geri alma kancası)"
  ck 0 forced_fail "SMOKE_TEST_FORCE_FAIL"
fi

if [[ "$MODE" == "local" && "$FORCED" -eq 0 ]]; then
  # --- php -l: tüm paket .php dosyaları ---
  if ! command -v php >/dev/null 2>&1; then
    err "php-cli bulunamadı — paket lokal doğrulanamaz"
    ck 0 php_lint "php-cli yok"
  else
    php_files=()
    while IFS= read -r f; do php_files+=("$f"); done < <(
      find "$TARGET" -type f -name '*.php' ! -name '._*' | sort
    )
    if [[ "${#php_files[@]}" -eq 0 ]]; then
      err "hiç .php dosyası bulunamadı: $TARGET"
      ck 0 php_lint "0 dosya"
    else
      lint_bad=0
      for f in "${php_files[@]}"; do
        if ! out="$(php -l "$f" 2>&1)"; then
          err "php -l: ${f#"$TARGET"/} — ${out//$'\n'/ }"
          lint_bad=1
        fi
      done
      if [[ "$lint_bad" -eq 0 ]]; then
        ck 1 php_lint "${#php_files[@]} dosya geçti"
      else
        ck 0 php_lint "sözdizimi hatası var"
      fi
    fi
  fi

  # --- php -S: port adayları + yanıt-tekrar-dene (sabit uyku yok) ---
  BASE_PORT="${SMOKE_PORT:-$((18000 + RANDOM % 2000))}"
  PORT=""
  if command -v php >/dev/null 2>&1; then
    for off in 0 1 2 3 4; do
      p=$((BASE_PORT + off))
      php -S "127.0.0.1:$p" -t "$TARGET" >/dev/null 2>&1 &
      SRV_PID=$!
      up=0
      for _i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        if ! kill -0 "$SRV_PID" 2>/dev/null; then
          break
        fi
        if curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$p/" 2>/dev/null; then
          up=1
          PORT="$p"
          break
        fi
        sleep 0.2
      done
      if [[ "$up" -eq 1 ]]; then
        break
      fi
      kill "$SRV_PID" 2>/dev/null || true
      wait "$SRV_PID" 2>/dev/null || true
      SRV_PID=""
    done
    if [[ -z "$PORT" ]]; then
      err "php -S başlatılamadı — port adayları $BASE_PORT..$((BASE_PORT + 4)) tükendi"
      ck 0 server_start "başlatılamadı"
    else
      ck 1 server_start "127.0.0.1:$PORT"
    fi
  fi

  if [[ -n "$PORT" ]]; then
    BASE="http://127.0.0.1:$PORT"
    # --- blocker: GET / transport yanıtı ---
    code="$(http_code "$BASE/" "$BODY_F")"
    if [[ "$code" == "000" ]]; then
      err "GET / transport yok (yanıt alınamadı)"
      ck 0 root_transport "000"
    else
      ck 1 root_transport "HTTP $code"
      if [[ "$code" != "200" ]]; then
        viol "GET / → HTTP $code (lokalde DB/ortam farkı olabilir; içerik raporlayıcı sadece not)"
      fi
      content_reporter "lokal"
    fi
    # --- blocker: §14 zorunlu dosyalar statik servis edilmeli ---
    # not: php -S'de dosya yoksa istek index.php'ye (front-controller) düşer ve 200
    # döner — bu yüzden yalnız kod değil Content-Type da doğrulanır.
    meta_r="$(http_meta "$BASE/robots.txt" /dev/null "$HDR_F")"
    c_code_r="${meta_r%%$'\t'*}"
    c_ctype_r="${meta_r#*$'\t'}"
    if [[ "$c_code_r" == "200" && "$c_ctype_r" == text/plain* ]]; then
      ck 1 robots_txt "200 · $c_ctype_r"
    elif [[ "$c_code_r" == "200" ]]; then
      err "GET /robots.txt → 200 ama statik servis edilmedi (Content-Type: ${c_ctype_r:-yok}) — robots.txt pakette eksik, istek index.php'ye düşüyor"
      ck 0 robots_txt "yanlış ctype: ${c_ctype_r:-yok}"
    else
      err "GET /robots.txt → $c_code_r (§14 zorunlu dosya servis edilmedi)"
      ck 0 robots_txt "$c_code_r"
    fi
    meta_s="$(http_meta "$BASE/sitemap.xml" /dev/null "$HDR_F")"
    c_code_s="${meta_s%%$'\t'*}"
    c_ctype_s="${meta_s#*$'\t'}"
    if [[ "$c_code_s" == "200" && "$c_ctype_s" == *xml* ]]; then
      ck 1 sitemap_xml "200 · $c_ctype_s"
    elif [[ "$c_code_s" == "200" ]]; then
      err "GET /sitemap.xml → 200 ama statik servis edilmedi (Content-Type: ${c_ctype_s:-yok}) — sitemap.xml pakette eksik, istek index.php'ye düşüyor"
      ck 0 sitemap_xml "yanlış ctype: ${c_ctype_s:-yok}"
    else
      err "GET /sitemap.xml → $c_code_s (§14 zorunlu dosya servis edilmedi)"
      ck 0 sitemap_xml "$c_code_s"
    fi
    extra_paths_reporter "$BASE"
    info ".htaccess: php -S rewrite kurallarını uygulamaz; rewrite bağımlı rotalar canlıda (--url) doğrulanmalı"
  fi
elif [[ "$MODE" == "live" && "$FORCED" -eq 0 ]]; then
  # --- canlı mod: raporlayıcı katman (bloker yok) ---
  code="$(http_code "$URL" "$BODY_F")"
  if [[ "$code" == "000" ]]; then
    viol "ulaşılamadı: $URL"
    ck 0 reachable "000"
  else
    ck 1 reachable "HTTP $code"
    if [[ "$code" != "200" ]]; then
      viol "GET / → HTTP $code ($URL)"
    fi
    content_reporter "canlı"
    extra_paths_reporter "${URL%/}"
  fi
fi

RESULT="PASS"
if [[ -s "$ERR_F" ]]; then
  RESULT="FAIL"
elif [[ -s "$VIOL_F" ]]; then
  RESULT="WARN"
fi

export SMOKE_R="$REPORT" SMOKE_MODE="$MODE" SMOKE_DEST="${URL:-$TARGET}"
export SMOKE_RES="$RESULT" SMOKE_STRICT="$STRICT"
export SMOKE_E="$ERR_F" SMOKE_V="$VIOL_F" SMOKE_N="$NOTE_F" SMOKE_C="$CK_F"
python3 - <<'PY'
import datetime
import json
import os


def lines(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return [ln for ln in fh.read().splitlines() if ln.strip()]
    except FileNotFoundError:
        return []


checks = []
for ln in lines(os.environ["SMOKE_C"]):
    parts = ln.split("|", 2)
    if len(parts) == 3:
        checks.append({"ok": parts[0] == "1", "name": parts[1], "detail": parts[2]})

report = {
    "schema_version": 1,
    "tool": "smoke-test",
    "version": "1.0.0",
    "mode": os.environ["SMOKE_MODE"],
    "target": os.environ["SMOKE_DEST"],
    "result": os.environ["SMOKE_RES"],
    "strict": os.environ["SMOKE_STRICT"] == "1",
    "errors": lines(os.environ["SMOKE_E"]),
    "violations": lines(os.environ["SMOKE_V"]),
    "notes": lines(os.environ["SMOKE_N"]),
    "checks": checks,
    "at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(os.environ["SMOKE_R"], "w", encoding="utf-8") as fh:
    json.dump(report, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

echo "==> Smoke ($MODE): $RESULT → $REPORT"
if [[ "$RESULT" == "FAIL" ]]; then
  while IFS= read -r l; do echo "    [hata] $l"; done < "$ERR_F"
  exit 1
fi
if [[ "$RESULT" == "WARN" ]]; then
  while IFS= read -r l; do echo "    [uyarı] $l"; done < "$VIOL_F"
  if [[ "$STRICT" -eq 1 ]]; then
    echo "    --strict: WARN → exit 1"
    exit 1
  fi
fi
exit 0
