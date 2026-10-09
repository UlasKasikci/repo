#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika — frontmatter kontrat doğrulayıcı (qa-gate 14. kontrol / self-test 0).
# Gerekçe (K6 istisnası — somut bug): K1-K8 ref satırı frontmatter'ın ÜSTÜNE eklenince
# opencode mode/permission parse'ı sessiz kırıldı (14 dosya; A/B kanıtı: qa-gatekeeper
# permission.edit=deny kaybı). Kural eklemek kontratı bozmasın diye bu doğrulayıcı
# her qa-gate koşusunda ve self-test step 0'da fabrikanın kendi dosyalarını tarar.
#
# Kullanım: bash scripts/web/frontmatter-check.sh [kök_dizin]
#   varsayılan kök: repo kökü (betiğin ../.. dizini)
# Tarama: <kök> altındaki tüm *.md / *.mdc (hariç: .git node_modules vendor
#   Yukleme .factory snapshots, AppleDouble ._*)
# Kurallar:
#   - config dizinleri (.opencode/agent, .cursor/agents, .cursor/rules,
#     .cursor/skills, .opencode/skills) → frontmatter ZORUNLU, 1. satırda
#   - frontmatter YAML olarak okunabilir olmalı (stdlib alt küme parser)
#   - K1-K8 ref satırı body'de olmalı, frontmatter İÇİNDE olmamalı
#   - .opencode/agent: mode ∈ {primary, subagent}; qa-gatekeeper permission.edit=deny
#   - .cursor/agents: name == dosya adı; qa-gatekeeper readonly=true
#   - .mdc: description zorunlu; alwaysApply false ise globs zorunlu (dead-rule koruması)
#   - SKILL.md: name == dizin adı + ^[a-z0-9]+(-[a-z0-9]+)*$ ; description 1-1024
#   - kırık imza (ref 1. satırda / --- 2. satırda) → her dosyada FAIL
# Exit: 0 = geçerli · 1 = ihlal var

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
python3 - "$ROOT" <<'PY'
import os
import re
import sys

root = os.path.abspath(sys.argv[1])
SKIP_DIRS = {".git", "node_modules", "vendor", "Yukleme", ".factory", "snapshots"}
REF_MARK = "MASTER-PROMPT-V2.md"
SKILL_NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:[ \t]+(.*))?$")

errors = []
scanned = 0


# --- minimal YAML alt kümesi (stdlib; çapraz doğrulama: pyyaml) ---
# destek: skaler, true/false, flow liste ["a","b"] (quote-aware virgül),
# iç içe map, blok skalar (>- / |), yorum/boş satır yok sayılır.

def scalar(tok):
    t = tok.strip()
    if len(t) >= 2 and t[0] == t[-1] and t[0] in "\"'":
        return t[1:-1]
    if t in ("true", "True"):
        return True
    if t in ("false", "False"):
        return False
    if t in ("null", "~"):
        return None
    if re.match(r"^-?\d+$", t):
        try:
            return int(t)
        except ValueError:
            pass
    elif re.match(r"^-?\d+\.\d+$", t):
        try:
            return float(t)
        except ValueError:
            pass
    return t


def flow_list(text):
    inner = text[1:-1].strip()
    if not inner:
        return []
    items, cur, in_quote = [], "", None
    for ch in inner:
        if in_quote:
            cur += ch
            if ch == in_quote:
                in_quote = None
        elif ch in "\"'":
            in_quote = ch
            cur += ch
        elif ch == ",":
            items.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        items.append(cur.strip())
    return [scalar(i) for i in items]


def parse_yaml(raw_lines):
    lines = []
    for ln in raw_lines:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        lines.append((len(ln) - len(ln.lstrip(" ")), ln.strip()))
    if not lines:
        return None
    return _parse_map(lines, lines[0][0])


