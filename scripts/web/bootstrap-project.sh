#!/usr/bin/env bash
set -euo pipefail

# Webrail — temiz bootstrap: Webrail iskeletini yeni projeye kopyalar
#
# Kullanım:
#   bash scripts/web/bootstrap-project.sh <hedef_dizini> [--yes] [--force] [--allow-existing-git]
#
#   (bayrak yok)  → DRY-RUN: kopyalanacak/kalmayacak listesi + sayı, hedefe DOKUNMAZ
#   --yes         → kopyalamayı gerçekten yap + git init + ilk commit
#   --force       → hedef boş DEĞİLSE bile yaz (var olan dosyalar ezilir, fazladan durur)
#                   (git operasyonlarını kapsamaz — mevcut depo yine B.1'e tabidir)
#   --allow-existing-git → hedefte mevcut .git deposuna yazmaya izin ver
#                   (önce stage edilmiş değişiklik kontrolü; varsa yine DUR)
#
# KOPYALANIR (karar listesi — kod bunu uygular):
#   scripts/web/* (self-test.sh ve bu betik hariç), .factory/{contracts,meta.json,
#   web-state-graph.json, web-state.example.json, project-intent.example.json},
#   .cursor/{rules,agents,commands,mcp.json.example,mcp.required.json},
#   .opencode/{agent,command}, docs/**, CLAUDE.md, .cursorrules, antigravity.yaml,
#   opencode.json, .gitignore
# KOPYALANMAZ:
#   tests/ (Webrail fixture), .github/ (Webrail CI), scripts/web/{self-test,bootstrap-project}.sh,
#   .factory/{context,e2e-runs,test-runs,freeze.json} + runtime (web-state.json, domain-report.json,
#   lighthouse-report.json, smoke-report.json, qa/debug/packaging-report.json,
#   yukleme-{staging,archive,failed}/), .cursor/{skills,snapshots,history,cache,mcp.json},
#   .opencode/{plans,node_modules,sessions,storage,logs,cache,package*.json}, .git/,
#   node_modules/, Yukleme/, ._*, .DS_Store
#
# Git izi: hedefte taze `git init`; ilk commit
#   "bootstrap from webrail@<12-hex>"  (Webrail deposunun HEAD'i — sürüm izlenebilirliği)

PROJECT="${1:-}"
shift || true
YES=0
FORCE=0
ALLOW_EXISTING_GIT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)   YES=1; shift ;;
    --force) FORCE=1; shift ;;
    --allow-existing-git) ALLOW_EXISTING_GIT=1; shift ;;
    -h|--help)
      sed -n '4,35p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "bootstrap: bilinmeyen argüman: $1" >&2
      exit 1
      ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "kullanım: bootstrap-project.sh <hedef_dizini> [--yes] [--force] [--allow-existing-git]" >&2; exit 1; }
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
# Tur 2-16 B.1 (ChatGPT 2.2): veri bütünlüğü ön kontrolleri — kopyalamadan ÖNCE.
# 1) hedef == Webrail deposu → DUR  2) hedef Webrail’in İÇİNDE → DUR
# 3) hedefte mevcut .git → DUR (--allow-existing-git ile geçilir; geçildiğinde
#    stage edilmiş değişiklik varsa yine DUR — bootstrap commit'e karışmasın).
PROJ_N="${PROJECT%/}"
PROJ_ABS="$PROJ_N"
if [[ -d "$PROJ_N" ]]; then
  PROJ_ABS="$(cd "$PROJ_N" && pwd)"
elif [[ -d "$(dirname "$PROJ_N")" ]]; then
  PROJ_ABS="$(cd "$(dirname "$PROJ_N")" && pwd)/$(basename "$PROJ_N")"
fi
if [[ "$PROJ_ABS" == "$SOURCE" ]]; then
  echo "bootstrap: hedef Webrail deposunun KENDİSİ — duruldu: $PROJ_ABS" >&2
  exit 1
