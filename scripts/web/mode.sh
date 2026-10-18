#!/usr/bin/env bash
set -euo pipefail

# Webrail — keşif/fabrika mod kilidi
# Kullanım:
#   bash scripts/web/mode.sh status|init|promote|from-brief|require-factory [proje] [brief...]
#   from-brief: DISCOVERY doldur + promote (hız şeridi; bypass değil)
# Exit: 0 OK · 1 FAIL

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OP="${1:-}"
shift || true

usage() {
  echo "kullanım: mode.sh <status|init|promote|from-brief|require-factory> [proje_dizini] [brief...]" >&2
  exit 1
}

[[ -n "$OP" ]] || usage

PROJECT="."
BRIEF=""
case "$OP" in
  from-brief)
    PROJECT="${1:-.}"
    shift || true
    BRIEF="$*"
    [[ -n "$BRIEF" ]] || { echo "mode: from-brief için brief metni gerekli" >&2; exit 1; }
    ;;
  *)
    PROJECT="${1:-.}"
    ;;
esac

[[ -d "$PROJECT" ]] || { echo "mode: dizin yok: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
MODE_FILE="$PROJECT/.factory/mode.json"
DISCOVERY="$PROJECT/DISCOVERY.md"
TPL="$ROOT/docs/templates/DISCOVERY.md"
export MODE_FILE PROJECT DISCOVERY BRIEF TPL

read_mode() {
  python3 - <<'PY'
import json, os, sys
p = os.environ["MODE_FILE"]
if not os.path.isfile(p):
    print("factory")  # geriye uyum: mode yoksa fabrika (eski projeler)
    sys.exit(0)
try:
    d = json.load(open(p, encoding="utf-8"))
except Exception as e:
    print(f"mode: bozuk mode.json: {e}", file=sys.stderr)
    sys.exit(1)
print(d.get("mode") or "discovery")
PY
}

do_promote() {
  export MODE_FILE
  [[ -f "$DISCOVERY" ]] || {
    echo "mode: DISCOVERY.md yok — önce /kesfet, from-brief veya şablonu doldur" >&2
    exit 1
  }
  if ! grep -Eq '^\*\*Proje adı:\*\*[[:space:]]+([^_[:space:]]|[^_].+)' "$DISCOVERY" \
    || grep -Eq '^\*\*Proje adı:\*\*.*_buraya yaz' "$DISCOVERY"; then
    echo "mode: DISCOVERY.md → **Proje adı:** doldurulmalı (şablon yer tutucusu kabul değil)" >&2
    exit 1
  fi
  for p in core views SQL/veritabani.sql index.php; do
    if [[ -e "$PROJECT/$p" ]]; then
      echo "mode: uyarı — keşifte üretim izi var: $p (yine de promote edilebilir; P1 ile hizala)" >&2
    fi
  done
  python3 - <<'PY'
import json, os
from datetime import datetime, timezone
path = os.environ["MODE_FILE"]
os.makedirs(os.path.dirname(path), exist_ok=True)
doc = {}
if os.path.isfile(path):
    try:
        doc = json.load(open(path, encoding="utf-8"))
    except Exception:
        doc = {}
doc.update({
    "schema_version": 1,
    "mode": "factory",
    "promoted_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "discovery_path": "DISCOVERY.md",
    "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
})
json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("mode: promote → factory")
PY
  bash "$ROOT/scripts/web/measure.sh" "$PROJECT" mode_promoted true A0 || true
  bash "$ROOT/scripts/web/run-status.sh" "$PROJECT" || true
  echo "mode: sonraki → bash scripts/web/state.sh start $PROJECT"
}

fill_from_brief() {
  mkdir -p "$PROJECT/.factory"
  if [[ ! -f "$DISCOVERY" && -f "$TPL" ]]; then
    cp "$TPL" "$DISCOVERY"
  elif [[ ! -f "$DISCOVERY" ]]; then
    echo "mode: DISCOVERY şablonu yok: $TPL" >&2
    exit 1
  fi
  # mode.json yoksa init
  if [[ ! -f "$MODE_FILE" ]]; then
    bash "$ROOT/scripts/web/mode.sh" init "$PROJECT" >/dev/null
  fi
  python3 - <<'PY'
import os, re
from datetime import date
from pathlib import Path

discovery = Path(os.environ["DISCOVERY"])
brief = (os.environ.get("BRIEF") or "").strip()
if len(brief) < 8:
    raise SystemExit("mode: brief çok kısa (en az ~8 karakter)")

# Proje adı: ilk satır veya ilk 6 kelime
first_line = brief.splitlines()[0].strip()
name = re.sub(r'^[#*\-\s]+', '', first_line)
name = re.sub(r'[.!?].*$', '', name).strip()
words = name.split()
if len(words) > 8:
    name = " ".join(words[:8])
if len(name) < 2:
    name = "Proje"
# dosya-adı dostu değil; görünen ad
name = name[:80]

lower = brief.lower()
want_rbac = any(k in lower for k in ("kullanıcı", "user", "login", "auth", "rol", "admin"))
want_admin = "admin" in lower or "yönetim" in lower or "panel" in lower
want_cart = any(k in lower for k in ("sepet", "sipariş", "siparis", "e-ticaret", "ürün", "urun", "katalog"))
want_kvkk = any(k in lower for k in ("kvkk", "gdpr", "kişisel", "kisisel", "rıza", "riza"))
# varsayılan: web teslim → seo evet; kvkk TR işleri için varsayılan öner
if "kvkk" not in lower and "gdpr" not in lower:
    want_kvkk = True  # sektör varsayılanı (P1 onaylar)

text = discovery.read_text(encoding="utf-8")
text = re.sub(
    r'\*\*Proje adı:\*\*.*',
    f'**Proje adı:** {name}',
    text,
    count=1,
)
text = re.sub(
    r'\*\*Tarih:\*\*.*',
    f'**Tarih:** {date.today().isoformat()}',
    text,
    count=1,
)
# İş özeti
summary = brief if len(brief) <= 600 else brief[:597] + "..."
block1 = f"## 1. İş özeti (3–5 cümle)\n\n{summary}\n"
text = re.sub(
    r'## 1\. İş özeti \(3–5 cümle\).*?(?=\n## 2\. |\Z)',
    block1 + "\n",
    text,
    count=1,
    flags=re.S,
)
dahil = "brief kapsamı (from-brief)"
hariç = "henüz netleşmedi — P1'de dondurulacak"
block2 = (
    "## 2. Kapsam\n\n"
    "| Dahil | Hariç (bilinçli) |\n"
    "|-------|------------------|\n"
    f"| {dahil} | {hariç} |\n"
)
text = re.sub(
    r'## 2\. Kapsam.*?(?=\n## 3\. |\Z)',
    block2 + "\n",
    text,
    count=1,
    flags=re.S,
)
entities = ["users"]
if want_cart:
    entities += ["products", "orders"]
block3 = "## 3. Varlıklar (taslak tablo adları)\n\n" + "\n".join(f"- {e}" for e in entities) + "\n"
text = re.sub(
    r'## 3\. Varlıklar.*?(?=\n## 4\. |\Z)',
    block3 + "\n",
    text,
    count=1,
    flags=re.S,
)
block4 = "## 4. Roller\n\n- admin\n- moderator\n- user\n"
text = re.sub(
    r'## 4\. Roller.*?(?=\n## 5\. |\Z)',
    block4 + "\n",
    text,
    count=1,
    flags=re.S,
)

def yn(b: bool) -> str:
    return "evet" if b else "hayır / P1 karar"

block5 = (
    "## 5. Modül sinyalleri (P1’e girdi)\n\n"
    "| Modül | Gerekli? | Not |\n"
    "|-------|----------|-----|\n"
    f"| auth / rbac | {yn(want_rbac or True)} | from-brief |\n"
    f"| admin CRUD | {yn(want_admin)} | from-brief |\n"
    f"| sepet / sipariş | {yn(want_cart)} | from-brief |\n"
    f"| KVKK / GDPR | {yn(want_kvkk)} | from-brief |\n"
    "| SEO | evet | varsayılan |\n"
)
text = re.sub(
    r'## 5\. Modül sinyalleri.*?(?=\n## 6\. |\Z)',
    block5 + "\n",
    text,
    count=1,
    flags=re.S,
)
block6 = (
    "## 6. Riskler / açık sorular\n\n"
    "1. from-brief otomatik taslak — P1’de edge case ve security context dondurulacak.\n"
)
text = re.sub(
    r'## 6\. Riskler.*?(?=\n## 7\. |\Z)',
    block6 + "\n",
    text,
    count=1,
    flags=re.S,
)
discovery.write_text(text, encoding="utf-8")
print(f"mode: from-brief → DISCOVERY dolduruldu (proje adı: {name})")
PY
  bash "$ROOT/scripts/web/measure.sh" "$PROJECT" discovery_minutes 5 A0 || true
}

case "$OP" in
  status)
    export MODE_FILE
    m="$(read_mode)"
    echo "mode: $m ($MODE_FILE)"
    [[ -f "$DISCOVERY" ]] && echo "discovery: var ($DISCOVERY)" || echo "discovery: yok"
    ;;

  init)
    mkdir -p "$PROJECT/.factory"
    if [[ ! -f "$DISCOVERY" && -f "$TPL" ]]; then
      cp "$TPL" "$DISCOVERY"
      echo "mode: DISCOVERY.md şablonu kopyalandı"
    fi
    python3 - <<'PY'
