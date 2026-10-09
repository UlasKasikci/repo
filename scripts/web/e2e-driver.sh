#!/usr/bin/env bash
# App-Fabrika E2E driver — orchestrate --auto attempt döngüsü + Faz 1.4 L3
# att0-0-write watchdog: P2 fazında dosya-değişikliği idle_max saniye durursa
# çocuklar + orchestrate TERM edilir, deneme retry'a sayılır (WASTE-AUDIT §2-A:
# att0-0-write erken dönüşleri 6.2 saat duvar israfı — E2E-3 275dk / ab1 71dk).
# P1/P3/P4/P5'te sayaç sıfırlanır (P1 uzun sessizlikleri meşrudur — domain-report
# yalnız oturum sonunda yazılır).
# K1 genişletmesi (Tur 2-2/2-3): idle sinyali artık ÜÇ kanaldan + İKİ KADEMELİ kill —
#   Kanallar: (a) proje dosya değişikliği, (b) event stream non-empty output,
#            (c) opencode CPU time (reasoning NDJSON stream'i sessiz kalır — pilot1
#            kanıtı: 36KB'da 900s sabit, 27.4% CPU ile üretken reasoning).
#   Kademe 1 — idle_max: üç kanal da sessizse kill. Kademe 2 — no_write_cap
#   (NO_WRITE_CAP env, varsayılan 7200s): dosya yazımı yoksa CPU/stream aktif
#   olsa bile kill (busy-loop tuzağı — yeni sinyalin kör noktası, Tur2-3 ön koşulu).
# Stream yolu: orchestrate her ajan çağrısında .factory/e2e-last-ev dosyasına
# mktemp ev yolunu yazar; watchdog her turda okur.
# --p2-only: P1'i atla (domain-report.json bootstrap'ta kopyalanmış olmalı),
# state P2'ye alınır, yalnız P2 koşulur (pilot modu).
# Kullanım:
#   e2e-driver.sh [--p2-only] <proje_dizini> <run_dizini> [max_attempts=6] [idle_max=900] [sleep=30]
#   NO_WRITE_CAP=7200 e2e-driver.sh ...   # kademe-2 eşiği (env)
#   e2e-driver.sh --watchdog <proje_dizini> <hedef_pid> <idle_max> [no_write_cap]
set -u

kill_tree() { # watchdog kill sırası: önce çocuklar (agent/opencode), sonra hedef
  local pid="$1" c g
  for c in $(pgrep -P "$pid" 2>/dev/null); do
    for g in $(pgrep -P "$c" 2>/dev/null); do kill -TERM "$g" 2>/dev/null || true; done
    kill -TERM "$c" 2>/dev/null || true
  done
  kill -TERM "$pid" 2>/dev/null || true
}

watchdog_phase() { # $1=project — stdout: current_phase (yok/bozuk → OTHER)
  python3 - "$1/.factory/web-state.json" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        print(json.load(fh).get("current_phase", "OTHER"))
except (OSError, json.JSONDecodeError):
    print("OTHER")
PY
}

