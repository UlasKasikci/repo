# APP-FABRIKA Repository Intelligence Report

> **Hazırlayan:** Overmind (repo analizi — salt okuma)  
> **Tarih:** 2026-06-14  
> **Kapsam:** `clariongemini/APP-FABRIKA` — kök fabrika + `APP-FABRIKASI/` SVOS katmanı  
> **Amaç:** Dışarıdan bakan bir Principal Architect'in repoyu tam anlaması  
> **Kısıt:** Bu rapor oluşturulurken repo değiştirilmedi; scaffold/init scriptleri çalıştırılmadı.

---

## 1. Repo Durumu (Anlık Snapshot)

### Komut çıktıları

| Komut | Sonuç |
|-------|--------|
| `pwd` | `/Users/ulas/Desktop/Repo` |
| `git status --short` | *(temiz — commit edilmemiş değişiklik yok)* |
| `git remote -v` | `origin` → `https://github.com/clariongemini/APP-FABRIKA.git` · `android-app` → `https://github.com/clariongemini/Android-App.git` (legacy alias) |
| `git branch --show-current` | `main` |
| Son commit (analiz anı) | `bb39da3` — `docs(svos): professionalize APP-FABRIKASI README` |

### `find . -maxdepth 2 -type d` (özet)

Ana dizinler (`.git` hariç):

```
.
├── .cursor/          # rules, commands, skills, agents, snapshots
├── .factory/         # meta.json, freeze.json, context/
├── APP-FABRIKASI/    # Software Venture OS (01-core … 10-runtime, ULAS, scripts)
├── docs/             # 00-INDEX, standartlar, mimari, Executive OS belgeleri
├── factory/          # Intelligence V3 + portfolio/outcomes scaffold (git)
├── governance/       # Executive OS charter + protokoller (çoğu MD canonical)
├── knowledge/        # ADR, pattern, failure, postmortem (git)
├── runtime/          # Canlı JSON/raporlar (gitignore — boş README ile)
├── scripts/          # Bootstrap, governance, factory, analytics, CEO cycle
└── templates/        # Android Gradle, governance, YAPILACAKLAR şablonları
```

### `find . -maxdepth 2 -type f` (özet — kritik kök dosyalar)

| Dosya | Rol |
|-------|-----|
| `README.md` | Ana GitHub README (TR/EN, factory + SVOS) |
| `APP-FABRIKA.md` | Canonical repo pointer + SVOS link |
| `FACTORY_MISSION.md` | North star — ürün kanıtı, freeze durumu |
| `YAPILACAKLAR.md` | **Uninitialized stub** (fabrika şablonu) |
| `AGENTS.md` | 16+ Executive ajan dizini |
| `.cursorrules` | Overmind anayasa (kök) |
| `.gitignore` | Runtime, secrets, proje-özel governance JSON |

---

## 2. Nihai Teşhis (Kısa)

| Soru | Cevap |
|------|--------|
| Bu repo bir uygulama mı? | **Hayır.** APK yaşamaz; `templates/android/project/` iskeleti hedef projeye kopyalanır. |
| Template/factory mi? | **Evet.** GitHub Template + standart kaynağı + Cursor Agent OS. |
| Ne yapıyor? | Android uygulamalarını 33 katman, 16 ajan, Executive OS ve kalite kapılarıyla üretmek; üzerine taşınabilir SVOS venture katmanı sunmak. |
| Android-first mi? | **Evet — operasyonel.** Web/iOS/backend SVOS'ta `blueprint_frozen`. |
| Değiştirilmemesi gereken çekirdek | `.cursor/rules/00-*`, `20-agent-intent-gate`, `templates/`, `governance/executive/*.md`, `docs/33-LAYER-*`, fabrika freeze politikası |

---

## 3. Klasör Analizleri

## `.cursor/`

### Amaç
Cursor Agent Mode için kurallar, komutlar, beceriler, subagent tanımları ve snapshot şablonları.

### İçerik Özeti
| Alt klasör | İçerik |
|------------|--------|
| `rules/` | 20+ `.mdc` ajan kuralı (00–20) |
| `commands/` | `/baslat`, `/devam-et`, `/denetle`, `/faz-durumu`, `/yeni-proje`, `/import-aistudio` |
| `skills/` | zero-hallucination, yapilacaklar-planner/executor, hierarchical-audit |
| `agents/` | phase-verifier, phase-auditor, plan-expander, hallucination-guard |
| `snapshots/` | HANDOFF/RECOVERY şablonları; build/maestro/mcp çıktıları gitignore |

### Kritik Dosyalar
| Dosya | Görev | Değişiklik Riski |
|-------|-------|------------------|
| `rules/00-overmind-zero-hallucination.mdc` | YAPILACAKLAR kapısı, halüsinasyon sıfır | **Yüksek** — tüm ajan davranışı |
| `rules/20-agent-intent-gate.mdc` | DIAGNOSTIC vs IMPLEMENTATION | **Yüksek** |
| `rules/19-claude-reasoning.mdc` | Thinking blokları | Orta |
| `rules/06-mcp-orchestrator.mdc` | MCP zorunluluğu | Orta |
| `commands/baslat.md` | F0–F8 plan başlatma protokolü | Yüksek |
| `mcp.required.json` | P0 MCP listesi | Orta |
| `mcp.json` | Yerel MCP config | Düşük (gitignore) |

