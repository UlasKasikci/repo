---
description: Tek giriş — preflight/bootstrap/from-brief/promote/state start ($ARGUMENTS = proje; --brief metin)
---

# /webrail

```bash
bash scripts/web/webrail.sh $ARGUMENTS --yes --brief "<kısa iş özeti>"
# veya keşif için brief'siz:
bash scripts/web/webrail.sh $ARGUMENTS --yes
bash scripts/web/status.sh $ARGUMENTS
```

Sonraki: `/web-baslat` → `module-apply` → `P2_HUMAN_ASSIST=true` orchestrate → `/web-denetle`.
