#!/usr/bin/env bash
set -euo pipefail

# Webrail — proaktif boşluk taraması (WARN / blocker)
# Kullanım: bash scripts/web/gap-scan.sh <proje>
# Exit: 0 her zaman (rapor); blocker varsa stdout'ta BLOCKER satırı (denetle FAIL edebilir)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "gap-scan: dizin yok" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

export _G_PROJECT="$PROJECT"
python3 - <<'PY'
import json, re, os
from datetime import datetime, timezone
from pathlib import Path

p = Path(os.environ["_G_PROJECT"])
fac = p / ".factory"
fac.mkdir(parents=True, exist_ok=True)

def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""

disc_raw = read(p / "DISCOVERY.md")
plan_raw = read(p / "PLAN.md")
# Proaktif uyarı tablosu "sepet/ödeme" kelimesi içerir — varlık sayılmaz
def strip_warn_section(t: str) -> str:
    for mark in ("## Proaktif uyarılar", "## Oturum kayıtları"):
        if mark in t:
            t = t.split(mark)[0]
    return t
intent = (disc_raw + "\n" + strip_warn_section(plan_raw)).lower()
sql = ""
for cand in (p / "SQL" / "veritabani.sql",):
    sql += read(cand)
sql_l = sql.lower()
views = " ".join(f.name for f in (p / "views").rglob("*.php")) if (p / "views").is_dir() else ""
views_l = views.lower()
php_blob = ""
for f in list((p / "core").rglob("*.php"))[:40] if (p / "core").is_dir() else []:
    php_blob += read(f)[:2000]
php_l = php_blob.lower()

findings = []

def add(fid, title, detail, severity, source):
    findings.append({
        "id": fid, "title": title, "detail": detail,
        "severity": severity, "source": source,
    })

def module_yes(blob: str, *keys: str) -> bool:
    # DISCOVERY "| sepet / sipariş | evet |" satırı
    for line in blob.splitlines():
        if "|" not in line:
            continue
        low = line.lower()
        if "evet" not in low:
            continue
        if any(k in low for k in keys):
            return True
    return False

has_catalog = bool(re.search(r'create table.*(products|urunler|katalog|items)', sql_l, re.I)) \
    or any(k in intent for k in ("e-ticaret", "eticaret", "ürün", "urun", "katalog", "mağaza", "magaza", "shop"))
has_cart = bool(re.search(r'create table.*(orders|siparis|sepet|cart)', sql_l, re.I)) \
    or module_yes(disc_raw, "sepet", "sipariş", "siparis", "cart", "order") \
    or any(k in views_l for k in ("sepet", "cart", "checkout"))
has_pay = bool(re.search(r'create table.*(payments|odemeler|transactions)', sql_l, re.I)) \
    or any(k in php_l for k in ("iyzico", "stripe", "paytr", "payment")) \
    or module_yes(disc_raw, "ödeme", "odeme", "payment", "kart")
has_review = bool(re.search(r'create table.*(reviews|yorum|ratings)', sql_l, re.I)) \
    or any(k in views_l for k in ("review", "yorum", "rating", "oylama")) \
    or module_yes(disc_raw, "yorum", "oylama", "review", "rating")
has_rbac = "role_id" in sql_l or bool(re.search(r'create table.*roles', sql_l, re.I)) \
    or module_yes(disc_raw, "rbac", "auth / rbac", "rol")
has_users = bool(re.search(r'create table.*`?users`?', sql_l, re.I)) \
    or "users" in intent
has_kvkk = module_yes(disc_raw, "kvkk", "gdpr") or "kvkk" in intent or "gdpr" in intent
if (p / "views").is_dir():
    for vf in (p / "views").rglob("*.php"):
        n = vf.name.lower()
        if any(x in n for x in ("kvkk", "cerez", "cookie", "aydinlat", "privacy")):
            has_kvkk = True
            break
has_seo = (p / "robots.txt").is_file() and (p / "sitemap.xml").is_file()

# Bilinçli istisna: QA_GATE_EXTRA / decision.qa_gate_extra --allow-no-cart
allow_no_cart = "--allow-no-cart" in (os.environ.get("QA_GATE_EXTRA") or "")
dec = fac / "decision.json"
if dec.is_file():
    try:
        d = json.loads(dec.read_text(encoding="utf-8"))
        if "--allow-no-cart" in str(d.get("qa_gate_extra") or ""):
            allow_no_cart = True
    except Exception:
        pass

if has_catalog and not has_cart and not allow_no_cart:
    add("cart_missing", "Sepet/sipariş eksik",
        "Katalog/ürün sinyali var; orders/sepet yok — e-ticarette olmazsa olmaz",
        "blocker", "gap-scan")
if has_catalog and not has_pay:
    add("payment_missing", "Ödeme akışı belirsiz",
        "E-ticaret/katalog var; kart/kapıda/havale kararı veya entegrasyon yok",
        "warn", "gap-scan")
if has_catalog and not has_review:
    add("reviews_missing", "Ürün yorum/oylama yok",
        "Ürün sayfası muhtemel; son kullanıcı yorum/rating alanı önerilir",
        "warn", "gap-scan")
if has_users and not has_rbac:
    add("rbac_missing", "RBAC eksik",
        "users var/planlı ama role_id/roles yok",
        "blocker", "gap-scan")
if (p / "index.php").is_file() and not has_seo:
    add("seo_missing", "SEO artefaktları eksik",
        "robots.txt / sitemap.xml yok",
        "warn", "gap-scan")
if (p / "index.php").is_file() and not has_kvkk:
    add("kvkk_missing", "KVKK/çerez aydınlatma zayıf",
        "Canlı site iskeleti var; aydınlatma/çerez view önerilir",
        "warn", "gap-scan")

conscious = "hariç" in intent and ("sepet" in intent or "ödeme" in intent or "odeme" in intent)

report = {
    "schema_version": 1,
    "tool": "gap-scan",
    "project": str(p),
    "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "findings": findings,
    "blocker_count": sum(1 for f in findings if f["severity"] == "blocker"),
    "warn_count": sum(1 for f in findings if f["severity"] == "warn"),
    "conscious_exclusions_hint": conscious,
}
out = p / "gap-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(fac / "gap-report.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")

print(f"==> gap-scan · {p.name} · blocker={report['blocker_count']} warn={report['warn_count']}")
for f in findings:
    tag = f["severity"].upper()
    print(f"    [{tag}] {f['id']}: {f['title']} — {f['detail']}")
if not findings:
    print("    (boşluk yok)")
print(f"    rapor: {out}")
PY