### Runtime mı Core mu?
- **Core/canonical** — `rules/`, `commands/`, `skills/`, `agents/` git'te
- **Local:** `mcp.json`, `chat/`, `plans/`, snapshot alt klasörleri

### Project Intent Gate Açısından Önemi
**Kritik entegrasyon noktası.** `21-project-intent-gate.mdc` buraya eklenmeli; `/baslat` ve `/yeni-proje` komutları güncellenmeli.

### Risk / Belirsizlik
- `21-project-intent-gate.mdc` **henüz yok**
- `20-agent-intent-gate` workspace/domain doğrulamaz — yalnızca mesaj modu

---

## `.cursor/rules/`

### Amaç
Departman ajanları ve global davranış kuralları.

### alwaysApply: true olanlar
| Kural | Görev |
|-------|-------|
| `00-overmind-zero-hallucination.mdc` | YAPILACAKLAR kapısı, tek faz, keşif protokolü |
| `06-mcp-orchestrator.mdc` | İlk oturum MCP kontrolü |
| `19-claude-reasoning.mdc` | Tetikleyicide thinking blokları |
| `20-agent-intent-gate.mdc` | DIAGNOSTIC / IMPLEMENTATION ayrımı |

Diğer 01–18, 20-aistudio-import: `alwaysApply: false` — faz/ajan bağlamında devreye girer.

### Project Intent Gate
Yeni kural `21-project-intent-gate.mdc` hiyerarşide **20'den sonra, domain ajanlarından önce** uyumlu olur.

---

## `.cursor/commands/`

### Amaç
Cursor slash komut protokolleri (ajan davranış şablonu).

| Komut | Ne yapar? |
|-------|-----------|
| `/baslat` | Prompt → `init-yapilacaklar.sh` + planner skill → F0–F8 plan; F0 `işleniyor`; kod yok |
| `/yeni-proje` | `init-new-app.sh` + `/baslat` akışı; F0 bitene kadar F1 kodu yok |
| `/devam-et` | Aktif fazdaki ilk `bekliyor` madde; executor skill; L1 phase-verifier |
| `/denetle` | Hiyerarşik denetim script zinciri + phase-auditor |
| `/faz-durumu` | YAPILACAKLAR özeti; kod değiştirmez |
| `/import-aistudio` | Harici AI Studio export → `bootstrap-external-project.sh` |

**Eksik:** Hiçbir komut workspace/domain intent (Android vs Web vs Laravel) doğrulamaz.

---

## `.cursor/skills/`

### Amaç
Tekrarlanabilir çok adımlı ajan iş akışları.

| Skill | Rol |
|-------|-----|
| `zero-hallucination/` | Okuma/grep zorunluluğu, YAPILACAKLAR kapısı |
| `yapilacaklar-planner/` | Prompt → F0–F8 plan |
| `yapilacaklar-executor/` | Aktif faz maddelerini uygula |
| `hierarchical-audit/` | L1+L2 denetim — tek onay yasak |

### Runtime mı Core mu?
**Core** — git'te canonical.

---

## `.cursor/agents/`

### Amaç
Subagent tanımları (phase-verifier, phase-auditor, plan-expander, hallucination-guard).

### Project Intent Gate
`phase-verifier` F0'da project intent doğrulamasını kontrol listesine ekleyebilir.

---

## `.factory/`

### Amaç
Fabrika meta verisi, freeze politikası, oturum context paketi.

### İçerik Özeti
| Dosya | Durum |
|-------|--------|
| `meta.json` | v3.1.0-intelligence-operational, FROZEN, 16 ajan |
| `freeze.json` | Development freeze kuralları |
| `context/` | SESSION_CONTEXT, CONTEXT_MANIFEST (SESSION gitignore) |
| `project.json` | **Yok (şablon)** — init-new-app ile oluşur, **gitignore** |
| `bootstrap_manifest.json` | Harici import işareti — **gitignore** |
| `project-intent.json` | **Bulunamadı** |
| `project-intent.example.json` | **Bulunamadı** |

### Runtime mı Core mu?
- `meta.json`, `freeze.json`, `context/README` → **Core**
- `project.json`, `bootstrap_manifest.json`, `SESSION_CONTEXT.md` → **Runtime/local, gitignore**

### Project Intent Gate
`.factory/project-intent.json` önerilen konum; `project.json` ile paralel, gitignore edilmeli. Example şablon git'te kalmalı.

---

## `docs/`

### Amaç
Fabrika hafızası, mimari anayasa, standartlar, kurulum kılavuzları.

### Kritik Dosyalar
| Dosya | Görev | Risk |
|-------|-------|------|
| `00-INDEX.md` | Merkezi hafıza — init-new-app overwrite eder | Orta |
| `33-LAYER-ARCHITECTURE.md` | 33 katman anayasa | **Dokunma** |
| `33-LAYER-MANIFEST.yaml` | 360 bileşen kaynağı | **Dokunma** (tam okuma yasak — dilim kullan) |
| `YAPILACAKLAR_SISTEMI.md` | F0–F8, stub vs proje | Düşük |
| `BOOTSTRAP.md` | Kurulum senaryoları | Düşük |
| `EXECUTIVE_OS.md` | CEO V7 script ağacı | Düşük |
| `CURSOR_CONTEXT_BUDGET.md` | Token/okuma sırası | Orta |
| `KNOWLEDGE_OS.md` | Learning pipeline | Düşük |
| `LEARNING_FACTORY.md` | Intelligence engine | Düşük |
| `AI_STUDIO_IMPORT.md` | Harici proje bootstrap | Orta |

