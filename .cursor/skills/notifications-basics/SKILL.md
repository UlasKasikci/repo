---
name: notifications-basics
description: >-
  Bildirim stub — bildirimler tablosu + Notification.php; TR-ASCII adlandırma.
  E-posta/SMS sağlayıcı P2'de bağlanır.
category: domain
applies-to: [cursor, opencode, claude, antigravity]
webrail_phase: P2
version: "1.0.0"
---

# Notifications Basics (Webrail)

**Durum:** READY · **Paket:** `.factory/modules/notifications`

```bash
bash scripts/web/module-apply.sh . --module notifications
bash scripts/web/sql-dump.sh .
```

İkonlar UI'da SVG; emoji chrome yasak (`docs/UI-DESIGN-STANDARDS.md`).
