---
name: reviews-basics
description: >-
  Ürün yorum/oylama stub — yorumlar tablosu (TR-ASCII) + partial; yalnız ecommerce
  (veya kullanıcı açıkça istedi). Vitrin sitelerine zorlama yok.
category: domain
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: P2
version: "1.1.0"
---

# Reviews Basics (Webrail)

**Durum:** READY · **Paket:** `.factory/modules/reviews` · **Arketip:** ecommerce  
**Adlandırma:** `docs/DB-NAMING.md` — tablo `yorumlar`, FK `urun_id` / `kullanici_id`.

## Process

```bash
bash scripts/web/module-apply.sh . --module reviews
```
