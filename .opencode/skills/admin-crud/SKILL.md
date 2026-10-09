---
name: admin-crud
description: Admin panel CRUD modülü — kullanıcı/rol yönetimi listeleme form sayfalama ve yetki matrisi; yönetim arayüzü olan projelerde P2 öncesi kullan.
---

# Admin CRUD (iskelet — v2'de doldurulur)

**Durum:** iskelet · **Bağlantı:** `docs/WEB-EDITION.md` §3 (RBAC denetimi) ·
`qa-gate.sh` → `structure`, `sql_schema` (RBAC), `security_grep` kanalları.

## Ne zaman çağrılır

`domain-report.json` → `module_matrix` içinde admin/panel/management modülü varken;
`users`/`kullanicilar` tablosu tanımına giriyorsa RBAC ile birlikte.

## Modül adımları (v2 planı — içerik doldurulacak)

1. **Listeleme:** `views/admin/<entity>/index.php` — tablo, filtre, sayfalama
   (PDO `LIMIT/OFFSET` prepared), toplu işlem formu (CSRF token).
2. **Form:** `create.php` / `edit.php` — sunucu doğrulama (422 mantığı), hata mesajı
   `htmlspecialchars` ile basılır (XSS).
3. **Yetki:** her aksiyon `role_id` kontrolünden geçer; yetkisiz → 403 (interceptor
   `core/` içinde, tek noktadan). Admin paneli genel `views/` altında; rota `.htaccess`.
4. **domain-report:** `file_manifest` → tüm admin view'lar + controller + SQL migrasyon.

## qa-gate beklentileri

- RBAC: `users` varsa `role_id`/`permissions` kolonu + kodda parola hash'i (`password_policy`).
- `security_grep`: ham çıktı/superglobal yok; CSRF'siz POST yok.
- N+1 yasağı: liste sorgusu JOIN ile tek seferde.

## Yasak

- Yetki kontrolünü view içinde tek başına yapmak (mantık `core/` + view'da olmalı).
- Admin CRUD'i "iskelet var" diye planlamadan üretmek (P1 dondurulmadan P2 yok).
