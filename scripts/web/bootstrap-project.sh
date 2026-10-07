#!/usr/bin/env bash
set -euo pipefail

# App-Fabrika Web Edition — temiz bootstrap: fabrika iskeletini yeni projeye kopyalar
#
# Kullanım:
#   bash scripts/web/bootstrap-project.sh <hedef_dizini> [--yes] [--force]
#
#   (bayrak yok)  → DRY-RUN: kopyalanacak/kalmayacak listesi + sayı, hedefe DOKUNMAZ
#   --yes         → kopyalamayı gerçekten yap + git init + ilk commit
#   --force       → hedef boş DEĞİLSE bile yaz (var olan dosyalar ezilir, fazladan durur)
#
# KOPYALANIR (karar listesi — kod bunu uygular):
#   scripts/web/* (self-test.sh ve bu betik hariç), .factory/{contracts,meta.json,
#   web-state-graph.json, web-state.example.json, project-intent.example.json},
#   .cursor/{rules,agents,commands,mcp.json.example,mcp.required.json},
#   .opencode/{agent,command}, docs/**, CLAUDE.md, .cursorrules, antigravity.yaml,
#   opencode.json, .gitignore
# KOPYALANMAZ:
#   tests/ (fabrika fixture), .github/ (fabrika CI), scripts/web/{self-test,bootstrap-project}.sh,
#   .factory/{context,freeze.json} + runtime (web-state.json, domain-report.json,
#   lighthouse-report.json, qa/debug/packaging-report.json), .cursor/{skills,snapshots,mcp.json},
#   .opencode/{plans,node_modules,package*.json}, .git/, node_modules/, Yukleme/, ._*, .DS_Store
#
# Git izi: hedefte taze `git init`; ilk commit
#   "bootstrap from app-fabrika@<12-hex>"  (fabrika deposunun HEAD'i — sürüm izlenebilirliği)

PROJECT="${1:-}"
shift || true
YES=0
FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)   YES=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help)
      sed -n '4,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "bootstrap: bilinmeyen argüman: $1" >&2
      exit 1
      ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "kullanım: bootstrap-project.sh <hedef_dizini> [--yes] [--force]" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "bootstrap: python3 gerekli" >&2; exit 1; }

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GIT_HASH="bilinmiyor"
if [[ -d "$SOURCE/.git" ]] && command -v git >/dev/null 2>&1; then
  GIT_HASH="$(git -C "$SOURCE" rev-parse --short=12 HEAD 2>/dev/null || echo bilinmiyor)"
fi

# hedef denetimi (dry-run bile varoluşu raporlar)
if [[ -e "$PROJECT" && ! -d "$PROJECT" ]]; then
  echo "bootstrap: hedef bir dosya: $PROJECT" >&2
  exit 1
fi
if [[ -d "$PROJECT" && -n "$(ls -A "$PROJECT" 2>/dev/null)" && "$FORCE" -ne 1 ]]; then
  echo "bootstrap: hedef boş değil: $PROJECT (ezmek için --force)" >&2
  exit 1
fi

MODE="dry-run"
if [[ "$YES" -eq 1 ]]; then MODE="write"; fi

python3 - "$SOURCE" "${PROJECT%/}" "$MODE" "$GIT_HASH" <<'PY'
import fnmatch
import os
import shutil
import sys

source, target, mode, git_hash = sys.argv[1:5]

COPY_ROOTS = [
    "scripts/web",
    ".factory",
    ".cursor",
    ".opencode",
    "docs",
]
COPY_FILES = [
    "CLAUDE.md",
    ".cursorrules",
    "antigravity.yaml",
    "opencode.json",
    ".gitignore",
]

PRUNE_DIRS = {".git", "node_modules", "Yukleme", "__pycache__", ".DS_Store"}
PRUNE_REL_DIRS = {
    os.path.join(".factory", "context"),
    ".cursor/skills",
    ".cursor/snapshots",
    ".opencode/plans",
    ".github",
    "tests",
}
PRUNE_FILES = {
    "._*",
    ".DS_Store",
    "self-test.sh",
    "bootstrap-project.sh",
    "mcp.json",
    "package.json",
    "package-lock.json",
    "freeze.json",
    "web-state.json",
    "domain-report.json",
    "lighthouse-report.json",
    "qa-report.json",
    "debug_report.json",
    "packaging-report.json",
}


