<div align="center">

<!-- Hero -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/🏭_Android_Factory-v3.1.0-2563eb?style=for-the-badge&labelColor=0f172a">
  <img alt="Ulas Autonomous Android APP Factory v3.1.0" src="https://img.shields.io/badge/🏭_Android_Factory-v3.1.0-2563eb?style=for-the-badge">
</picture>

<br><br>

# Ulas Autonomous Android APP Factory

<h3>
  <em>Android Factory · Software Venture OS · Cursor-native · GitHub Template</em>
</h3>

<p>
  <strong>🇹🇷</strong> Android uygulamalarını aynı mühendislik disipliniyle üreten<br>
  <strong>standart, governance, intelligence ve Gradle fabrika şablonu</strong> —<br>
  üzerine taşınabilir <strong>Software Venture OS</strong> (<code>APP-FABRIKASI/</code>) katmanı.<br>
  Plan onaylanmadan kod üretilmez; örnek venture veya validation verisi repoda tutulmaz.
</p>

<p>
  <strong>🇬🇧</strong> A production-grade <strong>standards, governance, intelligence & Gradle factory template</strong><br>
  with a portable <strong>Software Venture OS</strong> (<code>APP-FABRIKASI/</code>) for venture lifecycle,<br>
  evidence, and ULAS decision intelligence — no sample app or pre-seeded venture data in git.
</p>

<br>

<p>
  <a href="#turkce"><strong>🇹🇷 Türkçe</strong></a>
  &nbsp;·&nbsp;
  <a href="#english"><strong>🇬🇧 English</strong></a>
</p>

<br>

