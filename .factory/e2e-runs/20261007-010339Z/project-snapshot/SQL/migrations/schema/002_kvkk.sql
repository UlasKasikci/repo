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
