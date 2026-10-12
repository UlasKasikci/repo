# Webrail Modül Kataloğu (açık kaynak)

Ücretli JEV yerine Webrail **karar katmanı** (`scripts/web/decide.sh`) bu dizini okur.

| Kaynak | Rol |
|--------|-----|
| `catalog.json` | modül adı → skill yolu |
| `.opencode/skills/*/SKILL.md` | yeniden kullanılabilir iskelet talimatı |

P2 ajanı önce `decision.json` içindeki `modules_to_apply` listesine bakar;
skill varsa onu uygular, yoksa domain-report’a göre üretir (yeniden icat etme).
