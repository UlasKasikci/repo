---
description: Şerit A keşif — DISCOVERY.md doldur, kod yazma; sonra mode.sh promote ($ARGUMENTS = proje, boşsa .)
---

# /kesfet — Saf IDE keşfi (kod YOK)

Hedef: `$ARGUMENTS` (boşsa `.`).

1. Bootstrap yoksa: `bash scripts/web/bootstrap-project.sh $ARGUMENTS --yes`
2. `DISCOVERY.md` doldur — **Proje adı** zorunlu; `core/`/`views/`/`SQL/` yazma.
3. `bash scripts/web/measure.sh $ARGUMENTS discovery_minutes <N> A0`
4. Bitince: `bash scripts/web/mode.sh promote $ARGUMENTS`
5. Sonra: `bash scripts/web/state.sh start $ARGUMENTS` + `/web-baslat`

Discovery modunda `orchestrate` / `decide` / `state start` kapalıdır.
