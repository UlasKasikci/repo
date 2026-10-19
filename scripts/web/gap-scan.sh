#!/usr/bin/env bash
set -euo pipefail

# Webrail — proaktif boşluk taraması (arketip-duyarlı)
# Kullanım: bash scripts/web/gap-scan.sh <proje>
# Exit: 0 her zaman (rapor); blocker varsa denetle FAIL edebilir
# İlke: docs/PROJECT-ARCHETYPES.md — her siteye sepet/ödeme zorlanmaz

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

def strip_warn_section(t: str) -> str:
    for mark in ("## Proaktif uyarılar", "## Oturum kayıtları"):
        if mark in t:
            t = t.split(mark)[0]
    return t

def extract_section(md: str, header: str) -> str:
    """Şablon tablo etiketleri (ör. '| sepet |') arketipi kirletmesin — yalnız iş özeti."""
    if header not in md:
        return ""
    rest = md.split(header, 1)[1]
    nxt = re.search(r'\n## \d+\.', rest)
    return rest[: nxt.start()] if nxt else rest

def plan_brief_only(plan: str) -> str:
    """Yalnız Proje + Brief satırları — checklist'teki 'sepet/ödeme' false-positive olmasın."""
    parts = []
    lines = plan.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("**Proje:**"):
            parts.append(line.split(":**", 1)[-1].strip())
        elif line.startswith("**Brief"):
            parts.append(line.split(":**", 1)[-1].strip())
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt.startswith("**") or nxt.startswith("#") or nxt.startswith("---"):
                    break
                if nxt.strip():
                    parts.append(nxt.strip())
                i += 1
            continue
        i += 1
    return "\n".join(parts)

# Brief / iş özeti odaklı (şablon etiketleri false-positive olmasın)
intent_blob = (
    extract_section(disc_raw, "## 1. İş özeti")
    + "\n" + extract_section(disc_raw, "## 2. Kapsam")
    + "\n" + plan_brief_only(plan_raw)
).lower()
sql = read(p / "SQL" / "veritabani.sql")
sql_l = sql.lower()
views = " ".join(f.name for f in (p / "views").rglob("*.php")) if (p / "views").is_dir() else ""
views_l = views.lower()
php_blob = ""
for f in list((p / "core").rglob("*.php"))[:40] if (p / "core").is_dir() else []:
    php_blob += read(f)[:2000]
php_l = php_blob.lower()

# project-intent override
intent_doc = {}
pi = fac / "project-intent.json"
if pi.is_file():
    try:
        intent_doc = json.loads(pi.read_text(encoding="utf-8"))
    except Exception:
        intent_doc = {}

def module_yes(blob: str, *keys: str) -> bool:
    for line in blob.splitlines():
        if "|" not in line or "evet" not in line.lower():
            continue
        low = line.lower()
        if any(k in low for k in keys):
            return True
    return False

def any_kw(blob: str, keys) -> bool:
    return any(k in blob for k in keys)

# --- sinyal ---
ecommerce_kw = (
    "e-ticaret", "eticaret", "e commerce", "ecommerce", "sepet", "satın al", "satin al",
    "checkout", "shop", "mağaza", "magaza", "ödeme al", "odeme al", "iyzico", "paytr",
    "stripe", "woocommerce", "sipariş ver", "siparis ver",
)
rfq_kw = ("teklif", "rfq", "sipariş talebi", "siparis talebi", "teklif formu")
showcase_kw = (
    "tanıtım", "tanitim", "vitrin", "portfolio", "portföy", "portfoy",
    "ürün tanıtım", "urun tanitim", "katalog sitesi", "showcase", "ürün vitrin",
)
onepage_kw = ("onepage", "one-page", "tek sayfa", "landing", "coming soon", "cv sitesi")
webapp_kw = ("admin panel", "yönetim paneli", "yonetim paneli", "saas", "dashboard", "üye alanı", "uye alani")
auth_kw = ("login", "kayıt", "kayit", "üye", "uye", "kullanıcı", "kullanici", "auth", "rbac")

