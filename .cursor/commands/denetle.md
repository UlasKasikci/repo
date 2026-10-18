# /denetle — Webrail otomatik denetim

Hedef: `$ARGUMENTS` (boşsa `.`).

Sistem uygun zamanda (P1 sonrası, P3, paket öncesi) bunu **kendi de çağırır**;
sen unutsan bile `orchestrate` / `denetle.sh` devreye girer.

```bash
bash scripts/web/denetle.sh $ARGUMENTS
# sıkı: bash scripts/web/denetle.sh $ARGUMENTS --strict
```

Çıktı: `gap-report.json` · `DENETIM.md` · gerekirse `FIX-BRIEF.md`  
Blocker (sepet/RBAC…) → PLAN/P1’e ekle. Warn (ödeme/yorum…) → onayla veya enjekte et.
