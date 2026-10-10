#!/bin/bash
# cjk-check.sh — CJK encoding taraması (Tur 2-8 C; ChatGPT denetimi Q5 kalıcı koruma).
# Kapsam: --include ile sh/md/json/yaml/yml; Türkçe karakterler (ç ş ğ ü ö ı İ) ETKİLENMEZ.
# GNU grep -P gerekir (ubuntu-latest'te var; macOS BSD grep -P desteklemez — lokalde
# python3 fallback). Çıktı: temizse rc=0 + "CLEAN"; isabet varsa dosya:satır listesi + rc=1.
set -uo pipefail
TARGET="${1:-.}"
if grep -rPn '[\x{4e00}-\x{9fff}\x{3040}-\x{30ff}]' \
  --include='*.sh' --include='*.md' --include='*.json' \
  --include='*.yaml' --include='*.yml' \
  "$TARGET" 2>/dev/null | grep -v '/\.git/'; then
  echo "CJK: isabet — encoding sızıntısı (AI edit kaynaklı olabilir)" >&2
  exit 1
fi
# BSD grep -P yoksa python3 fallback (yalnız GNU başarısızsa)
if ! printf 'x' | grep -P 'x' >/dev/null 2>&1; then
  python3 - "$TARGET" <<'PY'
import os, re, sys
pat = re.compile(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]')
exts = ('.sh', '.md', '.json', '.yaml', '.yml')
hits = []
root = sys.argv[1]
for r, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', 'vendor')]
    for f in files:
        if not f.endswith(exts):
            continue
        p = os.path.join(r, f)
        try:
            t = open(p, encoding='utf-8', errors='ignore').read()
        except OSError:
            continue
        for i, line in enumerate(t.splitlines(), 1):
            if pat.search(line):
                hits.append(f"{p}:{i}: {line.strip()[:100]}")
if hits:
    print('\n'.join(hits))
    sys.exit(1)
PY
  rc=$?
  [[ $rc == 0 ]] || { echo "CJK: isabet — encoding sızıntısı" >&2; exit 1; }
fi
echo "CLEAN"
exit 0
