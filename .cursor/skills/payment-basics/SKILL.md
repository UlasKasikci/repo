---
name: payment-basics
description: >-
  E-ticaret ödeme stub — odemeler tablosu (TR-ASCII) + Payment.php; yalnız
  project_type/archetype=ecommerce veya açık brief. Showcase/onepage'e uygulama.
category: domain
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: P2
version: "1.1.0"
---

# Payment Basics (Webrail)

**Durum:** READY · **Paket:** `.factory/modules/payment` · **Arketip:** ecommerce  
**Adlandırma:** `docs/DB-NAMING.md` — tablo `odemeler`, FK `siparis_id`.

## When

- `gap-scan` / `gap-inject` → `payment` proposed
- Brief’te sepet + ödeme / e-ticaret
- **ASLA** showcase / onepage / brochure varsayılanında zorlama

## Process

```bash
bash scripts/web/module-apply.sh . --module payment
# sonra sql-dump + PSP bağlama (iyzico/PayTR) — FIX-BRIEF
```
