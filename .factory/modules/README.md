# Webrail Modül Kataloğu

Ücretli JEV yok. `decide.sh` → `catalog.json`; P2 öncesi `module-apply.sh` paketleri kopyalar.

| Modül | Skill | Paket | Durum |
|-------|-------|-------|-------|
| rbac / auth | `.opencode/skills/auth-rbac/SKILL.md` | `auth-rbac/` | READY + files |
| admin | `.opencode/skills/admin-crud/SKILL.md` | `admin-crud/` | READY + files |
| kvkk / gdpr | `.opencode/skills/kvkk-compliance/SKILL.md` | `kvkk/` | READY + files |
| seo | `.opencode/skills/seo-basics/SKILL.md` | `seo/` | READY + files |
| cart | — | — | domain'e özel |

```bash
bash scripts/web/decide.sh .
bash scripts/web/module-apply.sh .
# --force ile mevcut dosyaları ez
```
