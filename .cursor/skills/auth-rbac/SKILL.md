---
name: auth-rbac
description: Kimlik doğrulama ve rol tabanlı erişim modülü — login/register/logout, session hijyeni, rol hiyerarşisi, password_argon2id; kullanıcı girişi olan her projede P2 öncesi kullan.
---

# Auth & RBAC

**Durum:** READY · **Kapı:** `password_policy` + `sql_schema` (RBAC) + `security_policy` · **Karar:** modül `rbac|auth`

## Ne zaman

`users` / `kullanicilar` domain’de varsa **zorunlu** (P1 proaktif denetim).

## Dosya sözleşmesi

| Dosya | Rol |
|-------|-----|
| `SQL/migrations/schema/001_core.sql` | `roles`, `users` (`role_id` FK), seed admin/moderator/user |
| `core/Auth.php` | `attempt`, `logout`, `requireLogin`, `requireRole` |
| `core/AuthController.php` (veya eşdeğeri) | login/register/logout POST — **ilk satır CSRF** |
| `views/login.php` veya `views/auth/login.php` | form + csrf_token |
| `views/auth/register.php` (kayıt varsa) | form + csrf_token |

## SQL çekirdek

```sql
CREATE TABLE IF NOT EXISTS roles (
  id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(32) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id TINYINT UNSIGNED NOT NULL,
  email VARCHAR(191) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO roles (id, name) VALUES (1,'admin'),(2,'moderator'),(3,'user')
  ON DUPLICATE KEY UPDATE name=VALUES(name);
```

## Zorunlu güvenlik kalıpları

```php
// Parola
$hash = password_hash($plain, PASSWORD_ARGON2ID);
password_verify($plain, $hash);

// Oturum (bootstrap / index.php)
session_set_cookie_params([
  'lifetime' => 0, 'path' => '/', 'secure' => true,
  'httponly' => true, 'samesite' => 'Lax',
]);
session_start();
// login başarı: session_regenerate_id(true);

// Her POST controller — ilk iş
guardPost(); // veya Csrf::requireValid();
```

## Uygulama sırası

1. roles/users SQL + seed → `sql-dump.sh`.
2. `core/Auth.php` tek giriş noktası (view’da rol if’i yok).
3. Login/register POST: CSRF → validate → hash/verify → regenerate.
4. Yetkisiz: 403; girişsiz korumalı rota: 302 login.
5. `qa-gate.sh` — password_policy + rbac sütunları PASS.

## Yasak

- md5/sha1 parola; merkezi Auth olmadan dağınık kontroller.
- CSRF’siz register/login POST.
