---
name: auth-rbac
description: Kimlik doğrulama ve rol tabanlı erişim modülü — login/register/logout, session hijyeni, rol hiyerarşisi, password_argon2id; kullanıcı girişi olan her projede P2 öncesi kullan.
---

# Auth & RBAC (iskelet — v2'de doldurulur)

**Durum:** iskelet · **Bağlantı:** `docs/WEB-EDITION.md` §5 (güvenlik tablosu) ·
`qa-gate.sh` → `password_policy`, `security_policy`, `sql_schema` (RBAC) kanalları.

## Ne zaman çağrılır

`users`/`kullanicilar` tablosu domain-report'a girdiği anda — zorunlu modül
(proaktif denetim: Admin/Moderatör/Kullanıcı rol katmanı enjekte edilir).

## Modül adımları (v2 planı — içerik doldurulacak)

1. **Kayıt:** `views/auth/register.php` — e-posta/kullanıcı adı benzersizlik kontrolü,
   `password_hash($p, PASSWORD_ARGON2ID)`, hammadde parola loglanmaz.
2. **Giriş:** `views/auth/login.php` — `password_verify` + başarısız deneme
   rate-limit (oturum/tablo), session fixation: girişte `session_regenerate_id(true)`.
3. **Çıkış:** `core/` logout → tüm oturum verisi temizlenir + cookie silinir.
4. **Rol:** `users.role_id` → `roles` tablosu (FK + seed: admin/moderator/user);
   `core/Auth.php` → `require_role()` / `require_permission()` tek giriş noktası;
   yetkisiz → 403, girişsiz → 302 login.
5. **domain-report:** `file_manifest` → auth view'lar + `core/Auth.php` + SQL (users/roles).

## qa-gate beklentileri

- `password_policy`: kod ARGON2ID/BCRYPT(cost≥12) kullanır (ham md5 → FAIL).
- `sql_schema`: `role_id` FK + seed INSERT (RBAC kanıtı) + sepet/katalog varsa cart flow.
- `security_policy`: login POST'u CSRF token taşır; oturum çerezi HttpOnly/Secure/SameSite.

## Yasak

- Rol kontrolünü tek dosyaya yaymak (merkezi `core/Auth` olmadan FAIL'e gider).
- `password_hash` yerine "md5 + salt" gibi şema (K5 ile de, OWASP ile de çelişir).