import json, os, sys
from datetime import datetime, timezone
path = os.environ["MODE_FILE"]
os.makedirs(os.path.dirname(path), exist_ok=True)
if os.path.isfile(path):
    try:
        existing = json.load(open(path, encoding="utf-8"))
        if existing.get("mode") in ("discovery", "factory"):
            print(f"mode: init → {existing.get('mode')} (korundu)")
            sys.exit(0)
    except Exception:
        pass
doc = {
    "schema_version": 1,
    "mode": "discovery",
    "promoted_at": None,
    "discovery_path": "DISCOVERY.md",
    "note": "Keşif (saf IDE) — kod yok. promote ile factory.",
    "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("mode: init → discovery")
PY
    ;;

  from-brief)
    fill_from_brief
    # v1.4: brief → hiyerarşik PLAN.md (YAPILACAKLAR değil)
    bash "$ROOT/scripts/web/plan-from-brief.sh" "$PROJECT" "$BRIEF" || {
      echo "mode: plan-from-brief başarısız" >&2
      exit 1
    }
    # soft denetle (blocker yoksa WARN yaz; promote'u engellemez)
    bash "$ROOT/scripts/web/denetle.sh" "$PROJECT" >/dev/null 2>&1 || true
    do_promote
    ;;

  promote)
    do_promote
    ;;

  require-factory)
    export MODE_FILE
    m="$(read_mode)"
    if [[ "$m" != "factory" ]]; then
      echo "mode: şu an '$m' — fabrika kapıları kapalı." >&2
      echo "mode: 1) DISCOVERY.md doldur veya mode.sh from-brief  2) promote" >&2
      echo "mode: (keşif = saf IDE; kod üretimi factory modunda)" >&2
      exit 1
    fi
    ;;

  *) usage ;;
esac
