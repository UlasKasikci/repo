# /prompt-genesis — Workspace Intent Kilidi

Bu komut proje başlatmaz; önce workspace intent kilidi oluşturur.

## Zorunlu Soru

Bu workspace'in rolü nedir?

1. `factory-template` — APP-FABRIKA standart kaynağı; product genesis yok
2. `android-app` — Yeni veya bu workspace'te Android uygulama
3. `web-app` — Web uygulaması (Leo Compatibility Layer veya ayrı factory)
4. `laravel-mysql-fullstack` — Laravel/MySQL full-stack (Leo layer; APP-FABRIKA core scaffold üretmez)
5. `existing-project-import` — Mevcut kod tabanına standart aktarım
6. `test-sandbox` — Geçici deneme; kalıcı scaffold için promotion gerekir

## Kurallar

- Eski konuşma bağlamını varsayım olarak kullanma.
- Kullanıcı explicit onay vermeden `.factory/project-intent.json` yazma.
- `android-app` için `project_name` ve `package_name` zorunludur.
- `web-app` için `package_name` zorunlu değildir.
- `laravel-mysql-fullstack` için APP-FABRIKA core scaffold üretmez; Leo Compatibility Layer veya ayrı factory gerekir.
- `factory-template` intent product `/baslat`, `init-new-app` ve scaffold işlemlerini bloke eder.
- `test-sandbox` kalıcı scaffold için yeterli değildir; explicit promotion gerekir.

## Onay Sonrası

Kullanıcı onayladıktan sonra `.factory/project-intent.json` oluştur:

- `schema_version`: 1
- `source`: `explicit-user-confirmation`
- `confirmed_by`: `user`
- `confirmed_at`: ISO-8601 UTC
- Role/platform eşlemesi: `docs/PROJECT_INTENT_GATE.md`

Doğrula:

```bash
python3 scripts/governance/validate-project-intent.py --mode diagnostic
```

## Çıktı Formatı

```markdown
## PROJECT INTENT CONFIRMATION REQUEST

| Alan | Değer |
|------|-------|
| workspace_role | … |
| platform | … |
| project_name | … |
| package_name | … |

Onaylıyor musunuz? (Evet/Hayır — değişiklik için rolü yeniden seçin)
```
