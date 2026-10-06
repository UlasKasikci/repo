# /import-aistudio — AI Studio / Stitch Sonrası Fabrika Bootstrap

AI Studio'dan export edilmiş **harici** Android projesinde fabrikayı devreye alır.

## Ön koşul

- Proje klasöründe AI Studio / Gradle iskeleti var (`settings.gradle.kts` veya `app/`)
- Fabrika reposu yolu biliniyor (ör. `~/Android-App-Factory`)

## Akış

1. **Skill:** `zero-hallucination`
2. **Oku:** `docs/AI_STUDIO_IMPORT.md`
3. **Kontrol:** `.factory/bootstrap_manifest.json` — varsa bootstrap atla
4. **Yoksa terminal:**

```bash
FACTORY_REPO="${FACTORY_REPO:-$HOME/Android-App-Factory}" \
  "$FACTORY_REPO/scripts/bootstrap-external-project.sh" \
  "$(pwd)" \
  "<AppAdi>" \
  "<com.sirket.app>" \
  "<kullanıcı vizyon promptu>"
```

5. **Sonra:** `/baslat` ile F0–F8 planını uygula — AI Studio kodunu koruyarak standartları ekle

## Kullanıcı mesajından al

- App adı, package, vizyon → bootstrap komutuna yaz
- Stitch tasarım path/URL → `docs/01-VISION/` veya `.cursor/snapshots/mcp/` handoff

## Yasak

- `first-setup.sh` harici projede (fabrika şablon reposu içindir)
- `sync-standards.sh .` fabrika script'i olmadan (önce FACTORY_REPO)
- Bootstrap olmadan tüm projeyi scaffold ile değiştirme

## Çıktı

- Bootstrap çalıştı mı?
- `bootstrap_manifest.json` oluştu mu?
- Sıradaki: `/baslat` → aktif faz F0