run_watchdog() { # $1=project $2=target-pid $3=idle_max $4=no_write_cap(Varsayılan 7200)
  # K1 genişletmesi (Tur 2-2/2-3): ÜÇ sinyal kanalı + İKİ KADEMELİ kill —
  #   Kanallar: (a) proje dosya değişikliği, (b) event stream non-empty output,
  #            (c) opencode CPU time ilerlemesi (reasoning token üretimi CPU kullanır;
  #                NDJSON stream reasoning sırasında sessiz — pilot1 kanıtı).
  #   Kademe 1 — idle_max: HER ÜÇ kanal da sessizse kill (ölü süreç).
  #   Kademe 2 — no_write_cap: DOSYA YAZIMI yoksa CPU/stream aktif olsa bile kill
  #     (busy-loop tuzağı: CPU yakan ama üretmeyen süreç; K1 korunur çünkü
  #     üretken reasoning er ya da geç dosya yazar — A2' duvar-saati de bunu zorlar).
  #   no_write_cap >> tipik reasoning→ilk-write süresi olmalı (varsayılan 7200s=2sa;
  #   pilot2 ilk write 23dk → ~5× marj).
  local project="$1" target="$2" idle_max="$3" now_cap="${4:-7200}"
  local mark last last_write now hit phase idle evpath size lastsize opid ct1 ct2
  mark="$(mktemp)"
  last="$(date +%s)"
  last_write="$last"
  lastsize=-1
  while kill -0 "$target" 2>/dev/null; do
    # Kanal (c) CPU örneği: uyku ÖNCESİ opencode CPU time'ı
    opid="$(pgrep -f "opencode run" 2>/dev/null | head -1)"
    ct1=""
    [[ -n "$opid" ]] && ct1="$(ps -p "$opid" -o cputime= 2>/dev/null | tr -d ' ')"
    sleep 5
    phase="$(watchdog_phase "$project")"
    if [[ "$phase" != "P2" ]]; then
      last="$(date +%s)" # sayaç yalnız P2'de işler
      last_write="$last"
      lastsize=-1
      continue
    fi
    # Kanal (a): proje dosya değişikliği
    hit="$(find "$project" -type f -newer "$mark" ! -path '*/.git/*' -print -quit 2>/dev/null)"
    if [[ -n "$hit" ]]; then
      touch "$mark"
      last="$(date +%s)"
      last_write="$last" # dosya ilerlemesi — no-write-cap sayacı sıfırlanır
      continue
    fi
    # Kanal (b): event stream non-empty output — son non-empty output sinyali.
    evpath="$(cat "$project/.factory/e2e-last-ev" 2>/dev/null || true)"
    if [[ -n "$evpath" && -f "$evpath" ]]; then
      size="$(wc -c < "$evpath" 2>/dev/null || echo 0)"
      size="${size// /}"
      if [[ "$size" =~ ^[0-9]+$ ]]; then
        if [[ "$lastsize" -lt 0 ]]; then
          lastsize="$size" # baseline
          if [[ "$size" -gt 0 ]]; then
            last="$(date +%s)" # mevcut stream içeriği aktivite kredisi (K1)
          fi
        elif [[ "$size" -gt "$lastsize" ]]; then
          lastsize="$size"
          last="$(date +%s)"
          # stream dolu — idle sıfırla; ama CONTINUE YOK (no-write-cap'e düşmeli)
        fi
      fi
    fi
    # Kanal (c): opencode CPU time ilerledi mi? (reasoning token üretimi CPU kullanır)
    if [[ -n "$opid" && -n "$ct1" ]]; then
      ct2="$(ps -p "$opid" -o cputime= 2>/dev/null | tr -d ' ')"
      if [[ -n "$ct2" && "$ct1" != "$ct2" ]]; then
        last="$(date +%s)"
        # CPU çalışıyor — idle sıfırla; ama CONTINUE YOK (no-write-cap'e düşmeli)
      fi
    fi
    now="$(date +%s)"
    idle=$((now - last))
    if [[ "$idle" -ge "$idle_max" ]]; then
      echo "WATCHDOG: P2 idle ${idle}s ≥ ${idle_max}s (dosya+stream+CPU sessiz) — TERM (pid $target)" >&2
      kill_tree "$target"
      rm -f "$mark"
      return 143
    fi
    # Kademe 2: busy-loop tuzağı — dosya ilerlemesi yoksa CPU/stream yetmez
    if [[ $((now - last_write)) -ge "$now_cap" ]]; then
      echo "WATCHDOG: P2 no-write $((now - last_write))s ≥ ${now_cap}s (CPU/stream aktif olsa bile dosya yok) — TERM (pid $target)" >&2
      kill_tree "$target"
      rm -f "$mark"
      return 143
    fi
  done
  rm -f "$mark"
  return 0
}

