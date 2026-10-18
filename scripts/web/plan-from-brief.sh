#!/usr/bin/env bash
set -euo pipefail

# Webrail — brief → PLAN.md (hiyerarşik P1–P5; YAPILACAKLAR değil)
# Kullanım: bash scripts/web/plan-from-brief.sh <proje> "<brief>"
# Exit: 0 OK · 1 hata

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
BRIEF="${2:-}"

[[ -d "$PROJECT" ]] || { echo "plan: dizin yok: $PROJECT" >&2; exit 1; }
[[ -n "$BRIEF" ]] || { echo "kullanım: plan-from-brief.sh <proje> \"<brief>\"" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
TPL="$ROOT/docs/templates/PLAN.md"
[[ -f "$TPL" ]] || { echo "plan: şablon yok: $TPL" >&2; exit 1; }

export _P_PROJECT="$PROJECT" _P_BRIEF="$BRIEF" _P_TPL="$TPL"

python3 - <<'PY'
import os, re
from pathlib import Path
from datetime import date

project = Path(os.environ["_P_PROJECT"])
brief = os.environ["_P_BRIEF"].strip()
tpl = Path(os.environ["_P_TPL"]).read_text(encoding="utf-8")

first = brief.splitlines()[0].strip()
name = re.sub(r'^[#*\-\s]+', '', first)
name = re.sub(r'[.!?].*$', '', name).strip()
words = name.split()
if len(words) > 8:
    name = " ".join(words[:8])
if len(name) < 2:
    name = "Proje"
name = name[:80]
summary = brief if len(brief) <= 400 else brief[:397] + "..."

lower = brief.lower()
signals = []
def add(cond, sid, msg, sev="warn"):
    if cond:
        signals.append((sid, msg, sev))

catalog = any(k in lower for k in ("ürün", "urun", "katalog", "e-ticaret", "eticaret", "shop", "mağaza", "magaza"))
add(catalog, "cart", "Katalog/e-ticaret sinyali — sepet/sipariş planlanmalı", "blocker")
add(catalog, "payment", "E-ticaret sinyali — kart/ödeme veya kapıda ödeme kararı gerekli", "warn")
add(catalog or "ürün" in lower or "urun" in lower, "reviews", "Ürün sayfası muhtemel — yorum/oylama alanı önerilir", "warn")
add(any(k in lower for k in ("kullanıcı", "user", "üye", "uye", "login")), "rbac", "Kullanıcı/auth — RBAC zorunlu", "blocker")
add(True, "seo", "SEO (robots/sitemap/meta) varsayılan", "warn")
add(any(k in lower for k in ("kvkk", "gdpr", "kişisel", "kisisel")) or True, "kvkk", "KVKK/aydınlatma/çerez — TR varsayılan öneri", "warn")

rows = "\n".join(f"| `{i}` | {m} | {s} | P1 karar |" for i, m, s in signals) or "| — | — | — | — |"

text = tpl
text = text.replace("_(ad)_", name)
text = text.replace("_(1–2 cümle)_", summary.replace("|", "/"))
marker = "## Proaktif uyarılar (gap-scan)"
if marker in text:
    head, _, _rest = text.partition(marker)
    text = (
        head + marker + "\n\n"
        "> Sistem brief’te unutulan ama sektörde zorunlu maddeleri buraya yazar (WARN).\n\n"
        "| ID | Bulgu | Önem | Karar |\n"
        "|----|-------|------|-------|\n"
        f"{rows}\n\n"
        "---\n\n## Oturum kayıtları\n\n"
        "`PHASE-LOG.md` + `bash scripts/web/phase-log.sh . \"…\" \"…\" \"<IDE>\"`\n"
    )
text = re.sub(r'\*\*Durum:\*\*.*', f'**Durum:** taslak · {date.today().isoformat()}', text, count=1)

out = project / "PLAN.md"
out.write_text(text, encoding="utf-8")
print(f"plan: yazıldı → {out} (proje={name}, uyarı={len(signals)})")
PY

# DISCOVERY ile hizala (varsa mode from-brief ayrı çağrılır)
if [[ ! -f "$PROJECT/PHASE-LOG.md" && -f "$ROOT/docs/templates/PHASE-LOG.md" ]]; then
  cp "$ROOT/docs/templates/PHASE-LOG.md" "$PROJECT/PHASE-LOG.md"
fi
bash "$ROOT/scripts/web/phase-log.sh" "$PROJECT" "PLAN.md üretildi (plan-from-brief)" "P1 domain" "plan" >/dev/null 2>&1 || true