### Alt klasörler
| Klasör | Durum |
|--------|--------|
| `01-VISION/` | Şablonlar — proje dosyaları gitignore |
| `02-ARCHITECTURE/` | ANDROID_STRUCTURE canonical; MODULE_MAP vb. proje-özel gitignore |
| `03-STANDARDS/` | 13 teknik standart (Liquid Glass, i18n, Security…) — **canonical** |
| `FACTORY_META/` | Fabrika kendi vizyon belgeleri |
| `33-LAYER-MANIFEST/` | layer-NN.yaml dilimleri |

### Runtime mı Core mu?
Karışık: MD standartlar core; doldurulmuş PRODUCT_BRIEF vb. runtime/gitignore.

---

## `governance/`

### Amaç
Executive OS (CEO V7) — karar → teslimat → ölçüm → öğrenme zinciri.

### İçerik Özeti
| Alt klasör | Sahip | Rol |
|------------|-------|-----|
| `executive/` | CEO | CEO OS, hiyerarşik denetim, onay protokolü, sprint lock |
| `product_decision/` | PDC | Roadmap, feature ranking |
| `execution/` | CEC | Teslimat hizası |
| `analytics/` | AID | Sprint P, event catalog |
| `cao/`, `egc/`, `cdid/`, `csgb/` | Executive council | Denetim, sağlık, WP |
| `market/`, `linguistic/`, `curriculum/`, `blue_ocean/`, `trends/` | Intelligence | Pazar, müfredat, keşif |
| `reality/` | CEO V7 | Product reality, NO_NEW_P0 |
| `memory/` | Org memory | Karar geçmişi şablonları |

### Kritik Dosyalar
| Dosya | Sınıf |
|-------|--------|
| `executive/CEO_OPERATING_SYSTEM.md` | **Canonical** |
| `executive/HIERARCHICAL_AUDIT_CHAIN.md` | **Canonical** |
| `executive/AGENT_APPROVAL_PROTOCOL.md` | **Canonical** |
| `phase-agents.json` | **Canonical** — F0–F8 → ajan eşlemesi |
| `dependency-rules.json` | **Canonical** — modül bağımlılık kuralları |
| `project.config.json` | **Runtime** — gitignore |
| `executive/SPRINT_LOCK.json` | **Runtime** — gitignore |
| `executive/APPROVAL_QUEUE.md` | **Runtime** — gitignore (şablonda seed var) |

### Project Intent Gate
`governance/project.config.json` veya yeni `project-intent` alanı F0'da doldurulabilir; canonical charter'a `PROJECT_INTENT_CHARTER.md` eklenebilir (şu an **yok**).

---

## `scripts/`

### Amaç
Bootstrap, scaffold, governance init, factory intelligence, denetim, CI.

~111 script (kök + alt klasörler + APP-FABRIKASI/scripts).

### Runtime mı Core mu?
**Core** — scriptler git'te; çıktıları `runtime/` ve gitignore altında.

---

## `templates/`

### Amaç
Kopyalanan şablonlar — Android Gradle, governance JSON/MD, YAPILACAKLAR.

### İçerik
| Yol | İçerik |
|-----|--------|
| `templates/android/project/` | 10 modül: `app`, `core/*`, `feature/*`, Gradle wrapper |
| `templates/governance/` | project.config, sprint lock, roadmap şablonları |
| `templates/YAPILACAKLAR.template.md` | F0–F8 tabloları |
| `templates/vision/`, `architecture/` | PRODUCT_BRIEF, MODULE_MAP şablonları |

### Runtime mı Core mu?
**Template/core** — dikkatli değiştir; tüm yeni projeleri etkiler.

---

## `factory/`

### Amaç
Factory Intelligence V3 (proof, memory, decision_accuracy, revenue, benchmark) + V4 portfolio/outcomes scaffold.

### İçerik
`proof/`, `memory/`, `portfolio/`, `outcomes/`, `certification/`, `regression/`, `revenue/`, `benchmark/`, `telemetry/`

### Runtime mı Core mu?
- Şablon/README → **git**
- Canlı veri → `runtime/factory/` (**gitignore**)

---

## `APP-FABRIKASI/`

### Amaç
Software Venture Operating System (SVOS) — venture charter, evidence, ULAS decision intelligence, learning.

### İçerik Özeti
| Katman | Rol |
|--------|-----|
| `01-core` … `10-runtime` | PURPOSE.md ile dokümante venture OS katmanları |
| `ULAS/` | Decision engine (`bin/ulas.py`), capability memory, dispatch |
| `scripts/` | `init-venture.sh`, `bridge-venture.sh`, `svos-health.sh` |
| `08-ventures/_template/` | Charter şablonu — canlı venture **gitignore** |
| `02-platforms/android/` | `bridge.defaults.json` — generic Gradle tasks |

### Runtime mı Core mu?
- OS scaffold, ULAS kodu, PURPOSE → **core**
- `08-ventures/*`, `07-evidence/*`, `10-runtime/maturity-report.json` → **runtime/gitignore**

### meta.json özeti
- v2.3.0-capability-memory-v2, STABILIZATION
- `platforms.android`: operational; ios/web/backend: blueprint_frozen
- `first_validation_venture`: null

