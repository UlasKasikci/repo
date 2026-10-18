---
name: admin-crud
description: Admin panel CRUD modülü — kullanıcı/rol yönetimi listeleme form sayfalama ve yetki matrisi; yönetim arayüzü olan projelerde P2 öncesi kullan.
---

# Admin CRUD

**Durum:** READY · **Kapı:** `structure` + RBAC + CSRF · **Karar:** modül `admin|admin-crud`

## Ne zaman

`module_matrix` içinde admin/panel/management **veya** yönetim ekranı isteniyorsa.
Her zaman `auth-rbac` ile birlikte uygulanır.

## Dosya sözleşmesi

| Dosya | Rol |
|-------|-----|
| `core/AdminController.php` | liste/oluştur/güncelle/sil — her aksiyonda `Auth::requireRole('admin')` |
| `views/admin/users.php` (veya `views/admin/users/index.php`) | liste + CSRF’li formlar |
| `views/admin/messages.php` (iletişim varsa) | aynı kalıp |
| Rotalar | `index.php` / App router — `/admin/*` |

## Uygulama kalıbı

1. **Guard:** controller metodunun ilk satırları: `requireLogin` + `requireRole('admin')` + POST’ta `guardPost()`.
2. **Liste:** PDO prepared `SELECT ... LIMIT :lim OFFSET :off` — string birleştirme yok.
3. **Yazma:** validate → prepared INSERT/UPDATE → flash → redirect.
4. **Çıktı:** tüm alanlar `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`.
5. **N+1 yok:** liste JOIN ile tek sorgu.

## Minimal controller iskeleti

```php
public function users(): void
{
    Auth::requireRole('admin');
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
        guardPost();
        // ... prepared write ...
    }
    $rows = Database::pdo()->query(
        'SELECT u.id, u.email, r.name AS role_name FROM users u JOIN roles r ON r.id = u.role_id ORDER BY u.id'
    )->fetchAll(PDO::FETCH_ASSOC);
    View::render('admin/users', ['users' => $rows]);
}
```

## Uygulama sırası

1. Auth/RBAC hazır değilse önce `auth-rbac` skill.
2. AdminController + views/admin/*.
3. Router’a `/admin` bağla.
4. `qa-gate.sh` PASS.

## Yasak

- Yetkiyi yalnız view’da kontrol etmek.
- CSRF’siz admin POST.
- P1 dondurulmadan admin ekranı üretmek.
