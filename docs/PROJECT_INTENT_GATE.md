# PROJECT INTENT GATE

> **APP-FABRIKA Core v1** — domain-neutral workspace güvenliği  
> Web/Laravel/SEO/CRO/premium UI ve `/cevap` intelligence → **Leo Compatibility Layer**

---

## Problem

**Eski konuşma bağlamı aktif proje niyeti değildir.**

Cursor oturumları, önceki chat'ler veya fabrika belgelerindeki örnekler yeni workspace için otomatik `app_name` / `package_name` kaynağı olamaz. Bu sızıntı:

- Temiz APP-FABRIKA template reposunu yanlışlıkla Android app workspace'e dönüştürür
- Web/full-stack/Laravel isteğini Android F0–F8 planına zorlar
- Leo/Cursor döngüsünde eski proje bağlamını yeni workspace'e taşır

---

## Amaç

Workspace **rolü** ve **domain/platform** açıkça seçilmeden:

- Scaffold
- Genesis (`init-new-app`, `/yeni-proje`)
- Domain-specific implementation (`/baslat` product planı, F3+ Android kodu)

**engellenir.**

Yalnızca diagnostic, audit, dokümantasyon ve intent kilidi olmadan salt okuma ( `--mode diagnostic` ) serbesttir.

---

## Workspace Role Değerleri

| `workspace_role` | Anlam |
|------------------|--------|
| `factory-template` | APP-FABRIKA GitHub template — standart kaynak; product genesis yok |
| `android-app` | Bu workspace bir Android uygulama projesi |
| `web-app` | Web uygulaması — Leo layer veya ayrı factory |
| `laravel-mysql-fullstack` | Laravel/MySQL — Leo layer; core scaffold yok |
| `existing-project-import` | Mevcut kod tabanına `sync-standards` / bootstrap |
| `test-sandbox` | Geçici deneme — kalıcı scaffold için promotion gerekir |

---

## Role / Platform Uyumu

| workspace_role | platform | stack (örnek) | package_name |
|----------------|----------|---------------|--------------|
| `factory-template` | `none` | `none` | — |
| `android-app` | `android` | `kotlin-compose-gradle` | **Zorunlu** |
| `web-app` | `web` | `react-next` / `vite` | Opsiyonel |
| `laravel-mysql-fullstack` | `fullstack` | `laravel-mysql` | Opsiyonel |
| `existing-project-import` | `existing` | `mixed` | Proje tipine göre |
| `test-sandbox` | `none` | `none` | — |

---

## Intent → İzin Matrisi

| Intent / Mod | İzin Verilen | Yasaklanan |
|--------------|--------------|------------|
| **Diagnostic** (intent yok) | Okuma, rapor, audit, `validate-*` dry-run | Scaffold, genesis, product `/baslat` |
| **factory-template** | Fabrika sağlık, standart geliştirme, SVOS belge | `init-new-app`, Android scaffold, product `/baslat`, `.factory/project.json` yazma |
| **android-app** | `init-new-app`, Android scaffold, Android F0–F8 `/baslat` | Web/Laravel scaffold (Leo layer) |
| **web-app** | Plan/diagnostic, Leo layer handoff | Android scaffold, F3 Gradle genesis |
| **laravel-mysql-fullstack** | Plan/diagnostic, Leo layer handoff | APP-FABRIKA core scaffold |
| **existing-project-import** | `sync-standards`, `bootstrap-external-project` | Fabrika template kökünde `init-new-app` |
| **test-sandbox** | Deneme, proof-of-concept okuma | Kalıcı genesis/scaffold (promotion öncesi) |

---

## project-intent.json Schema

Makine okunur **local intent lock** — gitignore altında (`.factory/project-intent.json`).

Örnek: [`.factory/project-intent.example.json`](../.factory/project-intent.example.json)

```json
{
  "schema_version": 1,
  "workspace_role": "android-app",
  "platform": "android",
  "stack": "kotlin-compose-gradle",
  "project_name": "My App",
  "package_name": "com.company.myapp",
  "confirmed_by": "user",
  "confirmed_at": "2026-07-02T12:00:00Z",
  "source": "explicit-user-confirmation",
  "notes": "Explicit user confirmation — not inferred from chat history."
}
```

| Alan | Zorunlu | Açıklama |
|------|---------|----------|
| `schema_version` | Evet | `1` |
| `workspace_role` | Evet | Tablo yukarıda |
| `platform` | Evet | Role ile eşleşmeli |
| `stack` | Önerilir | Teknoloji özeti |
| `project_name` | `android-app` için evet | |
| `package_name` | `android-app` için evet | |
| `source` | Evet | `explicit-user-confirmation` |
| `confirmed_by` | Evet | `user` |
| `confirmed_at` | Evet | ISO-8601 UTC |