### Project Intent Gate
SVOS venture intent (slug, codebase path) `venture.json` ile ayrı; **product domain intent** (Android vs Laravel) factory katmanında hâlâ eksik.

---

## `runtime/`

### Amaç
Proje bazlı canlı JSON/raporlar — template repo şişmesin.

### İçerik
`governance/`, `factory/`, `analytics/`, `telemetry/` — init-governance sonrası dolar.

### Runtime mı Core mu?
**Tamamen runtime** — `/runtime/` gitignore; yalnızca `README.md` git'te.

---

## `knowledge/`

### Amaç
Knowledge OS — ADR, pattern, failure, postmortem, venture hikayeleri (git).

### Project Intent Gate
Domain-specific pattern'ler (ör. `knowledge/patterns/experimental/media_app/`) Leo layer'da kalabilir; core'da generic tutulmalı.

---

## Kök dosyalar

| Dosya | Amaç | Sınıf |
|-------|------|-------|
| `README.md` | GitHub ana sayfa (factory + SVOS) | Core |
| `APP-FABRIKA.md` | Canonical repo + SVOS pointer | Core |
| `FACTORY_MISSION.md` | Mission, freeze, success criteria | Core |
| `YAPILACAKLAR.md` | **Uninitialized stub** | Stub → proje planına dönüşür |
| `.cursorrules` | Overmind anayasa | Core |
| `.gitignore` | Runtime/secrets politikası | Core |

---

## 4. Script Analizi

| Script | Ne yapar? | Yazma/destructive? | Etkilediği dosyalar | Aşama | Intent Gate gerekli mi? |
|--------|-----------|-------------------|---------------------|-------|-------------------------|
| `init-new-app.sh` | Kök repoda yeni app bootstrap | **Evet — yoğun overwrite** | `docs/*`, Gradle scaffold köke, `.factory/project.json`, governance, `YAPILACAKLAR.md` | Yeni proje | **Evet — P0** |
| `scaffold-android-project.sh` | Android iskeleti **mevcut köke** | Evet (yeni dosyalar) | `settings.gradle.kts`, modüller | Scaffold | **Evet** |
| `scaffold-android-project-to.sh` | İskelet **hedef dizine** | Evet | Hedef path | Harici scaffold | **Evet** |
| `governance/init-yapilacaklar.sh` | Template → `YAPILACAKLAR.md` | Overwrite `YAPILACAKLAR.md` | `YAPILACAKLAR.md` | Plan başlatma | Önerilir |
| `governance/init-governance.sh` | Executive OS seed | Overwrite runtime governance JSON | `governance/*.json`, `runtime/` | F0 | Hayır (proje meta sonrası) |
| `governance/validate-yapilacaklar.py` | Tek aktif faz, durum sözcüğü | Salt okuma (+ opsiyonel ajan satırı sync) | `YAPILACAKLAR.md` (sync) | Her faz | Hayır |
| `governance/validate-audit-chain.py` | L1/L2 denetim zinciri | Salt okuma | `APPROVAL_QUEUE.md` | F8 / denetle | Hayır |
| `factory-health.sh` | 10 kategori sağlık skoru | Salt okuma | — | first-setup, CI | Hayır |
| `factory-quality-gate.sh` | Bileşik kalite kapısı | Salt okuma | — | CI, denetle | Hayır |
| `first-setup.sh` | İzinler, MCP, hooks, health | Minimal (hooks) | `.git/hooks` | Fabrika ilk kurulum | Hayır |
| `check-mcp.sh` | P0 MCP denetimi | Salt okuma | — | F0 | Hayır |
| `sync-standards.sh` | Fabrikayı hedef projeye rsync | **Evet — hedef overwrite** | `.cursor`, `governance`, `scripts`, `APP-FABRIKASI`, docs… | Mevcut proje | **Evet** |
| `bootstrap-external-project.sh` | AI Studio import | sync + governance + YAPILACAKLAR + prompt | Hedef proje | Harici import | **Evet** |

### `init-new-app.sh` — detaylı analiz

| Soru | Cevap |
|------|--------|
| Çalıştığı repo kökünü uygulama projesine dönüştürüyor mu? | **Evet.** Hedef path parametresi **yok**; `$ROOT` = script'in bulunduğu repo kökü. |
| Hedef path alıyor mu? | **Hayır.** Harici proje için `sync-standards.sh` + `scaffold-android-project-to.sh` veya `bootstrap-external-project.sh` kullanılmalı. |
| Hangi dosyaları overwrite ediyor? | `docs/00-INDEX.md`, `01-VISION/*`, `02-ARCHITECTURE/*` (MODULE_MAP, DATA_FLOW, SECURITY, PENTEST, OEM), `docs/TODO.md` |
| `YAPILACAKLAR.md` yeniden yazılıyor mu? | **Evet** — `init-yapilacaklar.sh` (prompt argümanı **olmadan** — kaynak prompt boş kalır) |
| Android scaffold nasıl ekleniyor? | `scaffold-android-project.sh` → `templates/android/project` → kök dizine kopya |
| `.factory/project.json` nasıl oluşuyor? | Heredoc ile app_name, package, slug, factory_version |
| `init-governance.sh` çağırıyor mu? | **Evet** |
| `init-yapilacaklar.sh` çağırıyor mu? | **Evet** — prompt **geçirilmiyor** |
| Project Intent Gate nerede olmalı? | Script **başında** — factory template reposunda çalışmayı engelle; domain doğrula; onay al |

