---
name: after-action-review
description: >-
  Cursor işlem özetlerini APP-FABRIKA governance açısından değerlendirir.
  /cevap command tarafından kullanılır. DIAGNOSTIC — dosya değiştirmez.
---

# After Action Review Skill

## Purpose

Cursor işlem özetlerini APP-FABRIKA governance açısından değerlendirmek.

Bu skill `/cevap` command tarafından kullanılır.

**Contract:** `docs/CEVAP_REPORT_CONTRACT.md`

## Inputs

- Cursor işlem özeti (kullanıcı mesajı)
- Git status / changed files bilgisi (varsa özetten veya `git status`)
- Çalıştırılan validation komutları ve çıktıları
- `YAPILACAKLAR.md` aktif fazı
- Project intent durumu (`.factory/project-intent.json` veya diagnostic INFO)
- Kullanıcı onayı gerektiren noktalar

## Review Checklist

### 1. Project Intent

- `.factory/project-intent.json` var mı?
- `workspace_role` / `platform` yapılan iş ile uyumlu mu?
- `factory-template` veya `test-sandbox` ihlali var mı?
- Eski konuşma bağlamından türetilmiş varsayım var mı?

```bash
python3 scripts/governance/validate-project-intent.py --mode diagnostic
```

### 2. YAPILACAKLAR / Phase

- Aktif faz doğru mu?
- Tek faz `işleniyor` kuralı korunmuş mu?
- Yapılan iş aktif faz maddesine bağlı mı?
- F0.0 intent check durumu ne?

```bash
python3 scripts/governance/validate-yapilacaklar.py
```

### 3. Scope / User Approval

- Kullanıcı onayı gerektiren işlem yapılmış mı?
- Public API, route, schema, auth, scaffold, migration veya destructive işlem var mı?
- Scope dışı refactor veya broad change var mı?

### 4. Security / Privacy

- Secret, token, PII, log redaction riski var mı?
- Auth/session değişikliği var mı?
- İzinsiz file write/delete var mı?

Referans: `docs/03-STANDARDS/SECURITY.md`, `PRIVACY.md`

### 5. Architecture

- Boundary ihlali var mı?
- UI / data / domain ayrımı bozuldu mu?
- Gereksiz abstraction veya broad refactor var mı?

Referans: `.cursor/rules/02-architect.mdc`, `19-claude-reasoning` architecture_check

### 6. Design / Accessibility

- User-facing UI değişikliği var mı?
- i18n, accessibility, hardcoded string, icon policy etkisi var mı?

Referans: `.cursor/rules/03-android-elite.mdc`, `docs/03-STANDARDS/I18N.md` (Android context)

### 7. Validation Evidence

- Hangi komutlar çalıştı?
- Testler / build geçti mi?
- Validation eksikse **CONDITIONAL PASS** veya **NEEDS FIX** ver.

Örnek: `gradle-build-loop.sh`, `factory-health.sh`, `validate-project-intent.py`

### 8. Rollback

- Değişiklik geri alınabilir mi?
- Migration, scaffold veya generated dosya var mı?
- Tek commit revert yeterli mi?

### 9. Next Step

- En doğru hiyerarşik sonraki adım nedir? (`/devam-et`, `/denetle`, `/prompt-genesis`, F0.x)
- Cursor'a verilecek prompt ne olmalı? (contract formatında tek blok)

## Decision Rules

| Karar | Koşul |
|-------|--------|
| **BLOCKED** | Intent/faz/security validation failure; unauthorized destructive işlem; factory-template genesis |
| **NEEDS FIX** | Non-trivial bug, test fail, faz uyumsuzluğu, kanıtsız tamamlandı iddiası |
| **CONDITIONAL PASS** | Validation eksik ama risk düşük; küçük takip işleri var |
| **PASS** | Tüm kritik kontroller temiz; faz ve intent uyumlu |

## Output

`docs/CEVAP_REPORT_CONTRACT.md` içindeki **`/CEVAP REVIEW REPORT`** şablonunu kullan.

**Yasak:** Bu skill çalışırken repo dosyası değiştirme, commit, scaffold veya implementation başlatma.
