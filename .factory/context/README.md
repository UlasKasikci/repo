# Context Operating System

Proje açıldığında AI'ın **ne okuyacağını** tanımlar. Governance değil — **context engineering**.

## Hızlı başlangıç

```bash
./scripts/factory/assemble-context.sh
# → .factory/context/SESSION_CONTEXT.md (oturum paketi)
```

Cursor chat:

```
@.factory/context/SESSION_CONTEXT.md @YAPILACAKLAR.md
```

## Dosyalar

| Dosya | Rol |
|-------|-----|
| `CONTEXT_MANIFEST.json` | Oturum başı okuma sırası + faz override |
| `LAST_DECISION.md` | Son mimari/ürün kararı özeti (elle veya `record-adr.py`) |
| `SESSION_CONTEXT.md` | `assemble-context.sh` çıktısı — gitignore |

## İlişkili

- `docs/CURSOR_CONTEXT_BUDGET.md` — token kuralları
- `knowledge/` — pattern, failure, outcome, ADR arşivi
- `docs/KNOWLEDGE_OS.md` — öğrenen fabrika katmanı
