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
# K1b (Tur 2-5b, F3): stream-stall kanalı — stream sessiz + hedef ağaç CPU ≈0 +
#   token sabitse STREAM_STALL_MAX (env, varsayılan 90s) içinde TERM. F3 kanıtı
#   (Tur 2-5a pilot 2): boş assistant msg + 8dk token-0 asılı HTTP stream —
#   idle_max=900s bu gecikmeyle uyumsuz. Üretken reasoning CPU üretir (K1a korunur;
#   dolu stream'e kill yasak). Token bilinmiyorsa (DB yok) K1b DEVRE DIŞI (false-kill yasak).
# K1b-2 (Tur 2-5b sıkılaştırma — busy-hang): üretim (stream/token/dosya) sıfır +
#   CPU pencere deltası < 22.5s/90s (%25 — ağır reasoning ≈%27 üstü korunur) ise
#   ZERO_PROD_CAP (env, varsayılan 420s) içinde TERM "zero-prod". Kanıt: 5b pilot
#   turn 4 — 17.5dk turn, reas delta=32000 TAM, out=0 (busy-hang, CPU %2-10,
#   stream/token/dosya sabit); K1b strict CPU eşiğiyle doğru korudu ama kesmedi.
#   420s > ölçülen max üretken tek-turn (291s, 5b turn 3) — K1a marjı korunur.
# Stream yolu: orchestrate her ajan çağrısında .factory/e2e-last-ev dosyasına
# mktemp ev yolunu yazar; watchdog her turda okur.
# --p2-only: P1'i atla (domain-report.json bootstrap'ta kopyalanmış olmalı),
# state P2'ye alınır, yalnız P2 koşulur (pilot modu).
# Kullanım:
#   e2e-driver.sh [--p2-only] <proje_dizini> <run_dizini> [max_attempts=6] [idle_max=900] [sleep=30]
#   NO_WRITE_CAP=7200 e2e-driver.sh ...   # kademe-2 eşiği (env)
#   STREAM_STALL_MAX=90 e2e-driver.sh ... # K1b stream-stall eşiği (env; 60-120)
#   ZERO_PROD_CAP=420 e2e-driver.sh ...   # K1b-2 zero-prod eşiği (env; busy-hang)
#   OPENCODE_DB=<path> e2e-driver.sh ...  # K1b token kanalı DB (env; default data dir)
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

tree_pids() { # $1=pid — stdout: pid + torunlar (satır satır; kill_tree ile aynı derinlik ailesi)
  local pid="$1" c
  echo "$pid"
  for c in $(pgrep -P "$pid" 2>/dev/null); do tree_pids "$c"; done
}

cpu_time_pid() { # $1=pid → stdout: birikmiş CPU saniye (2 hane, yüksek çözünürlük)
  # Linux: /proc/<pid>/stat utime+stime (10ms çözünürlük) — `ps -o cputime` 1s truncate
  # eder; kısa pencere cdelta'sını 0'a düşürüp busy-hang'i stream-stall sanabiliyordu
  # (CI kanıtı: senaryo 34, run 38052451758+38053946442). macOS: /proc yok → ps (0.01s).
  local p="$1"
  if [[ -r "/proc/$p/stat" ]]; then
    sed 's/.*) //' "/proc/$p/stat" 2>/dev/null | awk '{ printf "%.2f\n", ($12 + $13) / 100 }'
  else
    ps -p "$p" -o cputime= 2>/dev/null | tr -d ' ' | awk '
      NF {
        n = split($0, a, ":"); s = 0
        if (n == 1) s = a[1]
        else if (n == 2) s = a[1] * 60 + a[2]
        else s = a[1] * 3600 + a[2] * 60 + a[3]
        printf "%.2f\n", s
      }'
  fi
}

tree_cpu_sum() { # $1=pid — stdout: ağaç toplam cputime saniye (float, 2 hane)
  tree_pids "$1" 2>/dev/null | while read -r p; do
    cpu_time_pid "$p"
  done | awk 'NF { t += $1 } END { printf "%.2f", t + 0 }'
}

tokens_sum() { # $1=project — stdout: son oturum (output+reasoning) | NA (bilinmiyorsa K1b kapalı)
  local db="${OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}"
  [[ -f "$db" ]] || { echo "NA"; return 0; }
  python3 - "$db" "$1" <<'PY'
import sqlite3, sys
try:
    c = sqlite3.connect("file:%s?mode=ro" % sys.argv[1], uri=True)
    row = c.execute(
        "SELECT COALESCE(tokens_output,0)+COALESCE(tokens_reasoning,0)"
        " FROM session WHERE directory LIKE ?"
        " ORDER BY time_created DESC LIMIT 1",
        ("%" + sys.argv[2] + "%",),
    ).fetchone()
    print(row[0] if row else "NA")
except Exception:
    print("NA")
PY
}