---

## Komut Ön Koşulları

| Komut / Script | Ön koşul |
|----------------|----------|
| `/prompt-genesis` | Intent yok — kilidi oluşturur |
| `/baslat` | Intent lock + `validate-project-intent.py --mode genesis` PASS; `factory-template` / `test-sandbox` → BLOCKED |
| `/yeni-proje` | `android-app` + `validate --mode genesis --require-role android-app` |
| `init-new-app.sh` | Terminal hook: `--mode genesis --require-role android-app` |
| `scaffold-android-project.sh` | `--mode scaffold --platform android --require-role android-app` |
| `scaffold-android-project-to.sh` | Aynı — hedef projede de intent lock önerilir |
| `ci-template-build.sh` | İzole `/tmp` workdir — `APP_FABRIKA_ALLOW_TEMPLATE_SCAFFOLD=1` (CI only; bkz. aşağı) |
| `sync-standards.sh` | `existing-project-import` veya uygun intent |
| `bootstrap-external-project.sh` | `existing-project-import` veya `android-app` |

### `/baslat` — Android-first sınırı

APP-FABRIKA **Android-first** fabrikadır. `web-app` veya `laravel-mysql-fullstack` intent ile `/baslat`:

- Yalnızca **plan / diagnostic** üretebilir
- Android scaffold veya **F3 Android implementation başlatmamalıdır**
- Tam F0–F8 Android planı yalnızca `workspace_role=android-app` için geçerlidir

### Template CI exception

`APP_FABRIKA_ALLOW_TEMPLATE_SCAFFOLD=1` yalnızca fabrika CI/template smoke build içindir (`scripts/ci-template-build.sh`). İzole geçici dizine scaffold doğrulaması yapar.

- **İzinli:** `--mode scaffold --platform android` (intent dosyası yokken, env set)
- **Yasak:** `genesis`, `implementation`, repo kökünde scaffold, `init-new-app.sh`, `.factory/project-intent.json` / `.factory/project.json` yazımı
- **Kullanıcıya önerilmez** — README quickstart veya manuel genesis bypass değildir

---

## Rule Ordering

```
21-project-intent-gate.mdc   → workspace role / platform lock
20-agent-intent-gate.mdc    → DIAGNOSTIC vs IMPLEMENTATION (mesaj modu)
00-overmind-zero-hallucination.mdc → YAPILACAKLAR + halüsinasyon sıfır
```

Validator:

```bash
python3 scripts/governance/validate-project-intent.py --mode diagnostic
python3 scripts/governance/validate-project-intent.py --mode genesis --require-role android-app
python3 scripts/governance/validate-project-intent.py --mode scaffold --platform android --require-role android-app
python3 scripts/governance/validate-project-intent.py --mode implementation
```

Exit codes: `0` PASS/INFO · `1` malformed · `2` BLOCKED

---

## APP-FABRIKA Core vs Leo Compatibility Layer

| Katman | Sorumluluk |
|--------|------------|
| **APP-FABRIKA Core** | Domain-neutral intent gate, factory template guard, Android factory scaffold |
| **Leo Compatibility Layer** | Web/Laravel/SEO/CRO/premium UI, multi-domain orchestration, `/cevap` intelligence |

Core'a **gömülmez:** Laravel gate, SEO/CRO kuralları, web scaffold template, Leo CLI/Ollama.

---

## Anti-patterns

- Önceki sohbet bağlamından `app_name` / `package_name` türetmek
- Domain seçmeden Android scaffold oluşturmak
- `factory-template` modunda product `/baslat` çalıştırmak
- Web/Laravel isteğini Android F0–F8 planına zorlamak
- `test-sandbox` ile kalıcı `init-new-app` çalıştırmak
- Cursor rule bypass — terminal hook'ları olmadan destructive script çalıştırmak

---

## `/cevap` Hazırlığı (Leo)

İleride `/cevap` Cursor özetini şu sırayla değerlendirecek:

1. Workspace intent doğru mu?
2. Domain/platform doğru mu?
3. Yapılan işlem izin verilen intent ile uyumlu mu?
4. YAPILACAKLAR / F0–F8 uyumu var mı?
5. Sonraki doğru hiyerarşik adım ne?
6. Cursor'a verilecek sonraki prompt ne?

Project Intent Gate bu zincirin **1–3** adımları için zemin sağlar.

---

*İlgili: [`APP_FABRIKA_REPO_INTELLIGENCE_REPORT.md`](APP_FABRIKA_REPO_INTELLIGENCE_REPORT.md) · Kural: `.cursor/rules/21-project-intent-gate.mdc`*