def _parse_map(lines, indent):
    result = {}
    i = 0
    while i < len(lines):
        ind, content = lines[i]
        if ind < indent:
            break
        if ind > indent:  # kaçık girinti — atla
            i += 1
            continue
        if content.startswith("- "):
            break
        m = KEY_RE.match(content)
        if not m:
            i += 1
            continue
        key, rest = m.group(1), m.group(2)
        if rest is None or rest == "":
            j = i + 1
            sub = []
            while j < len(lines) and lines[j][0] > ind:
                sub.append(lines[j])
                j += 1
            if not sub:
                result[key] = None
            elif sub[0][1].startswith("- "):
                result[key] = [scalar(c[2:]) for _, c in sub]
            elif sub[0][1].split()[0] in (">", ">-", ">|", "|", "|-", "|+"):
                marker = sub[0][1].split()[0]
                parts = [c for _, c in sub[1:]]
                result[key] = (" " if marker.startswith(">") else "\n").join(parts).strip()
            else:
                result[key] = _parse_map(sub, sub[0][0])
            i = j
        elif rest.split()[0] in (">", ">-", ">|", "|", "|-", "|+"):
            marker = rest.split()[0]
            j = i + 1
            parts = []
            while j < len(lines) and lines[j][0] > ind:
                parts.append(lines[j][1])
                j += 1
            result[key] = (" " if marker.startswith(">") else "\n").join(parts).strip()
            i = j
        elif rest.startswith("["):
            result[key] = flow_list(rest)
            i += 1
        else:
            result[key] = scalar(rest)
            i += 1
    return result


def classify(relpath):
    if relpath.startswith(".opencode/agent/"):
        return "oc_agent"
    if relpath.startswith(".cursor/agents/"):
        return "cur_agent"
    if relpath.startswith(".cursor/rules/") or relpath.endswith(".mdc"):
        return "mdc"
    if relpath.endswith("SKILL.md"):
        return "skill"
    return "generic"


def find_block(lines):
    if not lines or lines[0].strip() != "---":
        return None, None
    for idx in range(1, min(len(lines), 500)):
        if lines[idx].strip() == "---":
            return lines[1:idx], idx
    return "UNCLOSED", None


def nonempty(v):
    return isinstance(v, str) and bool(v.strip())


def validate_fields(rp, kind, fm, body_lines):
    stem = os.path.splitext(os.path.basename(rp))[0]
    if kind == "oc_agent":
        if not nonempty(fm.get("description")):
            errors.append(f"{rp}: description eksik")
        if fm.get("mode") not in ("primary", "subagent"):
            errors.append(f"{rp}: mode biri olmalı [primary|subagent] (gelen: {fm.get('mode')!r})")
        if stem == "web-qa-gatekeeper":
            perm = fm.get("permission")
            if not isinstance(perm, dict) or perm.get("edit") != "deny":
                errors.append(f"{rp}: gatekeeper permission.edit=deny zorunlu (K1 readonly kanıtı)")
        if not any(REF_MARK in ln for ln in body_lines):
            errors.append(f"{rp}: body'de K1-K8 ref satırı yok ({REF_MARK})")
    elif kind == "cur_agent":
        if fm.get("name") != stem:
            errors.append(f"{rp}: name == dosya adı olmalı (gelen: {fm.get('name')!r})")
        if not nonempty(fm.get("description")):
            errors.append(f"{rp}: description eksik")
        if stem == "web-qa-gatekeeper" and fm.get("readonly") is not True:
            errors.append(f"{rp}: gatekeeper readonly=true zorunlu")
        if not any(REF_MARK in ln for ln in body_lines):
            errors.append(f"{rp}: body'de K1-K8 ref satırı yok ({REF_MARK})")
    elif kind == "mdc":
        if not nonempty(fm.get("description")):
            errors.append(f"{rp}: description eksik")
        aa = fm.get("alwaysApply", None)
        if aa is not None and not isinstance(aa, bool):
            errors.append(f"{rp}: alwaysApply bool olmalı (gelen: {aa!r})")
        globs = fm.get("globs")
        if globs is not None and not isinstance(globs, list):
            errors.append(f"{rp}: globs liste olmalı (gelen: {globs!r})")
        if aa is False and not (isinstance(globs, list) and globs):
            errors.append(
                f"{rp}: alwaysApply=false ama globs boş/yok — kural asla uygulanmaz (dead rule)"
            )
        if aa is True and globs:
            errors.append(f"{rp}: alwaysApply=true ile globs birlikte anlamsız — globs'u kaldır")
    elif kind == "skill":
        dirname = os.path.basename(os.path.dirname(rp))
        name = fm.get("name")
        if name != dirname:
            errors.append(f"{rp}: name == dizin adı olmalı (dizin: {dirname}, name: {name!r})")
        if not isinstance(name, str) or not SKILL_NAME_RE.match(name or ""):
            errors.append(f"{rp}: name deseni ^[a-z0-9]+(-[a-z0-9]+)*$ (gelen: {name!r})")
        desc = fm.get("description")
        if not nonempty(desc):
            errors.append(f"{rp}: description eksik")
        elif len(desc) > 1024:
            errors.append(f"{rp}: description 1024 karakteri aşıyor ({len(desc)})")