explicit_type = (intent_doc.get("project_type") or intent_doc.get("archetype") or "").strip().lower()

has_product_tables = bool(re.search(r'create table.*(products|urunler|katalog|items)', sql_l, re.I))
has_product_copy = any_kw(intent_blob, ("ürün", "urun", "katalog", "hizmet listesi"))
has_cart = bool(re.search(r'create table.*(orders|siparis|sepet|cart)', sql_l, re.I)) \
    or module_yes(disc_raw, "sepet", "sipariş", "siparis", "cart", "order") \
    or any_kw(views_l, ("sepet", "cart", "checkout"))
has_pay = bool(re.search(r'create table.*(payments|odemeler|transactions)', sql_l, re.I)) \
    or any_kw(php_l, ("iyzico", "stripe", "paytr", "payment")) \
    or module_yes(disc_raw, "ödeme", "odeme", "payment", "kart")
has_review = bool(re.search(r'create table.*(reviews|yorum|ratings)', sql_l, re.I)) \
    or any_kw(views_l, ("review", "yorum", "rating", "oylama")) \
    or module_yes(disc_raw, "yorum", "oylama", "review", "rating")
has_notify = bool(re.search(r'create table.*(bildirimler|notifications)', sql_l, re.I)) \
    or module_yes(disc_raw, "bildirim", "notification", "notifications") \
    or any_kw(php_l, ("notification", "bildirim"))
has_rbac = "role_id" in sql_l or bool(re.search(r'create table.*roles', sql_l, re.I)) \
    or module_yes(disc_raw, "rbac", "auth / rbac", "rol")
has_users = bool(re.search(r'create table.*`?users`?', sql_l, re.I)) \
    or any_kw(intent_blob, auth_kw) or module_yes(disc_raw, "auth", "rbac", "kullanıcı")
has_kvkk = module_yes(disc_raw, "kvkk", "gdpr") or "kvkk" in intent_blob or "gdpr" in intent_blob
if (p / "views").is_dir():
    for vf in (p / "views").rglob("*.php"):
        n = vf.name.lower()
        if any(x in n for x in ("kvkk", "cerez", "cookie", "aydinlat", "privacy")):
            has_kvkk = True
            break
has_seo = (p / "robots.txt").is_file() and (p / "sitemap.xml").is_file()

# --- arketip ---
valid = {"onepage", "brochure", "showcase", "catalog_rfq", "ecommerce", "webapp"}
want_cart_module = module_yes(disc_raw, "sepet", "sipariş", "siparis", "cart")
if explicit_type in valid:
    archetype = explicit_type
elif any_kw(intent_blob, ecommerce_kw) or has_cart or want_cart_module:
    # satış fiili / orders tablosu / DISCOVERY'de sepet=evet → mağaza
    archetype = "ecommerce"
elif any_kw(intent_blob, rfq_kw) or module_yes(disc_raw, "teklif", "rfq"):
    archetype = "catalog_rfq"
elif any_kw(intent_blob, onepage_kw):
    # landing/tek sayfa — "ürün lansmanı" kelimesi vitrin zorlamasın
    archetype = "onepage"
elif any_kw(intent_blob, showcase_kw) or (
    (has_product_tables or has_product_copy) and not any_kw(intent_blob, ecommerce_kw)
    and not want_cart_module
):
    # ürün içeriği var ama sepet/satış fiili yok → vitrin
    archetype = "showcase"
elif any_kw(intent_blob, webapp_kw) or (has_users and any_kw(intent_blob, ("admin", "panel", "crud"))):
    archetype = "webapp"
else:
    archetype = "brochure"

findings = []

def add(fid, title, detail, severity, source="gap-scan"):
    findings.append({
        "id": fid, "title": title, "detail": detail,
        "severity": severity, "source": source, "archetype": archetype,
    })

allow_no_cart = "--allow-no-cart" in (os.environ.get("QA_GATE_EXTRA") or "")
dec = fac / "decision.json"
if dec.is_file():
    try:
        d = json.loads(dec.read_text(encoding="utf-8"))
        if "--allow-no-cart" in str(d.get("qa_gate_extra") or ""):
            allow_no_cart = True
    except Exception:
        pass