[![Version](https://img.shields.io/badge/sürüm-3.1.0-2563eb?style=flat-square)](.factory/meta.json)
[![License](https://img.shields.io/badge/lisans-MIT-059669?style=flat-square)](LICENSE)
[![Factory Health](https://img.shields.io/badge/factory_health-100%2F100-16a34a?style=flat-square)](docs/FACTORY_SCORECARD.md)
[![CI](https://img.shields.io/github/actions/workflow/status/clariongemini/APP-FABRIKA/validate.yml?branch=main&label=CI&style=flat-square)](https://github.com/clariongemini/APP-FABRIKA/actions/workflows/validate.yml)

<br>

[![Mission](https://img.shields.io/badge/mission-ship_products-0f766e?style=flat-square)](FACTORY_MISSION.md)
[![33 Layers](https://img.shields.io/badge/33_katman-360_bileşen-6366f1?style=flat-square)](docs/33-LAYER-ARCHITECTURE.md)
[![Executive OS](https://img.shields.io/badge/Executive_OS-7.0-8b5cf6?style=flat-square)](docs/EXECUTIVE_OS.md)
[![Agents](https://img.shields.io/badge/Cursor_ajanları-16-0ea5e9?style=flat-square)](AGENTS.md)
[![SVOS](https://img.shields.io/badge/SVOS-APP--FABRIKASI-7c3aed?style=flat-square)](APP-FABRIKASI/README.md)
[![MCP](https://img.shields.io/badge/MCP-Browser_·_GitHub-64748b?style=flat-square)](docs/MCP_SETUP.md)

<br><br>

<table>
<tr>
<td align="center" width="33%">
  <strong>📋 Plan önce</strong><br>
  <sub>YAPILACAKLAR F0–F8 faz kapısı</sub>
</td>
<td align="center" width="33%">
  <strong>🛡️ Denetim zinciri</strong><br>
  <sub>16 ajan · hiyerarşik audit · halüsinasyon sıfır</sub>
</td>
<td align="center" width="33%">
  <strong>📦 Ürün odaklı</strong><br>
  <sub>Portfolio · Outcomes · Play Store KPI</sub>
</td>
</tr>
</table>

<br>

**[Use this template](https://github.com/clariongemini/APP-FABRIKA/generate)** ·
**[SVOS](APP-FABRIKASI/README.md)** ·
**[Bootstrap](docs/BOOTSTRAP.md)** ·
**[Factory Mission](FACTORY_MISSION.md)** ·
**[Executive OS](docs/EXECUTIVE_OS.md)** ·
**[Ajanlar / Agents](AGENTS.md)** ·
**[Yazar / Author](docs/AUTHOR.md)**

<br>

<sub>
  <strong>Fabrika ≠ APK</strong> · Bu repo uygulama kodu değil; standartlar ve şablonlar burada yaşar.<br>
  <strong>Factory ≠ APK</strong> · Application code lives in your project — via <code>init-new-app.sh</code> or <code>sync-standards.sh</code>.
</sub>

</div>

---

<a id="turkce"></a>

## 🇹🇷 Türkçe

**Ulas Autonomous Android APP Factory**, Android uygulamalarını her seferinde aynı mühendislik disipliniyle üretmek için tasarlanmış **GitHub template fabrika reposudur**. Cursor Agent Mode üzerinde çalışır: **16 departman ajanı**, **33 katmanlı governance**, **Executive OS**, otomatik kalite kapıları ve **Factory Intelligence** katmanı ile karar → mimari → kod → denetim → ölçüm → **ürün sonucu** zinciri yönetilir.

Fabrika tek başına bir uygulama değildir. Bu repoda APK yaşamaz; `templates/android/project/` altındaki **10 modüllü Gradle iskeleti**, `init-new-app.sh` veya `sync-standards.sh` ile hedef projenize aktarılır. Governance ve intelligence verileri proje bazlı `runtime/` ağacında tutulur — fabrika şablonu temiz kalır.

**Software Venture OS:** [`APP-FABRIKASI/`](APP-FABRIKASI/README.md) taşınabilir venture katmanıdır (ULAS, evidence, learning, portfolio). Repoda **hazır venture yok** — her projede `init-venture.sh` ile charter oluşturulur; runtime raporları `.gitignore` ile commit edilmez.

**North star:** [`FACTORY_MISSION.md`](FACTORY_MISSION.md) — *Factory'nin amacı daha fazla governance üretmek değil, daha kısa sürede daha başarılı Android ürünleri üretmektir.*

| Meta | Değer |
|------|-------|
| **Yazar** | [Ulaş Kaşıkcı](docs/AUTHOR.md) |
| **Lisans** | [MIT](LICENSE) |
| **Sürüm** | v3.1.0-intelligence-operational |
| **Durum** | Development freeze — 3 production release sonrası meta-genişleme |

### Platform yol haritası ve AI referans kütüphanesi

Bu repo **Android** için Software Venture Operating System'tir. Gelecekte planlanan varyasyonlar:

| Platform | Hedef repo (plan) | Not |
|----------|-------------------|-----|
| **Android** | Bu repo (`APP-FABRIKA`) | Aktif — Gradle, Compose, Play Store, SVOS |
| **iOS** | Ayrı fabrika şablonu | SwiftUI, SPM, App Store parity |
| **Web** | Ayrı fabrika şablonu | React/Next veya eşdeğer stack |
| **Claude / Agent** | Kural ve context katmanları | Cursor rules + Knowledge OS |

**Harici bilgi kütüphanesi:** Gelişmiş AI ajan tasarımı (context engineering, tool disiplini, intent gate) için [CL4R1T4S](https://github.com/elder-plinius/CL4R1T4S) referans alınabilir — *prompt kopyalama değil*, tasarım prensibi gözlemi. Bu fabrikanın kendi kuralları: `.cursor/rules/`, [`docs/KNOWLEDGE_OS.md`](docs/KNOWLEDGE_OS.md), [`docs/LEARNING_FACTORY.md`](docs/LEARNING_FACTORY.md).

> CL4R1T4S şeffaflık arşividir; jailbreak veya sızdırılmış prompt'ları repoya yapıştırmayın.

### Ne sağlar?

- **APP-FABRIKASI (SVOS)** — Taşınabilir venture OS: charter → evidence → ULAS → learning ([`APP-FABRIKASI/README.md`](APP-FABRIKASI/README.md))
- **YAPILACAKLAR (F0–F8)** — Plan onaylanmadan kod üretilmez; aynı anda tek faz `işleniyor`
- **16 departman ajanı** — CPO, Baş Mimar, Android Elite, güvenlik, OEM, CEO/CAO/EGC…
- **33 katman · 360 bileşen** — Merkezi denetim çerçevesi (`docs/33-LAYER-ARCHITECTURE.md`)
- **10 modüllü Android iskeleti** — Compose, Clean Architecture, billing, FCM, güvenlik, i18n
- **Factory Intelligence (V3)** — Proof, memory, decision accuracy, revenue, benchmark motorları
- **Product Portfolio (V4)** — Kayıt, sertifikasyon, regression DB, **outcomes** (kullanıcı, retention, gelir, ROI)
- **Halüsinasyon sıfır** — CI, pre-commit, audit scriptleri; dosya okumadan referans yasak
- **MCP (P0)** — Browser + GitHub ile pazar, CI ve dokümantasyon doğrulama

### Hızlı başlangıç

> **Önce:** [Safe Start — Project Intent First](#safe-start-project-intent-first) · [`docs/PROJECT_INTENT_GATE.md`](docs/PROJECT_INTENT_GATE.md)

**Yeni Android uygulaması**

```bash
./scripts/first-setup.sh
# Cursor → /prompt-genesis → android-app intent kilidi
# Sonra → /yeni-proje veya init-new-app.sh
# Cursor → /baslat
```

**Mevcut projeye fabrika + SVOS**

```bash
./scripts/sync-standards.sh /path/to/existing-project
cd /path/to/existing-project && ./scripts/governance/init-governance.sh
./APP-FABRIKASI/scripts/init-venture.sh "My App" my-app .
./APP-FABRIKASI/scripts/svos-health.sh
```

**Yalnızca SVOS katmanı**

```bash
./APP-FABRIKASI/scripts/install-svos-into-project.sh /path/to/project
```

### Kalite kapısı

| Kapı | Komut | Hedef |
|:---|:---|:---:|
| Fabrika sağlığı | `./scripts/factory-health.sh` | **100 / 100** |
| Bileşik denetim | `./scripts/factory-quality-gate.sh` | CI + pre-commit |
| Smoke denetimi | `./scripts/run-factory-audit.sh` | 40+ kontrol · template build |

### Türkçe içindekiler

| Bölüm |
|-------|
| [Neden Cursor?](#neden-cursor) |
| [Cursor entegrasyonu](#cursor-entegrasyonu) |
| [Ne kazandırır?](#ne-kazandırır) |
| [Sistem Özeti](#sistem-özeti) |
| [Ne Sunar?](#ne-sunar) |
| [Mimari Akış](#mimari-akış) |
| [Adım Adım Kurulum](#adım-adım-kurulum-türkçe) |
| [Repo Haritası](#repo-haritası) |
| [YAPILACAKLAR F0–F8](#yapilacaklar-f0f8) |
| [Ajanlar & Executive OS](#ajanlar--executive-os) |
| [Android İskeleti](#android-i̇skeleti-10-modül) |
| [Doğrulama & Kalite](#doğrulama--kalite-kapısı) |
| [Kullanım Senaryoları](#kullanım-senaryoları) |
| [Belge Dizini](#belge-dizini) |
| [Safe Start — Project Intent](#safe-start-project-intent-first) |

> **İlk kez mi bakıyorsun?** Bu repo bir APK değil. Önce `/prompt-genesis` ile workspace rolünü kilitle; sonra `/baslat` ile faz planı açılır. Kurulum: [Bootstrap](docs/BOOTSTRAP.md).

<a id="safe-start-project-intent-first"></a>

### Safe Start: Project Intent First

APP-FABRIKA, açık bir project intent kilidi olana kadar **factory/template workspace**'tir. Eski konuşma bağlamı project intent değildir.

Uygulama oluşturmadan veya product genesis çalıştırmadan önce:

1. Workspace'i Cursor'da açın.
2. `/prompt-genesis` çalıştırın.
3. `workspace_role` seçin: `factory-template` · `android-app` · `web-app` · `laravel-mysql-fullstack` · `existing-project-import` · `test-sandbox`
4. Android için `project_name` ve `package_name` onaylayın.
5. Seçilen intent'e göre `/yeni-proje`, `init-new-app.sh` veya `/baslat` kullanın.
6. İşlem sonrası özet değerlendirmesi: `/cevap` veya `/after-action`

Geçerli `.factory/project-intent.json` olmadan destructive genesis/scaffold komutları **bloklanır**.

| Belge | Açıklama |
|-------|----------|
| [PROJECT_INTENT_GATE.md](docs/PROJECT_INTENT_GATE.md) | Workspace rolü ve intent kilidi |
| [CEVAP_REPORT_CONTRACT.md](docs/CEVAP_REPORT_CONTRACT.md) | After Action Review contract |
| [prompt-genesis](.cursor/commands/prompt-genesis.md) | Intent seçim komutu |
| [cevap](.cursor/commands/cevap.md) · [after-action](.cursor/commands/after-action.md) | AAR komutları |

<p align="center"><a href="#english">↓ English section</a></p>

---

<a id="english"></a>

## 🇬🇧 English

**Ulas Autonomous Android APP Factory** is a **GitHub template factory repository** built to ship Android apps under the same engineering discipline — every time. It runs on **Cursor Agent Mode**: a **16-agent department model**, **33-layer governance**, **Executive OS**, automated quality gates, and a **Factory Intelligence** layer orchestrate the decide → design → build → audit → measure → **product outcome** pipeline.

The factory is not an application. No APK lives here; the **10-module Gradle scaffold** under `templates/android/project/` is copied to your target project via `init-new-app.sh` or `sync-standards.sh`. Governance and intelligence data live in a per-project `runtime/` tree — the factory template stays clean with no sample app names baked in.

**North star:** [`FACTORY_MISSION.md`](FACTORY_MISSION.md) — *The factory exists to ship successful Android products faster, not to produce more governance.*

| Meta | Value |
|------|-------|
| **Author** | [Ulaş Kaşıkcı](docs/AUTHOR.md) |
| **License** | [MIT](LICENSE) |
| **Version** | v3.1.0-intelligence-operational |
| **Status** | Development freeze — meta expansion after 3 production releases |

### Platform roadmap & AI reference library

This repo is the **Android** Software Venture OS. Planned factory variants:

| Platform | Target repo (planned) | Notes |
|----------|----------------------|-------|
| **Android** | This repo (`APP-FABRIKA`) | Active — Gradle, Compose, Play Store, SVOS |
| **iOS** | Separate factory template | SwiftUI, SPM, App Store parity |
| **Web** | Separate factory template | React/Next or equivalent stack |
| **Claude / Agents** | Rules & context layers | Cursor rules + Knowledge OS |

**External knowledge library:** For advanced agent design patterns (context engineering, tool discipline, intent gates), see [CL4R1T4S](https://github.com/elder-plinius/CL4R1T4S) — observe **design principles**, do not copy proprietary prompts. This factory's canonical rules live in `.cursor/rules/`, [`docs/KNOWLEDGE_OS.md`](docs/KNOWLEDGE_OS.md), and [`docs/LEARNING_FACTORY.md`](docs/LEARNING_FACTORY.md).

> CL4R1T4S is a transparency archive; do not paste leaked prompts or jailbreaks into this repo.

### What you get

- **YAPILACAKLAR (F0–F8)** — No code before an approved phase plan; only one phase `in progress` at a time
- **16 department agents** — CPO, Chief Architect, Android Elite, security, OEM, CEO/CAO/EGC…
- **33 layers · 360 components** — Central governance framework (`docs/33-LAYER-ARCHITECTURE.md`)
- **10-module Android scaffold** — Compose, Clean Architecture, billing, FCM, security, i18n
- **Factory Intelligence (V3)** — Proof, memory, decision accuracy, revenue, benchmark motors
- **Product Portfolio (V4)** — Registry, certification, regression DB, **outcomes** (users, retention, revenue, ROI)
- **Zero-hallucination protocol** — CI, pre-commit, audit scripts; no references without reading files
- **MCP (P0)** — Browser + GitHub for market research, CI, and documentation verification

### Quick start

> **First:** [Safe Start — Project Intent First](#safe-start-project-intent-first-en) · [`docs/PROJECT_INTENT_GATE.md`](docs/PROJECT_INTENT_GATE.md)

**New Android app**

```bash
./scripts/first-setup.sh
# Cursor → /prompt-genesis → lock android-app intent
# Then → /yeni-proje or init-new-app.sh
# Cursor → /baslat
```

**Existing project + factory + SVOS**

```bash
./scripts/sync-standards.sh /path/to/existing-project
cd /path/to/existing-project && ./scripts/governance/init-governance.sh
./APP-FABRIKASI/scripts/init-venture.sh "My App" my-app .
./APP-FABRIKASI/scripts/svos-health.sh
```

**SVOS layer only**

```bash
./APP-FABRIKASI/scripts/install-svos-into-project.sh /path/to/project
```

### Quality gate

| Gate | Command | Target |
|:---|:---|:---:|
| Factory health | `./scripts/factory-health.sh` | **100 / 100** |
| Composite audit | `./scripts/factory-quality-gate.sh` | CI + pre-commit |
| Smoke audit | `./scripts/run-factory-audit.sh` | 40+ checks · template build |

### English table of contents

| Section |
|---------|
| [Why Cursor?](#why-cursor-en) |
| [How It Works in Cursor](#cursor-entegrasyonu) |
| [What You Gain](#what-you-gain-en) |
| [System Overview](#system-overview-en) |
| [What It Delivers](#what-it-delivers-en) |
| [Architecture Flow](#architecture-flow-en) |
| [Step-by-Step Setup](#step-by-step-setup-english) |
| [Repository Map](#repository-map-en) |
| [YAPILACAKLAR Phases](#yapilacaklar-phases-en) |
| [Agents & Executive OS](#agents--executive-os-en) |
| [Android Scaffold](#android-scaffold-10-modules-en) |
| [Validation & Quality Gate](#validation--quality-gate-en) |
| [Usage Scenarios](#usage-scenarios-en) |
| [Documentation Index](#documentation-index-en) |
| [Safe Start — Project Intent](#safe-start-project-intent-first-en) |

> **First time here?** This repo is not an APK. Lock workspace role with `/prompt-genesis` first; then `/baslat` opens the phase plan. Setup: [Bootstrap](docs/BOOTSTRAP.md).

<a id="safe-start-project-intent-first-en"></a>

### Safe Start: Project Intent First

APP-FABRIKA is a **factory/template workspace** until a project intent is explicitly locked. Old conversation context is not project intent.

Before creating an app or running product genesis:

1. Open the workspace in Cursor.
2. Run `/prompt-genesis`.
3. Select `workspace_role`: `factory-template` · `android-app` · `web-app` · `laravel-mysql-fullstack` · `existing-project-import` · `test-sandbox`
4. For Android apps, confirm `project_name` and `package_name`.
5. Then use `/yeni-proje`, `init-new-app.sh`, or `/baslat` according to the selected intent.
6. After execution summaries, review with `/cevap` or `/after-action`.

Without a valid `.factory/project-intent.json`, destructive genesis/scaffold commands are **blocked**.

| Doc | Purpose |
|-----|---------|
| [PROJECT_INTENT_GATE.md](docs/PROJECT_INTENT_GATE.md) | Workspace role and intent lock |
| [CEVAP_REPORT_CONTRACT.md](docs/CEVAP_REPORT_CONTRACT.md) | After Action Review contract |
| [prompt-genesis](.cursor/commands/prompt-genesis.md) | Intent selection command |
| [cevap](.cursor/commands/cevap.md) · [after-action](.cursor/commands/after-action.md) | AAR review commands |

<p align="center"><a href="#turkce">↑ Türkçe bölüm</a></p>

---

## Neden Cursor?

Fabrika Cursor Agent kurallarına göre çalışır; düz sohbet LLM'i ile aynı şey değil.

| Özellik | Genel AI sohbet | Bu fabrika (Cursor) |
|---------|-----------------|---------------------|
| Proje hafızası | Her oturum sıfırdan | `.cursorrules` + `docs/00-INDEX.md` kalıcı |
| Rol bazlı uzmanlık | Tek genel asistan | **16 departman ajanı** (CPO, Baş Mimar, Android…) |
| Halüsinasyon kontrolü | Kullanıcıya bağlı | **Zorunlu** — dosya okumadan referans yasak |
| İş akışı | Serbest sohbet | **YAPILACAKLAR F0–F8** faz kapısı |
| Denetim | Yok | **Hiyerarşik audit** — tek ajan onayı yasak |
| Gerçek dünya verisi | Sınırlı | **MCP**: Browser, GitHub, Docker |
| Komutlar | Yok | `/baslat` `/devam-et` `/denetle` `/faz-durumu` |
| Otomatik doğrulama | Yok | `pre-commit` + CI + `factory-quality-gate.sh` + `run-factory-audit.sh` |

**Cursor yoksa** bu repo statik dokümantasyon + Gradle şablonu. **Cursor varsa** YAPILACAKLAR, ajanlar ve denetim scriptleri devreye girer.

---

## Why Cursor? (EN) {#why-cursor-en}

Same factory; English labels in tables below. Expects Cursor Agent rules—not a generic chat session.

| Feature | Generic AI chat | This factory (Cursor) |
|---------|-----------------|------------------------|
| Project memory | Resets each session | Persistent via `.cursorrules` + `docs/00-INDEX.md` |
| Role-based expertise | One general assistant | **16 department agents** (CPO, Architect, Android…) |
| Hallucination control | User-dependent | **Mandatory** — no file references without reading |
| Workflow | Free-form chat | **YAPILACAKLAR F0–F8** phase gate |
| Audit | None | **Hierarchical audit** — single-agent approval forbidden |
| Real-world data | Limited | **MCP**: Browser, GitHub, Docker |
| Commands | None | `/baslat` `/devam-et` `/denetle` `/faz-durumu` |
| Automated validation | None | `pre-commit` + CI + `factory-quality-gate.sh` + `run-factory-audit.sh` |

**Without Cursor:** static docs + template. **With Cursor:** phase gates, agents, audit scripts.

---

## Cursor entegrasyonu

```mermaid
flowchart TB
    subgraph CursorIDE["Cursor IDE"]
        USER["Geliştirici"]
        CHAT["Chat + Agent Mode"]

        subgraph Rules["Always-on Rules"]
            CR[".cursorrules — Overmind"]
            R00["00-zero-hallucination.mdc"]
            R01["01–17 agent .mdc files"]
        end

        subgraph Commands["Slash Commands"]
            C1["/baslat"]
            C2["/devam-et"]
            C3["/denetle"]
            C4["/faz-durumu"]
        end

        subgraph Skills["Agent Skills"]
            S1["yapilacaklar-planner"]
            S2["yapilacaklar-executor"]
            S3["zero-hallucination"]
            S4["hierarchical-audit"]
        end

        subgraph Subagents["Subagents (L1 verify)"]
            A1["phase-verifier"]
            A2["phase-auditor"]
            A3["hallucination-guard"]
        end

        subgraph MCP["MCP Servers"]
            M1["Browser — pazar/OEM"]
            M2["GitHub — CI/PR"]
            M3["Docker — build"]
        end

        USER --> CHAT
        CHAT --> Commands
        Commands --> Skills
        Skills --> Rules
        Rules --> Subagents
        CHAT --> MCP
        Subagents --> YAP["YAPILACAKLAR.md"]
        MCP --> GOV["governance/"]
    end
```

### Cursor oturum akışı / Cursor session flow

```mermaid
sequenceDiagram
    participant U as Geliştirici / Developer
    participant C as Cursor Agent
    participant O as Overmind (.cursorrules)
    participant Y as YAPILACAKLAR.md
    participant A as Departman Ajanları
    participant M as MCP (Browser/GitHub)
    participant G as Governance Scripts

    U->>C: /baslat + ürün promptu
    C->>O: Kuralları yükle
    O->>Y: F0 işleniyor — plan oku
    C->>A: CPO → vizyon belgeleri
    A->>M: Rakip/pazar araştırması (Browser)
    C->>A: Baş Mimar → MODULE_MAP
    C->>A: Android → kod üretimi
    A->>G: validate-yapilacaklar.py
    G-->>C: ✅ Faz geçerli
    C->>U: L1 doğrulama özeti
    U->>C: /devam-et
    C->>Y: Sonraki faz işleniyor
```

### Kullanıcı yolculuğu / User journey

```
  GitHub Template                Cursor IDE                    Çıktı / Output
  ─────────────────              ───────────                   ──────────────

  [Use this template]  ──►  [first-setup.sh]     ──►  MCP + hooks hazır
         │                  [init-new-app.sh]    ──►  Android 10 modül + governance
         │                  [/baslat prompt]     ──►  YAPILACAKLAR F0–F8 planı
         │                  [/devam-et]          ──►  Faz faz kod + belgeler
         │                  [/denetle]           ──►  CAO/CEO audit zinciri
         └──────────────────► [quality-gate]      ──►  Play Store'a hazır temel
```

---

## Ne kazandırır?

### Cursor ile pratik farklar

| # | Sorun (fabrika olmadan) | Bu repo ile |
|---|-------------------------|-------------|
| 1 | Her projede mimari sıfırdan | 33 katman + 10 modül hazır iskelet |
| 2 | AI uydurma dosya/API üretir | Halüsinasyon sıfır protokolü + validator |
| 3 | "Şimdi ne yapayım?" belirsizliği | YAPILACAKLAR F0–F8 net yol haritası |
| 4 | Tek AI cevabına güvenmek | 16 ajan + hiyerarşik denetim |
| 5 | Samsung/MIUI'de uygulama ölür | OEM P0 matris + kod şablonu |
| 6 | Güvenlik sonradan eklenir | Security/Privacy/Pentest standartları baştan |
| 7 | i18n unutulur | Hard-coded string yasağı + locale JSON |
| 8 | Monetizasyon geç kalır | Billing 7 gün trial şablonu |
| 9 | Ölçüm yok | AID Sprint P event pipeline |
| 10 | Her app için standart yazmak | `sync-standards.sh` — tek kaynak |

### What you gain (EN) {#what-you-gain-en}

| # | Without factory | With this repo |
|---|-----------------|----------------|
| 1 | Architecture from scratch every project | 33 layers + 10-module ready scaffold |
| 2 | AI invents files/APIs | Zero-hallucination protocol + validators |
| 3 | "What do I do next?" uncertainty | YAPILACAKLAR F0–F8 clear roadmap |
| 4 | Trusting one AI answer | 16 agents + hierarchical audit |
| 5 | App dies on Samsung/MIUI | OEM P0 matrix + code templates |
| 6 | Security bolted on later | Security/Privacy/Pentest from day one |
| 7 | i18n forgotten | No hard-coded strings + locale JSON |
| 8 | Monetization arrives late | Billing 7-day trial template |
| 9 | No measurement | AID Sprint P event pipeline |
| 10 | Rewrite standards per app | `sync-standards.sh` — single source |

### Cursor'da tipik bir gün / A typical day in Cursor

```
09:00  cursor .                          → Proje açılır, Overmind kuralları yüklenir
09:05  /baslat "Offline habit tracker…"  → YAPILACAKLAR oluşur, F0 başlar
09:30  Agent: CPO pazar analizi          → MCP Browser → .cursor/snapshots/mcp/
10:00  Agent: Baş Mimar MODULE_MAP      → 10 modül yapısı onaylanır
11:00  /devam-et                         → F3 Android iskelet doğrulanır
11:30  ./scripts/gradle-build-loop.sh    → Derleme kanıtı (LATEST.gradle.log)
14:00  Agent: Android Compose UI         → Liquid Glass tema uygulanır
14:30  ./scripts/gradle-build-loop.sh    → Hata varsa log okunur, düzeltilir
16:00  /denetle                          → CAO audit, OEM matris kontrol
17:00  ./scripts/factory-quality-gate.sh → 100/100 kalite kapısı
```

### Cursor terminal köprüsü (10/10 için)

Cursor IDE **derleme ve emülatör görmez**. Fabrika terminal script'leri ile kapatır:

| Script | Amaç |
|--------|------|
| [`scripts/gradle-build-loop.sh`](scripts/gradle-build-loop.sh) | `./gradlew assembleDebug --stacktrace` + retry + log snapshot |
| [`scripts/run-maestro.sh`](scripts/run-maestro.sh) | Maestro E2E (adb + cihaz gerekir) |
| [`.cursor/snapshots/`](.cursor/snapshots/README.md) | MCP handoff + build log kanıtı |

Detay: [`docs/CURSOR_TERMINAL_BRIDGE.md`](docs/CURSOR_TERMINAL_BRIDGE.md)

### Context budget (token optimizasyonu)

Tam `33-LAYER-MANIFEST.yaml` okuma **yasak**. Ajanlar yalnızca ihtiyaç duydukları dilimleri yükler:

| Kaynak | Amaç |
|--------|------|
| [`docs/33-LAYER-MANIFEST/layer-NN.yaml`](docs/33-LAYER-MANIFEST/README.md) | Katman başına ~20 satır dilim |
| [`governance/phase-agents.json`](governance/phase-agents.json) | F0–F8 → aktif Cursor ajanları |
| [`docs/CURSOR_CONTEXT_BUDGET.md`](docs/CURSOR_CONTEXT_BUDGET.md) | Ne zaman ne okunur |
| `python3 scripts/split-layer-manifest.py` | Dilimleri manifest'ten üret |
| [`scripts/state-recovery.sh`](scripts/state-recovery.sh) | Truncation → checkpoint + rollback |
| [`docs/STATE_RECOVERY.md`](docs/STATE_RECOVERY.md) | Durum kurtarma (truncation / yarım Gradle) |

**Gradle edit sırası (Composer):** `libs.versions.toml` → `build.gradle.kts` → `AndroidManifest.xml` → `.kt`

---

## Sistem Özeti

**Ulas Autonomous Android APP Factory**, tek bir GitHub template üzerinden aynı standartla Android uygulamaları üretmek için kurduğum fabrika reposu.

Her yeni uygulamada standartları, mimariyi, güvenlik kurallarını, OEM matrisini ve Gradle iskeletini sıfırdan yazmak zorunda kalmazsın. Fabrika:

1. **Karar verir** — Ürün, pazar, roadmap (CPO, PDC, Mavi Okyanus)
2. **Tasarlar** — 33 katmanlı mimari, modül haritası (Baş Mimar)
3. **İnşa eder** — Jetpack Compose, Clean Architecture, 10 modül (Android Elite)
4. **Denetler** — Güvenlik, OEM, hiyerarşik onay zinciri (CAO, CEO, EGC)
5. **Ölçer** — Analytics Sprint P, gerçek kullanıcı verisi (AID)

Tüm süreç **halüsinasyon sıfır** protokolü ve **YAPILACAKLAR.md** faz kapısı ile yönetilir: AI, plan onaylanmadan ve aktif faz tamamlanmadan rastgele kod üretmez.

> **Fabrika ≠ Uygulama.** Bu repoda uygulama kodu yaşamaz; `templates/android/project/` altındaki iskelet, `init-new-app.sh` ile hedef projeye kopyalanır.

---

## System Overview (EN) {#system-overview-en}

**Ulas Autonomous Android APP Factory** is a GitHub template for building Android apps with the same standards, Cursor agent rules, and governance on every project.

You do not rewrite architecture, security, OEM notes, or Gradle scaffolds for each new app. The factory:

1. **Decides** — Product, market, roadmap (CPO, PDC, Blue Ocean)
2. **Designs** — 33-layer architecture, module map (Chief Architect)
3. **Builds** — Jetpack Compose, Clean Architecture, 10 modules (Android Elite)
4. **Audits** — Security, OEM, hierarchical approval chain (CAO, CEO, EGC)
5. **Measures** — Analytics Sprint P, live user data (AID)

The entire flow is governed by a **zero-hallucination protocol** and the **YAPILACAKLAR.md** phase gate: AI does not generate random code before the plan is approved and the active phase is complete.

> **Factory ≠ Application.** Application code does not live in this repo; the scaffold under `templates/android/project/` is copied to your target project via `init-new-app.sh`.

---

## Ne Sunar? {#ne-sunar}

| Bileşen / Component | Ne işe yarar? / Purpose | Nasıl davranır? / Behavior |
|---------------------|-------------------------|---------------------------|
| **The Overmind** (`.cursorrules`) | Merkezi koordinasyon | Tüm ajanları yönlendirir; YAPILACAKLAR okumadan kod yasak |
| **16 AI Ajanı** (`.cursor/rules/`) | Uzmanlaşmış departmanlar | Her ajan belirli katmanlardan sorumlu; tek başına nihai onay veremez |
| **Executive OS** (`governance/`) | CEO V7, sprint lock, denetim | Karar → teslimat → ölçüm zinciri; runtime dosyalar proje bazlı üretilir |
| **YAPILACAKLAR** (`YAPILACAKLAR.md`) | F0–F8 faz planı | Aynı anda tek faz `işleniyor`; L1 doğrulama zorunlu |
| **33 Katman** (`docs/33-LAYER-ARCHITECTURE.md`) | Merkezi katman çerçevesi | 360 bileşen manifest ile otomatik denetlenir |
| **Claude-Native reasoning** (`docs/CLAUDE_REASONING.md`) | v2.1 yapılandırılmış akıl yürütme | `19-claude-reasoning.mdc` — thinking, architecture_check, negative_constraints |
| **13 Standart** (`docs/03-STANDARDS/`) | Liquid Glass, i18n, Security… | Kod ve belge üretiminde referans; ihlal = süreç durur |
| **Android İskeleti** (`templates/android/project/`) | 10 Gradle modülü | Hilt, Room, Billing, FCM, OEM, Compose tema hazır |
| **MCP** (Browser + GitHub P0) | Gerçek dünya yetenekleri | Pazar araştırması, CI/PR, dokümantasyon doğrulama |
| **Doğrulama Scriptleri** (`scripts/`) | Otomatik kalite kapısı | `factory-quality-gate.sh` → hedef 100/100 |

### What It Delivers (EN) {#what-it-delivers-en}

Same components as above — see the Turkish table for file paths. Key surfaces: **Overmind** (`.cursorrules`), **16 agents**, **Executive OS** (`governance/`), **YAPILACAKLAR** phase gate, **33 layers**, **13 standards**, **Android scaffold**, **MCP**, validation scripts.

---

## Mimari Akış {#mimari-akış}

```mermaid
flowchart TB
    subgraph Input["Geliştirici"]
        P[Ürün promptu]
    end

    subgraph Gate["YAPILACAKLAR Gate"]
        Y[YAPILACAKLAR.md F0→F8]
    end

    subgraph Factory["Factory Division"]
        CPO[CPO · Vision]
        ARCH[Architect · Modules]
        AND[Android Elite · Code]
        SEC[Security Auditor]
        OEM[OEM Auditor]
    end

    subgraph Executive["Executive OS"]
        PDC[PDC · Roadmap]
        CEO[CEO · Sprint Lock]
        CAO[CAO · Audit Quality]
        EGC[EGC · Company Health]
    end

    subgraph Output["Deliverable"]
        APP[Android App + Docs + Governance]
    end

    P --> Y
    Y --> CPO --> PDC --> ARCH --> AND
    AND --> SEC --> OEM
    SEC --> CAO --> CEO --> EGC
    OEM --> APP
    CEO --> APP
```

### Architecture Flow (EN) {#architecture-flow-en}

Same pipeline as the diagram above: **YAPILACAKLAR gate** → Factory Division (CPO → Architect → Android → Security → OEM) → Executive OS (PDC → CAO → CEO → EGC) → **deliverable Android app** with docs and governance.

---

## Adım Adım Kurulum (Türkçe)

### Ön koşullar

| Gereksinim | Açıklama |
|------------|----------|
| [Cursor](https://cursor.com) | AI ajan kuralları ve MCP için |
| Git | Template klonlama ve sürüm kontrolü |
| JDK 17+ | Scaffold sonrası `./gradlew assembleDebug` için |
| Android Studio | İsteğe bağlı; Gradle sync ve emülatör |

---

### Adım 1 — Template reposunu oluştur

1. [github.com/clariongemini/APP-FABRIKA](https://github.com/clariongemini/APP-FABRIKA) adresine git
2. **Use this template** → **Create a new repository**
3. Yeni repoyu klonla ve Cursor'da aç:

```bash
git clone https://github.com/<org>/<yeni-repo>.git
cd <yeni-repo>
cursor .
```

**Ne olur?** Fabrikanın tam kopyası (kurallar, governance, şablonlar, scriptler) proje reposuna gelir. Henüz uygulama kodu yoktur.

---

### Adım 2 — İlk kurulum (`first-setup.sh`)

```bash
chmod +x scripts/*.sh scripts/**/*.sh 2>/dev/null || true
./scripts/first-setup.sh
```

**Script ne yapar?**

| # | İşlem | Sonuç |
|---|--------|-------|
| 1 | Script izinlerini ayarlar | Tüm `scripts/` çalıştırılabilir olur |
| 2 | `setup-mcp.sh` çağırır | `.cursor/mcp.json` yoksa example'dan oluşturur |
| 3 | MCP denetimi (`--warn`) | P0 eksikse uyarır, durdurmaz |
| 4 | Git pre-commit hook kurar | Commit öncesi otomatik denetim |
| 5 | Gradle wrapper bootstrap | Android şablonunda `gradlew` hazır |
| 6 | `factory-health.sh` | 10 kategoride sağlık skoru (hedef 100/100) |

---

### Adım 3 — MCP kurulumu (P0 zorunlu)

```bash
./scripts/setup-mcp.sh
./scripts/check-mcp.sh
```

| MCP | Öncelik | Ne sağlar? |
|-----|---------|------------|
| **cursor-ide-browser** | P0 | Play Store, rakip siteleri, OEM dokümantasyonu |
| **GitHub MCP** | P0 | PR, CI durumu, issue, release yönetimi |
| Docker MCP | P1 | İzole build ortamı |
| GitKraken MCP | P1 | Git branch, commit, PR |
| Fetch MCP | P2 | Web/API dokümantasyonu çekme |

**GitHub PAT adımları:**

1. GitHub → Settings → Developer settings → Personal access tokens
2. `repo` scope ile token oluştur
3. `.cursor/mcp.json` içinde `GITHUB_PERSONAL_ACCESS_TOKEN` değerini güncelle
4. Cursor'ı yeniden başlat

Detay: [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md)

---

### Adım 4 — Project Intent kilidi ve uygulama projesi

**Önce** workspace intent kilitleyin; `init-new-app.sh` yalnızca `android-app` intent sonrası çalışır.

1. Cursor'da `/prompt-genesis` çalıştırın.
2. `workspace_role = android-app` seçin; `project_name` ve `package_name` onaylayın.
3. `/yeni-proje` veya terminalde:

```bash
./scripts/init-new-app.sh "UygulamaAdi" "com.sirket.uygulama"
```

4. Ardından [Adım 5](#adım-5--cursorda-plan-başlat-baslat) ile `/baslat` — ürün promptunu ve `YAPILACAKLAR` planını zenginleştirin.

> `factory-template` modunda `init-new-app.sh` çalıştırmayın. Eski konuşma bağlamından project intent çıkarmayın.

**`init-new-app.sh` sırasında otomatik oluşur:**

| Çıktı | Konum | İçerik |
|-------|-------|--------|
| Merkezi hafıza | `docs/00-INDEX.md` | Uygulama adı, paket, sürüm |
| Vizyon şablonları | `docs/01-VISION/` | PRODUCT_BRIEF, MARKET_ANALYSIS, MONETIZATION |
| Mimari şablonları | `docs/02-ARCHITECTURE/` | MODULE_MAP, DATA_FLOW |
| Android iskeleti | Proje kökü | 10 modül, Gradle wrapper, Compose tema |
| Executive OS | `governance/` | Sprint lock, approval queue, roadmap seed |
| Faz planı | `YAPILACAKLAR.md` | F0–F8 bina metaforu |
| Proje meta | `.factory/project.json` | App adı, paket, fabrika sürümü |

**Gradle modülleri:** `app` + 7 `core` + 3 `feature` — detay [Android İskeleti](#android-i̇skeleti-10-modül)

---

### Adım 5 — Cursor'da plan başlat (`/baslat`)

Cursor chat'e yaz:

```
/baslat

Uygulama: [Kısa açıklama — örn. offline-first alışkanlık takipçisi, 7 gün trial, TR/EN]
Hedef kitle: [örn. 25–45, sağlık bilinci]
Monetizasyon: [örn. abonelik, 7 gün ücretsiz deneme]
```

**Ne olur?**

1. Overmind `YAPILACAKLAR.md` içindeki kaynak promptu doldurur
2. **F0** `işleniyor` olur — governance, MCP, hafıza doğrulanır
3. AI **doğrudan kod yazmaz**; önce vizyon (F1) ve mimari (F2) tamamlanır
4. Her faz bitince L1 ajan/subagent doğrulaması gerekir

---

### Adım 6 — Faz faz geliştirme

| Komut | Ne yapar? |
|-------|-----------|
| `/devam-et` | Aktif fazdan kaldığı yerden devam eder |
| `/faz-durumu` | F0–F8 özet tablosu |
| `/denetle` | Hiyerarşik denetim zinciri (CAO → CEO) |

Manuel doğrulama:

```bash
python3 scripts/governance/validate-yapilacaklar.py
python3 scripts/governance/validate-audit-chain.py
./scripts/agent-approval-gate.sh
./scripts/run-ceo-cycle.sh
```

---

### Adım 7 — Kalite kapısı (yayın öncesi)

```bash
./scripts/factory-quality-gate.sh   # Tüm doğrulamalar — hedef 100/100
./scripts/run-factory-audit.sh        # 40+ fabrika kontrolü → docs/AUDIT_REPORT.md
./scripts/ci-template-build.sh      # Template assembleDebug (JDK 17+)
./scripts/verify-environment.sh       # JDK + MCP + meta
./scripts/pre-commit.sh             # Commit öncesi denetim
./gradlew assembleDebug             # Android derleme kanıtı (JDK 17+)
```

---

## Step-by-Step Setup (English)

### Prerequisites

| Requirement | Description |
|-------------|-------------|
| [Cursor](https://cursor.com) | AI agent rules and MCP |
| Git | Template clone and version control |
| JDK 17+ | For `./gradlew assembleDebug` after scaffold |
| Android Studio | Optional; Gradle sync and emulator |

---

### Step 1 — Create from template

1. Go to [github.com/clariongemini/APP-FABRIKA](https://github.com/clariongemini/APP-FABRIKA)
2. Click **Use this template** → **Create a new repository**
3. Clone and open in Cursor:

```bash
git clone https://github.com/<org>/<new-repo>.git
cd <new-repo>
cursor .
```

**Result:** Full factory copy (rules, governance, templates, scripts). No application code yet.

---

### Step 2 — First setup

```bash
chmod +x scripts/*.sh scripts/**/*.sh 2>/dev/null || true
./scripts/first-setup.sh
```

| # | Action | Outcome |
|---|--------|---------|
| 1 | Sets script permissions | All `scripts/` become executable |
| 2 | Runs `setup-mcp.sh` | Creates `.cursor/mcp.json` from example if missing |
| 3 | MCP audit (`--warn`) | Warns on missing P0, does not block |
| 4 | Installs git pre-commit hook | Automatic checks before commit |
| 5 | Gradle wrapper bootstrap | `gradlew` ready in Android template |
| 6 | `factory-health.sh` | Health score across 10 categories (target 100/100) |

---

### Step 3 — MCP setup (P0 required)

```bash
./scripts/setup-mcp.sh
./scripts/check-mcp.sh
```

See [Step 3 TR table](#adım-3--mcp-kurulumu-p0-zorunlu) for MCP priorities.

Full guide: [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md)

---

### Step 4 — Create application project

```bash
./scripts/init-new-app.sh "MyApp" "com.company.myapp"
```

See [Step 4 TR table](#adım-4--uygulama-projesi-oluştur-init-new-appsh) for generated artifacts.

---

### Step 5 — Start plan in Cursor (`/baslat`)

```
/baslat

App: [Short description — e.g. offline-first habit tracker, 7-day trial, TR/EN]
Target audience: [e.g. 25–45, health-conscious]
Monetization: [e.g. subscription, 7-day free trial]
```

**Behavior:** Overmind fills YAPILACAKLAR, activates F0, blocks code until vision (F1) and architecture (F2) are complete.

---

### Step 6 — Phase-by-phase development

| Command | Action |
|---------|--------|
| `/devam-et` | Continue from active phase |
| `/faz-durumu` | F0–F8 status summary |
| `/denetle` | Hierarchical audit chain |

---

### Step 7 — Quality gate (pre-release)

```bash
./scripts/factory-quality-gate.sh   # All validations — target 100/100
./scripts/run-factory-audit.sh
./scripts/ci-template-build.sh
./scripts/pre-commit.sh             # Pre-commit audit
./gradlew assembleDebug             # Android build proof (JDK 17+)
```

---

## Repo Haritası {#repo-haritası}

```
.
├── FACTORY_MISSION.md        # North star — quality gate her çalışmada okunur
├── .cursorrules              # Overmind — merkezi anayasa
├── .factory/                 # meta.json, freeze.json, project.json (proje bazlı)
├── .cursor/
│   ├── rules/                # 00–16 agent rules
│   ├── commands/             # /baslat /devam-et /denetle /faz-durumu
│   ├── skills/               # planner, executor, zero-hallucination, audit
│   └── agents/               # phase-verifier, plan-expander, auditors
├── APP-FABRIKASI/             # Software Venture OS (portable, no pre-seeded venture)
│   ├── scripts/               # init-venture, bridge-venture, svos-health
│   ├── 02-platforms/          # Android bridge defaults
│   ├── 08-ventures/_template/ # Charter şablonu (canlı venture gitignore)
│   └── ULAS/                  # Decision intelligence
├── factory/                  # Intelligence + Portfolio + Outcomes (canonical, git)
│   ├── proof/ memory/ decision_accuracy/ revenue/ benchmark/
│   ├── portfolio/            # App registry scaffold
│   ├── outcomes/             # Users, retention, MRR, ROI
│   ├── certification/        # CERTIFIED_BY_FACTORY
│   └── regression/           # Regression pattern DB
├── runtime/                  # Canlı veri (gitignore) — governance + factory + analytics
├── YAPILACAKLAR.md           # Boş stub — /baslat veya init-new-app ile dolar
├── AGENTS.md                 # Ajan dizini ve denetim zinciri
├── governance/               # Executive OS charter + protokoller
│   ├── executive/            # CEO OS, hiyerarşik denetim, onay protokolü
│   ├── product_decision/     # PDC — roadmap
│   ├── execution/            # CEC — teslimat hizası
│   ├── analytics/            # AID — Sprint P ölçüm
│   └── ...                   # market, linguistic, curriculum, blue_ocean…
├── docs/
│   ├── 00-INDEX.md           # Proje hafızası
│   ├── 33-LAYER-ARCHITECTURE.md
│   ├── FACTORY_V4_PRODUCTIZATION.md
│   ├── FACTORY_FREEZE.md
│   ├── 03-STANDARDS/         # 13 teknik standart
│   ├── BOOTSTRAP.md
│   └── EXECUTIVE_OS.md
├── scripts/
│   ├── factory/              # Intelligence, portfolio, outcomes, KPI
│   ├── run-factory-audit.sh
│   ├── factory-quality-gate.sh
│   └── ci-template-build.sh
└── templates/
    ├── android/project/      # 10 modüllü Gradle iskeleti
    ├── factory/              # Intelligence + portfolio + outcomes şablonları
    └── governance/           # Runtime JSON/MD şablonları
```

**Runtime vs Git:** Sprint lock, approval queue, portfolio/outcomes JSON ve analytics çıktıları `runtime/` altında tutulur (gitignore). Politika: [`governance/FACTORY_REPO_POLICY.md`](governance/FACTORY_REPO_POLICY.md)

### Repository Map (EN) {#repository-map-en}

Same tree as above. **Git** holds standards, rules, templates, and scripts. **Runtime** (ignored) holds per-project governance state, portfolio registry, and outcome metrics filled from Play Store / AID.

---

## YAPILACAKLAR F0–F8 {#yapilacaklar-f0f8}

| Faz | Bina metaforu | TR — Ne yapılır? | EN — What happens? |
|-----|---------------|------------------|---------------------|
| **F0** | Zemin & temel | MCP, governance, hafıza, audit chain | MCP, governance, memory, audit chain |
| **F1** | Kolon & taşıyıcı | CPO vizyon, pazar, monetizasyon, PDC roadmap | CPO vision, market, monetization, PDC roadmap |
| **F2** | Kat döşeme | Mimari, modül haritası, bağımlılık kuralları | Architecture, module map, dependency rules |
| **F3** | Duvar & tesisat | Gradle iskelet, Hilt, Room, i18n | Gradle scaffold, Hilt, Room, i18n |
| **F4** | Cephe & UI | Compose, Liquid Glass, adaptive layout | Compose, Liquid Glass, adaptive layout |
| **F5** | Elektrik & güvenlik | Security audit, OEM matris (Samsung/MIUI P0) | Security audit, OEM matrix (Samsung/MIUI P0) |
| **F6** | Ölçüm & analitik | AID Sprint P, event catalog, Firebase gate | AID Sprint P, event catalog, Firebase gate |
| **F7** | İç mekan | Feature work packages, roadmap P0 implementasyon | Feature WPs, roadmap P0 implementation |
| **F8** | Anahtar teslim | CAO + CEO cycle + approval gate + release | CAO + CEO cycle + approval gate + release |

**Durum ibareleri / Status:** `bekliyor` · `işleniyor` · `tamamlandı` — aynı anda yalnızca **bir** faz `işleniyor` olabilir.

Detay: [`docs/YAPILACAKLAR_SISTEMI.md`](docs/YAPILACAKLAR_SISTEMI.md)

### YAPILACAKLAR Phases (EN) {#yapilacaklar-phases-en}

| Phase | Metaphor | What happens |
|-------|----------|--------------|
| **F0** | Foundation | MCP, governance, memory, audit chain |
| **F1** | Columns | CPO vision, market, monetization, PDC roadmap |
| **F2** | Floor | Architecture, module map, dependency rules |
| **F3** | Walls | Gradle scaffold, Hilt, Room, i18n |
| **F4** | Facade | Compose, Liquid Glass, adaptive layout |
| **F5** | Electrical | Security audit, OEM matrix (Samsung/MIUI P0) |
| **F6** | Measurement | AID Sprint P, event catalog, Firebase gate |
| **F7** | Interior | Feature work packages, roadmap P0 |
| **F8** | Handover | CAO + CEO cycle + approval gate + release |

**Status labels:** `bekliyor` (waiting) · `işleniyor` (in progress) · `tamamlandı` (done) — only **one** phase may be `in progress`.

---

## Ajanlar & Executive OS {#ajanlar--executive-os}

### Factory Division (6)

| Ajan | Kural | Sorumluluk |
|------|-------|------------|
| CPO | `01-product-cpo.mdc` | Vizyon, pazar, monetizasyon |
| Baş Mimar | `02-architect.mdc` | Mimari, modül haritası, offline-first |
| Android Elite | `03-android-elite.mdc` | Compose UI, Kotlin, i18n |
| Denetçi | `04-auditor-security.mdc` | Güvenlik, QA, performans |
| OEM Denetçi | `05-oem-compat-auditor.mdc` | Samsung, MIUI, OPPO — P0 release blocker |
| MCP Orkestratör | `06-mcp-orchestrator.mdc` | MCP kurulum doğrulama |

### Intelligence & Executive (10)

| Ajan | Kural | Rol |
|------|-------|-----|
| LIUD | `07-linguistic-intelligence.mdc` | Talep istihbaratı, locale |
| CIKA | `08-curriculum-intelligence.mdc` | Müfredat zekâsı |
| PDC | `09-product-decision-council.mdc` | Roadmap kararları |
| Mavi Okyanus | `10-mavi-okyanus.mdc` | Portföy keşfi |
| CEO V7 | `11-ceo-agent.mdc` | Delivery orchestration |
| CAO | `12-chief-audit-officer.mdc` | Denetim kalitesi |
| CEC | `13-chief-execution-council.mdc` | Execution alignment |
| EGC | `14-executive-governance-council.mdc` | Company health |
| CDID | `15-chief-delivery-intelligence.mdc` | Decision → work packages |
| AID | `16-analytics-intelligence.mdc` | Measurement (Sprint P) |
| Growth | `17-marketing-growth.mdc` | GTM, ASO |

**Hiyerarşik denetim:** Hiçbir ajan kendi işini nihai onaylayamaz. Zincir: Uygulayan → L1 üst departman → CAO → CEO → EGC.

Tam eşleme: [`governance/executive/HIERARCHICAL_AUDIT_CHAIN.md`](governance/executive/HIERARCHICAL_AUDIT_CHAIN.md) · [`AGENTS.md`](AGENTS.md)

### Agents & Executive OS (EN) {#agents--executive-os-en}

16 department agents under Cursor rules; hierarchical audit forbids single-agent final approval. Chain: implementer → L1 parent → CAO → CEO → EGC. Full map: [`AGENTS.md`](AGENTS.md).

---

## Android İskeleti (10 Modül) {#android-i̇skeleti-10-modül}

| Modül | Paket | Ne sunar? |
|-------|-------|-----------|
| `:app` | `{{PACKAGE}}` | Application, MainActivity, FCM, locales |
| `:core:common` | `.core.common` | AppResult, paylaşılan tipler |
| `:core:designsystem` | `.core.designsystem` | Liquid Glass tema, GlassCard |
| `:core:i18n` | `.core.i18n` | LocaleManager, hard-coded string yasağı |
| `:core:database` | `.core.database` | Room + SQLCipher hazır |
| `:core:network` | `.core.network` | Retrofit/OkHttp iskeleti |
| `:core:security` | `.core.security` | Root/emulator detection, Play Integrity |
| `:core:oem` | `.core.oem` | Samsung/MIUI/OPPO uyumluluk |
| `:feature:home` | `.feature.home` | Ana ekran Compose iskeleti |
| `:feature:settings` | `.feature.settings` | Ayarlar modülü |
| `:feature:premium` | `.feature.premium` | Play Billing, 7 gün trial |

**Teknoloji yığını:** Kotlin · Jetpack Compose · Hilt · Room · WorkManager · Firebase FCM · Play Billing · Maestro E2E

Şablon konumu: `templates/android/project/` → `init-new-app.sh` ile proje köküne kopyalanır.

### Android Scaffold (10 Modules) (EN) {#android-scaffold-10-modules-en}

10 Gradle modules: `:app`, 7× `:core:*`, 3× `:feature:*` — Compose, Hilt, Room, billing, FCM, security, OEM. Template path: `templates/android/project/`.

---

## 13 Teknik Standart / 13 Technical Standards

| Standart | Dosya | Kapsam |
|----------|-------|--------|
| Liquid Glass UI | `LIQUID_GLASS.md` | Compose tema, 120fps hedef |
| i18n | `I18N.md` | `assets/locales/tr.json`, `en.json` — hard-coded yasak |
| Security | `SECURITY.md` | SQLCipher, EncryptedSharedPreferences |
| Privacy | `PRIVACY.md` | GDPR/KVKK, veri minimizasyonu |
| OEM | `OEM_COMPATIBILITY.md` + `OEM_MATRIX.yaml` | Samsung, MIUI P0 |
| Background | `BACKGROUND_PROCESSING.md` | WorkManager, pil dostu |
| FCM | `FCM_PUSH.md` | Push bildirim şablonu |
| Monetization | `MONETIZATION_TECH.md` | 7 gün trial + abonelik |
| Play Integrity | `PLAY_INTEGRITY.md` | Sahtekârlık tespiti |
| Testing | `TESTING.md` | Unit, Maestro E2E |
| Performance | `PERFORMANCE.md` | 120fps, lazy list |
| Pentest | `PENTEST.md` | Release öncesi checklist |

Dizin: [`docs/03-STANDARDS/`](docs/03-STANDARDS/)

---

## Doğrulama & Kalite Kapısı {#doğrulama--kalite-kapısı}

| Script | Ne denetler? | Ne zaman? |
|--------|--------------|-----------|
| `factory-health.sh` | 10 kategori, 100/100 hedef | Her zaman |
| `factory-quality-gate.sh` | Tüm doğrulamalar + bileşik skor | Yayın / merge öncesi |
| `validate-code.sh` | Zorunlu dosya varlığı | CI + pre-commit |
| `validate-yapilacaklar.py` | Faz tutarlılığı | Her kod değişikliği öncesi |
| `validate-audit-chain.py` | Hiyerarşik denetim zinciri | Faz kapanışı |
| `audit-layers.sh` | 33 katman bütünlüğü | CI |
| `validate-android-template.sh` | Gradle wrapper, placeholder yok | CI |
| `state-recovery.sh` | Truncation / yarım Gradle → checkpoint + rollback | F3+ Gradle edit |
| `validate-layer-slices.sh` | 33 katman manifest dilimleri | CI |
| `pre-commit.sh` | Yukarıdakilerin birleşimi | Her commit |

### Fabrika doğrulama (`scripts/`)

```bash
./scripts/factory-quality-gate.sh   # Önerilen — tam kapı (v3.1.0)
./scripts/run-factory-audit.sh      # F0–F8 + reasoning → docs/AUDIT_REPORT.md
./scripts/ci-template-build.sh      # Gradle template derleme kanıtı
./scripts/bootstrap-external-project.sh  # Stitch/AI Studio import
```

Detay: [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) · Rapor: [`docs/AUDIT_REPORT.md`](docs/AUDIT_REPORT.md) (üretilir, gitignore)

```bash
./scripts/factory-quality-gate.sh   # ✅ hedef: 100/100
```

Skor kartı: [`docs/FACTORY_SCORECARD.md`](docs/FACTORY_SCORECARD.md)

### Validation & Quality Gate (EN) {#validation--quality-gate-en}

Run `./scripts/factory-quality-gate.sh` before merge or release (target **100/100**). Includes `factory-health.sh`, `run-factory-audit.sh`, `validate-yapilacaklar.py`, layer audit, Android template validation, and pre-commit hooks. Scorecard: [`docs/FACTORY_SCORECARD.md`](docs/FACTORY_SCORECARD.md).

---

## Kullanım Senaryoları {#kullanım-senaryoları}

### Senaryo A — Yeni proje (önerilen)

1. `./scripts/first-setup.sh`
2. Cursor'da `/prompt-genesis`
3. `workspace_role = android-app`
4. `project_name` + `package_name` explicit onayı
5. `/yeni-proje` veya `./scripts/init-new-app.sh`
6. `/baslat`
7. F0 tamamlanmadan feature implementation yok

> `factory-template` modunda `init-new-app.sh` çalıştırmayın. Eski konuşma bağlamından project intent çıkarmayın.

### Senaryo B — Mevcut Android projesine aktarma

```bash
git clone https://github.com/clariongemini/APP-FABRIKA.git ~/android-factory
~/android-factory/scripts/sync-standards.sh /path/to/existing-app
cd /path/to/existing-app && ./scripts/governance/init-governance.sh
```

Mevcut `app/` kodu korunur; AI kuralları ve governance eklenir.

### Senaryo C — Submodule ile güncel standart

```bash
git submodule add https://github.com/clariongemini/APP-FABRIKA.git .factory
./.factory/scripts/sync-standards.sh .
git submodule update --remote .factory && ./.factory/scripts/sync-standards.sh .
```

### Senaryo D — Fabrika bütünlük testi (smoke)

Template'i güncelledikten veya büyük değişiklikten sonra:

```bash
./scripts/run-factory-audit.sh
./scripts/factory-quality-gate.sh
./scripts/ci-template-build.sh
```

Detay: [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md)

### Senaryo E — Stitch / AI Studio import

Prompt → Google Stitch (tasarım) → AI Studio (Android export) → fabrika ile olgunlaştırma:

```bash
export FACTORY_REPO=~/APP-FABRIKA-Factory
"$FACTORY_REPO/scripts/bootstrap-external-project.sh" /path/to/export "App" "com.app" "vizyon"
```

Cursor: `/import-aistudio` → `/baslat` — Detay: [`docs/AI_STUDIO_IMPORT.md`](docs/AI_STUDIO_IMPORT.md)

**Fabrika doğrulaması (CI/lokal):** `./scripts/factory-quality-gate.sh` · `./scripts/run-factory-audit.sh`

### Senaryo F — Software Venture OS (SVOS)

Mevcut veya yeni kod tabanında venture charter, build köprüsü ve olgunluk denetimi:

```bash
./APP-FABRIKASI/scripts/init-venture.sh "My App" my-app /path/to/codebase
./APP-FABRIKASI/scripts/bridge-venture.sh my-app
./APP-FABRIKASI/scripts/svos-health.sh
```

Detay: [`APP-FABRIKASI/README.md`](APP-FABRIKASI/README.md) · [`APP-FABRIKASI/NORTH_STAR.md`](APP-FABRIKASI/NORTH_STAR.md)

### Usage Scenarios (EN) {#usage-scenarios-en}

| Scenario | Flow |
|----------|------|
| **A — New project** | Run `first-setup.sh`, lock explicit `android-app` intent with `/prompt-genesis`, confirm `project_name` and `package_name`, then `/yeni-proje` or `init-new-app.sh`, then `/baslat`. Do not run `init-new-app.sh` in `factory-template` mode. |
| **B — Existing app** | `sync-standards.sh /path/to/app` + `init-governance.sh` |
| **C — Submodule** | Add factory as submodule; `sync-standards.sh` on update |
| **D — Integrity check** | `run-factory-audit.sh` + `factory-quality-gate.sh` + `ci-template-build.sh` |
| **E — AI Studio import** | `bootstrap-external-project.sh` → `/baslat` |
| **F — SVOS venture** | `init-venture.sh` → `bridge-venture.sh` → `svos-health.sh` |

---

## Belge Dizini {#belge-dizini}

| Belge | Açıklama |
|-------|----------|
| [`APP-FABRIKASI/README.md`](APP-FABRIKASI/README.md) | Software Venture OS — charter, evidence, ULAS |
| [`docs/AUTHOR.md`](docs/AUTHOR.md) | Proje sahibi — Ulaş Kaşıkcı |
| [`docs/00-INDEX.md`](docs/00-INDEX.md) | Proje hafızası |
| [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) | Detaylı kurulum senaryoları |
| [`docs/EXECUTIVE_OS.md`](docs/EXECUTIVE_OS.md) | CEO V7, script ağacı |
| [`docs/YAPILACAKLAR_SISTEMI.md`](docs/YAPILACAKLAR_SISTEMI.md) | Faz sistemi, komutlar |
| [`docs/33-LAYER-ARCHITECTURE.md`](docs/33-LAYER-ARCHITECTURE.md) | 33 katman anayasa |
| [`docs/CURSOR_CONTEXT_BUDGET.md`](docs/CURSOR_CONTEXT_BUDGET.md) | Token / okuma sırası |
| [`docs/CURSOR_TERMINAL_BRIDGE.md`](docs/CURSOR_TERMINAL_BRIDGE.md) | Gradle/Maestro terminal köprüsü |
| [`docs/STATE_RECOVERY.md`](docs/STATE_RECOVERY.md) | Truncation durum kurtarma |
| [`docs/FACTORY_META/README.md`](docs/FACTORY_META/README.md) | Fabrika vizyon & roadmap |
| [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md) | MCP kurulum kılavuzu |
| [`governance/FACTORY_REPO_POLICY.md`](governance/FACTORY_REPO_POLICY.md) | Git vs runtime politika |
| [`AGENTS.md`](AGENTS.md) | Tam ajan dizini |

### Documentation Index (EN) {#documentation-index-en}

| Document | Description |
|----------|-------------|
| [`FACTORY_MISSION.md`](FACTORY_MISSION.md) | North star — ship products, not governance |
| [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) | Setup scenarios |
| [`docs/EXECUTIVE_OS.md`](docs/EXECUTIVE_OS.md) | CEO V7, script tree |
| [`docs/FACTORY_V4_PRODUCTIZATION.md`](docs/FACTORY_V4_PRODUCTIZATION.md) | Portfolio + outcomes |
| [`docs/FACTORY_EVOLUTION_DIRECTIVE_AUDIT.md`](docs/FACTORY_EVOLUTION_DIRECTIVE_AUDIT.md) | 12-layer directive vs repo (gap only) |
| [`factory/outcomes/README.md`](factory/outcomes/README.md) | Outcome validation |
| [`AGENTS.md`](AGENTS.md) | Full agent directory |

---

## Tek prompt

Cursor'da yeterli olan kısa ifade:

> *"Uygulamayı 33 katman standartlarına göre geliştir."*

Overmind önce `YAPILACAKLAR.md` okur; aktif faz bitmeden rastgele kod üretmez.

---

## License

MIT — [`LICENSE`](LICENSE)

<p align="center">
  <strong>Ulaş Kaşıkcı</strong> · Android Factory + Software Venture OS · Cursor + Executive OS
</p>
