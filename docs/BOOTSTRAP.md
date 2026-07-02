# Bootstrap — Yeni Android projesi

Bu belge, fabrikayı yeni bir Android projesine nasıl uygulayacağını adım adım anlatır.

**Yazar:** [Ulaş Kaşıkcı](AUTHOR.md)

## Recommended Bootstrap Order

1. Clone APP-FABRIKA (GitHub Template veya `git clone`).
2. Run `./scripts/first-setup.sh`.
3. Open the workspace in Cursor.
4. Run `/prompt-genesis`.
5. Lock explicit workspace intent (`.factory/project-intent.json`).
6. For `android-app`, confirm `project_name` and `package_name`.
7. Run `/yeni-proje` or `./scripts/init-new-app.sh` **only after** intent validation passes.
8. Run `/baslat` only after the proper intent lock.
9. Use `/cevap` or `/after-action` to review execution summaries.

**Warnings**

- Do **not** run `init-new-app.sh` in a `factory-template` workspace.
- Do **not** infer project intent from previous conversations or old chat context.

Belge: [`docs/PROJECT_INTENT_GATE.md`](PROJECT_INTENT_GATE.md) · Komut: [`.cursor/commands/prompt-genesis.md`](../.cursor/commands/prompt-genesis.md)

## Senaryo A: GitHub Template ile Sıfırdan

1. GitHub'da **Ulas Autonomous Android APP Factory** → **Use this template**
2. Klonla ve Cursor'da aç
3. İlk kurulum:

```bash
./scripts/first-setup.sh
```

4. MCP kurulumu (zorunlu): `docs/MCP_SETUP.md`
5. **Project Intent Gate** — Cursor'da `/prompt-genesis` çalıştır; `android-app` rolünü ve `package_name` onayla
6. Uygulama oluştur (yalnızca intent kilidi sonrası):

```bash
./scripts/init-new-app.sh "UygulamaAdi" "com.sirket.uygulama"
```

7. `init-new-app.sh` otomatik olarak:
   - Tüm belgeleri oluşturur
   - **Tam Android iskeletini** scaffold eder (10 modül)
8. Cursor chat'te:

```
/baslat
Bu projeyi 33 katman standartlarına göre geliştir.
Uygulama: [kısa açıklama]
```

Overmind önce `YAPILACAKLAR.md` oluşturur (F0–F8), sonra F0'dan başlar — **halüsinasyon uyarısı otomatik**. Detay: `docs/YAPILACAKLAR_SISTEMI.md`

9. Executive OS hazır: `governance/executive/SPRINT_LOCK.json` — P0 AID Sprint P varsayılan

## Senaryo B: Mevcut Android Projesine Standart Aktarma

```bash
# Fabrika reposunu bir kez klonla
git clone https://github.com/YOUR_ORG/autonomous-app-factory.git ~/autonomous-app-factory

# Mevcut projene standartları aktar
export FACTORY_REPO=~/autonomous-app-factory
cd /path/to/mevcut-proje
$FACTORY_REPO/scripts/sync-standards.sh .
```

Aktarılan içerik:
- `.cursorrules`
- `.cursor/rules/*.mdc` (Factory + Executive OS agents)
- `governance/` (CEO V7, sprint lock, PDC, CEC, CAO, AID templates)
- `AGENTS.md`
- `docs/` (standart belgeler + şablonlar + EXECUTIVE_OS.md)
- `scripts/` (denetim + governance araçları)

Mevcut `app/` kodunuz korunur. Sadece AI kuralları ve dokümantasyon eklenir.

## Senaryo C: Git Submodule (Güncel Standart Takibi)

```bash
cd my-android-app
git submodule add https://github.com/YOUR_ORG/autonomous-app-factory.git .factory

# Standartları senkronize et
./.factory/scripts/sync-standards.sh .

# Fabrika güncellendiğinde
git submodule update --remote .factory
./.factory/scripts/sync-standards.sh .
```

## Senaryo D: Google Stitch → AI Studio → Fabrika

1. Prompt → **Google Stitch** (UI tasarım, manuel export)
2. **Google AI Studio** → Android projesi indir
3. Bootstrap (mevcut AI Studio kodu korunur):

```bash
export FACTORY_REPO=~/Android-App-Factory
"$FACTORY_REPO/scripts/bootstrap-external-project.sh" \
  /path/to/aistudio-export "AppAdi" "com.sirket.app" "Vizyon promptu"
```

4. Cursor: `/import-aistudio` veya `/baslat`

Detay: [`docs/AI_STUDIO_IMPORT.md`](AI_STUDIO_IMPORT.md)

## init-new-app.sh Ne Yapar?

| Adım | Açıklama |
|------|----------|
| 1 | `docs/00-INDEX.md` içine uygulama adı ve paket adı yazar |
| 2 | `docs/01-VISION/` altına şablon brifler oluşturur |
| 3 | `docs/02-ARCHITECTURE/MODULE_MAP.md` şablonunu oluşturur |
| 4 | `docs/TODO.md` sıfırlar ve Faz 0 ekler |
| 5 | `android/` klasör yapısı referansını oluşturur |
| 6 | `governance/` Executive OS bootstrap (`init-governance.sh`) |

## Executive OS

```bash
./scripts/run-ceo-cycle.sh
./scripts/agent-approval-gate.sh
```

Kılavuz: [EXECUTIVE_OS.md](./EXECUTIVE_OS.md)

- **İlk prompt:** Uygulama fikrini verin, kod istemeyin — Overmind önce vizyon belgelerini oluşturur
- **Devam promptu:** `@docs/00-INDEX.md` ile hafızayı tazeleyin
- **Denetim:** Kod yazıldıktan sonra `./scripts/pre-commit.sh` çalıştırın
- **Katman kontrolü:** `./scripts/audit-layers.sh`

## GitHub Template Ayarı

Repo sahibi GitHub'da şunu yapmalı:

1. **Settings** → **General** → **Template repository** ✅ işaretle
2. README'deki `YOUR_ORG` placeholder'ını gerçek org/ad ile değiştir

## Sık Sorulan Sorular

**Her projede fabrika reposunu fork'lamalı mıyım?**  
Hayır. Template kullanın veya `sync-standards.sh` ile mevcut projeye aktarın.

**Standartlar güncellenirse ne olur?**  
Submodule veya `sync-standards.sh` ile yeniden senkronize edin. `CHANGELOG.md` değişiklikleri takip edin.

**Android kodu bu repoda mı?**  
Hayır. Bu repo standartların kaynağıdır. Uygulama kodu template'den türeyen proje reposunda yaşar.