def pruned_file(rel):
    base = os.path.basename(rel)
    return any(fnmatch.fnmatch(base, pat) for pat in PRUNE_FILES)


def collect():
    files = []
    for root_rel in COPY_ROOTS:
        root_abs = os.path.join(source, root_rel)
        if not os.path.isdir(root_abs):
            continue
        for dirpath, dirnames, filenames in os.walk(root_abs):
            rel_dir = os.path.relpath(dirpath, source)
            dirnames[:] = [
                d for d in dirnames
                if d not in PRUNE_DIRS
                and os.path.join(rel_dir, d).replace(os.sep, "/") not in PRUNE_REL_DIRS
                and not fnmatch.fnmatch(d, "._*")
            ]
            for name in sorted(filenames):
                rel = os.path.join(rel_dir, name)
                rel_posix = rel.replace(os.sep, "/")
                if pruned_file(rel):
                    continue
                files.append(rel_posix)
    for rel in COPY_FILES:
        if os.path.isfile(os.path.join(source, rel)):
            files.append(rel)
    return sorted(set(files))


files = collect()
total = sum(os.path.getsize(os.path.join(source, f)) for f in files)

EXCLUDED_NOTE = (
    "hariç: tests/, .github/, scripts/web/{self-test,bootstrap-project}.sh, "
    ".factory/{context,freeze.json,runtime raporlar}, .cursor/{skills,snapshots,mcp.json}, "
    ".opencode/{plans,node_modules,package*.json}, .git/, node_modules/, Yukleme/, ._*, .DS_Store"
)

if mode == "dry-run":
    print(f"DRY-RUN bootstrap @ {git_hash}")
    print(f"  kaynak:  {source}")
    print(f"  hedef:   {target}")
    print(f"  kopyalanacak: {len(files)} dosya ({total} bayt)")
    for rel in files[:8]:
        print(f"    - {rel}")
    if len(files) > 8:
        print(f"    ... ve {len(files) - 8} dosya daha")
    print(f"  {EXCLUDED_NOTE}")
    print("  yazmak için: --yes (hedef boş değilse ayrıca --force)")
    sys.exit(0)

os.makedirs(target, exist_ok=True)
for rel in files:
    src = os.path.join(source, rel)
    dst = os.path.join(target, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)

print(f"BOOTSTRAP @ {git_hash}: {len(files)} dosya ({total} bayt) → {target}")
print(f"  {EXCLUDED_NOTE}")
PY

[[ "$MODE" == "write" ]] || exit 0

# --- git izi: taze depo + sürüm bağlayıcı ilk commit ---
if command -v git >/dev/null 2>&1; then
  git -C "$PROJECT" init -q 2>/dev/null || true
  git -C "$PROJECT" config user.name >/dev/null 2>&1 \
    || git -C "$PROJECT" config user.name "App-Fabrika Bootstrap"
  git -C "$PROJECT" config user.email >/dev/null 2>&1 \
    || git -C "$PROJECT" config user.email "bootstrap@app-fabrika.local"
  git -C "$PROJECT" add -A
  if git -C "$PROJECT" diff --cached --quiet 2>/dev/null; then
    echo "  git: içerik aynı — commit atlanmadı (mevcut iz korundu)"
  else
    git -C "$PROJECT" commit -qm "bootstrap from app-fabrika@${GIT_HASH}"
    git -C "$PROJECT" branch -M main 2>/dev/null || true
    echo "  git: ilk commit 'bootstrap from app-fabrika@${GIT_HASH}' (main)"
  fi
else
  echo "  git: kurulu değil — iz bırakılmadı" >&2
fi

cat <<EOF

Sonraki adımlar (iskelet henüz boş — bu normal):
  1) cd $PROJECT
  2) bash scripts/web/state.sh start .   # P1
  3) domain raporunu yaz (docs/WEB-EDITION.md §3) → bash scripts/web/orchestrate.sh .
     P2'de web-core-engineer index.php, core/, views/ VE phpstan.neon.dist,
     .eslintrc.json, phpunit.xml + tests/ iskeletini üretir.
NOT: P2 öncesi ilk \`qa-gate.sh\` koşusu KASITLI FAIL verir — yapısal dosyalar
(index.php, .htaccess, ...) + asimetrik çekirdek (phpstan/phpunit yapılandırması)
zorunludur; config'leri elle kurmak yerine P2 iskeletini bekleyin.
EOF