def validate(path):
    global scanned
    rp = os.path.relpath(path, root).replace(os.sep, "/")
    scanned += 1
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except UnicodeDecodeError:
        errors.append(f"{rp}: UTF-8 değil")
        return
    kind = classify(rp)
    cfg = kind != "generic"

    # kırık imza — her dosyada FAIL (A/B kanıtı: regresyon kalıbı).
    # NOT: ref 1. satır + hemen ardından --- Veya ilk 10 satırda --- olan dosya
    # regresyon desenidir. CLAUDE.md gibi frontmattersız bilinçli üst-satır ref'i
    # (--- yakınında değil) serbesttir.
    if (
        lines
        and lines[0].strip().startswith(">")
        and REF_MARK in lines[0]
        and any(lines[i].strip() == "---" for i in range(1, min(len(lines), 10)))
    ):
        errors.append(f"{rp}: K1-K8 ref satırı 1. satırda — frontmatter üstünde, parse kırılır")
        return
    if len(lines) > 1 and lines[0].strip() != "---" and lines[1].strip() == "---":
        errors.append(f"{rp}: frontmatter 1. satırda değil (--- ikinci satırda)")
        return

    block, close = find_block(lines)
    if lines and lines[0].strip() == "---":
        if block == "UNCLOSED":
            errors.append(f"{rp}: frontmatter kapanış --- yok")
            return
        if any(REF_MARK in b for b in block):
            errors.append(f"{rp}: K1-K8 ref satırı frontmatter İÇİNDE — body'ye taşı")
            return
        try:
            fm = parse_yaml(block)
        except Exception as exc:  # noqa: BLE001 — parser hattı hepsi ihlal
            errors.append(f"{rp}: frontmatter okunamadı ({exc})")
            return
        if not isinstance(fm, dict) or not fm:
            if cfg:
                errors.append(f"{rp}: frontmatter boş/şema değil")
                return
            return  # düz markdown hr başlangıcı olabilir
        if cfg:
            validate_fields(rp, kind, fm, lines[close + 1:])
        return
    if cfg:
        errors.append(f"{rp}: frontmatter yok (--- ile başlamalı)")
        return
    # generic + frontmatter'sız: kırık imza taraması zaten geçti → temiz


for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
    for fn in sorted(filenames):
        if fn.startswith("._"):
            continue
        if fn.endswith(".md") or fn.endswith(".mdc"):
            validate(os.path.join(dirpath, fn))

if errors:
    for e in errors:
        print(e)
    print(f"frontmatter-check: {len(errors)} ihlal / {scanned} dosya tarandı")
    sys.exit(1)
print(f"OK: {scanned} dosya frontmatter kontratı geçerli")
PY