### `scaffold-android-project.sh` riski

`settings.gradle.kts` varsa exit 1; yoksa tüm template'i köke yazar. Fabrika şablon reposunda yanlışlıkla çalıştırılırsa template repo APK iskeletine dönüşür.

---

## 5. Cursor Rule / Command Tablosu

| Rule/Command | Tür | alwaysApply | Görev | Risk | Intent Gate ilişkisi |
|--------------|-----|-------------|-------|------|----------------------|
| `00-overmind-zero-hallucination.mdc` | Rule | **true** | YAPILACAKLAR kapısı, tek faz | Yüksek | Faz kapısı; domain değil |
| `20-agent-intent-gate.mdc` | Rule | **true** | DIAGNOSTIC vs IMPLEMENTATION | Yüksek | Mesaj modu only |
| `19-claude-reasoning.mdc` | Rule | **true** | Thinking blokları | Orta | Yok |
| `06-mcp-orchestrator.mdc` | Rule | **true** | MCP kurulum | Orta | Yok |
| `01`–`18` ajan kuralları | Rule | false | Departman uzmanlığı | Orta | Domain ajanları intent sonrası |
| `20-aistudio-import.mdc` | Rule | false | AI Studio import | Orta | Harici proje akışı |
| `/baslat` | Command | — | Prompt → YAPILACAKLAR F0–F8 | Yüksek | **Workspace intent eksik** |
| `/yeni-proje` | Command | — | init-new-app + baslat | **Kritik** | **Android intent zorunlu olmalı** |
| `/devam-et` | Command | — | Aktif madde uygula | Orta | Aktif plandaki domain |
| `/denetle` | Command | — | Hiyerarşik audit scriptleri | Düşük | Yok |
| `/faz-durumu` | Command | — | Özet okuma | Yok | Yok |
| `/import-aistudio` | Command | — | Harici bootstrap | Yüksek | Hedef path + Android varsayımı |

### Intent Gate soruları — cevaplar

| Soru | Cevap |
|------|--------|
| `20-agent-intent-gate` yalnızca DIAGNOSTIC/IMPLEMENTATION mı? | **Evet.** Workspace/domain rolü kontrol etmez. |
| Workspace/domain rolünü kontrol ediyor mu? | **Hayır.** |
| `21-project-intent-gate.mdc` hiyerarşiye uyumlu mu? | **Evet** — 20 (mesaj) → 21 (proje/workspace) → 00 (faz) → domain ajanları |
| `/baslat` product prompt öncesi workspace intent doğrulamalı mı? | **Evet** — fabrika şablonunda yanlış prompt + Android F3 varsayımı riski |
| `/yeni-proje` Android app intent zorunlu tutmalı mı? | **Evet** — package + platform alanları zorunlu |

---

## 6. YAPILACAKLAR / F0–F8 Analizi

### Mevcut durum (fabrika şablon reposu)

`YAPILACAKLAR.md` durumu: **`uninitialized` stub**

```html
<!-- yapilacaklar-state: uninitialized -->
```

- Proje/package: *(henüz tanımlanmadı)*
- F0–F8 tabloları: **yok** (bilerek)
- `validate-yapilacaklar.py`: stub için exit 0 (⏸ mesajı)

### Uninitialized stub ne demek?

Fabrika GitHub reposu bir **uygulama planı taşımaz**. Template klonlayan veya fabrikayı kullanan her proje kendi `YAPILACAKLAR.md` instancelarını `/baslat` veya `init-new-app.sh` ile oluşturur.

### F0–F8 fazları

| Faz | Metafor | İçerik |
|-----|---------|--------|
| F0 | Zemin | MCP, governance, hafıza |
| F1 | Kolon | CPO vizyon, pazar, monetizasyon |
| F2 | Kat döşeme | Mimari, modül haritası |
| F3 | Duvar | Android iskelet, core modüller |
| F4 | Cephe | Compose UI, i18n |
| F5 | Güvenlik | Denetim, OEM |
| F6 | Ölçüm | AID Sprint P |
| F7 | İç mekan | Feature WP'ler |
| F8 | Anahtar teslim | CAO + CEO + approval gate |

### Kurallar

- **Aynı anda tek faz `işleniyor`** — `validate-yapilacaklar.py` zorunlu kılar
- Durum sözcükleri: `bekliyor` · `işleniyor` · `tamamlandı`
- Faz → ajan eşlemesi: `governance/phase-agents.json`

### `/baslat` YAPILACAKLAR'ı nasıl değiştiriyor?

1. `init-yapilacaklar.sh "<prompt>"` → template'den dolu F0–F8
2. `init-yapilacaklar.py --prompt` → Kaynak prompt satırı
3. Planner skill → F1/F7 özel maddeler
4. F0 `işleniyor`, F0.1'den başla

### `init-new-app.sh` YAPILACAKLAR'ı nasıl instantiate ediyor?

`init-yapilacaklar.sh` **prompt olmadan** — Kaynak prompt şablonda `*(Geliştirici promptu buraya)*` kalır.

### Product prompt olmadan ne eksik kalır?

- F1 vizyon/monetizasyon maddeleri generic
- PDC roadmap bağlamı zayıf
- F7 feature WP'leri ürüne özel değil
- AI ajanlar yanlış domain varsayımı (Android scaffold zaten eklenmiş)

