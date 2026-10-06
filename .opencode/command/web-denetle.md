---
description: App-Fabrika P3 — qa-gate.sh --record çalıştır, 0 Error 0 Warning ver, yoksa debug_report.json ile dur ($ARGUMENTS = proje dizini, boşsa .)
---

Proje dizini: `$ARGUMENTS` (boşsa `.`).

1. `bash scripts/web/state.sh status $ARGUMENTS` — faz P1/P2 ise önce gate'leri kapatıp
   `advance` ile P3'e geç; P5 ise raporu oku ve `/web-yukle`'e geç.
2. `bash scripts/web/qa-gate.sh $ARGUMENTS --record`
3. `qa-report.json` oku ve tabloya dök: php_lint, structure, sql_schema (FK/seed/RBAC/sepet),
   security_grep, security_policy + state (faz/retry).
4. PASS (exit 0): state otomatik `qa-pass` → P5. FAIL (exit 1): hataları kanıtla
   (dosya:satır), düzelt, tekrar çalıştır (retry 1–3).
5. HALT (exit 2, 4. fail): `debug_report.json`'u sun, kök neden çözmeden tekrar deneme.

PASS yalnızca 0 Error, 0 Warning. Kod düzeltmesini bu komutta sen yapma (Agent 2'ye devret).
