---
name: cart-basics
description: >-
  Sepet/sipariş stub — siparisler + siparis_kalemleri (TR-ASCII) + Cart.php;
  ecommerce veya catalog_rfq. Showcase/onepage'e uygulama.
category: domain
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: P2
version: "1.1.0"
---

# Cart Basics (Webrail)

**Durum:** READY · **Paket:** `.factory/modules/cart` · **Arketip:** ecommerce, catalog_rfq  
**Adlandırma:** `docs/DB-NAMING.md` — `siparisler` / `siparis_kalemleri`.

## When

- `gap-scan` → `cart_missing` BLOCKER
- `gap-inject` / decide → `cart` proposed/missing
- **ASLA** showcase / onepage varsayılanında

## Process

```bash
bash scripts/web/module-apply.sh . --module cart
bash scripts/web/sql-dump.sh .
```