### Project Intent Gate zamanlaması

| Seçenek | Değerlendirme |
|---------|---------------|
| F0 öncesi | Geç — scaffold zaten oluşmuş olabilir |
| `/baslat` öncesi | **Önerilen** — plan doğru domain ile yazılır |
| `init-new-app` öncesi | **Zorunlu** — destructive bootstrap öncesi |
| Her IMPLEMENTATION öncesi | 20-agent-intent ile birlikte — faz kapısı |

**Öneri:** `init-new-app` ve `/baslat` **öncesi** project intent; IMPLEMENTATION için mevcut 20-agent-intent + YAPILACAKLAR.

---

## 7. Core / Runtime / Generated Sınıflandırma

| Yol | Sınıf | Git'te mi? | Değiştirilebilir mi? | Not |
|-----|-------|------------|----------------------|-----|
| `.cursor/rules/` | Core governance | Evet | Dikkatli | alwaysApply kurallar kritik |
| `.cursor/commands/` | Core workflow | Evet | Dikkatli | Slash protokolleri |
| `.cursor/skills/` | Core workflow | Evet | Dikkatli | |
| `.cursor/mcp.json` | Local | Hayır | Serbest | PAT içerir |
| `.cursorrules` | Core | Evet | Dikkatli | |
| `.factory/meta.json` | Core meta | Evet | Freeze döneminde kısıtlı | |
| `.factory/project.json` | Runtime/local | Hayır | Generated | init-new-app |
| `.factory/bootstrap_manifest.json` | Runtime/local | Hayır | Generated | AI Studio import |
| `.factory/context/SESSION_CONTEXT.md` | Runtime/local | Hayır | Generated | assemble-context |
| `runtime/` | Runtime | Hayır | Generated | Tüm alt ağaç |
| `governance/executive/*.md` | Core charter | Evet | Dikkatli | Protokoller |
| `governance/*.json` (çoğu) | Runtime | Hayır | Generated | init-governance |
| `governance/phase-agents.json` | Core | Evet | Evet | Faz-ajan haritası |
| `governance/dependency-rules.json` | Core | Evet | Dikkatli | |
| `templates/` | Template/core | Evet | Dikkatli | Tüm projeleri etkiler |
| `templates/android/project/` | Template | Evet | Dikkatli | 10 modül scaffold |
| `YAPILACAKLAR.md` | Stub / plan | Evet | Workflow ile | Şablonda uninitialized |
| `docs/03-STANDARDS/` | Core | Evet | Dikkatli | |
| `docs/01-VISION/*.md` (dolu) | Runtime | Hayır | Proje | gitignore |
| `knowledge/` | Core + proje | Evet | Kısmen | Pattern'ler |
| `factory/` (scaffold) | Core | Evet | Freeze | |
| `factory/runtime/` | Runtime | Hayır | — | Legacy yol |
| `APP-FABRIKASI/` (OS) | Core SVOS | Evet | STABILIZATION modunda kısıtlı | |
| `APP-FABRIKASI/08-ventures/*` | Runtime | Hayır | init-venture | gitignore |
| `APP-FABRIKASI/10-runtime/*` | Runtime | Kısmen | Generated | .gitkeep only |
| `gradlew`, `app/`, `core/` (köke scaffold sonrası) | **Proje kodu** | Proje reposunda | Evet | Fabrika şablonda olmamalı |

---

## 8. Domain Kapsamı

### Bu repo Android-first bir app factory mi?

**Evet — operasyonel olarak Android-first.**

| Alan | Durum | Kanıt |
|------|--------|-------|
| Android | **Operational** | `templates/android/project/`, Gradle scripts, 03-android-elite, OEM standartları |
| Web | Blueprint only | `APP-FABRIKASI/meta.json` → `web: blueprint_frozen`; kök README'de "gelecek fabrika" |
| iOS | Blueprint only | SVOS meta `ios: blueprint_frozen` |
| Laravel/MySQL | **Yok** | Repoda Laravel scaffold, PHP, MySQL template bulunamadı |
| Existing project import | **Var** | `sync-standards.sh`, `bootstrap-external-project.sh` |
| AI Studio import | **Var** | `/import-aistudio`, `docs/AI_STUDIO_IMPORT.md` |
| Full-stack factory | **Hayır** | Yalnızca Android Gradle + governance + SVOS venture layer |

### Web/Laravel/SEO/CRO (Leo) — core'a gömülmeli mi?

**Hayır — Leo Compatibility Layer'da kalmalı.**

Gerekçe:
- `FACTORY_MISSION.md` ve `.factory/meta.json` freeze + Android product validation odaklı
- F3–F4 fazları Android Compose/i18n'e kilitli
- `phase-agents.json` Android-centric L1 kuralları (`android` → CPO)
- Core'a Leo gate gömülürse template her projede Laravel/SEO varsayımı taşır — Mavi Okyanus "fabrika ≠ ürün" ilkesini ihlal eder

---

## 9. Project Intent Gate Entegrasyon Analizi

### 1. Gerekli mi?

**Evet** — özellikle `init-new-app.sh`'ın fabrika şablon kökünde çalıştırılması ve `/baslat`'ın domain seçimi olmadan Android F0–F8 üretmesi risk oluşturuyor.

### 2. Hangi problemi çözer?

