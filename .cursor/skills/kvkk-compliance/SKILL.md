---
name: kvkk-compliance
description: KVKK/GDPR uyumluluk modülü — aydınlatma metinleri, çerez rıza banner'ı, user_consents/anonymization_log şeması; intent.compliance=kvkk|gdpr olan projelerde P2 öncesi kullan.
---

# KVKK/GDPR Compliance

**Durum:** READY · **Kapı:** `qa-gate.sh` → `kvkk` · **Karar:** `decision.json` modules `kvkk|gdpr`

## Ne zaman

`project-intent.json` veya `domain-report.compliance` ∈ `{kvkk, gdpr}` ise P2’de **zorunlu**.

## Dosya sözleşmesi (hepsi zorunlu)

| Dosya | İçerik |
|-------|--------|
| `views/legal/aydinlatma.php` | Veri sorumlusu, amaçlar, haklar (KVKK md. 10/11) — placeholder yasak |
| `views/legal/gizlilik.php` | İşleme, saklama, üçüncü taraflar |
| `views/legal/cerez.php` | Çerez türleri, süre, ret/onay |
| `views/partials/cookie-consent.php` | Banner: kabul / red / tercihler; CSRF’li form veya JS API |
| `assets/js/cookie-consent.js` | Tercihi `localStorage` veya non-HttpOnly çerezde sakla; tekrar aç |
| `SQL/migrations/schema/002_kvkk.sql` | Aşağıdaki tablolar |
| `SQL/veritabani.sql` | `sql-dump.sh` ile yeniden üretilmiş dump |

## SQL (002_kvkk.sql)

```sql
CREATE TABLE IF NOT EXISTS user_consents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  purpose VARCHAR(64) NOT NULL,
  granted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_uc_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS anonymization_log (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(64) NOT NULL,
  basis VARCHAR(128) NOT NULL,
  performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Dump: `bash scripts/web/sql-dump.sh .`

## Uygulama sırası

1. SQL migration yaz → dump üret.
2. Üç legal view + cookie partial + JS yaz (gerçek metin; lorem FAIL).
3. `file_manifest`’e bu yolları ekle (P1’de yoksa P2’de domain-report’u güncelleme — yeni dosyaları üret).
4. Ana layout’ta consent partial’ı include et.
5. `bash scripts/web/qa-gate.sh .` — `kvkk` kanalı PASS.

## Yasak

- Tek bileşenle “yeter” demek.
- Placeholder / lorem yasal metin.
- Dump’ı elle düzenlemek (sql_dump drift FAIL).