if [[ "${1:-}" == "--watchdog" ]]; then
  [[ $# -ge 4 ]] || { echo "kullanım: e2e-driver.sh --watchdog <proje> <pid> <idle_max> [no_write_cap]" >&2; exit 1; }
  run_watchdog "$2" "$3" "$4" "${5:-${NO_WRITE_CAP:-7200}}"
  exit $?
fi

P2_ONLY=0
ARGS=()
for a in "$@"; do
  if [[ "$a" == "--p2-only" ]]; then
    P2_ONLY=1
  else
    ARGS+=("$a")
  fi
done
set -- ${ARGS[@]+"${ARGS[@]}"}

PROJ="${1:-}"
RUN="${2:-}"
MAX_ATTEMPTS="${3:-6}"
IDLE_MAX="${4:-900}"
SLEEP_BETWEEN="${5:-30}"
NO_WRITE_CAP="${NO_WRITE_CAP:-7200}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -n "$PROJ" && -n "$RUN" ]] || {
  echo "kullanım: e2e-driver.sh [--p2-only] <proje> <run-dir> [max_attempts] [idle_max] [sleep]" >&2
  exit 1
}
[[ -d "$PROJ" ]] || { echo "driver: proje dizini yok: $PROJ" >&2; exit 1; }
[[ -d "$RUN" ]] || { echo "driver: run dizini yok: $RUN" >&2; exit 1; }

# --p2-only pilot kurulumu: domain-report zaten varsa state'i P2'ye al (P1 atla)
if [[ "$P2_ONLY" -eq 1 ]]; then
  if [[ ! -f "$PROJ/.factory/domain-report.json" ]]; then
    echo "driver: --p2-only için .factory/domain-report.json gerekli (bootstrap'ta kopyala)" >&2
    exit 1
  fi
  bash "$REPO/scripts/web/state.sh" start "$PROJ" >/dev/null 2>&1 || true
  bash "$REPO/scripts/web/state.sh" advance "$PROJ" >/dev/null 2>&1 || true
  echo "driver: --p2-only — P1 atlandı, state P2'ye alındı"
fi

LOG="$RUN/orchestrate.log"
attempt=0
rc=0
WD_KILLS=0
printf 'DRIVER header: max_attempts=%s idle_max=%s no_write_cap=%s launched=%s\n' \
  "$MAX_ATTEMPTS" "$IDLE_MAX" "$NO_WRITE_CAP" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
while [[ "$attempt" -lt "$MAX_ATTEMPTS" ]]; do
  attempt=$((attempt + 1))
  wd_fired=0
  printf '######## attempt %s · %s ########\n' "$attempt" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  rc=0
  bash "$REPO/scripts/web/orchestrate.sh" "$PROJ" --auto >> "$LOG" 2>&1 &
  opid=$!
  run_watchdog "$PROJ" "$opid" "$IDLE_MAX" "$NO_WRITE_CAP" 2>> "$LOG" &
  wpid=$!
  wait "$opid" || rc=$?
  kill "$wpid" 2>/dev/null || true
  wrc=0
  wait "$wpid" 2>/dev/null || wrc=$?
  if [[ "$wrc" -eq 143 ]]; then
    wd_fired=1
    WD_KILLS=$((WD_KILLS + 1))
  fi
  printf -- '---- attempt %s rc=%s watchdog=%s · %s\n' "$attempt" "$rc" "$wd_fired" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
  [[ "$rc" -eq 0 ]] && break
  [[ "$rc" -eq 2 ]] && break
  # 143: dış TERM (kendi kontrolümüz) → dur; watchdog TERM'i → retry
  if [[ "$rc" -eq 143 && "$wd_fired" -eq 0 ]]; then
    break
  fi
  sleep "$SLEEP_BETWEEN"
done
printf 'DRIVER_DONE rc=%s attempts=%s watchdog_kills=%s\n' "$rc" "$attempt" "$WD_KILLS" >> "$LOG"
printf '%s\n' "$rc" > "$RUN/driver.rc"
exit "$rc"
