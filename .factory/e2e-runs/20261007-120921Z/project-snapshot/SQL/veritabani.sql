-- App-Fabrika Web Edition — veritabani.sql (sql-dump.sh ile üretildi)
-- Kaynak: SQL/migrations/schema (2 dosya) + SQL/migrations/seed (1 dosya)
-- Sürüm Tarihi: yerel · Kaynak Hash: 82c1e54fe825
-- Deterministik: saat damgası yok — aynı kaynak = byte-identical çıktı
-- Elle DÜZENLEMEYİN: kaynakları SQL/migrations/ altında değiştirin, sonra:
--   bash scripts/web/sql-dump.sh <proje>


-- ============ SCHEMA ============
-- source: SQL/migrations/schema/001_core.sql
-- App-Fabrika Web Edition — e2e-iletisim çekirdek şeması (Agent 2, P2)
-- RBAC enjeksiyonu: roles (Admin/Moderator/User) + users.role_id FK
-- Motor: InnoDB · Karakter seti: utf8mb4 + utf8mb4_unicode_ci · B-Tree index

SET NAMES utf8mb4;

CREATE TABLE roles (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_roles_name (name) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_id INT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email) USING BTREE,
    KEY idx_users_role (role_id) USING BTREE,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE messages (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NULL DEFAULT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(190) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent VARCHAR(255) NULL DEFAULT NULL,
    status ENUM('new','read','archived') NOT NULL DEFAULT 'new',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_messages_status_created (status, created_at) USING BTREE,
    KEY idx_messages_ip (ip_address) USING BTREE,
    KEY idx_messages_user (user_id) USING BTREE,
    CONSTRAINT fk_messages_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- source: SQL/migrations/schema/002_kvkk.sql
-- App-Fabrika Web Edition — e2e-iletisim KVKK/GDPR uyum şeması (Agent 2, P2)
-- 6698 sayılı KVKK m.5/1 (açık rıza) + m.11 (ilgili kişinin hakları) kapsamında:
--   user_consents     → açık rıza kaydı (çerez onay banner'ı + yasal metin onayları)
--   anonymization_log → anonimleştirme izi (users fiziksel silinmez; iz bırakılır)
-- Boş şema (seed yok) · users FK'ları ON DELETE SET NULL · InnoDB · utf8mb4

SET NAMES utf8mb4;

CREATE TABLE user_consents (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NULL DEFAULT NULL,
    email VARCHAR(190) NULL DEFAULT NULL,
    purpose VARCHAR(255) NOT NULL,
    consent_type VARCHAR(50) NOT NULL,
    consent_text_version VARCHAR(20) NOT NULL,
    granted TINYINT(1) NOT NULL DEFAULT 1,
    ip_address VARCHAR(45) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_consents_email (email) USING BTREE,
    KEY idx_consents_user (user_id) USING BTREE,
    CONSTRAINT fk_consents_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE anonymization_log (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entity VARCHAR(50) NOT NULL,
    entity_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NULL DEFAULT NULL,
    action VARCHAR(50) NOT NULL,
    basis VARCHAR(255) NOT NULL,
    performed_by INT UNSIGNED NULL DEFAULT NULL,
    reason VARCHAR(255) NOT NULL,
    performed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_anonym_entity (entity, entity_id) USING BTREE,
    KEY idx_anonym_user (user_id) USING BTREE,
    KEY idx_anonym_performer (performed_by) USING BTREE,
    CONSTRAINT fk_anonym_user FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_anonym_performer FOREIGN KEY (performed_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ SEED ============
-- source: SQL/migrations/seed/001_seed.sql
-- App-Fabrika Web Edition — e2e-iletisim seed verisi (Agent 2, P2)
-- 4 satır: 3 rol (RBAC katmanı) + 1 admin hesabı (PASSWORD_ARGON2ID hash).
-- NOT: admin@example.com / Fabrika!2026 bir DEMO hesabıdır — canlıya almadan önce
-- parola mutlaka değiştirilmelidir (Argon2id hash, password_verify ile doğrulanır).
-- messages / user_consents / anonymization_log boş şema olarak teslim edilir.

SET NAMES utf8mb4;

INSERT INTO roles (id, name) VALUES
    (1, 'Admin'),
    (2, 'Moderator'),
    (3, 'User');

INSERT INTO users (role_id, name, email, password_hash, is_active) VALUES
    (1, 'Site Yöneticisi', 'admin@example.com', '$argon2id$v=19$m=65536,t=4,p=1$bklzbEhxTjBVMlZFL2lsNw$EEsoTW/US+4ijyNvNaMlcCOZyexkx4ahZBZHlZ3mIlg', 1);