fi
case "$PROJ_ABS" in
  "$SOURCE"/*)
    echo "bootstrap: hedef Webrail deposunun İÇİNDE — duruldu: $PROJ_ABS (Webrail dışı bir dizin seçin)" >&2
    exit 1
    ;;
esac
if [[ -e "$PROJ_ABS/.git" ]]; then
  if [[ "$ALLOW_EXISTING_GIT" -ne 1 ]]; then
    echo "bootstrap: hedefte mevcut git deposu var — duruldu (--allow-existing-git ile geçilir, mevcut geçmiş korunur): $PROJ_ABS" >&2
    exit 1
  fi
  # B.2: stage edilmiş değişiklikler bootstrap commit'ine KARIŞAMAZ — kopyadan önce DUR.
  if command -v git >/dev/null 2>&1 \
     && ! git -C "$PROJ_ABS" diff --cached --quiet 2>/dev/null; then
    echo "bootstrap: hedefte stage edilmiş değişiklikler var — önce commit veya reset edin (bootstrap commit'e karışmasın)" >&2
    exit 1
  fi
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
    "templates",
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
    os.path.join(".factory", "e2e-runs"),
    os.path.join(".factory", "test-runs"),
    os.path.join(".factory", "yukleme-staging"),
    os.path.join(".factory", "yukleme-archive"),
    os.path.join(".factory", "yukleme-failed"),
    ".cursor/skills",
    ".cursor/snapshots",
    ".cursor/history",
    ".cursor/cache",
    ".opencode/plans",
    ".opencode/node_modules",
    ".opencode/sessions",
    ".opencode/storage",
    ".opencode/logs",
    ".opencode/cache",
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
    "project-intent.json",
    "domain-report.json",
    "lighthouse-report.json",
    "smoke-report.json",
    "metrics.jsonl",
    "qa-report.json",
    "debug_report.json",
    "packaging-report.json",
    "module-apply-report.json",
    "guard-log.jsonl",
    "project.json",
    "bootstrap_manifest.json",
    "sync.json",
    ".bootstrap-manifest",
    "mode.json",
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
    ".factory/{context,e2e-runs,test-runs,yukleme-*,freeze.json,runtime}, "
    ".cursor/{skills,snapshots,history,cache,mcp.json}, "
    ".opencode/{plans,node_modules,sessions,storage,logs,cache,package*.json}, "
    ".git/, node_modules/, Yukleme/, ._*, .DS_Store"
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

# F2: bootstrap'ın kopyaladığı dosya listesini manifest'e yaz (git add için).
# --force'ta mevcut (bootstrap dışı) dosyalar commit'e GİRMEZ.
manifest = os.path.join(target, ".factory", ".bootstrap-manifest")
os.makedirs(os.path.dirname(manifest), exist_ok=True)
with open(manifest, "w", encoding="utf-8") as fh:
    fh.write("\n".join(files) + "\n")

print(f"BOOTSTRAP @ {git_hash}: {len(files)} dosya ({total} bayt) → {target}")
print(f"  {EXCLUDED_NOTE}")
PY

[[ "$MODE" == "write" ]] || exit 0

# Keşif modu (Şerit A): commit öncesi — DISCOVERY.md + mode.json ilk izde olsun
ROOT_BOOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$ROOT_BOOT/scripts/web/mode.sh" init "$PROJECT" || {
  echo "bootstrap: mode.sh init başarısız — duruldu" >&2
  exit 1
}

# --- git izi: taze depo + sürüm bağlayıcı ilk commit ---
if command -v git >/dev/null 2>&1; then
  # Tur 2-16 B.2: init hatası YUTULMAZ — durulur (sessiz devam = bozuk iz).
  if ! git -C "$PROJECT" init -q; then
    echo "bootstrap: git init başarısız — duruldu: $PROJECT" >&2
    exit 1
  fi
  git -C "$PROJECT" config user.name >/dev/null 2>&1 \
    || git -C "$PROJECT" config user.name "Webrail Bootstrap"
  git -C "$PROJECT" config user.email >/dev/null 2>&1 \
    || git -C "$PROJECT" config user.email "bootstrap@webrail.local"
  # F2: yalnız bootstrap'ın yönettiği dosyaları add et (add -A DEĞİL).
  # --force'ta hedefte bootstrap dışı dosya varsa UYAR + atla (commit'e girmez).
  BOOT_MANIFEST="$PROJECT/.factory/.bootstrap-manifest"
  if [[ -f "$BOOT_MANIFEST" ]]; then
    # bootstrap dışı dosyaları tespit et (uyarı)
    EXTRAS=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      [[ -f "$PROJECT/$f" ]] || continue
    done < <(git -C "$PROJECT" ls-files 2>/dev/null)
    # mevcut tracked olmayan ama disk'te olan .factory dışı dosyaları say
    EXTRA_COUNT="$(cd "$PROJECT" && find . -type f \
      -not -path "./.git/*" -not -path "./.factory/.bootstrap-manifest" \
      -not -name "._*" -not -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')"
    TRACKED_BY_BOOT="$(grep -c . "$BOOT_MANIFEST" 2>/dev/null || echo 0)"
    if [[ "$FORCE" -eq 1 ]] && [[ "$EXTRA_COUNT" -gt "$TRACKED_BY_BOOT" ]]; then
      echo "  git: dikkat — hedefte bootstrap dışı dosyalar var; --force'ta yalnız bootstrap dosyaları commit edilir" >&2
    fi
    # her bootstrap dosyasını tek tek add et
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      [[ -f "$PROJECT/$f" ]] && git -C "$PROJECT" add -- "$f" 2>/dev/null || true
    done < "$BOOT_MANIFEST"
    # manifest'in kendisi de eklensin (izlenebilirlik)
    git -C "$PROJECT" add -- .factory/.bootstrap-manifest 2>/dev/null || true
    # mode kilidi artefaktları (manifest'te olmayabilir — init sonrası üretilir)
    [[ -f "$PROJECT/.factory/mode.json" ]] && git -C "$PROJECT" add -- .factory/mode.json 2>/dev/null || true
    [[ -f "$PROJECT/DISCOVERY.md" ]] && git -C "$PROJECT" add -- DISCOVERY.md 2>/dev/null || true
  else
    # Tur 2-16 B.2: manifest yoksa add -A YASAK — hedefteki her şey commit'e
    # karışırdı (D7.1 veri bütünlüğü ihlali). Bozuk bootstrap: dur.
    echo "bootstrap: .bootstrap-manifest yok — git add -A yasak (veri bütünlüğü), duruldu" >&2
    exit 1
  fi
  if git -C "$PROJECT" diff --cached --quiet 2>/dev/null; then
    echo "  git: içerik aynı — commit atlanmadı (mevcut iz korundu)"
  else
    git -C "$PROJECT" commit -qm "bootstrap from webrail@${GIT_HASH}"
    git -C "$PROJECT" branch -M main 2>/dev/null || true
    echo "  git: ilk commit 'bootstrap from webrail@${GIT_HASH}' (main)"
  fi
else
  echo "  git: kurulu değil — iz bırakılmadı" >&2
fi

cat <<EOF

Sonraki adımlar (Şerit A → B — kod henüz YOK):
  1) cd $PROJECT
  2) DISCOVERY.md doldur (saf IDE / /kesfet) — core/views/SQL yazma
  3) bash scripts/web/mode.sh promote .     # discovery → factory
  4) bash scripts/web/state.sh start .      # P1 (factory kilidi gerekir)
  5) bash scripts/web/orchestrate.sh . --auto
     P2 tercihen hybrid: P2_HUMAN_ASSIST=true (saf IDE gücü + Webrail kapısı)
NOT: P2 öncesi ilk \`qa-gate.sh\` koşusu KASITLI FAIL verir — yapısal dosyalar
+ phpstan/phpunit P2 iskeletinden gelir.
EOF