| Problem | Açıklama |
|---------|----------|
| Yanlış workspace bootstrap | Factory template repo APK iskeletine dönüşür |
| Domain karışıklığı | Web/Laravel promptu → Android scaffold + Gradle |
| Boş product prompt | `init-new-app` Kaynak prompt doldurmaz |
| Konuşma bağlamı | Önceki chat Android varsayımı yeni domain için geçerli sayılabilir |
| Leo vs Factory | Domain-özel gate'lerin core'a sızması |

### 3–12. Teknik öneriler

| # | Soru | Öneri |
|---|------|--------|
| 3 | Core'a neler eklenir? | `21-project-intent-gate.mdc`, `.factory/project-intent.example.json`, `validate-project-intent.py`, F0.0 madde |
| 4 | Leo layer'da neler kalır? | Laravel/SEO/CRO/MySQL özel kurallar, Leo gate extensions |
| 5 | `21-project-intent-gate.mdc` doğru mu? | **Evet** — `20` mesaj modu, `21` workspace/domain |
| 6 | `.factory/project-intent.example.json` yeri? | **Evet** — `.factory/` yanında `project.json` ile simetrik |
| 7 | `project-intent.json` gitignore? | **Evet** — `.factory/project.json` gibi |
| 8 | `validate-project-intent.py` nerede? | `scripts/governance/validate-project-intent.py` |
| 9 | `init-new-app.sh` hook? | **Evet — script başı** — template repo guard + intent zorunlu |
| 10 | `scaffold-android-project.sh` hook? | **Evet** — `platform: android` intent doğrulaması |
| 11 | `/baslat`, `/yeni-proje` güncelleme? | Intent soru seti + validate; web projede Android scaffold yasak |
| 12 | 20 vs 21 ayrımı? | **20:** bu mesaj kod mu soru mu? **21:** bu workspace hangi ürün/platform? |

### Öneri tablosu

| Öneri | Core'a? | Leo Layer? | Gerekçe | Risk |
|-------|---------|------------|---------|------|
| `21-project-intent-gate.mdc` | **Evet** | Hayır | Tüm projelerde workspace doğrulama | Düşük |
| `project-intent.json` schema | **Evet** (example) | Hayır | Makine okunur intent | Düşük |
| `validate-project-intent.py` | **Evet** | Hayır | CI + F0 kapısı | Düşük |
| `init-new-app` guard | **Evet** | Hayır | Template repo koruma | Orta — breaking if misused |
| Laravel/SEO/CRO gates | Hayır | **Evet** | Domain-specific | Core şişmesi |
| Web scaffold template | Hayır | **Evet** (gelecek) | Android factory misyonu dışı | Yüksek karmaşıklık |
| SVOS `venture.json` platform alanı | **Evet** (genişletme) | Kısmen | Venture-level intent | Düşük |

---

## 10. Eksikler, Riskler, Düzeltmeler

## Eksikler

- `21-project-intent-gate.mdc` — tanımlı değil
- `.factory/project-intent.example.json` — yok
- `scripts/governance/validate-project-intent.py` — yok
- `init-new-app.sh` hedef path parametresi — yok (harici proje için alternatif scriptler gerekli)
- `init-new-app.sh` → `init-yapilacaklar.sh` prompt geçişi — yok
- Web/iOS operasyonel scaffold — yok (yalnızca blueprint)
- `governance/PROJECT_INTENT_CHARTER.md` — yok
- Fabrika şablon reposunda `settings.gradle.kts` guard — init-new-app sonrası fabrika kirlenirse geri dönüş manuel

## Riskler

| Seviye | Risk | Etki | Öneri |
|--------|------|------|-------|
| **Kritik** | `init-new-app.sh` fabrika template kökünde çalıştırılır | Template repo APK iskeletine dönüşür; GitHub template bozulur | Project intent + `meta.type=factory` guard |
| **Yüksek** | `/baslat` domain seçimi yok | Web/Laravel prompt → Android F3–F8 planı | 21-project-intent + planner skill güncelle |
| **Yüksek** | Önceki konuşma bağlamı | Yeni domain için Android varsayımı | SESSION_CONTEXT + intent reset |
| **Orta** | `scaffold-android-project.sh` doğrudan çalışır | Kökte Gradle oluşur | Intent gate + onay |
| **Orta** | Dual remote (`Android-App` vs `APP-FABRIKA`) | Dokümantasyon/karışıklık | Tek canonical: APP-FABRIKA |
| **Orta** | `runtime/` vs `governance/*.json` | İki runtime yolu | FACTORY_REPO_POLICY okuma sırası |
| **Düşük** | Yerel `ulas-player` venture klasörleri | IDE sync; gitignore ile commit edilmez | `.gitignore` yeterli |

## Düzeltilmesi Gerekenler

| Alan | Sorun | Önerilen Düzeltme | Öncelik |
|------|-------|-------------------|---------|
| `init-new-app.sh` | Prompt geçirilmiyor | `init-yapilacaklar.sh "$APP_NAME vision"` veya ayrı argüman | P1 |
| `init-new-app.sh` | Template repo guard yok | `meta.json type=factory` ise exit veya `--force` | P0 |
| `/yeni-proje` | Android zorunluluğu implicit | Explicit platform + package validation | P0 |
| `/baslat` | Product-only, workspace yok | F0.0 project intent adımı | P0 |
| `YAPILACAKLAR` F0 | Intent maddesi yok | F0.0 `validate-project-intent.py` | P1 |
| `bootstrap-external-project.sh` | `FACTORY_REPO` default eski isim | README ile uyumlu APP-FABRIKA path | P2 |
| `governance/README.md` | Sürüm v2.1.0 vs meta v3.1.0 | Belge senkronu | P3 |