run_watchdog() { # $1=project $2=target-pid $3=idle_max $4=no_write_cap(Varsayılan 7200)
  # K1 genişletmesi (Tur 2-2/2-3): ÜÇ sinyal kanalı + İKİ KADEMELİ kill —
  #   Kanallar: (a) proje dosya değişikliği, (b) event stream non-empty output,
  #            (c) opencode CPU time ilerlemesi (reasoning token üretimi CPU kullanır;
  #                NDJSON stream reasoning sırasında sessiz — pilot1 kanıtı).
  #   Kademe 1 — idle_max: HER ÜÇ kanal da sessizse kill (ölü süreç).
  #   Kademe 1b (Tur 2-5b F3) — stream-stall: stream sessiz + hedef ağaç CPU pencere
  #     deltası < 0.5s (≈%0.5) + token sabit + opencode/asıl ev dosyası mevcut →
  #     STREAM_STALL_MAX (90s) içinde TERM. Asılı HTTP stream (token 0, CPU ~0)
  #     için; üretken reasoning CPU ürettiği için K1a'yı İHLAL ETMEZ.
  #   Kademe 2 — no_write_cap: DOSYA YAZIMI yoksa CPU/stream aktif olsa bile kill
  #     (busy-loop tuzağı: CPU yakan ama üretmeyen süreç; K1 korunur çünkü
  #     üretken reasoning er ya da geç dosya yazar — A2' duvar-saati de bunu zorlar).
  #   no_write_cap >> tipik reasoning→ilk-write süresi olmalı (varsayılan 7200s=2sa;
  #   pilot2 ilk write 23dk → ~5× marj).
  local project="$1" target="$2" idle_max="$3" now_cap="${4:-7200}"
  local mark last last_write now hit phase idle evpath size lastsize opid ct1 ct2
  local stall_max last_stream_grow last_tok last_tok_val cpu_win_t cpu_win_sum
  local csum cdelta prod_last tok wlen
  mark="$(mktemp)"
  last="$(date +%s)"
  last_write="$last"
  lastsize=-1
  stall_max="${STREAM_STALL_MAX:-90}"
  last_stream_grow="$last"
  last_tok="$last"
  last_tok_val=""
  cpu_win_t="$last"
  cpu_win_sum=""
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
      last_stream_grow="$last"
      last_tok="$last"
      continue
    fi
    now="$(date +%s)"
    # Kanal (a): proje dosya değişikliği
    hit="$(find "$project" -type f -newer "$mark" ! -path '*/.git/*' -print -quit 2>/dev/null)"
    if [[ -n "$hit" ]]; then
      touch "$mark"
      last="$now" # dosya ilerlemesi — no-write-cap sayacı sıfırlanır
      last_write="$now"
      last_stream_grow="$now"
      last_tok="$now"
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
            last="$now" # mevcut stream içeriği aktivite kredisi (K1)
            last_stream_grow="$now"
          fi
        elif [[ "$size" -gt "$lastsize" ]]; then
          lastsize="$size"
          last="$now"
          last_stream_grow="$now"
          # stream dolu — idle sıfırla; ama CONTINUE YOK (no-write-cap'e düşmeli)
        fi
      fi
    fi
    # K1b token kanalı: oturum token toplamı değişti mi? (NA → K1b kapalı — false-kill yasak)
    tok="$(tokens_sum "$project")"
    if [[ "$tok" == "NA" ]]; then
      last_tok="$now"
      last_tok_val=""
    elif [[ "$tok" != "$last_tok_val" ]]; then
      last_tok_val="$tok"
      last_tok="$now"
    fi
    # Kanal (c): opencode CPU time ilerledi mi? (reasoning token üretimi CPU kullanır)
    if [[ -n "$opid" && -n "$ct1" ]]; then
      ct2="$(ps -p "$opid" -o cputime= 2>/dev/null | tr -d ' ')"
      if [[ -n "$ct2" && "$ct1" != "$ct2" ]]; then
        last="$now"
        # CPU çalışıyor — idle sıfırla; ama CONTINUE YOK (no-write-cap'e düşmeli)
      fi
    fi
    idle=$((now - last))
    if [[ "$idle" -ge "$idle_max" ]]; then
      echo "WATCHDOG: P2 idle ${idle}s ≥ ${idle_max}s (dosya+stream+CPU sessiz) — TERM (pid $target)" >&2
      [[ -n "${E2E_WD_KILL_MARK:-}" ]] && echo "idle" >> "$E2E_WD_KILL_MARK"
      kill_tree "$target"
      rm -f "$mark"
      return 143
    fi
    # Kademe 1b (K1b · F3) + K1b-2 (zero-prod · busy-hang) — üretim sinyalleri:
    #   stream/token kanalları sessiz + opencode çalışıyor + ev dosyası var +
    #   token kanalı biliniyor. CPU pencere örneği (stall_max aralıkla) iki
    #   hükmün ortak girdisidir: K1b strict (<0.5s ≈%0.5 — asılı idle), K1b-2
    #   geniş (<22.5s ≈%25 — busy-hang; ağır reasoning %27 üstü, korunur).
    if [[ -n "$opid" && -n "$evpath" && -f "$evpath" && -n "$last_tok_val" ]]; then
      prod_last="$last_stream_grow"
      [[ "$last_tok" -gt "$prod_last" ]] && prod_last="$last_tok"
      cdelta="NA"
      if [[ $((now - cpu_win_t)) -ge "$stall_max" ]]; then
        csum="$(tree_cpu_sum "$target")"
        wlen=$((now - cpu_win_t))
        if [[ -n "$cpu_win_sum" && "$wlen" -gt 0 ]]; then
          # cdelta = CPU YÜZDESİ (pencere uzunluğuna normalize) — K1b <%0.55, K1b-2 <%25
          cdelta="$(awk -v a="$csum" -v b="$cpu_win_sum" -v w="$wlen" 'BEGIN { d = a - b; if (d < 0) d = -d; printf "%.3f", d * 100 / w }')"
        fi
        cpu_win_sum="$csum"
        cpu_win_t="$now"
      fi
      # K1b: asılı idle stream — CPU ≈%0 → STREAM_STALL_MAX'de TERM
      if [[ $((now - prod_last)) -ge "$stall_max" && "$cdelta" != "NA" ]] \
        && awk -v d="$cdelta" 'BEGIN { exit !(d < 0.55) }'; then
        echo "WATCHDOG: P2 stream-stall $((now - prod_last))s (stream sessiz, CPU ${cdelta}%<0.55%, token sabit) — TERM (pid $target)" >&2
        [[ -n "${E2E_WD_KILL_MARK:-}" ]] && echo "stream-stall" >> "$E2E_WD_KILL_MARK"
        kill_tree "$target"
        rm -f "$mark"
        return 143
      fi
      # K1b-2: busy-hang — üretim sıfır + CPU %25 altı → ZERO_PROD_CAP'de TERM
      if [[ $((now - prod_last)) -ge "${ZERO_PROD_CAP:-420}" && "$cdelta" != "NA" ]] \
        && awk -v d="$cdelta" 'BEGIN { exit !(d < 25) }'; then
        echo "WATCHDOG: P2 zero-prod $((now - prod_last))s ≥ ${ZERO_PROD_CAP:-420}s (stream/token/dosya sabit, CPU ${cdelta}%<25%) — TERM (pid $target)" >&2
        [[ -n "${E2E_WD_KILL_MARK:-}" ]] && echo "zero-prod" >> "$E2E_WD_KILL_MARK"
        kill_tree "$target"
        rm -f "$mark"
        return 143
      fi
    fi
    # Kademe 2: busy-loop tuzağı — dosya ilerlemesi yoksa CPU/stream yetmez
    if [[ $((now - last_write)) -ge "$now_cap" ]]; then
      echo "WATCHDOG: P2 no-write $((now - last_write))s ≥ ${now_cap}s (CPU/stream aktif olsa bile dosya yok) — TERM (pid $target)" >&2
      [[ -n "${E2E_WD_KILL_MARK:-}" ]] && echo "no-write" >> "$E2E_WD_KILL_MARK"
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
  WD_MARK="$RUN/.wd-kill.$attempt"
  rm -f "$WD_MARK"
  bash "$REPO/scripts/web/orchestrate.sh" "$PROJ" --auto >> "$LOG" 2>&1 &
  opid=$!
  E2E_WD_KILL_MARK="$WD_MARK" run_watchdog "$PROJ" "$opid" "$IDLE_MAX" "$NO_WRITE_CAP" 2>> "$LOG" &
  wpid=$!
  wait "$opid" || rc=$?
  # Tur 2-4 fix: watchdog doğal çıkışını bekle (hedef ölünce ≤5s'de return 0);
  # 12s sonra hâlâ yaşıyorsa TERM et. Sayım ARTIK wrc'ye göre DEĞİL — yalniz
  # kill marker dosyasına göre (eski davranış: driver'ın kendi TERM'i 143 üretip
  # sahte kill sayıyordu — Tur 2-3: watchdog_kills=6, gerçek kill=0).
  waited=0
  while kill -0 "$wpid" 2>/dev/null && [[ "$waited" -lt 12 ]]; do
    sleep 1
    waited=$((waited + 1))
  done
  kill "$wpid" 2>/dev/null || true
  wait "$wpid" 2>/dev/null || true
  wd_fired=0
  if [[ -s "$WD_MARK" ]]; then
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
