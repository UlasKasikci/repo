-- App-Fabrika Web Edition — veritabani.sql (sql-dump.sh ile üretildi)
-- Kaynak: SQL/migrations/schema (2 dosya) + SQL/migrations/seed (1 dosya)
-- Sürüm Tarihi: 2026-10-07 · P2 iskelet: RBAC + iletisim + KVKK (user_consents/anonymization_log) · Kaynak Hash: 07d9b280355f
-- Deterministik: saat damgası yok — aynı kaynak = byte-identical çıktı
-- Elle DÜZENLEMEYİN: kaynakları SQL/migrations/ altında değiştirin, sonra:
--   bash scripts/web/sql-dump.sh <proje>


-- ============ SCHEMA ============
-- source: SQL/migrations/schema/001_core.sql
-- ============================================================
-- App-Fabrika Web Edition — e2e-iletisim
-- 001_core.sql — RBAC (roles/users) + iletisim (messages)
-- Motor: InnoDB · Karakter seti: utf8mb4
-- Sorgu kuralı: uygulama katmanında yalnızca PDO prepared statements
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- roles: rol katmanı (admin | moderator | user)
-- ------------------------------------------------------------
CREATE TABLE roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_name (name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'RBAC rol katmani: admin/moderator/user (P1 domain-report)';

-- ------------------------------------------------------------
-- users: panel kullanıcıları — role_id FK (ON DELETE RESTRICT:
-- kullanıcıya bağlı rol silinemez), Argon2id parola özeti
-- ------------------------------------------------------------
CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_id INT UNSIGNED NOT NULL,
    email VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role_id (role_id),
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Panel kullanicilari — Argon2id hash, oturum fixation korumali';

-- ------------------------------------------------------------
-- messages: iletişim formu kayıtları (anonim ziyaretçi → POST)
-- ip_hash: SHA-256 özeti — ham IP KVKK gereği saklanmaz
-- ------------------------------------------------------------
CREATE TABLE messages (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(190) NOT NULL,
    phone VARCHAR(32) NULL,
    subject VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    ip_hash CHAR(64) NULL,
    status ENUM('new', 'read', 'archived') NOT NULL DEFAULT 'new',
    consent_given TINYINT(1) NOT NULL DEFAULT 0,
    consent_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_messages_status (status),
    KEY idx_messages_created_at (created_at),
    KEY idx_messages_ip_hash (ip_hash),
    CONSTRAINT chk_messages_status CHECK (status IN ('new', 'read', 'archived'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Iletisim formu kayitlari — riza kaydi (consent_given/consent_at) tutulur';

-- source: SQL/migrations/schema/002_kvkk.sql
-- ============================================================
-- App-Fabrika Web Edition — e2e-iletisim
-- 002_kvkk.sql — KVKK/GDPR açık rıza + anonimleştirme izi
-- Rıza kaydı: user_consents (kullanıcı silinince CASCADE ile birlikte silinir)
-- Anonimleştirme izi: anonymization_log (SET NULL — log satırı kalır, kullanıcı bağı kopar)
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- user_consents: açık rıza kayıtları (KVKK m.5/2-a, m.6/2-a; GDPR Art. 6(1)(a), 7)
-- user_id FK CASCADE: kullanıcı silindiğinde rıza kayıtları da silinir
-- ------------------------------------------------------------
CREATE TABLE user_consents (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NULL,
    purpose VARCHAR(100) NOT NULL,
    granted TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_consents_user_id (user_id),
    KEY idx_user_consents_purpose (purpose),
    CONSTRAINT fk_user_consents_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'KVKK/GDPR acik riza kaydi — amaç bazlı, geri alınabilir';

-- ------------------------------------------------------------
-- anonymization_log: anonimleştirme / veri işleme eylem izi (KVKK m.11 silme
-- hakkı; GDPR Art. 17). user_id FK SET NULL: log satırı kalır, kimlik bağı kopar.
-- ------------------------------------------------------------
CREATE TABLE anonymization_log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NULL,
    action VARCHAR(50) NOT NULL,
    basis VARCHAR(190) NOT NULL,
    performed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_anonymization_log_user_id (user_id),
    CONSTRAINT fk_anonymization_log_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Anonimlestirme eylem izi — SET NULL ile kimlik bagı koparılır';

-- ============ SEED ============
-- source: SQL/migrations/seed/001_seed.sql
-- ============================================================
-- App-Fabrika Web Edition — e2e-iletisim
-- 001_seed.sql — seed verisi: 3 rol + 1 örnek yönetici (dev)
-- Seed parola: Fabrika!2026 (PASSWORD_ARGON2ID özeti) — üretimde değiştirin
-- ============================================================

SET NAMES utf8mb4;

INSERT INTO roles (id, name) VALUES
    (1, 'admin'),
    (2, 'moderator'),
    (3, 'user');

INSERT INTO users (id, role_id, email, password_hash, full_name, is_active) VALUES
    (1, 1, 'admin@e2e-iletisim.local',
     '$argon2id$v=19$m=65536,t=4,p=1$S2lkVm5qVVF2WUttcVNPTw$JdoLgkNPgntu+z7oqKLUqExdk+BuC882PPya5WxyVR4',
     'Site Yöneticisi', 1);
