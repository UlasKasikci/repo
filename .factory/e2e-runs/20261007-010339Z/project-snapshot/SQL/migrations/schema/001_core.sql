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
