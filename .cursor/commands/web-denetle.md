# /web-denetle — QA & Security Gate (P3 → P5)

Tek ajan onayı yasak; kapı `qa-gate.sh`'dir (Agent 4 · `26-web-qa-gate`, readonly).

## Sıra

1. State:

```bash
bash scripts/web/state.sh status
```

   - State yoksa: `state.sh start` + `advance` ×2 (P1→P2→P3) — yalnız P1/P2 gate'leri
     gerçekten kapandıysa.
   - Faz P1/P2 ise önce `/web-baslat` gate'lerini kapat.
   - Faz P5 ise kapı zaten PASS; raporu oku, `/web-yukle`'e geç.

2. QA kapısı (state kaydıyla):

```bash
bash scripts/web/qa-gate.sh . --record
cat qa-report.json
```

3. FAIL ise `debug_report.json` + hata listesini sun; düzelt → tekrar `/web-denetle`
   (retry 1–3). **4. fail HALT** (exit 2): `debug_report.json`'u geliştiriciye sun,
   kök neden çözülmeden tekrar deneme.

## Rapor formatı

| Kontrol | Sonuç | Kanıt |
|---------|-------|-------|
| php_lint | PASS/FAIL/SKIPPED | dosya:satır |
| structure | ... | ... |
| sql_schema (FK/seed/RBAC/sepet) | ... | ... |
| security_grep + policy | ... | ... |
| State | faz / retry | qa-report.state |

**PASS yalnızca 0 Error, 0 Warning** → `state.sh` otomatik `qa-pass` (→P5) → `/web-yukle`.