# Arketipe göre kurallar
if archetype == "ecommerce":
    if not has_cart and not allow_no_cart:
        add("cart_missing", "Sepet/sipariş eksik",
            "Arketip=ecommerce; orders/sepet yok", "blocker")
    if not has_pay:
        add("payment_missing", "Ödeme akışı belirsiz",
            "E-ticaret: kart/kapıda/havale kararı veya entegrasyon yok", "warn")
    if not has_review:
        add("reviews_missing", "Ürün yorum/oylama yok",
            "Mağaza ürün sayfası için yorum/rating önerilir (zorunlu değil)", "warn")
    if not has_notify:
        add("notifications_missing", "Bildirim stub yok",
            "Sipariş/ödeme durumu için bildirimler tablosu önerilir", "warn")
elif archetype == "webapp":
    if not has_notify and any_kw(intent_blob, ("bildirim", "notification", "alert", "uyarı", "uyari")):
        add("notifications_missing", "Bildirim stub yok",
            "Brief’te bildirim sinyali var; bildirimler tablosu önerilir", "warn")
elif archetype == "catalog_rfq":
    if not has_cart and not module_yes(disc_raw, "teklif") and not any_kw(intent_blob, rfq_kw):
        add("rfq_missing", "Teklif/sipariş talebi belirsiz",
            "Katalog+RFQ arketipi; teklif formu veya sipariş talebi planlanmalı", "warn")
elif archetype == "showcase":
    # Bilinçli: sepet/ödeme/yorum zorlanmaz — bilgi satırı raporda
    add("archetype_note", "Vitrin/tanıtım arketipi",
        "Ürün içeriği olabilir; sepet/ödeme/yorum varsayılan zorunlu değil", "info")
elif archetype == "onepage":
    add("archetype_note", "One-page arketipi",
        "Tek sayfa: sepet/RBAC/ödeme zorlanmaz", "info")

# Auth → RBAC (arketipten bağımsız; üyelik varsa)
if has_users and not has_rbac and archetype in ("ecommerce", "webapp", "catalog_rfq"):
    add("rbac_missing", "RBAC eksik",
        "Kullanıcı/üyelik sinyali var; role_id/roles yok", "blocker")
elif has_users and not has_rbac and archetype not in ("onepage",):
    add("rbac_missing", "RBAC eksik",
        "Kullanıcı planlı; rol katmanı önerilir", "warn")

# SEO / KVKK — canlı iskelet (yumuşak)
if (p / "index.php").is_file() and not has_seo:
    add("seo_missing", "SEO artefaktları eksik",
        "robots.txt / sitemap.xml yok", "warn")
if (p / "index.php").is_file() and not has_kvkk and archetype != "onepage":
    add("kvkk_missing", "KVKK/çerez aydınlatma zayıf",
        "Canlı site; aydınlatma/çerez view önerilir (TR)", "warn")

conscious = "hariç" in intent_blob and any_kw(intent_blob, ("sepet", "ödeme", "odeme", "yorum"))

report = {
    "schema_version": 1,
    "tool": "gap-scan",
    "project": str(p),
    "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "archetype": archetype,
    "project_type_source": "project-intent" if explicit_type in valid else "inferred",
    "findings": findings,
    "blocker_count": sum(1 for f in findings if f["severity"] == "blocker"),
    "warn_count": sum(1 for f in findings if f["severity"] == "warn"),
    "info_count": sum(1 for f in findings if f["severity"] == "info"),
    "conscious_exclusions_hint": conscious,
}
out = p / "gap-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(fac / "gap-report.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")

print(f"==> gap-scan · {p.name} · archetype={archetype} · blocker={report['blocker_count']} warn={report['warn_count']}")
for f in findings:
    print(f"    [{f['severity'].upper()}] {f['id']}: {f['title']} — {f['detail']}")
if not findings:
    print("    (boşluk yok)")
print(f"    rapor: {out}")
PY
