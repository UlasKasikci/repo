#!/usr/bin/env python3
"""App-Fabrika P1 domain artefaktı semantik denetimi — tek doğruluk kaynağı.

Kullanım: domain-check.py <domain-report.json> <proje_dizini>
Çıktı: hatalar stderr · exit 0 = PASS · 1 = FAIL · 2 = kullanım hatası

Kontroller: result sabiti · module_matrix ≥4 · modül adı benzersizliği ·
status enum · justification ≥20 karakter + şablon tekrar yasağı ·
evidence ≥10 karakter + kaynak referansı (dosya uzantısı/`:`/`/`) ·
filesystem: evidence'da geçen dosya adları proje kökünde GERÇEKTEN VAR olmalı.
"""

import json
import os
import re
import sys

FILE_EXTS = (
    "php|sql|js|css|html|json|md|txt|xml|yml|yaml|neon|scss|ts|"
    "htaccess|ini|dist|env|example|lock"
)
SOURCE_RE = re.compile(r"[/\\:]|\.[A-Za-z]{2,6}\b")
FILE_RE = re.compile(
    r"(?<![\w])([A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:" + FILE_EXTS + r"))\b"
)


def main(argv):
    if len(argv) != 3:
        print("kullanım: domain-check.py <domain-report.json> <proje_dizini>",
              file=sys.stderr)
        return 2
    report, project = argv[1], argv[2]

    errors = []
    try:
        with open(report, encoding="utf-8") as fh:
            doc = json.load(fh)
    except Exception as exc:
        print(f"geçersiz JSON: {exc}", file=sys.stderr)
        return 1

    if doc.get("result") != "requirements-frozen":
        errors.append('result "requirements-frozen" değil')

    mm = doc.get("module_matrix")
    if not isinstance(mm, list):
        errors.append("module_matrix yok")
        mm = []
    if len(mm) < 4:
        errors.append(f"module_matrix en az 4 modül içermeli (bulunan: {len(mm)})")

    seen = set()
    for i, cell in enumerate(mm):
        if not isinstance(cell, dict):
            errors.append(f"module_matrix[{i}] obje değil")
            continue
        name = str(cell.get("module", "")).strip()
        if not name:
            errors.append(f"module_matrix[{i}].module boş")
        elif name.lower() in seen:
            errors.append(f"module_matrix modül tekrarı: {name}")
        else:
            seen.add(name.lower())

        status = cell.get("status")
        if status not in ("present", "missing", "injected", "proposed"):
            errors.append(f"module_matrix[{i}].status geçersiz: {status!r}")

        just = str(cell.get("justification", "")).strip()
        if len(just) < 20:
            errors.append(
                f"module_matrix[{i}] justification yetersiz (<20 karakter) — şablon/boş çıktı"
            )
        elif name and just.lower() == name.lower():
            errors.append(
                f"module_matrix[{i}] justification şablon (yalnız modül adı tekrarı)"
            )

        ev = str(cell.get("evidence", "")).strip()
        if len(ev) < 10:
            errors.append(
                f"module_matrix[{i}] evidence yetersiz (<10 karakter) — dosya/satır kanıtı bekleniyor"
            )
        else:
            if not SOURCE_RE.search(ev):
                errors.append(
                    f"module_matrix[{i}] evidence kaynak referansı içermiyor "
                    f"(ör. SQL/veritabani.sql:users veya core/App.php:21)"
                )
            for cand in FILE_RE.findall(ev):
                if cand.startswith("/") or ".." in cand.split("/"):
                    continue
                if not os.path.exists(os.path.join(project, cand)):
                    errors.append(
                        f"module_matrix[{i}] evidence kaynak dosyası bulunamadı: "
                        f"{cand} (proje kökünde yok — {project})"
                    )

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
