#!/usr/bin/env bash
set -euo pipefail

# Webrail — QA FAIL sınıflandırma + imza (Adaptive Recovery girdisi)
# Kullanım: bash scripts/web/classify-fail.sh <proje>
# Okur: qa-report.json · Yazar: failure-report.json + .factory/failure-log.jsonl
# Exit: 0 her zaman (rapor); qa yoksa 1

PROJECT="${1:-.}"
[[ -d "$PROJECT" ]] || { echo "classify-fail: dizin yok" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
[[ -f "$PROJECT/qa-report.json" ]] || { echo "classify-fail: qa-report.json yok" >&2; exit 1; }

export _CF_PROJECT="$PROJECT"
python3 - <<'PY'
import hashlib, json, os, re
from datetime import datetime, timezone
from pathlib import Path

p = Path(os.environ["_CF_PROJECT"])
fac = p / ".factory"
fac.mkdir(parents=True, exist_ok=True)
qa = json.loads((p / "qa-report.json").read_text(encoding="utf-8"))
errors = list(qa.get("errors") or [])
warnings = list(qa.get("warnings") or [])

def classify_one(msg: str) -> str:
    m = msg.lower()
    if any(k in m for k in ("phpstan yapılandırması", "phpunit yapılandırması", "eslint", "komut bulunamadı", "tool", "binary")):
        return "infra"
    if any(k in m for k in ("eksik modül", "role_id", "sepet", "sipariş", "kvkk:", "user_consents", "anonymization")):
        return "missing_req"
    if any(k in m for k in ("whitelist", "allowlist", "manifest", "context", "okuma", "read:")):
        return "bad_context"
    if any(k in m for k in ("csrf", "htmlspecialchars", "password_", "prepared", "mysql_", "session_set_cookie", "syntax", "php_lint", "pdo")):
        return "code"
    if any(k in m for k in ("iskelet", "index.php eksik", "core/ dizini", "hollow", "boş")):
        return "model"
    return "code"

classes = [{"class": classify_one(e), "error": e} for e in errors]
# birincil: missing_req > infra > bad_context > model > code (öncelik onarım yolu)
prio = {"missing_req": 0, "infra": 1, "bad_context": 2, "model": 3, "code": 4}
primary = "code"
if classes:
    primary = sorted((c["class"] for c in classes), key=lambda x: prio.get(x, 9))[0]

# imza: kanallar + normalize hata başlıkları
norm = []
for e in errors:
    # dosya:satır kırp
    t = re.sub(r':\d+', '', e)
    t = re.sub(r'/[^\s]+', '', t)
    t = re.sub(r'\s+', ' ', t).strip().lower()[:120]
    norm.append(t)
sig_src = "|".join(sorted(set(norm))) or "empty"
signature = hashlib.sha256(sig_src.encode()).hexdigest()[:16]

# geçmiş
log_path = fac / "failure-log.jsonl"
prior = []
if log_path.is_file():
    for line in log_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            prior.append(json.loads(line))
        except Exception:
            pass
same = [x for x in prior if x.get("signature") == signature]
prior_strategies = [x.get("strategy") for x in same if x.get("strategy")]
repeat_count = len(same)

# strateji
def pick_strategy() -> tuple[str, str]:
    used = set(prior_strategies)
    if primary == "infra":
        if "doctor_loop" not in used:
            return "doctor_loop", "altyapı/config — safe doctor loop"
        return "halt_infra", "infra tekrarladı — üretimi durdur, aracı düzelt"
    if primary == "missing_req":
        if "module_apply" not in used:
            return "module_apply", "eksik modül — module-apply / PLAN enjekte"
        if "fix_brief_p4" not in used:
            return "fix_brief_p4", "modül sonrası kalan — FIX-BRIEF P4"
        return "expand_context", "gereksinim belirsiz — bağlam/PLAN genişlet"
    if primary == "bad_context":
        return "expand_context", "bağlam/allowlist — context genişlet, kör yeniden yazma yok"
    if primary == "model":
        if "alt_model" not in used and repeat_count >= 1:
            return "alt_model", "iskelet/model çıktısı zayıf — alternatif model"
        if repeat_count >= 2:
            multi = os.environ.get("WEBRAIL_MULTI_CANDIDATE", "0") == "1"
            if multi:
                return "multi_candidate", "tekrarlayan model fail — kontrollü 2–3 aday"
            return "expand_context", "multi_candidate kapalı — hybrid/P2_HUMAN_ASSIST öner"
        return "fix_brief_p4", "ilk model fail — dar FIX-BRIEF"
    # code
    if "doctor_loop" not in used and any(
        classify_one(e) == "code" and any(k in e.lower() for k in ("phpstan", "phpunit", "fixture"))
        for e in errors
    ):
        return "doctor_loop", "güvenli code/config — doctor loop"
    if repeat_count == 0:
        return "fix_brief_p4", "kod hatası — P4 FIX-BRIEF (aynı promptu tekrarla)"
    if "alt_model" not in used:
        return "alt_model", "aynı imza tekrar — alternatif model/strateji"
    multi = os.environ.get("WEBRAIL_MULTI_CANDIDATE", "0") == "1"
    if multi and "multi_candidate" not in used:
        return "multi_candidate", "tekrarlayan code fail — aday üretimi"
    return "fix_brief_p4", "varsayılan P4 — yeni yaklaşım FIX-BRIEF'te belirtilmeli"

strategy, reason = pick_strategy()
# aynı stratejiyi ardışık tekrarlama
if prior_strategies and prior_strategies[-1] == strategy and strategy not in ("halt_infra",):
    # bir üst basamak
    ladder = ["doctor_loop", "fix_brief_p4", "module_apply", "expand_context", "alt_model", "multi_candidate", "halt_infra"]
    try:
        i = ladder.index(strategy)
        for nxt in ladder[i + 1 :]:
            if nxt == "multi_candidate" and os.environ.get("WEBRAIL_MULTI_CANDIDATE", "0") != "1":
                continue
            if nxt not in used or nxt == "halt_infra":
                strategy, reason = nxt, f"önceki strateji tekrarlanmasın → {nxt}"
                break
    except ValueError:
        pass

at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
report = {
    "schema_version": 1,
    "tool": "classify-fail",
    "project": str(p),
    "at": at,
    "qa_result": qa.get("result"),
    "signature": signature,
    "primary_class": primary,
    "classes": classes,
    "error_count": len(errors),
    "warning_count": len(warnings),
    "strategy": strategy,
    "strategy_reason": reason,
    "repeat_count": repeat_count,
    "prior_strategies": prior_strategies,
    "multi_candidate_enabled": os.environ.get("WEBRAIL_MULTI_CANDIDATE", "0") == "1",
}
out = p / "failure-report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(fac / "failure-report.json").write_text(out.read_text(encoding="utf-8"), encoding="utf-8")

# append log (strateji denemesi orchestrate/adaptive sonra da yazılabilir; burada sınıflandırma kaydı)
entry = {
    "at": at,
    "signature": signature,
    "primary_class": primary,
    "strategy": strategy,
    "error_count": len(errors),
}
with log_path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(entry, ensure_ascii=False) + "\n")

print(f"==> classify-fail · {p.name} · class={primary} · sig={signature} · strategy={strategy} · repeat={repeat_count}")
print(f"    {reason}")
print(f"    rapor: {out}")
PY
