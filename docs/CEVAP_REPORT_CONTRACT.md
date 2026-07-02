# CEVAP REPORT CONTRACT

> **APP-FABRIKA Core** — domain-neutral After Action Review (AAR) / Next Step Prompt Contract  
> Leo CLI `/cevap` intelligence bu contract'ı **consume edebilir**; core burada multi-model routing yapmaz.

---

## Purpose

`/cevap`, Cursor'un yaptığı işten sonra kullanıcıya verilen işlem özetini APP-FABRIKA governance açısından değerlendirir.

Bu contract şu başlıkları standartlaştırır:

- Intent uyumu
- YAPILACAKLAR / faz uyumu
- Güvenlik / gizlilik / mimari / tasarım etkileri
- Validation kanıtları
- Rollback notları
- Sonraki hiyerarşik adım
- Cursor'a verilecek sonraki prompt

**Komut:** `.cursor/commands/cevap.md`  
**Skill:** `.cursor/skills/after-action-review/SKILL.md`

---

## Non-Goals

Bu contract şunları **yapmaz**:

- Leo CLI / Ollama multi-model routing
- Web/Laravel/SEO/CRO domain intelligence
- Kod üretimi veya otomatik düzeltme (remediation)
- Yeni agent / council ekleme
- Scaffold, genesis veya faz atlama
- Commit / push

---

## Input

`/cevap` komutu kullanıcıdan **Cursor işlem özetini** alır. Özet şunları içerebilir:

- Yapılan değişiklikler (dosya listesi, kısa açıklama)
- Çalıştırılan komutlar ve çıktıları
- Aktif YAPILACAKLAR fazı / madde
- Kullanıcı onayı gerekip gerekmediği
- Bilinen riskler veya eksikler

Değerlendirme **DIAGNOSTIC** moddadır — dosya değiştirilmez.

---

## Required Checks

| # | Kontrol | Kaynak |
|---|---------|--------|
| 1 | Workspace intent | `.factory/project-intent.json`, `validate-project-intent.py --mode diagnostic` |
| 2 | Domain/platform compatibility | `docs/PROJECT_INTENT_GATE.md`, role-platform eşlemesi |
| 3 | APP-FABRIKA / YAPILACAKLAR phase | `YAPILACAKLAR.md`, `validate-yapilacaklar.py` |
| 4 | User approval boundary | Public API, route, schema, auth, scaffold, migration, destructive write |
| 5 | Security/privacy | `docs/03-STANDARDS/SECURITY.md`, `PRIVACY.md` — secrets, PII, log redaction |
| 6 | Architecture boundary | `02-architect` prensipleri — domain/data/UI ayrımı |
| 7 | Design/accessibility impact | Token, hardcoded string, i18n, temel a11y (domain-neutral) |
| 8 | Validation evidence | gradle-build-loop, validate-*, audit script çıktıları |
| 9 | Rollback/reversibility | Git revert, migration, generated dosya |
| 10 | Missing information | Kanıtsız iddia, okunmamış dosya referansı |
| 11 | Next hierarchical step | F0–F8, `/devam-et`, `/denetle`, `/prompt-genesis` |

---

## Output Format

Aşağıdaki şablon **zorunlu** başlık sırasıdır. Boş bölüm bırakılmaz; yoksa `—` veya `Yok` yazılır.

```markdown
# /CEVAP REVIEW REPORT

## Kısa Karar
PASS | CONDITIONAL PASS | NEEDS FIX | BLOCKED

## Intent Uyum Kontrolü

| Kontrol | Sonuç | Not |
|---------|-------|-----|
| Workspace intent (`project-intent.json` / role-platform) | ✅ / ⚠️ / ⛔ | |
| İşlem domain/platform ile uyumlu | ✅ / ⚠️ / ⛔ | |
| factory-template / test-sandbox ihlali | ✅ / ⚠️ / ⛔ | |

## Yapılan İşin Özeti

- (3–7 madde; dosya/script referanslı)

## APP-FABRIKA / YAPILACAKLAR Uyumu

| Alan | Durum | Not |
|------|-------|-----|
| Aktif faz | | |
| Aktif madde | | |
| Tek faz `işleniyor` kuralı | | |
| F0.0 intent check | | |

## Riskler

| Seviye | Risk | Etki | Öneri |
|--------|------|------|-------|
| | | | |

## Eksikler

- ...

## Validation Kanıtları

| Komut / Kanıt | Sonuç | Not |
|---------------|-------|-----|
| validate-project-intent.py | | |
| validate-yapilacaklar.py | | |
| (diğer) | | |

## Rollback Notları

- ...

## Sonraki En Doğru Hiyerarşik Adım

1. ...

## Cursor'a Verilecek Sonraki Prompt

```text
(Tek blok, kopyalanabilir. Leo layer bu bloğu zenginleştirebilir.)
```
```

---

## Decision Semantics

### PASS

İş doğru intent, doğru faz, yeterli validation ve düşük riskle tamamlandı. Kritik kontroller temiz.

### CONDITIONAL PASS

İş kabul edilebilir; ancak blokör olmayan eksikler, uyarılar veya kullanıcı aksiyonları var (ör. validation eksik ama risk düşük, küçük takip işleri).

### NEEDS FIX

Non-trivial problem var — devam etmeden düzeltme gerekir (bug, eksik validation, faz ihlali, scope dışı değişiklik).

### BLOCKED

Intent, faz, güvenlik, veri kaybı, unauthorized write veya validation failure nedeniyle ilerleme **durmalı**. Sonraki prompt uygulanmamalı.

| Durum | Tipik tetikleyici |
|-------|-------------------|
| BLOCKED | Intent yok + genesis/scaffold yapıldı; factory-template'te product bootstrap; güvenlik ihlali |
| NEEDS FIX | Gradle/test fail; YAPILACAKLAR faz uyumsuzluğu; halüsinasyon şüphesi |
| CONDITIONAL PASS | Diagnostic-only oturum; dokümantasyon patch; validation kısmen eksik |
| PASS | Governance patch; audit PASS; faz maddesi kapanışına uygun |

---

## Core vs Leo Layer

| | APP-FABRIKA core `/cevap` | Leo `/cevap` |
|---|---------------------------|--------------|
| **Rol** | Domain-neutral AAR contract | Multi-model intelligence |
| **Çıktı** | Governance checklist + temel sonraki prompt | Domain playbooks, zengin prompt |
| **Kapsam** | Intent, YAPILACAKLAR, validation, risk | Web/Laravel/SEO/CRO/Premium UI |
| **Dosya** | Bu contract + command + skill | Leo CLI / Ollama (repo dışı) |

---

## İlgili Belgeler

- [`PROJECT_INTENT_GATE.md`](PROJECT_INTENT_GATE.md)
- [`YAPILACAKLAR_SISTEMI.md`](YAPILACAKLAR_SISTEMI.md)
- [`CURSOR_CONTEXT_BUDGET.md`](CURSOR_CONTEXT_BUDGET.md)
- `.cursor/rules/21-project-intent-gate.mdc`
- `.cursor/rules/20-agent-intent-gate.mdc`