---

## 11. Uygulama Üretim Akışı (Özet Diyagram)

```
GitHub Template (APP-FABRIKA)
        │
        ├─► first-setup.sh (fabrika sağlık, MCP, hooks)
        │
        ├─► [Yol A] init-new-app.sh "App" com.pkg
        │         └─► docs + Gradle scaffold + governance + YAPILACAKLAR
        │
        ├─► [Yol B] /baslat + prompt
        │         └─► init-yapilacaklar + F0–F8 plan
        │
        ├─► [Yol C] sync-standards.sh /hedef
        │         └─► mevcut Android projesine fabrika kopyala
        │
        ├─► [Yol D] bootstrap-external-project.sh (AI Studio)
        │
        └─► /devam-et → F0…F8 maddeler
                  └─► /denetle → validate-* + CAO + approval gate
                            └─► F8 release gate
```

**SVOS paralel akış:**

```
init-venture.sh → bridge-venture.sh → evidence → ULAS decide/work/dispatch → svos-health.sh
```

---

## 12. Komut Referansı (Kullanıcı Sorusu)

| Komut | Özet |
|-------|------|
| `/baslat` | Promptu F0–F8 `YAPILACAKLAR.md` planına çevirir; F0 başlar; kod yok |
| `/yeni-proje` | `init-new-app.sh` + plan; tam bootstrap |
| `/devam-et` | Aktif fazın sıradaki maddesini uygular |
| `/denetle` | validate-yapilacaklar, audit-chain, roadmap, CAO, approval gate |
| `/faz-durumu` | Plan özeti — salt okuma |
| `/import-aistudio` | Harici Android export'a fabrika standartları |

---

# EXECUTIVE SUMMARY

## Repo Hakkında Nihai Teşhis

**APP-FABRIKA**, Android uygulamaları üretmek için tasarlanmış **donmuş (FROZEN / MAINTENANCE)** bir **GitHub template factory** reposudur. Uygulama kodu repoda yaşamaz; standartlar, 16 Cursor ajanı, 33 katman governance, Executive OS ve Gradle scaffold şablonları burada tutulur. Üzerine **APP-FABRIKASI (SVOS)** taşınabilir venture katmanı eklenmiştir — charter, evidence, ULAS karar zekâsı. Repoda örnek venture veya validation verisi bilerek yoktur.

Fabrika şu an **Android-first**; web/iOS/backend yalnızca SVOS blueprint düzeyinde. Laravel/full-stack factory değildir.

## Project Intent Gate Gerekli mi?

**Evet.**

`20-agent-intent-gate` yalnızca *bu mesaj kod mu soru mu* ayrımı yapar; *bu workspace hangi ürün/platform* sorusunu yanıtlamaz. `init-new-app.sh` destructive bootstrap'i hedef path olmadan kök repoda çalışır; `/baslat` domain gate olmadan Android-merkezli F0–F8 üretir. Leo-tipi domain gate'leri core'a değil, compatibility layer'a ait olmalıdır.

## Öncelikli 5 Düzeltme

1. **`init-new-app.sh` factory template guard** — `meta.type=factory` iken scaffold'u engelle veya `--target` zorunlu kıl
2. **`21-project-intent-gate.mdc` + `validate-project-intent.py`** — workspace/domain doğrulama
3. **`/baslat` ve `/yeni-proje` komut güncellemesi** — intent onayı olmadan plan/bootstrap yok
4. **`init-new-app` → prompt geçişi** — Kaynak prompt boş kalmasın
5. **F0.0 YAPILACAKLAR maddesi** — project intent validate kapısı

## APP-FABRIKA Core'a Eklenmesi Gerekenler

- `21-project-intent-gate.mdc`
- `.factory/project-intent.example.json`
- `scripts/governance/validate-project-intent.py`
- `init-new-app.sh` / `scaffold-android-project.sh` intent hook'ları
- `YAPILACAKLAR.template.md` F0.0 satırı
- Fabrika template repo koruma (factory meta guard)

## Leo Compatibility Layer'da Kalması Gerekenler

- Laravel / MySQL / PHP scaffold ve kuralları
- SEO / CRO / web-specific gate'ler
- Web-first veya full-stack faz şablonları
- Domain-özel Leo prompt ve validation mantığı

## Sıradaki En Doğru Adım

1. **DIAGNOSTIC onay** — bu raporu Principal Architect ile gözden geçir
2. **IMPLEMENTATION** — Project Intent Gate minimal paketi (21-kural + example JSON + validate script + init-new-app guard)
3. Fabrika şablon reposunda **asla** `init-new-app.sh` çalıştırmadan önce hedefin uygulama reposu olduğunu doğrula
4. Yeni uygulama için: GitHub **Use this template** → klon → `first-setup.sh` → `init-new-app.sh` veya `/yeni-proje`
5. Mevcut Android projesi için: `sync-standards.sh` + `init-governance.sh` + `/baslat`

---

*Rapor sonu — yalnızca `docs/APP_FABRIKA_REPO_INTELLIGENCE_REPORT.md` oluşturuldu; repo davranışı değiştirilmedi.*
